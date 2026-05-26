// lib/presentation/screens/quiz/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class QuizScreen extends StatefulWidget {
  final NoteModel note;

  const QuizScreen({super.key, required this.note});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    final auth = context.read<AuthProvider>();
    await context.read<AiProvider>().generateQuiz(
          content: widget.note.content,
          noteId: widget.note.id,
          userId: auth.currentUser?.id ?? '',
          numQuestions: AppConstants.defaultQuizQuestions,
          fileUrl: widget.note.fileUrl,
          fileType: widget.note.fileType,
        );
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });
    context.read<AiProvider>().answerQuestion(index);
  }

  void _next() {
    setState(() {
      _selectedAnswer = null;
      _answered = false;
    });
    final ai = context.read<AiProvider>();
    ai.nextQuestion();
    if (ai.quizCompleted) {
      _saveAndNavigate();
    }
  }

  Future<void> _saveAndNavigate() async {
    final auth = context.read<AuthProvider>();
    await context.read<AiProvider>().saveResult(
          userId: auth.currentUser?.id ?? '',
          noteId: widget.note.id,
        );
    if (mounted) {
      Navigator.of(context)
          .pushReplacementNamed(AppRouter.quizResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, ai, _) {
        // ── Loading ──────────────────────────────────────────────────
        if (ai.quizStatus == AiStatus.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Generating Quiz')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  const Text('AI is generating your quiz...',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  const Text('This may take a few seconds',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // ── Error ────────────────────────────────────────────────────
        if (ai.quizStatus == AiStatus.error) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppTheme.errorRed, size: 64),
                    const SizedBox(height: 16),
                    const Text('Failed to generate quiz',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      ai.errorMessage ??
                          'Make sure the backend server is running.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Try Again',
                      icon: Icons.refresh_rounded,
                      onPressed: _generateQuiz,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Quiz Active ──────────────────────────────────────────────
        final question = ai.currentQuestion;
        if (question == null) return const SizedBox();

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Question ${ai.currentQuestionIndex + 1} of ${ai.totalQuestions}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quit',
                    style: TextStyle(color: AppTheme.errorRed)),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Progress bar ─────────────────────────────────────
              LinearProgressIndicator(
                value: ai.quizProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryPurple),
                minHeight: 6,
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppTheme.warningAmber, size: 16),
                                const SizedBox(width: 4),
                                Text('Score: ${ai.score}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryPurple)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Question card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryPurple.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ${ai.currentQuestionIndex + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              question.question,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: -0.1),

                      const SizedBox(height: 24),

                      // Options
                      ...question.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        return _OptionTile(
                          label: String.fromCharCode(65 + index), // A B C D
                          text: option,
                          state: _getOptionState(index, question.correctIndex),
                          onTap: () => _selectAnswer(index),
                        )
                            .animate()
                            .fadeIn(
                                delay: (index * 80).ms, duration: 300.ms)
                            .slideX(begin: 0.1);
                      }),

                      // Explanation (shown after answering)
                      if (_answered && question.explanation != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppTheme.accentTeal.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outlined,
                                  color: AppTheme.accentTeal, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  question.explanation!,
                                  style: TextStyle(
                                    color: AppTheme.accentTeal
                                        .withOpacity(0.9),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                      ],

                      const SizedBox(height: 24),

                      // Next button (shown after answering)
                      if (_answered)
                        GradientButton(
                          text: ai.currentQuestionIndex ==
                                  ai.totalQuestions - 1
                              ? 'Finish Quiz'
                              : 'Next Question',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _next,
                        ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _OptionState _getOptionState(int index, int correctIndex) {
    if (!_answered) return _OptionState.none;
    if (index == correctIndex) return _OptionState.correct;
    if (index == _selectedAnswer) return _OptionState.wrong;
    return _OptionState.none;
  }
}

// ─── Option State ────────────────────────────────────────────────────────────

enum _OptionState { none, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color labelColor;

    switch (state) {
      case _OptionState.correct:
        borderColor = AppTheme.successGreen;
        bgColor = AppTheme.successGreen.withOpacity(0.08);
        labelColor = AppTheme.successGreen;
        break;
      case _OptionState.wrong:
        borderColor = AppTheme.errorRed;
        bgColor = AppTheme.errorRed.withOpacity(0.08);
        labelColor = AppTheme.errorRed;
        break;
      default:
        borderColor = Theme.of(context).dividerColor;
        bgColor = Theme.of(context).cardColor;
        labelColor = AppTheme.primaryPurple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: state == _OptionState.none ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                      ),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successGreen, size: 20),
              if (state == _OptionState.wrong)
                const Icon(Icons.cancel_rounded,
                    color: AppTheme.errorRed, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
