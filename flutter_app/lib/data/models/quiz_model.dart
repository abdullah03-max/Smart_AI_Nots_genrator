// lib/data/models/quiz_model.dart

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;   // 4 MCQ options
  final int correctIndex;       // 0-3
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
      };
}

class QuizModel {
  final String id;
  final String noteId;
  final String userId;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  QuizModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.questions,
    required this.createdAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] ?? '',
      noteId: json['note_id'] ?? '',
      userId: json['user_id'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class QuizResultModel {
  final String id;
  final String userId;
  final String noteId;
  final int score;
  final int totalQuestions;
  final DateTime createdAt;

  QuizResultModel({
    required this.id,
    required this.userId,
    required this.noteId,
    required this.score,
    required this.totalQuestions,
    required this.createdAt,
  });

  double get percentage => totalQuestions > 0
      ? (score / totalQuestions) * 100
      : 0;

  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      noteId: json['note_id'] ?? '',
      score: json['score'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'note_id': noteId,
        'score': score,
        'total_questions': totalQuestions,
      };
}
