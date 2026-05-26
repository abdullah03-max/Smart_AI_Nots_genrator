// lib/presentation/screens/quiz/quiz_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/ai_provider.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final score = ai.score;
    final total = ai.totalQuestions;
    final percentage = total > 0 ? (score / total * 100).round() : 0;

    final Color resultColor;
    final String resultTitle;
    final String resultEmoji;
    final IconData resultIcon;

    if (percentage >= 80) {
      resultColor = AppTheme.successGreen;
      resultTitle = 'Excellent!';
      resultEmoji = '🏆';
      resultIcon = Icons.emoji_events_rounded;
    } else if (percentage >= 60) {
      resultColor = AppTheme.primaryBlue;
      resultTitle = 'Good Job!';
      resultEmoji = '👍';
      resultIcon = Icons.thumb_up_rounded;
    } else if (percentage >= 40) {
      resultColor = AppTheme.warningAmber;
      resultTitle = 'Keep Trying!';
      resultEmoji = '💪';
      resultIcon = Icons.fitness_center_rounded;
    } else {
      resultColor = AppTheme.errorRed;
      resultTitle = 'Keep Studying!';
      resultEmoji = '📚';
      resultIcon = Icons.menu_book_rounded;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Result icon ──────────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(resultIcon, color: resultColor, size: 60),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                resultEmoji,
                style: const TextStyle(fontSize: 48),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 8),

              Text(
                resultTitle,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: resultColor,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // ── Score card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resultColor.withOpacity(0.08),
                      resultColor.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: resultColor.withOpacity(0.25), width: 1.5),
                ),
                child: Column(
                  children: [
                    // Big percentage
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$score out of $total correct',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Question breakdown
                    ...ai.questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      final userAnswer = ai.userAnswers.length > i
                          ? ai.userAnswers[i]
                          : null;
                      final isCorrect = userAnswer == q.correctIndex;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: isCorrect
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Q${i + 1}: ${q.question}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 32),

              // ── Action buttons ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AiProvider>().resetQuiz();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side:
                            const BorderSide(color: AppTheme.primaryPurple),
                        foregroundColor: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AiProvider>().resetQuiz();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                                AppRouter.home, (route) => false);
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Dashboard'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
