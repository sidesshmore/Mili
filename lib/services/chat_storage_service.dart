import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindmate/models/chat_message.dart';
import 'package:mindmate/services/auth_service.dart';

class ChatStorageService {
  static const String _boxName = 'chat_messages';
  static Box<ChatMessage>? _box;

  // Initialize Hive and open the box
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register adapter manually since we don't have the generated adapter yet
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(_ChatMessageAdapter());
      }

      _box = await Hive.openBox<ChatMessage>(_boxName);
      log('Chat storage initialized successfully');
    } catch (e) {
      log('Error initializing chat storage: $e');
      rethrow;
    }
  }

  // Get the current user ID from SharedPreferences
  static Future<String?> _getCurrentUserId() async {
    return await AuthService.getUserId();
  }

  // Save a chat message
  static Future<void> saveMessage(ChatMessage message) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        log('No user ID found, cannot save message');
        return;
      }

      if (_box == null) {
        await init();
      }

      // Create message with current user ID
      final messageWithUserId = ChatMessage(
        text: message.text,
        isUser: message.isUser,
        timestamp: message.timestamp,
        userId: userId,
      );

      await _box!.add(messageWithUserId);
      log('Message saved: ${messageWithUserId.text}');
    } catch (e) {
      log('Error saving message: $e');
    }
  }

  // Get all messages for the current user, ordered by timestamp (oldest first)
  static Future<List<ChatMessage>> getMessagesForCurrentUser() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        log('No user ID found, returning empty list');
        return [];
      }

      if (_box == null) {
        await init();
      }

      // Get all messages for the current user
      final userMessages = _box!.values
          .where((message) => message.userId == userId)
          .toList();

      // Sort by timestamp (oldest first)
      userMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      log('Retrieved ${userMessages.length} messages for user: $userId');
      return userMessages;
    } catch (e) {
      log('Error getting messages: $e');
      return [];
    }
  }

  // NEW METHOD: Get recent context for AI (20 messages with 70% user, 30% AI)
  static Future<List<ChatMessage>> getRecentContextForAI() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        log('No user ID found for context');
        return [];
      }

      if (_box == null) {
        await init();
      }

      // Get all messages for current user, sorted by timestamp (newest first for context)
      final allMessages = _box!.values
          .where((message) => message.userId == userId)
          .toList();

      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (allMessages.isEmpty) {
        return [];
      }

      // Separate user and AI messages
      final userMessages = allMessages.where((m) => m.isUser).toList();
      final aiMessages = allMessages.where((m) => !m.isUser).toList();

      // Calculate how many messages we want (70% user, 30% AI, max 20 total)
      const maxContextMessages = 20;
      final targetUserMessages = (maxContextMessages * 0.7).round();
      final targetAiMessages = (maxContextMessages * 0.3).round();

      // Take the most recent messages according to our ratio
      final recentUserMessages = userMessages.take(targetUserMessages).toList();
      final recentAiMessages = aiMessages.take(targetAiMessages).toList();

      // Combine and sort by timestamp (oldest first for proper context)
      final contextMessages = [...recentUserMessages, ...recentAiMessages];
      contextMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      log(
        'Retrieved ${contextMessages.length} messages for AI context (${recentUserMessages.length} user, ${recentAiMessages.length} AI)',
      );
      return contextMessages;
    } catch (e) {
      log('Error getting context messages: $e');
      return [];
    }
  }

  // Get all messages for a specific user
  static Future<List<ChatMessage>> getMessagesForUser(String userId) async {
    try {
      if (_box == null) {
        await init();
      }

      final userMessages = _box!.values
          .where((message) => message.userId == userId)
          .toList();

      // Sort by timestamp (oldest first)
      userMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return userMessages;
    } catch (e) {
      log('Error getting messages for user $userId: $e');
      return [];
    }
  }

  // Clear all messages for the current user
  static Future<void> clearMessagesForCurrentUser() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        log('No user ID found, cannot clear messages');
        return;
      }

      if (_box == null) {
        await init();
      }

      // Get keys of messages to delete
      final keysToDelete = <dynamic>[];
      for (int i = 0; i < _box!.length; i++) {
        final message = _box!.getAt(i);
        if (message != null && message.userId == userId) {
          keysToDelete.add(_box!.keyAt(i));
        }
      }

      // Delete the messages
      await _box!.deleteAll(keysToDelete);
      log('Cleared ${keysToDelete.length} messages for user: $userId');
    } catch (e) {
      log('Error clearing messages: $e');
    }
  }

  // Clear all messages for all users (admin function)
  static Future<void> clearAllMessages() async {
    try {
      if (_box == null) {
        await init();
      }

      await _box!.clear();
      log('All messages cleared');
    } catch (e) {
      log('Error clearing all messages: $e');
    }
  }

  // Get message count for current user
  static Future<int> getMessageCountForCurrentUser() async {
    try {
      final messages = await getMessagesForCurrentUser();
      return messages.length;
    } catch (e) {
      log('Error getting message count: $e');
      return 0;
    }
  }

  // Delete a specific message by index (for current user)
  static Future<void> deleteMessage(int index) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final userMessages = await getMessagesForCurrentUser();
      if (index < 0 || index >= userMessages.length) return;

      final messageToDelete = userMessages[index];

      // Find and delete the message from Hive
      for (int i = 0; i < _box!.length; i++) {
        final message = _box!.getAt(i);
        if (message != null &&
            message.userId == userId &&
            message.timestamp == messageToDelete.timestamp &&
            message.text == messageToDelete.text) {
          await _box!.deleteAt(i);
          break;
        }
      }

      log('Message deleted at index: $index');
    } catch (e) {
      log('Error deleting message: $e');
    }
  }

  // Get storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final userId = await _getCurrentUserId();
      final totalMessages = _box?.length ?? 0;
      final userMessages = userId != null
          ? (await getMessagesForCurrentUser()).length
          : 0;

      return {
        'totalMessages': totalMessages,
        'userMessages': userMessages,
        'userId': userId,
        'isInitialized': _box != null,
      };
    } catch (e) {
      log('Error getting storage info: $e');
      return {
        'totalMessages': 0,
        'userMessages': 0,
        'userId': null,
        'isInitialized': false,
      };
    }
  }

  // Close the box (call when app is closing)
  static Future<void> close() async {
    try {
      await _box?.close();
      _box = null;
      log('Chat storage closed');
    } catch (e) {
      log('Error closing chat storage: $e');
    }
  }
}

// Manual ChatMessage adapter implementation
class _ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      text: fields[0] as String,
      isUser: fields[1] as bool,
      timestamp: fields[2] as DateTime,
      userId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.isUser)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
