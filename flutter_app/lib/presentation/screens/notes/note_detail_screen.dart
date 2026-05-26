// lib/presentation/screens/notes/note_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/app_widgets.dart';

class NoteDetailScreen extends StatelessWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => Navigator.of(context)
                .pushNamed(AppRouter.editNote, arguments: note),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ────────────────────────────────────────────────
            Text(note.title, style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMMM d, yyyy • HH:mm').format(note.createdAt),
              style: theme.textTheme.bodySmall,
            ),

            // ── Tags ─────────────────────────────────────────────────
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: note.tags
                    .map((tag) => Chip(
                          label: Text(tag,
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 6),
            Text('${note.wordCount} words',
                style: theme.textTheme.bodySmall),

            const Divider(height: 32),

            // ── Content ──────────────────────────────────────────────
            Text(
              note.content,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
            ),

            // ── File attachment ──────────────────────────────────────
            if (note.fileUrl != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Attachment', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.pdfPreview,
                    arguments: {
                      'pdfUrl': note.fileUrl!,
                      'title': note.title,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        note.fileType == 'pdf'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note.fileType == 'pdf' ? 'PDF Document' : 'Image',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 18, color: AppTheme.primaryPurple),
                    ],
                  ),
                ),
              ),
              if (note.fileType == 'image') ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(note.fileUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: CachedNetworkImage(
                      imageUrl: note.fileUrl!,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                        ),
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ],

            const SizedBox(height: 32),

            // ── AI Action Buttons ─────────────────────────────────────
            Text('AI Tools', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AiActionButton(
                    label: 'Summarize',
                    icon: Icons.auto_awesome_rounded,
                    color: AppTheme.accentTeal,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.aiSummary, arguments: note),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AiActionButton(
                    label: 'Take Quiz',
                    icon: Icons.quiz_rounded,
                    color: AppTheme.primaryPurple,
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRouter.quiz, arguments: note),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This will permanently delete this note.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<NotesProvider>().deleteNote(note.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _AiActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AiActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
