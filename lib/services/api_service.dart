// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1', // Android emulator localhost
  );

  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — auto-attach Firebase ID token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 401 → try refreshing token once
        if (e.response?.statusCode == 401) {
          final newToken = await _refreshToken();
          if (newToken != null) {
            e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retry = await _dio.fetch(e.requestOptions);
            return handler.resolve(retry);
          }
        }
        handler.next(e);
      },
    ));
  }

  Future<String?> _getToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _refreshToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (_) {
      return null;
    }
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

  Future<Map<String, dynamic>> uploadFile(File file, String filename) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: filename),
    });
    final r = await _dio.post('/files/upload', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
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

  Future<void> submitQuestionFeedback(String questionId, String feedbackType, {String? comment}) async {
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

  Future<List<Map<String, dynamic>>> getSessionQuestions(String sessionId) async {
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

  Future<Map<String, dynamic>> startRecoverySession(String topic, {int questionCount = 10}) async {
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

  Future<Map<String, dynamic>> updateProfile({String? name, String? university}) async {
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