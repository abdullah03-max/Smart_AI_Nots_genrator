// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/dashboard/stats_card.dart';
import '../../widgets/notes/note_card.dart';
import '../notes/notes_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  final List<Widget> _tabs = const [
    _DashboardTab(),
    NotesListScreen(isEmbedded: true),
    ProfileScreen(isEmbedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser != null) {
      await context
          .read<NotesProvider>()
          .loadNotes(auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedTab, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.createNote).then(
                    (_) => _loadData(),
                  ),
              icon: const Icon(Icons.add),
              label: const Text('New Note'),
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

// ─── Dashboard Tab ──────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final notes = context.watch<NotesProvider>();
    final user = auth.currentUser;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) {
            await notes.loadNotes(user.id);
          }
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$greeting,',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    user?.name ?? 'Student',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(0.2),
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stats Row ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'Total Notes',
                          value: '${notes.notesCount}',
                          icon: Icons.note_alt_rounded,
                          color: AppTheme.primaryPurple,
                        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Quizzes Taken',
                          value: '0',
                          icon: Icons.quiz_rounded,
                          color: AppTheme.accentTeal,
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatsCard(
                          title: 'AI Summaries',
                          value: '0',
                          icon: Icons.auto_awesome_rounded,
                          color: AppTheme.accentOrange,
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatsCard(
                          title: 'Study Streak',
                          value: '1 day',
                          icon: Icons.local_fire_department_rounded,
                          color: AppTheme.errorRed,
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Actions ───────────────────────────────────────
                  Text('Quick Actions', style: theme.textTheme.headlineSmall)
                      .animate()
                      .fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),
                  _QuickActionsRow(),

                  const SizedBox(height: 24),

                  // ── Recent Notes ────────────────────────────────────────
                  SectionHeader(
                    title: 'Recent Notes',
                    actionText: 'See All',
                    onAction: () => Navigator.of(context)
                        .pushNamed(AppRouter.notesList),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),

                  if (notes.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (notes.recentNotes.isEmpty)
                    EmptyStateWidget(
                      title: 'No notes yet',
                      subtitle: 'Create your first note to get started!',
                      icon: Icons.note_add_rounded,
                      onAction: () =>
                          Navigator.of(context).pushNamed(AppRouter.createNote),
                      actionLabel: 'Create Note',
                    ).animate().fadeIn(delay: 700.ms)
                  else
                    ...notes.recentNotes.asMap().entries.map(
                          (entry) => NoteCard(
                            note: entry.value,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRouter.noteDetail,
                              arguments: entry.value,
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (700 + entry.key * 100).ms)
                              .slideY(begin: 0.2),
                        ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions Row ───────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'New Note',
        icon: Icons.add_circle_outline_rounded,
        color: AppTheme.primaryPurple,
        route: AppRouter.createNote,
      ),
      (
        label: 'AI Summary',
        icon: Icons.auto_awesome_outlined,
        color: AppTheme.accentTeal,
        route: null, // needs a note
      ),
      (
        label: 'Take Quiz',
        icon: Icons.quiz_outlined,
        color: AppTheme.accentOrange,
        route: null,
      ),
      (
        label: 'All Notes',
        icon: Icons.folder_open_rounded,
        color: AppTheme.primaryBlue,
        route: AppRouter.notesList,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () {
            if (a.route != null) {
              Navigator.of(context).pushNamed(a.route!);
            } else {
              AppSnackbar.show(
                context,
                'Select a note first to use this feature',
              );
            }
          },
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: a.color.withOpacity(0.2)),
                ),
                child: Icon(a.icon, color: a.color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                a.label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
