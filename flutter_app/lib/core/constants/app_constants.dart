// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'Notexa';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Study Smarter with AI';

  // Supabase Config
  static const String supabaseUrl = 'https://fokeuknbaapxbyggjpuv.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_AFCryjRNb4gD8r0A9nAWwA_q5M2XUlU';

  // Backend API Base URL — update when deploying
  static const String apiBaseUrl = 'https://smart-ai-nots-genrator.vercel.app'; // Production server on Vercel
  // static const String apiBaseUrl = 'http://10.64.180.175:8000'; // Connected physical device over Wi-Fi

  // Supabase Table Names
  static const String usersTable = 'users';
  static const String notesTable = 'notes';
  static const String quizzesTable = 'quizzes';
  static const String quizResultsTable = 'quiz_results';

  // Supabase Storage Buckets
  static const String profilesBucket = 'profiles';
  static const String noteFilesBucket = 'note-files';

  // API Endpoints
  static const String summarizeEndpoint = '/api/ai/summarize';
  static const String quizEndpoint = '/api/ai/generate-quiz';
  static const String explainEndpoint = '/api/ai/explain';
  static const String uploadEndpoint = '/api/files/upload';

  // Shared Preference Keys
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefThemeMode = 'theme_mode';
  static const String prefUserId = 'user_id';

  // Pagination
  static const int notesPageSize = 20;
  static const int quizPageSize = 10;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNotesTitleLength = 100;
  static const int maxNotesContentLength = 10000;

  // Animation Durations
  static const int splashDuration = 2500; // milliseconds
  static const int animationFast = 200;
  static const int animationNormal = 350;
  static const int animationSlow = 600;

  // Quiz Config
  static const int defaultQuizQuestions = 5;
  static const int quizTimePerQuestion = 30; // seconds
}
