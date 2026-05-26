// lib/presentation/providers/ai_provider.dart

import 'package:flutter/material.dart';
import '../../data/datasources/api_service.dart';
import '../../data/datasources/supabase_service.dart';
import '../../data/models/quiz_model.dart';

enum AiStatus { idle, loading, loaded, error }

class AiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SupabaseService _supabase = SupabaseService();

  // Summary state
  AiStatus _summaryStatus = AiStatus.idle;
  String? _summary;

  // Explanation state
  AiStatus _explainStatus = AiStatus.idle;
  String? _explanation;

  // Quiz state
  AiStatus _quizStatus = AiStatus.idle;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _quizCompleted = false;
  List<int?> _userAnswers = [];

  String? _errorMessage;

  // Getters - Summary
  AiStatus get summaryStatus => _summaryStatus;
  String? get summary => _summary;

  // Getters - Explanation
  AiStatus get explainStatus => _explainStatus;
  String? get explanation => _explanation;

  // Getters - Quiz
  AiStatus get quizStatus => _quizStatus;
  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  bool get quizCompleted => _quizCompleted;
  List<int?> get userAnswers => _userAnswers;
  String? get errorMessage => _errorMessage;
  QuizQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentQuestionIndex < _questions.length
          ? _questions[_currentQuestionIndex]
          : null;
  double get quizProgress =>
      _questions.isEmpty ? 0 : (_currentQuestionIndex / _questions.length);
  int get totalQuestions => _questions.length;

  // ─── SUMMARY ──────────────────────────────────────────────────────────────

  Future<void> summarizeNote(String content, {String? fileUrl, String? fileType}) async {
    try {
      _summaryStatus = AiStatus.loading;
      _summary = null;
      _errorMessage = null;
      notifyListeners();

      _summary = await _api.summarizeNote(content, fileUrl: fileUrl, fileType: fileType);
      _summaryStatus = AiStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _summaryStatus = AiStatus.error;
    }
    notifyListeners();
  }

  // ─── EXPLANATION ──────────────────────────────────────────────────────────

  Future<void> explainText(String text) async {
    try {
      _explainStatus = AiStatus.loading;
      _explanation = null;
      _errorMessage = null;
      notifyListeners();

      _explanation = await _api.explainText(text);
      _explainStatus = AiStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _explainStatus = AiStatus.error;
    }
    notifyListeners();
  }

  // ─── QUIZ GENERATION ──────────────────────────────────────────────────────

  Future<void> generateQuiz({
    required String content,
    required String noteId,
    required String userId,
    int numQuestions = 5,
    String? fileUrl,
    String? fileType,
  }) async {
    try {
      _quizStatus = AiStatus.loading;
      _questions = [];
      _errorMessage = null;
      _resetQuizState();
      notifyListeners();

      _questions = await _api.generateQuiz(
        content: content,
        numQuestions: numQuestions,
        fileUrl: fileUrl,
        fileType: fileType,
      );

      // Persist questions in Supabase
      await _supabase.saveQuiz(
        noteId: noteId,
        userId: userId,
        questions: _questions,
      );

      _userAnswers = List.filled(_questions.length, null);
      _quizStatus = AiStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _quizStatus = AiStatus.error;
    }
    notifyListeners();
  }

  // ─── QUIZ GAMEPLAY ────────────────────────────────────────────────────────

  /// Answer the current question
  void answerQuestion(int selectedIndex) {
    if (_currentQuestionIndex >= _questions.length) return;
    _userAnswers[_currentQuestionIndex] = selectedIndex;

    if (selectedIndex == _questions[_currentQuestionIndex].correctIndex) {
      _score++;
    }
    notifyListeners();
  }

  /// Move to the next question or complete the quiz
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _quizCompleted = true;
    }
    notifyListeners();
  }

  /// Save the completed quiz result
  Future<void> saveResult({
    required String userId,
    required String noteId,
  }) async {
    final result = QuizResultModel(
      id: '',
      userId: userId,
      noteId: noteId,
      score: _score,
      totalQuestions: _questions.length,
      createdAt: DateTime.now(),
    );
    await _supabase.saveQuizResult(result);
  }

  /// Reset quiz to play again
  void resetQuiz() {
    _resetQuizState();
    notifyListeners();
  }

  void _resetQuizState() {
    _currentQuestionIndex = 0;
    _score = 0;
    _quizCompleted = false;
    _userAnswers = List.filled(_questions.length, null);
  }

  void clearSummary() {
    _summary = null;
    _summaryStatus = AiStatus.idle;
    notifyListeners();
  }

  void clearExplanation() {
    _explanation = null;
    _explainStatus = AiStatus.idle;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
