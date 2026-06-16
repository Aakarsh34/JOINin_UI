import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/glass.dart';
import 'chat_screens.dart';
import 'create_session.dart';
import 'home_feed.dart';
import 'profile_screens.dart';
import 'search_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Looks up the nearest [MainNavigationState] so descendants (e.g. the
  /// Create Session form) can programmatically switch tabs.
  static MainNavigationState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationState>();
  }

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(
        outlined: Icons.home_outlined, filled: Icons.home, label: 'Home'),
    _NavItem(
        outlined: Icons.search_outlined,
        filled: Icons.search,
        label: 'Search'),
    _NavItem(
        outlined: Icons.add_circle_outline,
        filled: Icons.add_circle,
        label: 'Create',
        isHero: true),
    _NavItem(
        outlined: Icons.chat_bubble_outline,
        filled: Icons.chat_bubble,
        label: 'Messages'),
    _NavItem(
        outlined: Icons.person_outline,
        filled: Icons.person,
        label: 'Profile'),
  ];

  final GlobalKey<HomeFeedScreenState> _homeKey =
      GlobalKey<HomeFeedScreenState>();

  late final List<Widget?> _screens = List<Widget?>.filled(_items.length, null);

  @override
  void initState() {
    super.initState();
    _screens[0] = HomeFeedScreen(key: _homeKey);
  }

  void switchTo(int index) {
    if (index < 0 || index >= _items.length) return;
    _ensureBuilt(index);
    if (index == 0) {
      _homeKey.currentState?.refresh();
    }
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _ensureBuilt(int index) {
    if (_screens[index] != null) return;
    _screens[index] = switch (index) {
      0 => HomeFeedScreen(key: _homeKey),
      1 => const SearchScreen(),
      2 => const CreateSessionScreen(),
      3 => const DirectMessagesScreen(),
      4 => const UserProfileScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _ensureBuilt(index);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.cs.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientOrbs()),
          IndexedStack(
            index: _currentIndex,
            children: [
              for (int i = 0; i < _items.length; i++)
                _screens[i] ?? const SizedBox.shrink(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _GlassBottomNav(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _NavItem {
  final IconData outlined;
  final IconData filled;
  final String label;
  final bool isHero;
  const _NavItem({
    required this.outlined,
    required this.filled,
    required this.label,
    this.isHero = false,
  });
}

class _GlassBottomNav extends StatelessWidget {
  const _GlassBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isDark = context.isDark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMetrics.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: AppMetrics.glassBlur, sigmaY: AppMetrics.glassBlur),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppMetrics.radiusXl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (int i = 0; i < items.length; i++)
                  _NavSlot(
                    item: items[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (item.isHero) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent
                    .withValues(alpha: active ? 0.55 : 0.30),
                blurRadius: active ? 20 : 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: AppTheme.darkBackground, size: 28),
        ),
      );
    }

    final color =
        active ? AppTheme.primaryAccent : context.cs.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryAccent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: active
              ? Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.25))
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Column(
            key: ValueKey('${item.label}_$active'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? item.filled : item.outlined,
                  color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
