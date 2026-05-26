// lib/presentation/screens/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../widgets/common/app_widgets.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Smart Note Taking',
      subtitle: 'Create beautiful notes with rich text, images, and PDFs — all in one place.',
      icon: Icons.edit_note_rounded,
      colors: [Color(0xFF6C63FF), Color(0xFF4A90E2)],
    ),
    _OnboardingPage(
      title: 'AI-Powered Summaries',
      subtitle: 'Let AI summarize lengthy notes in seconds so you can focus on what matters.',
      icon: Icons.auto_awesome_rounded,
      colors: [Color(0xFF00BFA5), Color(0xFF4A90E2)],
    ),
    _OnboardingPage(
      title: 'Auto Quiz Generation',
      subtitle: 'Turn your notes into interactive quizzes to test your knowledge effortlessly.',
      icon: Icons.quiz_rounded,
      colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
    ),
    _OnboardingPage(
      title: 'Study Smarter',
      subtitle: 'Track your progress, review quiz history, and ace your exams with AI assistance.',
      icon: Icons.school_rounded,
      colors: [Color(0xFF9C27B0), Color(0xFF6C63FF)],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingDone, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, index) {
                    final page = _pages[index];
                    return _buildPage(page);
                  },
                ),
              ),

              // Bottom section: indicators + button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next / Get Started button
                    GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      icon: _currentPage == _pages.length - 1
                          ? Icons.arrow_forward_rounded
                          : null,
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: page.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.colors[0].withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 68),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
