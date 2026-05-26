// lib/core/utils/app_router.dart

import 'package:flutter/material.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/notes/notes_list_screen.dart';
import '../../presentation/screens/notes/create_note_screen.dart';
import '../../presentation/screens/notes/note_detail_screen.dart';
import '../../presentation/screens/ai/ai_summary_screen.dart';
import '../../presentation/screens/quiz/quiz_screen.dart';
import '../../presentation/screens/quiz/quiz_result_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/notes/pdf_preview_screen.dart';
import '../../data/models/note_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Route names (use these everywhere — no string typos)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String notesList = '/notes';
  static const String createNote = '/notes/create';
  static const String editNote = '/notes/edit';
  static const String noteDetail = '/notes/detail';
  static const String aiSummary = '/ai/summary';
  static const String quiz = '/quiz';
  static const String quizResult = '/quiz/result';
  static const String profile = '/profile';
  static const String pdfPreview = '/notes/pdf-preview';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);

      case onboarding:
        return _slideRoute(const OnboardingScreen(), settings);

      case login:
        return _fadeRoute(const LoginScreen(), settings);

      case signup:
        return _slideRoute(const SignupScreen(), settings);

      case forgotPassword:
        return _slideRoute(const ForgotPasswordScreen(), settings);

      case resetPassword:
        return _slideRoute(const ResetPasswordScreen(), settings);

      case home:
        return _fadeRoute(const HomeScreen(), settings);

      case notesList:
        return _slideRoute(const NotesListScreen(), settings);

      case createNote:
        return _slideRoute(const CreateNoteScreen(), settings);

      case editNote:
        final note = settings.arguments as NoteModel;
        return _slideRoute(CreateNoteScreen(existingNote: note), settings);

      case noteDetail:
        final note = settings.arguments as NoteModel;
        return _slideRoute(NoteDetailScreen(note: note), settings);

      case aiSummary:
        final note = settings.arguments as NoteModel;
        return _slideRoute(AiSummaryScreen(note: note), settings);

      case quiz:
        final note = settings.arguments as NoteModel;
        return _slideRoute(QuizScreen(note: note), settings);

      case quizResult:
        return _slideRoute(const QuizResultScreen(), settings);

      case profile:
        return _slideRoute(const ProfileScreen(), settings);

      case pdfPreview:
        final args = settings.arguments as Map<String, dynamic>;
        final pdfUrl = args['pdfUrl'] as String;
        final title = args['title'] as String;
        return _slideRoute(PdfPreviewScreen(pdfUrl: pdfUrl, title: title), settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route found for ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Fade transition
  static PageRoute _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide-up transition
  static PageRoute _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
