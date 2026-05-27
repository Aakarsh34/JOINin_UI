import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

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
      title: 'Discover Local Activities',
      subtitle:
          'Find people playing football, basketball, badminton, and more near you.',
      icon: Icons.sports_tennis,
    ),
    _OnboardingPage(
      title: 'Host Your Own Sessions',
      subtitle:
          "Can't find what you're looking for? Host a session and let others join.",
      icon: Icons.group_add,
    ),
    _OnboardingPage(
      title: 'Connect and Play',
      subtitle:
          'Chat with participants, make new friends, and build your community.',
      icon: Icons.chat_bubble_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _OnboardingContent(
                  page: _pages[index],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _pages.length, (index) => _buildDot(index: index)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacementNamed(context, '/main');
                        } else {
                          _pageController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic);
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AnimatedContainer _buildDot({required int index}) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: active ? 28 : 8,
      decoration: BoxDecoration(
        gradient: active ? AppTheme.primaryGradient : null,
        color: active ? null : context.cs.outline,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _OnboardingContent extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryAccent.withValues(alpha: 0.18),
                  AppTheme.secondaryAccent.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(page.icon, size: 96, color: AppTheme.primaryAccent),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.cs.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
