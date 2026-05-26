// lib/presentation/screens/notes/notes_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/notes/note_card.dart';

class NotesListScreen extends StatefulWidget {
  /// When embedded inside HomeScreen's tab bar, hide the scaffold shell
  final bool isEmbedded;

  const NotesListScreen({super.key, this.isEmbedded = false});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      await context.read<NotesProvider>().loadNotes(auth.currentUser!.id);
    }
  }

  void _onSearch(String query) {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      context.read<NotesProvider>().searchNotes(auth.currentUser!.id, query);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note? This cannot be undone.'),
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

    if (confirm == true && mounted) {
      final ok = await context.read<NotesProvider>().deleteNote(noteId);
      if (mounted) {
        AppSnackbar.show(
          context,
          ok ? 'Note deleted' : 'Failed to delete note',
          isError: !ok,
          isSuccess: ok,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.isEmbedded) return SafeArea(child: body);

    return Scaffold(
      appBar: AppBar(title: const Text('My Notes')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed(AppRouter.createNote)
            .then((_) => _loadNotes()),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
        backgroundColor: AppTheme.primaryPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        return Column(
          children: [
            // ── Search Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            notesProvider.clearSearch();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // ── Note count ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${notesProvider.notes.length} note${notesProvider.notes.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotes,
                child: notesProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notesProvider.notes.isEmpty
                        ? EmptyStateWidget(
                            title: 'No notes found',
                            subtitle: _searchController.text.isNotEmpty
                                ? 'Try a different search term'
                                : 'Tap the + button to create your first note',
                            icon: Icons.note_add_rounded,
                            onAction: _searchController.text.isEmpty
                                ? () => Navigator.of(context)
                                    .pushNamed(AppRouter.createNote)
                                    .then((_) => _loadNotes())
                                : null,
                            actionLabel: 'Create Note',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: notesProvider.notes.length,
                            itemBuilder: (_, index) {
                              final note = notesProvider.notes[index];
                              return NoteCard(
                                note: note,
                                colorIndex: index,
                                onTap: () => Navigator.of(context)
                                    .pushNamed(AppRouter.noteDetail,
                                        arguments: note)
                                    .then((_) => _loadNotes()),
                                onDelete: () => _deleteNote(note.id),
                              )
                                  .animate()
                                  .fadeIn(delay: (index * 60).ms)
                                  .slideY(begin: 0.1);
                            },
                          ),
              ),
            ),
          ],
        );
      },
    );
  }
}
