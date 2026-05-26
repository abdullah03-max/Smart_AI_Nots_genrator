// lib/presentation/screens/auth/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    final auth = context.read<AuthProvider>();
    final ok = await auth.updatePassword(_passwordController.text.trim());
    
    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
    } else {
      AppSnackbar.show(
        context,
        auth.errorMessage ?? 'Failed to reset password. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        automaticallyImplyLeading: false, // Don't show back button (deep link user)
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _success ? _buildSuccessState(theme) : _buildForm(theme),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final auth = context.watch<AuthProvider>();

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
            child: const Icon(
              Icons.vpn_key_rounded,
              color: AppTheme.primaryPurple,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text('Create New Password', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Your identity has been verified! Please enter your new secure password below.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          // ── Password field ──────────────────────────────────────────────
          AppTextField(
            label: 'New Password',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Confirm Password field ──────────────────────────────────────
          AppTextField(
            label: 'Confirm Password',
            hint: '••••••••',
            controller: _confirmController,
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),

          GradientButton(
            text: 'Reset Password',
            isLoading: auth.isLoading,
            onPressed: _updatePassword,
            icon: Icons.check_circle_outline_rounded,
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
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.successGreen,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        Text('Password Reset!', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully updated. You can now log in with your new password.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Clean stack and push login
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.login,
              (route) => false,
            );
          },
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
}
