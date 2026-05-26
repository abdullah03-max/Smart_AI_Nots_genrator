// lib/presentation/screens/ai/ai_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note_model.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class AiSummaryScreen extends StatefulWidget {
  final NoteModel note;

  const AiSummaryScreen({super.key, required this.note});

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  final _explainController = TextEditingController();

  @override
  void dispose() {
    _explainController.dispose();
    super.dispose();
  }

  Future<void> _summarize() async {
    await context.read<AiProvider>().summarizeNote(
          widget.note.content,
          fileUrl: widget.note.fileUrl,
          fileType: widget.note.fileType,
        );
  }

  Future<void> _explain() async {
    final text = _explainController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(context, 'Please enter text to explain', isError: true);
      return;
    }
    await context.read<AiProvider>().explainText(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AiProvider>().clearSummary(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Note info ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.note_alt_rounded,
                      color: AppTheme.primaryPurple, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.note.title,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('${widget.note.wordCount} words',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─────────────────────────────────────────────────────────
            // SECTION 1: SUMMARIZE
            // ─────────────────────────────────────────────────────────
            _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Summary',
              color: AppTheme.accentTeal,
            ),
            const SizedBox(height: 12),

            Consumer<AiProvider>(
              builder: (_, ai, __) {
                if (ai.summaryStatus == AiStatus.loading) {
                  return _LoadingCard(
                    message: 'Generating summary...',
                    color: AppTheme.accentTeal,
                  );
                }
                if (ai.summaryStatus == AiStatus.loaded &&
                    ai.summary != null) {
                  return _ResultCard(
                    content: ai.summary!,
                    color: AppTheme.accentTeal,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: ai.summary!));
                      AppSnackbar.show(context, 'Copied to clipboard',
                          isSuccess: true);
                    },
                  ).animate().fadeIn().slideY(begin: 0.1);
                }
                if (ai.summaryStatus == AiStatus.error) {
                  return _ErrorCard(
                    message: ai.errorMessage ??
                        'AI service unavailable. Make sure the backend is running.',
                    color: AppTheme.accentTeal,
                  );
                }
                // Idle state
                return GradientButton(
                  text: 'Summarize Note',
                  icon: Icons.auto_awesome_rounded,
                  gradientColors: [AppTheme.accentTeal, AppTheme.primaryBlue],
                  onPressed: _summarize,
                );
              },
            ),

            const SizedBox(height: 32),

            // ─────────────────────────────────────────────────────────
            // SECTION 2: EXPLAIN TEXT
            // ─────────────────────────────────────────────────────────
            _SectionTitle(
              icon: Icons.help_outline_rounded,
              title: 'Explain Difficult Text',
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explainController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Paste a difficult paragraph here...',
              ),
            ),
            const SizedBox(height: 12),

            Consumer<AiProvider>(
              builder: (_, ai, __) {
                if (ai.explainStatus == AiStatus.loading) {
                  return _LoadingCard(
                    message: 'Explaining text...',
                    color: AppTheme.primaryPurple,
                  );
                }
                if (ai.explainStatus == AiStatus.loaded &&
                    ai.explanation != null) {
                  return Column(
                    children: [
                      _ResultCard(
                        content: ai.explanation!,
                        color: AppTheme.primaryPurple,
                        onCopy: () {
                          Clipboard.setData(
                              ClipboardData(text: ai.explanation!));
                          AppSnackbar.show(context, 'Copied!',
                              isSuccess: true);
                        },
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => context.read<AiProvider>().clearExplanation(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Explain Another'),
                      ),
                    ],
                  );
                }
                if (ai.explainStatus == AiStatus.error) {
                  return _ErrorCard(
                    message: ai.errorMessage ?? 'Could not explain text.',
                    color: AppTheme.primaryPurple,
                  );
                }
                return GradientButton(
                  text: 'Explain Text',
                  icon: Icons.help_outline_rounded,
                  onPressed: _explain,
                );
              },
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;
  final Color color;

  const _LoadingCard({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: color),
          ),
          const SizedBox(width: 14),
          Text(message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String content;
  final Color color;
  final VoidCallback onCopy;

  const _ResultCard(
      {required this.content, required this.color, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Result',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              IconButton(
                icon: Icon(Icons.copy_rounded, color: color, size: 18),
                onPressed: onCopy,
                tooltip: 'Copy',
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.7)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Color color;

  const _ErrorCard({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppTheme.errorRed, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
