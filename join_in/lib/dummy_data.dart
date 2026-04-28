import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final String bio;
  final int sessionsHosted;
  final int sessionsJoined;
  final List<String> activities;

  User({required this.id, required this.name, required this.avatar, required this.rating, required this.bio, required this.sessionsHosted, required this.sessionsJoined, required this.activities});
}

class Session {
  final String id;
  final String title;
  final String activityType;
  final String venueName;
  final String dateTime;
  final int totalSlots;
  int filledSlots;
  final String skillLevel;
  final double distance;
  final User organizer;
  final List<User> participants;
  final String description;
  final double entryFee;
  final bool isInviteOnly;
  bool isJoined;
  bool isWaitlisted;

  Session({
    required this.id,
    required this.title,
    required this.activityType,
    required this.venueName,
    required this.dateTime,
    required this.totalSlots,
    required this.filledSlots,
    required this.skillLevel,
    required this.distance,
    required this.organizer,
    required this.participants,
    required this.description,
    this.entryFee = 0.0,
    this.isInviteOnly = false,
    this.isJoined = false,
    this.isWaitlisted = false,
  });
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String time;
  final bool isMe;

  ChatMessage({required this.id, required this.senderId, required this.senderName, required this.text, required this.time, required this.isMe});
}

final User currentUser = User(
  id: 'u0', name: 'You', avatar: 'https://ui-avatars.com/api/?name=You&background=00FF87&color=0D1117', rating: 4.5, bio: 'Sports enthusiast!', sessionsHosted: 2, sessionsJoined: 15, activities: ['Football', 'Badminton']
);

final List<User> dummyUsers = [
  User(id: 'u1', name: 'Raj Krishnamurthy', avatar: 'https://ui-avatars.com/api/?name=Raj+K&background=00B4D8&color=fff', rating: 4.8, bio: 'Football & Cricket player', sessionsHosted: 47, sessionsJoined: 40, activities: ['Football', 'Cricket']),
  User(id: 'u2', name: 'Priya Nair', avatar: 'https://ui-avatars.com/api/?name=Priya+N&background=F72585&color=fff', rating: 4.5, bio: 'Badminton & Pickleball', sessionsHosted: 12, sessionsJoined: 20, activities: ['Badminton', 'Pickleball']),
  User(id: 'u3', name: 'Arjun Mehta', avatar: 'https://ui-avatars.com/api/?name=Arjun+M&background=F8961E&color=fff', rating: 4.2, bio: 'Cricket & Basketball', sessionsHosted: 8, sessionsJoined: 8, activities: ['Cricket', 'Basketball']),
];

final List<Session> dummySessions = [
  Session(
    id: 's1', title: 'Sunday Football at ETA Turf', activityType: 'Football', venueName: 'ETA Turf, Velachery, Chennai', dateTime: 'Tomorrow 6AM', totalSlots: 11, filledSlots: 8, skillLevel: 'Intermediate', distance: 2.5, organizer: dummyUsers[0], participants: [dummyUsers[1], dummyUsers[2]], description: 'Competitive match. Wear turf shoes.', entryFee: 150.0,
  ),
  Session(
    id: 's2', title: 'Badminton Doubles', activityType: 'Badminton', venueName: 'Koramangala, Bangalore', dateTime: 'Today 7PM', totalSlots: 4, filledSlots: 3, skillLevel: 'All Welcome', distance: 5.2, organizer: dummyUsers[1], participants: [dummyUsers[0], dummyUsers[2]], description: 'Mavis 350 shuttles provided.', entryFee: 200.0,
  ),
  Session(
    id: 's3', title: 'Cricket Warm-up Game', activityType: 'Cricket', venueName: 'Andheri, Mumbai', dateTime: 'Sat 5AM', totalSlots: 22, filledSlots: 14, skillLevel: 'Beginner', distance: 8.0, organizer: dummyUsers[2], participants: [dummyUsers[0], dummyUsers[1]], description: 'Friendly box cricket match. Equipment provided.',
  ),
  Session(
    id: 's4', title: 'Pickleball Meetup', activityType: 'Pickleball', venueName: 'Banjara Hills, Hyderabad', dateTime: 'Sun 8AM', totalSlots: 6, filledSlots: 4, skillLevel: 'Beginner', distance: 1.5, organizer: dummyUsers[1], participants: [dummyUsers[0]], description: 'Never played? No problem. We will teach you the rules.',
  ),
  Session(
    id: 's5', title: 'Basketball 3v3', activityType: 'Basketball', venueName: 'Powai, Mumbai', dateTime: 'Today 6PM', totalSlots: 6, filledSlots: 6, skillLevel: 'Advanced', distance: 3.0, organizer: dummyUsers[2], participants: [dummyUsers[0], dummyUsers[1]], description: 'High intensity game.',
  ),
  Session(
    id: 's6', title: 'Tennis Social', activityType: 'Tennis', venueName: 'Jubilee Hills, Hyderabad', dateTime: 'Fri 7AM', totalSlots: 4, filledSlots: 2, skillLevel: 'Intermediate', distance: 4.5, organizer: dummyUsers[1], participants: [], description: 'Social hit for intermediate players.',
  ),
  Session(
    id: 's7', title: 'Friday Night Football', activityType: 'Football', venueName: 'Velachery, Chennai', dateTime: 'Fri 8PM', totalSlots: 10, filledSlots: 5, skillLevel: 'Advanced', distance: 2.5, organizer: dummyUsers[0], participants: [dummyUsers[2]], description: 'Invite only competitive group.', isInviteOnly: true,
  ),
  Session(
    id: 's8', title: 'Morning Badminton Club', activityType: 'Badminton', venueName: 'Whitefield, Bangalore', dateTime: 'Daily 6AM', totalSlots: 6, filledSlots: 1, skillLevel: 'All Welcome', distance: 6.0, organizer: dummyUsers[1], participants: [], description: 'Early birds only!',
  ),
];

List<ChatMessage> dummyGroupChat = [
  ChatMessage(id: 'm1', senderId: 'u1', senderName: 'Raj', text: 'Anyone need a ride from Velachery metro?', time: '10:00 AM', isMe: false),
  ChatMessage(id: 'm2', senderId: 'u2', senderName: 'Priya', text: 'I\'ll be 5 mins late, please wait', time: '10:05 AM', isMe: false),
  ChatMessage(id: 'm3', senderId: 'u3', senderName: 'Arjun', text: 'Bringing extra balls just in case', time: '10:10 AM', isMe: false),
  ChatMessage(id: 'm4', senderId: 'u1', senderName: 'Raj', text: 'Great, see everyone there 💪', time: '10:12 AM', isMe: false),
];

List<Map<String, dynamic>> dummyNotifications = [
  {"type": "join", "title": "Sneha joined your session", "time": "2 min ago", "isRead": false},
  {"type": "message", "title": "New message from Arjun", "time": "1 hr ago", "isRead": false},
  {"type": "rating", "title": "Rate your recent Badminton session", "time": "Yesterday", "isRead": true},
  {"type": "cancel", "title": "Tennis Social was cancelled", "time": "Yesterday", "isRead": true},
];
