// lib/data/datasources/api_service.dart
// HTTP client for FastAPI AI backend

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/quiz_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String _baseUrl = AppConstants.apiBaseUrl;

  /// Get the current user's JWT token from Supabase for auth
  Future<String?> _getToken() async {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  /// Build common headers
  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Generic POST request
  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _buildHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'API error: ${response.statusCode}');
    }
  }

  // ─── AI ENDPOINTS ──────────────────────────────────────────────────────────

  /// Summarize note content using AI
  Future<String> summarizeNote(String content, {String? fileUrl, String? fileType}) async {
    final result = await _post(AppConstants.summarizeEndpoint, {
      'content': content,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
    });
    return result['summary'] ?? '';
  }

  /// Generate quiz questions from note content
  Future<List<QuizQuestion>> generateQuiz({
    required String content,
    int numQuestions = 5,
    String? fileUrl,
    String? fileType,
  }) async {
    final result = await _post(AppConstants.quizEndpoint, {
      'content': content,
      'num_questions': numQuestions,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
    });

    final List<dynamic> questions = result['questions'] ?? [];
    return questions
        .map((q) => QuizQuestion(
              id: q['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              question: q['question'] ?? '',
              options: List<String>.from(q['options'] ?? []),
              correctIndex: q['correct_index'] ?? 0,
              explanation: q['explanation'],
            ))
        .toList();
  }

  /// Explain a difficult text passage
  Future<String> explainText(String text) async {
    final result = await _post(AppConstants.explainEndpoint, {
      'text': text,
    });
    return result['explanation'] ?? '';
  }

  // ─── HEALTH CHECK ──────────────────────────────────────────────────────────

  /// Ping the backend to verify it's running
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
