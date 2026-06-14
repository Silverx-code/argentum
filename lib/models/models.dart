// lib/models/models.dart

// ─── Question ───────────────────────────────────────────────────────────────

class Question {
  final String id;
  final String topic;
  final String? subtopic;
  final String difficulty;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String? correctAnswer;  // null when hidden during test
  final String? explanation;
  final int timeAllocationSeconds;

  const Question({
    required this.id,
    required this.topic,
    this.subtopic,
    required this.difficulty,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    this.correctAnswer,
    this.explanation,
    this.timeAllocationSeconds = 60,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['id'] as String,
    topic: j['topic'] as String,
    subtopic: j['subtopic'] as String?,
    difficulty: j['difficulty'] as String,
    questionText: j['question_text'] as String,
    optionA: j['option_a'] as String,
    optionB: j['option_b'] as String,
    optionC: j['option_c'] as String,
    optionD: j['option_d'] as String,
    correctAnswer: j['correct_answer'] as String?,
    explanation: j['explanation'] as String?,
    timeAllocationSeconds: j['time_allocation_seconds'] as int? ?? 60,
  );

  String optionFor(String letter) {
    switch (letter.toUpperCase()) {
      case 'A': return optionA;
      case 'B': return optionB;
      case 'C': return optionC;
      case 'D': return optionD;
      default: return '';
    }
  }
}

// ─── Test Session ────────────────────────────────────────────────────────────

class TestSession {
  final String id;
  final String mode;
  final String status;
  final String? topicFilter;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctAnswers;
  final double scorePercentage;
  final int? timeLimitSeconds;
  final bool isRecoverySession;

  const TestSession({
    required this.id,
    required this.mode,
    required this.status,
    this.topicFilter,
    required this.totalQuestions,
    this.answeredQuestions = 0,
    this.correctAnswers = 0,
    this.scorePercentage = 0,
    this.timeLimitSeconds,
    this.isRecoverySession = false,
  });

  factory TestSession.fromJson(Map<String, dynamic> j) => TestSession(
    id: j['id'] as String,
    mode: j['mode'] as String,
    status: j['status'] as String,
    topicFilter: j['topic_filter'] as String?,
    totalQuestions: j['total_questions'] as int,
    answeredQuestions: j['answered_questions'] as int? ?? 0,
    correctAnswers: j['correct_answers'] as int? ?? 0,
    scorePercentage: (j['score_percentage'] as num?)?.toDouble() ?? 0,
    timeLimitSeconds: j['time_limit_seconds'] as int?,
    isRecoverySession: j['is_recovery_session'] as bool? ?? false,
  );
}

// ─── Weakness ────────────────────────────────────────────────────────────────

class Weakness {
  final String id;
  final String topic;
  final String? subtopic;
  final double accuracy;
  final int totalAttempts;
  final double confidenceGap;

  const Weakness({
    required this.id,
    required this.topic,
    this.subtopic,
    required this.accuracy,
    required this.totalAttempts,
    this.confidenceGap = 0,
  });

  factory Weakness.fromJson(Map<String, dynamic> j) => Weakness(
    id: j['id'] as String,
    topic: j['topic'] as String,
    subtopic: j['subtopic'] as String?,
    accuracy: (j['accuracy'] as num).toDouble(),
    totalAttempts: j['total_attempts'] as int,
    confidenceGap: (j['confidence_gap'] as num?)?.toDouble() ?? 0,
  );
}

// ─── Topic ───────────────────────────────────────────────────────────────────

class Topic {
  final String name;
  final int questionCount;
  final double? accuracy;
  final bool isMastered;
  final String status;

  const Topic({
    required this.name,
    required this.questionCount,
    this.accuracy,
    this.isMastered = false,
    this.status = 'not_attempted',
  });

  factory Topic.fromJson(Map<String, dynamic> j) => Topic(
    name: j['topic'] as String,
    questionCount: j['question_count'] as int? ?? j['total_questions_available'] as int? ?? 0,
    accuracy: (j['accuracy'] as num?)?.toDouble(),
    isMastered: j['is_mastered'] as bool? ?? false,
    status: j['status'] as String? ?? 'not_attempted',
  );
}

// ─── Uploaded File ───────────────────────────────────────────────────────────

class UploadedFileRecord {
  final String id;
  final String originalFilename;
  final String fileType;
  final String status;
  final String? topicName;
  final int questionsGenerated;

  const UploadedFileRecord({
    required this.id,
    required this.originalFilename,
    required this.fileType,
    required this.status,
    this.topicName,
    this.questionsGenerated = 0,
  });

  factory UploadedFileRecord.fromJson(Map<String, dynamic> j) => UploadedFileRecord(
    id: j['id'] as String,
    originalFilename: j['original_filename'] as String,
    fileType: j['file_type'] as String,
    status: j['status'] as String,
    topicName: j['topic_name'] as String?,
    questionsGenerated: j['questions_generated'] as int? ?? 0,
  );

  bool get isReady => status == 'ready';
  bool get isProcessing => status == 'processing' || status == 'uploaded';
  bool get hasFailed => status == 'failed';
}

// ─── Dashboard ───────────────────────────────────────────────────────────────

class DashboardData {
  final double overallAccuracy;
  final int totalQuestionsAnswered;
  final int streakCount;
  final List<Weakness> weakestTopics;
  final List<Weakness> strongestTopics;
  final int recoverySessionsAvailable;
  final List<Map<String, dynamic>> improvementTrend;

  const DashboardData({
    required this.overallAccuracy,
    required this.totalQuestionsAnswered,
    required this.streakCount,
    required this.weakestTopics,
    required this.strongestTopics,
    required this.recoverySessionsAvailable,
    required this.improvementTrend,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    overallAccuracy: (j['overall_accuracy'] as num?)?.toDouble() ?? 0,
    totalQuestionsAnswered: j['total_questions_answered'] as int? ?? 0,
    streakCount: j['streak_count'] as int? ?? 0,
    weakestTopics: (j['weakest_topics'] as List?)
        ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    strongestTopics: (j['strongest_topics'] as List?)
        ?.map((e) => Weakness.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    recoverySessionsAvailable: j['recovery_sessions_available'] as int? ?? 0,
    improvementTrend: (j['improvement_trend'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [],
  );
}

// ─── Tutor Message ───────────────────────────────────────────────────────────

class TutorMessage {
  final String role; // 'user' or 'ai'
  final String content;
  final DateTime timestamp;

  const TutorMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

// ─── Answer Result ───────────────────────────────────────────────────────────

class AnswerResult {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final double timeTakenSeconds;

  const AnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.timeTakenSeconds,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> j) => AnswerResult(
    isCorrect: j['is_correct'] as bool,
    correctAnswer: j['correct_answer'] as String,
    explanation: j['explanation'] as String,
    timeTakenSeconds: (j['time_taken_seconds'] as num).toDouble(),
  );
}
