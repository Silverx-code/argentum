// lib/providers/app_provider.dart
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ─── Dashboard state ────────────────────────────────────────────────
  DashboardData? _dashboard;
  bool _dashboardLoading = false;
  String? _dashboardError;

  DashboardData? get dashboard => _dashboard;
  bool get dashboardLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  // ─── Topics ─────────────────────────────────────────────────────────
  List<Topic> _topics = [];
  bool _topicsLoading = false;

  List<Topic> get topics => _topics;
  bool get topicsLoading => _topicsLoading;

  // ─── Weaknesses ─────────────────────────────────────────────────────
  List<Weakness> _weaknesses = [];
  List<Map<String, dynamic>> _suggestedRecovery = [];

  List<Weakness> get weaknesses => _weaknesses;
  List<Map<String, dynamic>> get suggestedRecovery => _suggestedRecovery;

  // ─── Files ──────────────────────────────────────────────────────────
  List<UploadedFileRecord> _files = [];
  bool _filesLoading = false;

  List<UploadedFileRecord> get files => _files;
  bool get filesLoading => _filesLoading;

  // ─── Active test session ────────────────────────────────────────────
  TestSession? _activeSession;
  List<Question> _sessionQuestions = [];
  int _currentQuestionIndex = 0;
  Map<String, AnswerResult> _answerResults = {};
  int _correctInSession = 0;
  DateTime? _questionStartTime;

  TestSession? get activeSession => _activeSession;
  List<Question> get sessionQuestions => _sessionQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<String, AnswerResult> get answerResults => _answerResults;
  int get correctInSession => _correctInSession;

  Question? get currentQuestion =>
      _currentQuestionIndex < _sessionQuestions.length
          ? _sessionQuestions[_currentQuestionIndex]
          : null;

  bool get isLastQuestion =>
      _currentQuestionIndex >= _sessionQuestions.length - 1;

  double get sessionProgress => _sessionQuestions.isEmpty
      ? 0
      : _currentQuestionIndex / _sessionQuestions.length;

  // ─── Load dashboard ─────────────────────────────────────────────────

  Future<void> loadDashboard() async {
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      final data = await _api.getDashboard();
      _dashboard = DashboardData.fromJson(data);
    } catch (e) {
      _dashboardError = 'Failed to load dashboard';
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  // ─── Load topics ────────────────────────────────────────────────────

  Future<void> loadTopics() async {
    _topicsLoading = true;
    notifyListeners();
    try {
      final data = await _api.getTopics();
      _topics = data.map(Topic.fromJson).toList();
    } catch (_) {} finally {
      _topicsLoading = false;
      notifyListeners();
    }
  }

  // ─── Load weaknesses ────────────────────────────────────────────────

  Future<void> loadWeaknesses() async {
    try {
      final data = await _api.getWeaknesses();
      _weaknesses = data.map(Weakness.fromJson).toList();
      final recovery = await _api.getSuggestedRecovery();
      _suggestedRecovery = recovery;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Load files ─────────────────────────────────────────────────────

  Future<void> loadFiles() async {
    _filesLoading = true;
    notifyListeners();
    try {
      final data = await _api.listFiles();
      _files = data.map(UploadedFileRecord.fromJson).toList();
    } catch (_) {} finally {
      _filesLoading = false;
      notifyListeners();
    }
  }

  void addFile(UploadedFileRecord file) {
    _files.insert(0, file);
    notifyListeners();
  }

  void updateFileStatus(String fileId, String status, {String? topicName, int? questionsGenerated}) {
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx != -1) {
      _files[idx] = UploadedFileRecord(
        id: fileId,
        originalFilename: _files[idx].originalFilename,
        fileType: _files[idx].fileType,
        status: status,
        topicName: topicName ?? _files[idx].topicName,
        questionsGenerated: questionsGenerated ?? _files[idx].questionsGenerated,
      );
      notifyListeners();
    }
  }

  // ─── Test session flow ──────────────────────────────────────────────

  Future<bool> startTest({
    required String mode,
    String? topicFilter,
    int questionCount = 10,
    int? timeLimitSeconds,
    String? difficulty,
    String? fileId,
  }) async {
    try {
      final sessionData = await _api.startTest(
        mode: mode,
        topicFilter: topicFilter,
        questionCount: questionCount,
        timeLimitSeconds: timeLimitSeconds,
        difficulty: difficulty,
        fileId: fileId,
      );
      _activeSession = TestSession.fromJson(sessionData);

      final questionsData = await _api.getSessionQuestions(_activeSession!.id);
      _sessionQuestions = questionsData.map(Question.fromJson).toList();
      _currentQuestionIndex = 0;
      _answerResults = {};
      _correctInSession = 0;
      _questionStartTime = DateTime.now();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Start test error: $e');
      return false;
    }
  }

  void markQuestionStart() {
    _questionStartTime = DateTime.now();
  }

  Future<AnswerResult?> submitAnswer(String selectedAnswer, {String? confidence}) async {
    if (_activeSession == null || currentQuestion == null) return null;
    final timeTaken = DateTime.now()
        .difference(_questionStartTime ?? DateTime.now())
        .inMilliseconds / 1000.0;

    try {
      final data = await _api.submitAnswer(
        sessionId: _activeSession!.id,
        questionId: currentQuestion!.id,
        selectedAnswer: selectedAnswer,
        timeTakenSeconds: timeTaken,
        confidence: confidence,
      );
      final result = AnswerResult.fromJson(data);
      _answerResults[currentQuestion!.id] = result;
      if (result.isCorrect) _correctInSession++;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Submit answer error: $e');
      return null;
    }
  }

  void advanceToNextQuestion() {
    if (!isLastQuestion) {
      _currentQuestionIndex++;
      _questionStartTime = DateTime.now();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> completeTest() async {
    if (_activeSession == null) return null;
    try {
      final data = await _api.completeTest(_activeSession!.id);
      // Refresh weaknesses and dashboard after test
      loadWeaknesses();
      loadDashboard();
      return data;
    } catch (e) {
      debugPrint('Complete test error: $e');
      return null;
    }
  }

  void clearSession() {
    _activeSession = null;
    _sessionQuestions = [];
    _currentQuestionIndex = 0;
    _answerResults = {};
    _correctInSession = 0;
    notifyListeners();
  }
}
