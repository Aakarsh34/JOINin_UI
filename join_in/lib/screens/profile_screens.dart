import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../state/auth_state.dart';
import '../theme.dart';

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
    final user = context.read<AuthState>().user;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: user.bio);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDarkElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
          content: Text('Profile updated', style: TextStyle(color: AppTheme.darkBackground)),
        ));
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString()),
        ));
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to use the app.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      await context.read<AuthState>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _editProfile),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _signOut),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AuthState>().refreshProfile();
          await _loadStats();
        },
        child: ListView(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 100, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B4D8), Color(0xFF0D1117)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryAccent, width: 4)),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.cardDarkElevated,
                      backgroundImage: user.photo.isNotEmpty ? NetworkImage(user.photo) : null,
                      child: user.photo.isEmpty
                          ? Text(
                              user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 32, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.displayName, style: Theme.of(context).textTheme.headlineLarge),
                  if (user.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(user.phone!, style: const TextStyle(color: Colors.white70)),
                  ],
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(user.bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: _loadingStats
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: CircularProgressIndicator()))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Created', _stats?['sessionsCreated']?.toString() ?? '0'),
                          Container(width: 1, height: 40, color: Colors.white10),
                          _buildStat('Joined', _stats?['sessionsJoined']?.toString() ?? '0'),
                          Container(width: 1, height: 40, color: Colors.white10),
                          _buildStat(
                            'Rating',
                            (_stats?['avgRatingReceived'] is num)
                                ? (_stats!['avgRatingReceived'] as num).toStringAsFixed(1)
                                : '—',
                          ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Favorite Sports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (user.activities.isEmpty)
                    const Text('Add your sports in the profile editor to get better recommendations.', style: TextStyle(color: AppTheme.textMuted))
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: user.activities
                          .map((a) => Chip(
                                label: Text(a, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBackground)),
                                backgroundColor: AppTheme.primaryAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.textLight)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}
