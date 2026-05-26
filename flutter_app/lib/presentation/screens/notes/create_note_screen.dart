// lib/presentation/screens/notes/create_note_screen.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/models/note_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/app_widgets.dart';

class CreateNoteScreen extends StatefulWidget {
  final NoteModel? existingNote;

  const CreateNoteScreen({super.key, this.existingNote});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedFile;
  String? _fileExtension;
  List<String> _tags = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
      _tags = List.from(widget.existingNote!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileExtension = 'pdf';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
        _fileExtension = image.path.split('.').last.toLowerCase();
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    final notesProvider = context.read<NotesProvider>();

    bool ok;
    if (_isEditing) {
      ok = await notesProvider.updateNote(
        noteId: widget.existingNote!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
      );
    } else {
      final note = await notesProvider.createNote(
        userId: auth.currentUser!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        file: _selectedFile,
        fileExtension: _fileExtension,
        tags: _tags,
      );
      ok = note != null;
    }

    setState(() => _isSaving = false);

    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        _isEditing ? 'Note updated!' : 'Note created!',
        isSuccess: true,
      );
      Navigator.of(context).pop();
    } else {
      AppSnackbar.show(context, 'Failed to save note', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'New Note'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: const Text('Save'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryPurple,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ────────────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                style: theme.textTheme.headlineMedium,
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
                maxLines: 2,
              ),
              const Divider(height: 24),

              // ── Content ──────────────────────────────────────────────
              TextFormField(
                controller: _contentController,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                decoration: const InputDecoration(
                  hintText: 'Start writing your notes here...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                minLines: 10,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Content is required' : null,
              ),

              const SizedBox(height: 16),
              const Divider(),

              // ── Tags ─────────────────────────────────────────────────
              Text('Tags', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add a tag...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded,
                        color: AppTheme.primaryPurple),
                    onPressed: _addTag,
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            onDeleted: () =>
                                setState(() => _tags.remove(tag)),
                            deleteIconColor: AppTheme.primaryPurple,
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),

              // ── File Upload ──────────────────────────────────────────
              Text('Attachments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              if (_selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryPurple.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _fileExtension == 'pdf'
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split('/').last,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.red),
                        onPressed: () =>
                            setState(() => _selectedFile = null),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _AttachButton(
                        label: 'Add PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        color: AppTheme.errorRed,
                        onTap: _pickPdf,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _AttachButton(
                        label: 'Add Image',
                        icon: Icons.image_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: _pickImage,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AttachButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
