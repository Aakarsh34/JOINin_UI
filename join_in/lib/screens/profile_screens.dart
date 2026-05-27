import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../state/auth_state.dart';
import '../state/theme_state.dart';
import '../theme.dart';
import '../widgets/theme_toggle.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserService _users = UserService();
  Map<String, dynamic>? _stats;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final stats = await _users.getMyStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _editProfile() async {
    HapticFeedback.selectionClick();
    final user = context.read<AuthState>().user;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: user.bio);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit profile',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final auth = context.read<AuthState>();
      try {
        await _users.updateMe(
          name: nameController.text.trim(),
          bio: bioController.text.trim(),
        );
        await auth.refreshProfile();
        if (!mounted) return;
        messenger.showSnackBar(const SnackBar(
          backgroundColor: AppTheme.primaryAccent,
          content: Text('Profile updated',
              style: TextStyle(
                  color: AppTheme.darkBackground,
                  fontWeight: FontWeight.bold)),
        ));
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text(e.toString()),
        ));
      }
    }
  }

  Future<void> _signOut() async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      await context.read<AuthState>().signOut();
    }
  }

  void _showAppearanceSheet() {
    HapticFeedback.selectionClick();
    final theme = context.read<ThemeState>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('Appearance',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: theme,
                  builder: (context, _) {
                    return Column(
                      children: [
                        _AppearanceOption(
                          icon: Icons.light_mode_outlined,
                          label: 'Light',
                          selected: theme.mode == ThemeMode.light,
                          onTap: () {
                            theme.setMode(ThemeMode.light);
                            Navigator.pop(ctx);
                          },
                        ),
                        _AppearanceOption(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark',
                          selected: theme.mode == ThemeMode.dark,
                          onTap: () {
                            theme.setMode(ThemeMode.dark);
                            Navigator.pop(ctx);
                          },
                        ),
                        _AppearanceOption(
                          icon: Icons.brightness_auto_outlined,
                          label: 'Match system',
                          selected: theme.mode == ThemeMode.system,
                          onTap: () {
                            theme.setMode(ThemeMode.system);
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: ThemeToggleButton(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthState>().refreshProfile();
          await _loadStats();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(user),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                    color: context.cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.cs.outline)),
                child: _loadingStats
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator()))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Created',
                              _stats?['sessionsCreated']?.toString() ?? '0'),
                          _statDivider(context),
                          _buildStat('Joined',
                              _stats?['sessionsJoined']?.toString() ?? '0'),
                          _statDivider(context),
                          _buildStat(
                            'Rating',
                            (_stats?['avgRatingReceived'] is num)
                                ? (_stats!['avgRatingReceived'] as num)
                                    .toStringAsFixed(1)
                                : '—',
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(label: 'Favorite Sports'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: user.activities.isEmpty
                  ? Text(
                      'Add your sports in the profile editor to get better recommendations.',
                      style: TextStyle(color: context.cs.onSurfaceVariant))
                  : Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: user.activities
                          .map((a) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(a,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.darkBackground)),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 28),
            _SectionHeader(label: 'Settings'),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _appearanceLabel(context),
              onTap: _showAppearanceSheet,
            ),
            _SettingsTile(
              icon: Icons.edit_outlined,
              title: 'Edit profile',
              subtitle: 'Update your name, bio and photo',
              onTap: _editProfile,
            ),
            _SettingsTile(
              icon: Icons.logout,
              title: 'Sign out',
              subtitle: 'Sign out of your account',
              destructive: true,
              onTap: _signOut,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _appearanceLabel(BuildContext context) {
    final mode = context.watch<ThemeState>().mode;
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
      case ThemeMode.system:
        return 'Match system';
    }
  }

  Widget _buildHeader(AppUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, bottom: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.isDark
              ? [
                  AppTheme.secondaryAccent.withValues(alpha: 0.85),
                  context.cs.surface,
                ]
              : [
                  AppTheme.secondaryAccent.withValues(alpha: 0.45),
                  context.cs.surface,
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppTheme.primaryAccent, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: context.cs.surfaceContainerHigh,
              backgroundImage: user.photo.isNotEmpty
                  ? NetworkImage(user.photo)
                  : null,
              child: user.photo.isEmpty
                  ? Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 32,
                          color: context.cs.onSurface,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(user.displayName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(blurRadius: 16, color: Colors.black54),
                    ],
                  )),
          if (user.phone != null) ...[
            const SizedBox(height: 4),
            Text(user.phone!,
                style: const TextStyle(color: Colors.white70)),
          ],
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(user.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15, height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statDivider(BuildContext context) =>
      Container(width: 1, height: 36, color: context.cs.outline);

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: context.cs.onSurface)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: context.cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppTheme.primaryAccent.withValues(alpha: 0.12)
            : context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon,
                    color: selected
                        ? AppTheme.primaryAccent
                        : context.cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? AppTheme.primaryAccent
                              : context.cs.onSurface)),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.primaryAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : context.cs.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: destructive
                          ? AppTheme.danger.withValues(alpha: 0.12)
                          : AppTheme.primaryAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon,
                      color: destructive
                          ? AppTheme.danger
                          : AppTheme.primaryAccent,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: context.cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
