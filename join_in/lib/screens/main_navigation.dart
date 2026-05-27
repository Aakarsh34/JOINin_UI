import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
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

  // Direct GlobalKey to the Home feed so we can ask it to refresh after the
  // user publishes a new session, without tearing it down and re-running its
  // initState() on every tab switch.
  final GlobalKey<HomeFeedScreenState> _homeKey = GlobalKey<HomeFeedScreenState>();

  // Lazily materialised so cold start only triggers Home's initial network
  // call. Subsequent tabs are built the first time they are tapped and then
  // kept alive by [IndexedStack].
  late final List<Widget?> _screens = List<Widget?>.filled(_items.length, null);

  @override
  void initState() {
    super.initState();
    _screens[0] = HomeFeedScreen(key: _homeKey);
  }

  /// Programmatically switch the active tab. Used after publishing a session
  /// to jump the user back to the Home feed and silently refresh it.
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (int i = 0; i < _items.length; i++)
            _screens[i] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
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

class _BottomNav extends StatelessWidget {
  const _BottomNav({
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
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.cs.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: 8, bottom: 8 + bottomInset),
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryAccent
                    .withValues(alpha: active ? 0.5 : 0.25),
                blurRadius: active ? 18 : 12,
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
            Icon(active ? item.filled : item.outlined, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
