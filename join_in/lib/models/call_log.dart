import '_helpers.dart';

class CallLog {
  final String id;
  final String callId;
  final int durationSeconds;
  final String status;
  final DateTime? timestamp;
  final String otherPartyId;
  final String otherPartyName;
  final String otherPartyPhoto;

  const CallLog({
    required this.id,
    required this.callId,
    required this.durationSeconds,
    required this.status,
    required this.timestamp,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.otherPartyPhoto,
  });

  factory CallLog.fromJson(Map<String, dynamic> json) {
    final other = json['otherParty'];
    return CallLog(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      callId: stringFromJson(json['callId']),
      durationSeconds: intFromJson(json['durationSeconds']),
      status: stringFromJson(json['status']),
      timestamp: parseIsoDate(json['timestamp']),
      otherPartyId: other is Map ? (other['_id'] ?? other['id'] ?? '').toString() : '',
      otherPartyName: other is Map ? stringFromJson(other['name']) : '',
      otherPartyPhoto: other is Map ? stringFromJson(other['photo']) : '',
    );
  }
}
