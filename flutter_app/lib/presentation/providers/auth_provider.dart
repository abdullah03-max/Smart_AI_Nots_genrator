// lib/presentation/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_router.dart';
import '../../data/datasources/supabase_service.dart';
import '../../data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  /// Initialise: check current session and listen for changes
  void _init() {
    final user = _supabase.currentUser;
    if (user != null) {
      _loadUserProfile(user.id);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }

    // Listen to auth state changes (login, logout, token refresh)
    _supabase.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _loadUserProfile(data.session!.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        AppRouter.navigatorKey.currentState?.pushNamed(AppRouter.resetPassword);
      }
    });
  }

  /// Load user profile from Supabase DB
  Future<void> _loadUserProfile(String userId) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      _currentUser = await _supabase.getUserProfile(userId);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.authenticated; // Still authenticated even if profile fails
    }
    notifyListeners();
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _supabase.signUp(email: email, password: password, name: name);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _supabase.signIn(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.signOut();
  }

  /// Send password reset email
  Future<bool> forgotPassword(String email) async {
    try {
      await _supabase.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh user profile (e.g. after update)
  Future<void> refreshProfile() async {
    if (_currentUser != null) {
      await _loadUserProfile(_currentUser!.id);
    }
  }

  /// Update password (for recovery or profile change)
  Future<bool> updatePassword(String newPassword) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();
      await _supabase.updatePassword(newPassword);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
