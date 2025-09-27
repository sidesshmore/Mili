import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindmate/services/auth_service.dart';
import 'package:mindmate/services/chat_storage_service.dart';
import 'package:mindmate/models/chat_message.dart';

class ChatSummaryService {
  static final _supabase = Supabase.instance.client;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  /// Main method to check and generate summaries
  /// Call this when chat is initialized or after sending messages
  static Future<void> checkAndGenerateSummaries() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found, cannot generate summaries');
        return;
      }

      // Get current message count
      final allMessages = await ChatStorageService.getMessagesForCurrentUser();
      final currentMessageCount = allMessages.length;

      log('Current message count: $currentMessageCount');

      if (currentMessageCount < 10) {
        log('Not enough messages for summary generation');
        return;
      }

      // Get the last summary count for this user
      final lastSummaryCount = await _getLastSummaryCount(userId);
      log('Last summary count: $lastSummaryCount');

      // Calculate which summaries we need to generate
      final summariesNeeded = _calculateSummariesNeeded(
        currentMessageCount,
        lastSummaryCount,
      );

      log('Summaries needed: $summariesNeeded');

      // Generate missing summaries
      for (final summaryCount in summariesNeeded) {
        await _generateSummaryForRange(userId, allMessages, summaryCount);

        // Add a small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      log('Error in checkAndGenerateSummaries: $e');
    }
  }

  /// Get the highest message_count_at_summary for a user
  static Future<int> _getLastSummaryCount(String userId) async {
    try {
      final response = await _supabase
          .from('chat_summaries')
          .select('message_count_at_summary')
          .eq('user_id', userId)
          .order('message_count_at_summary', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return 0;
      }

      return response.first['message_count_at_summary'] as int;
    } catch (e) {
      log('Error getting last summary count: $e');
      return 0;
    }
  }

  /// Calculate which summary counts we need to generate
  static List<int> _calculateSummariesNeeded(
    int currentCount,
    int lastSummaryCount,
  ) {
    final List<int> needed = [];

    // Start from the next summary point after the last one
    int nextSummaryCount = ((lastSummaryCount ~/ 10) + 1) * 10;

    // Generate summaries for every 10 messages up to current count
    while (nextSummaryCount <= currentCount) {
      needed.add(nextSummaryCount);
      nextSummaryCount += 10;
    }

    return needed;
  }

  /// Generate summary for a specific message range
  static Future<void> _generateSummaryForRange(
    String userId,
    List<ChatMessage> allMessages,
    int summaryCount,
  ) async {
    try {
      log('Generating summary for message count: $summaryCount');

      // Get messages from (summaryCount-10) to summaryCount-1
      final startIndex = summaryCount - 10;
      final endIndex = summaryCount - 1;

      if (startIndex < 0 || endIndex >= allMessages.length) {
        log('Invalid range for summary generation: $startIndex to $endIndex');
        return;
      }

      final messagesToSummarize = allMessages.sublist(startIndex, endIndex + 1);

      // Check if summary already exists
      final existingSummary = await _checkSummaryExists(userId, summaryCount);
      if (existingSummary) {
        log('Summary already exists for count: $summaryCount');
        return;
      }

      // Generate summary using Gemini
      final summaryData = await _generateSummaryWithGemini(messagesToSummarize);

      if (summaryData != null) {
        // Store summary in database
        await _storeSummary(
          userId: userId,
          summary: summaryData['summary'] ?? 'XYZ',
          moodEmoji: summaryData['emoji'] ?? 'ABC',
          messageCountAtSummary: summaryCount,
          summaryPeriodStart: messagesToSummarize.first.timestamp,
          summaryPeriodEnd: messagesToSummarize.last.timestamp,
        );

        log('Summary generated and stored for count: $summaryCount');
      }
    } catch (e) {
      log('Error generating summary for range: $e');
    }
  }

  /// Check if summary already exists for a specific count
  static Future<bool> _checkSummaryExists(
    String userId,
    int messageCount,
  ) async {
    try {
      final response = await _supabase
          .from('chat_summaries')
          .select('id')
          .eq('user_id', userId)
          .eq('message_count_at_summary', messageCount)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      log('Error checking summary existence: $e');
      return false;
    }
  }

  /// Generate summary using Gemini API
  static Future<Map<String, String>?> _generateSummaryWithGemini(
    List<ChatMessage> messages,
  ) async {
    try {
      final service = ChatSummaryService();

      // Create conversation text for summarization
      final conversationText = _formatMessagesForSummary(messages);

      // Create summary prompt
      final prompt = _createSummaryPrompt(conversationText);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-goog-api-key': service._apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.3,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 512,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final generatedText =
              data['candidates'][0]['content']['parts'][0]['text'];
          return _parseSummaryResponse(generatedText);
        }
      }

      log('Failed to generate summary with Gemini: ${response.statusCode}');
      return null;
    } catch (e) {
      log('Error generating summary with Gemini: $e');
      return null;
    }
  }

  /// Format messages for summary generation
  static String _formatMessagesForSummary(List<ChatMessage> messages) {
    final StringBuffer buffer = StringBuffer();

    for (final message in messages) {
      final speaker = message.isUser ? 'User' : 'MindMate';
      final timestamp = message.timestamp.toIso8601String();
      buffer.writeln('[$timestamp] $speaker: ${message.text}');
    }

    return buffer.toString();
  }

  /// Create prompt for summary generation
  static String _createSummaryPrompt(String conversationText) {
    return '''
You are analyzing a mental health conversation between a user and MindMate (an AI companion). Please create a comprehensive summary that captures:

1. The main topics and themes discussed
2. User's emotional state and mood changes
3. Specific personal details, events, or situations the user shared
4. Key concerns, challenges, or positive developments mentioned
5. Any significant moments, breakthroughs, or emotional expressions

Please provide your response in this exact format:
SUMMARY: [5-6 line detailed summary capturing user's experiences, emotions, personal details, and conversation highlights]
EMOJI: [Single emoji that best represents the overall emotional tone of the conversation]

Conversation:
$conversationText

Focus on the user's perspective and experiences. Capture minute details, emotions, and personal information they shared. The summary should be comprehensive yet concise.''';
  }

  /// Parse the summary response from Gemini
  static Map<String, String>? _parseSummaryResponse(String response) {
    try {
      final lines = response.split('\n');
      String summary = '';
      String emoji = '';

      for (final line in lines) {
        if (line.startsWith('SUMMARY:')) {
          summary = line.substring(8).trim();
        } else if (line.startsWith('EMOJI:')) {
          emoji = line.substring(6).trim();
        }
      }

      if (summary.isNotEmpty && emoji.isNotEmpty) {
        return {'summary': summary, 'emoji': emoji};
      }

      // Fallback parsing if format is different
      final summaryMatch = RegExp(
        r'SUMMARY:\s*(.+?)(?=EMOJI:|$)',
        dotAll: true,
      ).firstMatch(response);
      final emojiMatch = RegExp(
        r'EMOJI:\s*(.+?)$',
        multiLine: true,
      ).firstMatch(response);

      if (summaryMatch != null && emojiMatch != null) {
        return {
          'summary': summaryMatch.group(1)?.trim() ?? '',
          'emoji': emojiMatch.group(1)?.trim() ?? '💭',
        };
      }

      log('Could not parse summary response properly');
      return null;
    } catch (e) {
      log('Error parsing summary response: $e');
      return null;
    }
  }

  /// Store summary in Supabase database
  static Future<void> _storeSummary({
    required String userId,
    required String summary,
    required String moodEmoji,
    required int messageCountAtSummary,
    required DateTime summaryPeriodStart,
    required DateTime summaryPeriodEnd,
  }) async {
    try {
      await _supabase.from('chat_summaries').insert({
        'user_id': userId,
        'summary': summary,
        'mood_emoji': moodEmoji,
        'message_count_at_summary': messageCountAtSummary,
        'summary_period_start': summaryPeriodStart.toIso8601String(),
        'summary_period_end': summaryPeriodEnd.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      log('Summary stored successfully in database');
    } catch (e) {
      log('Error storing summary: $e');
      rethrow;
    }
  }

  /// Get all summaries for current user
  static Future<List<Map<String, dynamic>>> getSummariesForCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return [];
      }

      final response = await _supabase
          .from('chat_summaries')
          .select()
          .eq('user_id', userId)
          .order('message_count_at_summary', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error getting summaries: $e');
      return [];
    }
  }

  /// Get latest summary for current user
  static Future<Map<String, dynamic>?> getLatestSummaryForCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('chat_summaries')
          .select()
          .eq('user_id', userId)
          .order('message_count_at_summary', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }

      return null;
    } catch (e) {
      log('Error getting latest summary: $e');
      return null;
    }
  }

  /// Delete all summaries for current user (for testing/cleanup)
  static Future<void> clearSummariesForCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return;
      }

      await _supabase.from('chat_summaries').delete().eq('user_id', userId);

      log('All summaries cleared for current user');
    } catch (e) {
      log('Error clearing summaries: $e');
    }
  }

  /// Get summary statistics
  static Future<Map<String, dynamic>> getSummaryStats() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return {
          'totalSummaries': 0,
          'lastSummaryCount': 0,
          'nextSummaryAt': 10,
        };
      }

      final summaries = await getSummariesForCurrentUser();
      final messageCount =
          await ChatStorageService.getMessageCountForCurrentUser();
      final lastSummaryCount = summaries.isNotEmpty
          ? summaries.first['message_count_at_summary'] as int
          : 0;

      final nextSummaryAt = ((messageCount ~/ 10) + 1) * 10;

      return {
        'totalSummaries': summaries.length,
        'lastSummaryCount': lastSummaryCount,
        'nextSummaryAt': nextSummaryAt,
        'currentMessageCount': messageCount,
        'summariesNeeded':
            messageCount >= 10 && messageCount > lastSummaryCount,
      };
    } catch (e) {
      log('Error getting summary stats: $e');
      return {
        'totalSummaries': 0,
        'lastSummaryCount': 0,
        'nextSummaryAt': 10,
        'currentMessageCount': 0,
        'summariesNeeded': false,
      };
    }
  }
}
