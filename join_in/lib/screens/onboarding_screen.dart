import 'package:flutter/material.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Discover Local Activities",
      "subtitle": "Find people playing football, basketball, badminton, and more near you.",
      "icon": "sports_tennis",
    },
    {
      "title": "Host Your Own Sessions",
      "subtitle": "Can't find what you're looking for? Host a session and let others join.",
      "icon": "group_add",
    },
    {
      "title": "Connect and Play",
      "subtitle": "Chat with participants, make new friends, and build your community.",
      "icon": "chat_bubble_outline",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: _onboardingData[index]["title"]!,
                  subtitle: _onboardingData[index]["subtitle"]!,
                  iconData: _getIconData(_onboardingData[index]["icon"]!),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_onboardingData.length, (index) => _buildDot(index: index)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _onboardingData.length - 1) {
                          Navigator.pushReplacementNamed(context, '/main');
                        } else {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        }
                      },
                      child: Text(_currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next', style: const TextStyle(fontSize: 18, color: AppTheme.darkBackground)),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.primaryAccent : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'sports_tennis': return Icons.sports_tennis;
      case 'group_add': return Icons.group_add;
      case 'chat_bubble_outline': return Icons.chat_bubble_outline;
      default: return Icons.sports;
    }
  }
}

class OnboardingContent extends StatelessWidget {
  final String title, subtitle;
  final IconData iconData;

  const OnboardingContent({super.key, required this.title, required this.subtitle, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 120, color: AppTheme.primaryAccent),
          const SizedBox(height: 40),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
