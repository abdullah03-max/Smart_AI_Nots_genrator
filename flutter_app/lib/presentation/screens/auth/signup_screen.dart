// lib/presentation/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      AppSnackbar.show(
        context,
        'Account created! Please verify your email.',
        isSuccess: true,
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    } else {
      AppSnackbar.show(context, auth.errorMessage ?? 'Sign up failed',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppTheme.primaryPurple),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Create Account',
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 28)),
              const SizedBox(height: 6),
              Text('Join thousands of smart students',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),

              AppTextField(
                label: 'Full Name',
                hint: 'John Doe',
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                hint: 'you@university.edu',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm Password',
                hint: '••••••••',
                controller: _confirmController,
                obscureText: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) {
                  if (v != _passwordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Consumer<AuthProvider>(
                builder: (_, auth, __) => GradientButton(
                  text: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: _signUp,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: theme.textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
