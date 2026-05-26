// lib/presentation/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else {
      AppSnackbar.show(context, auth.errorMessage ?? 'Something went wrong',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: AppTheme.primaryPurple),
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSuccessState(theme) : _buildForm(theme),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: AppTheme.primaryPurple, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Forgot Password?', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (_, auth, __) => GradientButton(
              text: 'Send Reset Link',
              isLoading: auth.isLoading,
              onPressed: _sendReset,
              icon: Icons.send_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: AppTheme.successGreen, size: 60),
        ),
        const SizedBox(height: 24),
        Text('Email Sent!', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
