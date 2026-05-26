// lib/presentation/screens/profile/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../../data/datasources/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _supabase = SupabaseService();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        context.read<AuthProvider>().currentUser?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || !mounted) return;
    setState(() => _isSaving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      final url =
          await _supabase.uploadProfileImage(File(image.path), userId);
      await _supabase
          .updateUserProfile(userId: userId, updates: {'profile_image': url});
      await context.read<AuthProvider>().refreshProfile();
      if (mounted)
        AppSnackbar.show(context, 'Profile picture updated!', isSuccess: true);
    } catch (e) {
      print('Profile image upload error: $e');
      if (mounted)
        AppSnackbar.show(context, 'Upload failed', isError: true);
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser!.id;
      await _supabase
          .updateUserProfile(userId: userId, updates: {'name': name});
      await context.read<AuthProvider>().refreshProfile();
      setState(() => _isEditing = false);
      if (mounted) AppSnackbar.show(context, 'Name updated!', isSuccess: true);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, 'Update failed', isError: true);
    }
    setState(() => _isSaving = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted)
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.isEmbedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Profile')), body: body);
  }

  Widget _buildBody(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration:
                const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: user?.profileImage != null
                              ? NetworkImage(user!.profileImage!)
                              : null,
                          child: user?.profileImage == null
                              ? Text(
                                  (user?.name ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w700),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 15, color: AppTheme.primaryPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user?.email ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                      child: _StatBox(
                          label: 'Notes',
                          value: '${notes.notesCount}',
                          icon: Icons.note_alt_rounded,
                          color: AppTheme.primaryPurple)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatBox(
                          label: 'Quizzes',
                          value: '0',
                          icon: Icons.quiz_rounded,
                          color: AppTheme.accentTeal)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatBox(
                          label: 'Streak',
                          value: '1',
                          icon: Icons.local_fire_department_rounded,
                          color: AppTheme.errorRed)),
                ]).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'PERSONAL INFO',
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: _isEditing
                            ? TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                    labelText: 'Name'))
                            : ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.person_outline,
                                    color: AppTheme.primaryPurple),
                                title: const Text('Full Name'),
                                subtitle: Text(user?.name ?? '—')),
                      ),
                      if (_isSaving)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        IconButton(
                          icon: Icon(
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              color: AppTheme.primaryPurple),
                          onPressed: _isEditing
                              ? _saveName
                              : () => setState(() => _isEditing = true),
                        ),
                    ]),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.email_outlined,
                          color: AppTheme.primaryPurple),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? '—'),
                    ),
                  ]),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: 'PREFERENCES',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.dark_mode_outlined,
                        color: AppTheme.primaryPurple),
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeColor: AppTheme.primaryPurple,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 12),
                _ProfileSection(
                  title: 'ACCOUNT',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded,
                        color: AppTheme.errorRed),
                    title: const Text('Sign Out',
                        style: TextStyle(color: AppTheme.errorRed)),
                    onTap: _logout,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _ProfileSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryPurple,
                fontSize: 11,
                letterSpacing: 0.6)),
        const SizedBox(height: 4),
        child,
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: 11)),
      ]),
    );
  }
}
