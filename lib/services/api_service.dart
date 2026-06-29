// lib/services/api_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Automatically picks the right host:
  //   Android emulator → 10.0.2.2
  //   iOS simulator    → 127.0.0.1
  //   Web / desktop    → 127.0.0.1
  // Override via --dart-define=API_BASE_URL=... at build time.
  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/v1';
  }

  static final String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  late final Dio _dio;
  // Separate client with NO interceptors, for the token-exchange/refresh calls
  // themselves — avoids recursion and never attaches a token to public routes.
  late final Dio _authDio;

  // Backend session tokens, obtained by exchanging the Firebase ID token.
  String? _accessToken;
  String? _refreshToken;
  String? _tokenUid;            // Firebase uid these tokens belong to
  Future<String?>? _pendingExchange;

  static const _kAccess  = 'argentum_backend_access';
  static const _kRefresh = 'argentum_backend_refresh';
  static const _kUid     = 'argentum_backend_uid';

  ApiService() {
    final opts = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    );
    _dio = Dio(opts);
    _authDio = Dio(opts);

    _loadTokens();

    // Auth interceptor — attach the BACKEND access token. The backend cannot
    // validate a raw Firebase ID token (it issues its own HS256 JWT), so we
    // exchange the Firebase token for a backend session on demand.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _backendAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        final isAuthError = e.response?.statusCode == 401;
        final alreadyRetried = e.requestOptions.extra['retried'] == true;

        // 401 → refresh/re-exchange the backend session once per request.
        if (isAuthError && !alreadyRetried) {
          final newToken = await _refreshBackendSession();
          if (newToken != null) {
            e.requestOptions.extra['retried'] = true;
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            try {
              final retry = await _dio.fetch(e.requestOptions);
              return handler.resolve(retry);
            } catch (_) {
              return handler.next(e);
            }
          }
        }
        handler.next(e);
      },
    ));
  }

  // ── Backend session management ────────────────────────────────────────
  // Flow: sign in with Firebase → exchange the Firebase ID token for the
  // backend's JWT via POST /auth/firebase → carry that token on every call.

  Future<void> _loadTokens() async {
    try {
      final p = await SharedPreferences.getInstance();
      _accessToken  = p.getString(_kAccess);
      _refreshToken = p.getString(_kRefresh);
      _tokenUid     = p.getString(_kUid);
    } catch (_) {/* prefs unavailable — tokens stay null, exchange on demand */}
  }

  Future<void> _saveTokens() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (_accessToken  != null) await p.setString(_kAccess, _accessToken!);
      if (_refreshToken != null) await p.setString(_kRefresh, _refreshToken!);
      if (_tokenUid     != null) await p.setString(_kUid, _tokenUid!);
    } catch (_) {/* best-effort persistence */}
  }

  /// A valid backend access token for the CURRENT Firebase user, exchanging on
  /// demand. Null if nobody is signed in.
  Future<String?> _backendAccessToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    // Reuse the cached token only if it belongs to the signed-in user.
    if (_accessToken != null && _tokenUid == uid) return _accessToken;
    // Account switch or no token yet → exchange.
    _accessToken = null;
    _refreshToken = null;
    return _exchangeFirebaseForBackend();
  }

  /// Exchange the current Firebase ID token for backend JWTs. Concurrent
  /// callers share a single in-flight exchange.
  Future<String?> _exchangeFirebaseForBackend() {
    return _pendingExchange ??=
        _doExchange().whenComplete(() => _pendingExchange = null);
  }

  Future<String?> _doExchange() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    String? idToken;
    try {
      idToken = await user.getIdToken().timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
    if (idToken == null) return null;
    try {
      final r = await _authDio.post('/auth/firebase', data: {
        'firebase_token': idToken,
        if (user.displayName != null) 'name': user.displayName,
      });
      _accessToken  = r.data['access_token']  as String?;
      _refreshToken = r.data['refresh_token'] as String?;
      _tokenUid     = user.uid;
      await _saveTokens();
      return _accessToken;
    } catch (_) {
      return null;
    }
  }

  /// On 401: try the backend refresh token; if that fails, re-exchange with a
  /// fresh Firebase ID token.
  Future<String?> _refreshBackendSession() async {
    if (_refreshToken != null) {
      try {
        final r = await _authDio.post('/auth/refresh',
            data: {'refresh_token': _refreshToken});
        _accessToken  = r.data['access_token']  as String?;
        _refreshToken = (r.data['refresh_token'] as String?) ?? _refreshToken;
        await _saveTokens();
        return _accessToken;
      } catch (_) {/* refresh expired/invalid — fall through to re-exchange */}
    }
    _accessToken = null;
    return _exchangeFirebaseForBackend();
  }

  /// Clear the backend session (call on sign-out). Safe to call anytime.
  Future<void> clearBackendSession() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenUid = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_kAccess);
      await p.remove(_kRefresh);
      await p.remove(_kUid);
    } catch (_) {}
  }

  // ─── Dashboard ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final r = await _dio.get('/dashboard/');
    return r.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getLearningGraph() async {
    final r = await _dio.get('/dashboard/learning-graph');
    return (r.data['learning_graph'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getTopicBreakdown() async {
    final r = await _dio.get('/dashboard/topic-breakdown');
    return {'topics': r.data};
  }

  Future<Map<String, dynamic>> getWeeklyProgress() async {
    final r = await _dio.get('/dashboard/weekly-progress');
    return {'weeks': r.data};
  }

  // ─── Files ──────────────────────────────────────────────────────────

  /// Upload using raw bytes — works on Flutter web and native.
  /// Use this everywhere: on web, [Uint8List] is the only option;
  /// on native it's equally valid and avoids dart:io path issues.
  Future<Map<String, dynamic>> uploadFileBytes(
      Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final r = await _dio.post(
      '/files/upload',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return r.data as Map<String, dynamic>;
  }

  /// Upload using a [File] path — native (Android/iOS/Windows) only.
  /// Prefer [uploadFileBytes] for cross-platform code.
  Future<Map<String, dynamic>> uploadFile(File file, String filename) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: filename),
    });
    final r = await _dio.post(
      '/files/upload',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFileStatus(String fileId) async {
    final r = await _dio.get('/files/$fileId/status');
    return r.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listFiles() async {
    final r = await _dio.get('/files/');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> deleteFile(String fileId) async {
    await _dio.delete('/files/$fileId');
  }

  // ─── Questions ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQuestions({
    String? topic,
    String? difficulty,
    String? fileId,
    int limit = 50,
  }) async {
    final r = await _dio.get('/questions/', queryParameters: {
      if (topic != null) 'topic': topic,
      if (difficulty != null) 'difficulty': difficulty,
      if (fileId != null) 'file_id': fileId,
      'limit': limit,
    });
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getTopics() async {
    final r = await _dio.get('/questions/topics');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getQuestion(String questionId) async {
    final r = await _dio.get('/questions/$questionId');
    return r.data as Map<String, dynamic>;
  }

  Future<void> submitQuestionFeedback(String questionId, String feedbackType,
      {String? comment}) async {
    await _dio.post('/questions/$questionId/feedback', data: {
      'feedback_type': feedbackType,
      if (comment != null) 'comment': comment,
    });
  }

  Future<void> rateExplanation(String questionId, String rating) async {
    await _dio.post('/questions/$questionId/explanation-rating',
        queryParameters: {'rating': rating});
  }

  // ─── Tests ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startTest({
    required String mode,
    String? topicFilter,
    int questionCount = 10,
    int? timeLimitSeconds,
    String? difficulty,
    String? fileId,
  }) async {
    final r = await _dio.post('/tests/start', data: {
      'mode': mode,
      if (topicFilter != null) 'topic_filter': topicFilter,
      'question_count': questionCount,
      if (timeLimitSeconds != null) 'time_limit_seconds': timeLimitSeconds,
      if (difficulty != null) 'difficulty': difficulty,
      if (fileId != null) 'file_id': fileId,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSessionQuestions(
      String sessionId) async {
    final r = await _dio.get('/tests/$sessionId/questions');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required String questionId,
    required String selectedAnswer,
    required double timeTakenSeconds,
    String? confidence,
  }) async {
    final r = await _dio.post('/tests/$sessionId/answer', data: {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
      'time_taken_seconds': timeTakenSeconds,
      if (confidence != null) 'confidence': confidence,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeTest(String sessionId) async {
    final r = await _dio.post('/tests/$sessionId/complete');
    return r.data as Map<String, dynamic>;
  }

  Future<void> abandonTest(String sessionId) async {
    await _dio.post('/tests/$sessionId/abandon');
  }

  Future<List<Map<String, dynamic>>> getTestHistory({int limit = 10}) async {
    final r = await _dio.get('/tests/history', queryParameters: {'limit': limit});
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  // ─── Recovery ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWeaknesses() async {
    final r = await _dio.get('/recovery/weaknesses');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMastery() async {
    final r = await _dio.get('/recovery/mastery');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> startRecoverySession(String topic,
      {int questionCount = 10}) async {
    final r = await _dio.post('/recovery/start', data: {
      'topic': topic,
      'question_count': questionCount,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSuggestedRecovery() async {
    final r = await _dio.get('/recovery/suggested');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  // ─── Tutor ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> chatWithTutor({
    required String message,
    String? topicContext,
    String? fileId,
    String? sessionId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final r = await _dio.post('/tutor/chat', data: {
      'message': message,
      if (topicContext != null) 'topic_context': topicContext,
      if (fileId != null) 'file_id': fileId,
      if (sessionId != null) 'session_id': sessionId,
      'conversation_history': conversationHistory ?? [],
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> explainQuestion(String questionId) async {
    final r = await _dio.post('/tutor/explain-question',
        queryParameters: {'question_id': questionId});
    return r.data as Map<String, dynamic>;
  }

  // ─── User ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final r = await _dio.get('/users/me');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
      {String? name, String? university}) async {
    final r = await _dio.patch('/users/me', data: {
      if (name != null) 'name': name,
      if (university != null) 'university': university,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStats() async {
    final r = await _dio.get('/users/me/stats');
    return r.data as Map<String, dynamic>;
  }
}

// Extension for account deletion (called from settings_screen.dart)
extension ApiServiceAccount on ApiService {
  Future<void> deleteAccount() async {
    await _dio.delete('/users/me');
  }
}