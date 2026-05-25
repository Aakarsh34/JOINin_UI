import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../theme.dart';
import 'chat_screens.dart';
import 'dart:ui';

class SessionDetailScreen extends StatefulWidget {
  final Session session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _isLoading = false;

  void _handleJoin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isLoading = false;
      widget.session.isJoined = true;
      if (!widget.session.isWaitlisted && widget.session.filledSlots < widget.session.totalSlots) {
        widget.session.filledSlots++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFull = widget.session.filledSlots >= widget.session.totalSlots;
    final isJoined = widget.session.isJoined;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
          child: const BackButton(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Map Background
          Positioned(
            top: 0, left: 0, right: 0, height: 320,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=1000&auto=format&fit=crop'), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, AppTheme.darkBackground],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 250, bottom: 100),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.darkBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.secondaryAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(widget.session.activityType, style: const TextStyle(color: AppTheme.secondaryAccent, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.session.title, style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 24),

                    // Quick Info Grid
                    Row(
                      children: [
                        Expanded(child: _buildInfoCard(Icons.calendar_today, widget.session.dateTime.split(' ')[0], widget.session.dateTime.split(' ').sublist(1).join(' '))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoCard(Icons.attach_money, widget.session.entryFee > 0 ? '\$${widget.session.entryFee}' : 'Free', 'Entry Fee')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(Icons.location_on, widget.session.venueName, '${widget.session.distance} km away'),
                    
                    const SizedBox(height: 32),
                    const Text('Organizer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 28, backgroundImage: NetworkImage(widget.session.organizer.avatar)),
                      title: Text(widget.session.organizer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${widget.session.organizer.rating} • ${widget.session.organizer.sessionsHosted} sessions hosted', style: const TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text('Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.session.description, style: const TextStyle(color: AppTheme.textLight, height: 1.5, fontSize: 16)),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Slots (${widget.session.filledSlots}/${widget.session.totalSlots})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(widget.session.skillLevel, style: const TextStyle(color: AppTheme.secondaryAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(widget.session.totalSlots, (index) {
                        bool isFilled = index < widget.session.filledSlots;
                        return Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppTheme.primaryAccent : Colors.transparent,
                            border: Border.all(color: isFilled ? AppTheme.primaryAccent : Colors.white24, width: 2),
                          ),
                          child: isFilled ? const Icon(Icons.check, size: 16, color: AppTheme.darkBackground) : null,
                        );
                      }),
                    ),

                    // Chat Preview
                    if (isJoined) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Group Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(session: widget.session))),
                            child: const Text('View All', style: TextStyle(color: AppTheme.primaryAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            _buildChatPreview(dummyGroupChat[dummyGroupChat.length - 2]),
                            const SizedBox(height: 12),
                            _buildChatPreview(dummyGroupChat[dummyGroupChat.length - 1]),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom CTA
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                  ),
                  child: ElevatedButton(
                    onPressed: isJoined ? null : _handleJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined ? AppTheme.cardDarkElevated : (isFull ? Colors.orangeAccent : AppTheme.primaryAccent),
                      foregroundColor: isJoined ? Colors.white : AppTheme.darkBackground,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.darkBackground, strokeWidth: 3))
                      : Text(isJoined ? 'Joined ✓' : (isFull ? 'Join Waitlist' : 'Join Session')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.secondaryAccent),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChatPreview(ChatMessage msg) {
    return Row(
      children: [
        Text('${msg.senderName}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
        Expanded(child: Text(msg.text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textLight))),
      ],
    );
  }
}
