// lib/presentation/widgets/notes/note_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/note_model.dart';

/// Color palette for note cards (cycles by index)
const _noteColors = [
  Color(0xFF6C63FF),
  Color(0xFF00BFA5),
  Color(0xFFFF6B35),
  Color(0xFF4A90E2),
  Color(0xFF9C27B0),
  Color(0xFFFFB300),
];

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final int colorIndex;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDelete,
    this.colorIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _noteColors[colorIndex % _noteColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row ────────────────────────────────────────────
              Row(
                children: [
                  // Color accent
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM d, yyyy • HH:mm')
                              .format(note.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 20),
                      onPressed: onDelete,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Preview ───────────────────────────────────────────────
              Text(
                note.preview,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // ── Tags & metadata ───────────────────────────────────────
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.text_fields_rounded,
                      size: 14,
                      color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text('${note.wordCount} words',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  if (note.fileUrl != null) ...[
                    Icon(
                      note.fileType == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.fileType == 'pdf' ? 'PDF' : 'Image',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: color),
                    ),
                  ],
                  const Spacer(),
                  // Tags
                  if (note.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note.tags.first,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
