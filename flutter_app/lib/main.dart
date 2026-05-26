// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Supabase initialisation ──────────────────────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const AiSmartNotesApp());
}

class AiSmartNotesApp extends StatelessWidget {
  const AiSmartNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme (must be first — other widgets depend on it)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Auth — initialises from Supabase session on startup
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Notes
        ChangeNotifierProvider(create: (_) => NotesProvider()),

        // AI features
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            // ── Theming ────────────────────────────────────────────────
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // ── Routing ────────────────────────────────────────────────
            navigatorKey: AppRouter.navigatorKey,
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}
