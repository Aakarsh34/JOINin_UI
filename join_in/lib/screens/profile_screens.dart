import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../theme.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
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
                    child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(currentUser.avatar)),
                  ),
                  const SizedBox(height: 16),
                  Text(currentUser.name, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${currentUser.rating} ', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                      const Text('(124 reviews)', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(currentUser.bio, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            
            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('Hosted', currentUser.sessionsHosted.toString()),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildStat('Joined', currentUser.sessionsJoined.toString()),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildStat('Rating', currentUser.rating.toString()),
                  ],
                ),
              ),
            ),
            
            // Activities
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Favorite Sports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: currentUser.activities.map((a) => Chip(
                      label: Text(a, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBackground)),
                      backgroundColor: AppTheme.primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text('Recent Reviews', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildReviewCard('Raj Krishnamurthy', 'Great organizer. Always brings good vibes and extra water!', 5.0, '2 days ago'),
                  _buildReviewCard('Sneha Reddy', 'Awesome session, very competitive but friendly.', 4.5, '1 week ago'),
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

  Widget _buildReviewCard(String name, String text, double rating, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), Text(' $rating', style: const TextStyle(fontWeight: FontWeight.bold))]),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          Text(time, style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}
