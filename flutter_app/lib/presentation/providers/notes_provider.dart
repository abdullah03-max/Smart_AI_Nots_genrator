// lib/presentation/providers/notes_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/supabase_service.dart';
import '../../data/models/note_model.dart';

enum NotesStatus { initial, loading, loaded, error }

class NotesProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final _uuid = const Uuid();

  NotesStatus _status = NotesStatus.initial;
  List<NoteModel> _notes = [];
  List<NoteModel> _filteredNotes = [];
  String? _errorMessage;
  String _searchQuery = '';
  bool _isSearching = false;

  // Getters
  NotesStatus get status => _status;
  List<NoteModel> get notes => _searchQuery.isEmpty ? _notes : _filteredNotes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == NotesStatus.loading;
  bool get isSearching => _isSearching;
  int get notesCount => _notes.length;

  // Recent notes (latest 5 for dashboard)
  List<NoteModel> get recentNotes => _notes.take(5).toList();

  /// Load all notes for the current user
  Future<void> loadNotes(String userId) async {
    try {
      _status = NotesStatus.loading;
      notifyListeners();

      _notes = await _supabase.getNotes(userId);
      _status = NotesStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotesStatus.error;
    }
    notifyListeners();
  }

  /// Search notes
  Future<void> searchNotes(String userId, String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    try {
      _isSearching = true;
      notifyListeners();
      _filteredNotes = await _supabase.searchNotes(userId, query);
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _filteredNotes = [];
    _isSearching = false;
    notifyListeners();
  }

  /// Create a new note
  Future<NoteModel?> createNote({
    required String userId,
    required String title,
    required String content,
    File? file,
    String? fileExtension,
    List<String> tags = const [],
  }) async {
    try {
      String? fileUrl;
      String? fileType;

      // Upload file if provided
      if (file != null && fileExtension != null) {
        final tempId = _uuid.v4();
        fileUrl = await _supabase.uploadNoteFile(file, tempId, fileExtension);
        fileType = fileExtension == 'pdf' ? 'pdf' : 'image';
      }

      final note = NoteModel(
        id: _uuid.v4(),
        title: title,
        content: content,
        userId: userId,
        fileUrl: fileUrl,
        fileType: fileType,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await _supabase.createNote(note);
      _notes.insert(0, created); // add to front (newest first)
      notifyListeners();
      return created;
    } catch (e) {
      print('Create note error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Update a note
  Future<bool> updateNote({
    required String noteId,
    required String title,
    required String content,
    List<String>? tags,
  }) async {
    try {
      final updated = await _supabase.updateNote(noteId, {
        'title': title,
        'content': content,
        if (tags != null) 'tags': tags,
      });

      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        _notes[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _supabase.deleteNote(noteId);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
