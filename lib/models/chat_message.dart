import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final bool isUser;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String userId;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.userId,
  });

  // Convert to Map for easier handling
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  // Create from Map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'] ?? '',
    );
  }

  @override
  String toString() {
    return 'ChatMessage(text: $text, isUser: $isUser, timestamp: $timestamp, userId: $userId)';
  }
}
