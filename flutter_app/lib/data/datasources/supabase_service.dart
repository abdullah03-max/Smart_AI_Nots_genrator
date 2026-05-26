// lib/data/datasources/supabase_service.dart
// Central helper for all Supabase operations

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note_model.dart';
import '../models/quiz_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Get the Supabase client
  SupabaseClient get client => Supabase.instance.client;

  // Current user ID shorthand
  String? get currentUserId => client.auth.currentUser?.id;

  // ─── AUTH METHODS ──────────────────────────────────────────────────────────

  /// Sign up a new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    // Insert profile record into users table
    try {
      if (response.user != null) {
        await client.from(AppConstants.usersTable).insert({
          'id': response.user!.id,
          'name': name,
          'email': email,
        });
      }
    } catch (e) {
      // Silent catch: allows registration to complete even if email confirmation is required
      // or if a database trigger handles the synchronization automatically.
      print('Profile insertion warning: $e');
    }
    return response;
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'aismartnotes://login-callback',
    );
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Get current auth user
  User? get currentUser => client.auth.currentUser;

  /// Auth state changes stream
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // ─── USER PROFILE METHODS ──────────────────────────────────────────────────

  /// Fetch user profile from DB
  Future<UserModel?> getUserProfile(String userId) async {
    final data = await client
        .from(AppConstants.usersTable)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data != null ? UserModel.fromJson(data) : null;
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await client
        .from(AppConstants.usersTable)
        .update(updates)
        .eq('id', userId);
  }

  /// Upload profile picture to storage and return public URL
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    final fileName = '$userId/profile.jpg';
    await client.storage
        .from(AppConstants.profilesBucket)
        .upload(fileName, imageFile, fileOptions: const FileOptions(upsert: true));
    return client.storage
        .from(AppConstants.profilesBucket)
        .getPublicUrl(fileName);
  }

  // ─── NOTES METHODS ─────────────────────────────────────────────────────────

  /// Get all notes for current user, ordered by newest
  Future<List<NoteModel>> getNotes(String userId) async {
    final data = await client
        .from(AppConstants.notesTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => NoteModel.fromJson(e)).toList();
  }

  /// Search notes by title or content
  Future<List<NoteModel>> searchNotes(String userId, String query) async {
    final data = await client
        .from(AppConstants.notesTable)
        .select()
        .eq('user_id', userId)
        .or('title.ilike.%$query%,content.ilike.%$query%')
        .order('created_at', ascending: false);

    return (data as List).map((e) => NoteModel.fromJson(e)).toList();
  }

  /// Get a single note by ID
  Future<NoteModel?> getNoteById(String noteId) async {
    final data = await client
        .from(AppConstants.notesTable)
        .select()
        .eq('id', noteId)
        .maybeSingle();

    return data != null ? NoteModel.fromJson(data) : null;
  }

  /// Create a new note
  Future<NoteModel> createNote(NoteModel note) async {
    final data = await client
        .from(AppConstants.notesTable)
        .insert(note.toInsertJson())
        .select()
        .single();

    return NoteModel.fromJson(data);
  }

  /// Update an existing note
  Future<NoteModel> updateNote(String noteId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    final data = await client
        .from(AppConstants.notesTable)
        .update(updates)
        .eq('id', noteId)
        .select()
        .single();

    return NoteModel.fromJson(data);
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    await client.from(AppConstants.notesTable).delete().eq('id', noteId);
  }

  Future<String> uploadNoteFile(File file, String noteId, String extension) async {
    final userId = currentUserId ?? 'public';
    final fileName = '$userId/note_${noteId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await client.storage
        .from(AppConstants.noteFilesBucket)
        .upload(fileName, file);
    return client.storage
        .from(AppConstants.noteFilesBucket)
        .getPublicUrl(fileName);
  }

  // ─── QUIZ METHODS ──────────────────────────────────────────────────────────

  /// Save generated quiz to DB
  Future<void> saveQuiz({
    required String noteId,
    required String userId,
    required List<QuizQuestion> questions,
  }) async {
    for (final q in questions) {
      await client.from(AppConstants.quizzesTable).insert({
        'note_id': noteId,
        'user_id': userId,
        'question': q.question,
        'options': q.options,
        'correct_index': q.correctIndex,
        'explanation': q.explanation,
      });
    }
  }

  /// Save quiz result
  Future<void> saveQuizResult(QuizResultModel result) async {
    await client
        .from(AppConstants.quizResultsTable)
        .insert(result.toInsertJson());
  }

  /// Get quiz history for a user
  Future<List<QuizResultModel>> getQuizHistory(String userId) async {
    final data = await client
        .from(AppConstants.quizResultsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => QuizResultModel.fromJson(e)).toList();
  }

  // ─── STATISTICS ────────────────────────────────────────────────────────────

  /// Get count of notes for a user
  Future<int> getNotesCount(String userId) async {
    final data = await client
        .from(AppConstants.notesTable)
        .select()
        .eq('user_id', userId);
    return (data as List).length;
  }

  /// Get count of quizzes taken
  Future<int> getQuizzesCount(String userId) async {
    final data = await client
        .from(AppConstants.quizResultsTable)
        .select()
        .eq('user_id', userId);
    return (data as List).length;
  }
}
