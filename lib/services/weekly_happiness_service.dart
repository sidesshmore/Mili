import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindmate/services/auth_service.dart';

class WeeklyHappinessService {
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

  /// Generate and store weekly happiness summary for current user
  static Future<Map<String, dynamic>?> generateWeeklyHappiness() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found for weekly happiness generation');
        return null;
      }

      // Calculate current week dates (Monday to Sunday)
      final now = DateTime.now();
      final currentWeekStart = _getWeekStart(now);
      final currentWeekEnd = _getWeekEnd(currentWeekStart);

      // Check if weekly summary already exists for this week
      final existingSummary = await _getWeeklyHappiness(
        userId,
        currentWeekStart,
      );
      if (existingSummary != null) {
        log('Weekly happiness summary already exists for this week');
        return existingSummary;
      }

      // Get chat summaries for the current week
      final weeklyChats = await _getWeeklyChats(
        userId,
        currentWeekStart,
        currentWeekEnd,
      );

      if (weeklyChats.isEmpty) {
        log('No chat summaries found for current week');
        return null;
      }

      // Generate happiness reasons using Gemini
      final happinessData = await _generateHappinessWithGemini(weeklyChats);

      if (happinessData != null) {
        // Store in database
        await _storeWeeklyHappiness(
          userId: userId,
          weekStart: currentWeekStart,
          weekEnd: currentWeekEnd,
          happinessData: happinessData,
        );

        log('Weekly happiness summary generated and stored');
        return await _getWeeklyHappiness(userId, currentWeekStart);
      }

      return null;
    } catch (e) {
      log('Error generating weekly happiness: $e');
      return null;
    }
  }

  /// Get existing weekly happiness summary
  static Future<Map<String, dynamic>?> getWeeklyHappiness([
    DateTime? date,
  ]) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return null;

      final targetDate = date ?? DateTime.now();
      final weekStart = _getWeekStart(targetDate);

      return await _getWeeklyHappiness(userId, weekStart);
    } catch (e) {
      log('Error getting weekly happiness: $e');
      return null;
    }
  }

  /// Get chat summaries for a specific week
  static Future<List<Map<String, dynamic>>> _getWeeklyChats(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    try {
      final response = await _supabase
          .from('chat_summaries')
          .select(
            'summary, mood_emoji, summary_period_start, summary_period_end',
          )
          .eq('user_id', userId)
          .gte('summary_period_start', weekStart.toIso8601String())
          .lte('summary_period_end', weekEnd.toIso8601String())
          .order('summary_period_start', ascending: true);

      log('Retrieved ${response.length} chat summaries for week');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error getting weekly chats: $e');
      return [];
    }
  }

  /// Generate happiness reasons using Gemini API
  static Future<Map<String, String>?> _generateHappinessWithGemini(
    List<Map<String, dynamic>> weeklyChats,
  ) async {
    try {
      final service = WeeklyHappinessService();

      // Create summary text from chat summaries
      final summariesText = _formatSummariesForHappiness(weeklyChats);

      // Create happiness generation prompt
      final prompt = _createHappinessPrompt(summariesText);

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
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 800,
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
          return _parseHappinessResponse(generatedText);
        }
      }

      log('Failed to generate happiness with Gemini: ${response.statusCode}');
      return null;
    } catch (e) {
      log('Error generating happiness with Gemini: $e');
      return null;
    }
  }

  /// Format chat summaries for happiness generation
  static String _formatSummariesForHappiness(
    List<Map<String, dynamic>> summaries,
  ) {
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < summaries.length; i++) {
      final summary = summaries[i];
      final emoji = summary['mood_emoji'] as String;
      final text = summary['summary'] as String;
      final date = DateTime.parse(summary['summary_period_start']);

      buffer.writeln('Day ${i + 1} (${_formatDate(date)}) - $emoji:');
      buffer.writeln(text);
      buffer.writeln('');
    }

    return buffer.toString();
  }

  static String _createHappinessPrompt(String summariesText) {
    return '''
You are analyzing a week's worth of mental health conversation summaries between a user and their AI companion MindMate. Based on these summaries, identify the top 3 specific moments or experiences this person should feel proud of or grateful for this week.

IMPORTANT: Create titles that help the user instantly recall the exact moment or day. Use specific details, actions, or outcomes mentioned in the conversations.

Instead of generic titles like "Personal Growth" or "Positive Mindset", use specific ones like:
- "Tuesday's Presentation Success"
- "Found Calm During Mom's Call"
- "Chose Self-Care Over Overtime"
- "That Breakthrough in Therapy"
- "Helped Sarah Through Her Crisis"

Focus on:
- Specific accomplishments with concrete details
- Exact moments of breakthrough or realization
- Particular challenges overcome or handled well
- Specific acts of self-care, kindness, or courage
- Precise social interactions or connections made
- Particular skills used or progress noticed

For each reason, provide:
1. A specific, memorable title that references the exact moment/day/situation (4-8 words)
2. A warm description that expands on the details and why it matters (2-3 sentences)

Please provide your response in this exact format:
REASON_1_TITLE: [Specific moment/experience title]
REASON_1_DESC: [Detailed description explaining the moment and its significance]
REASON_2_TITLE: [Specific moment/experience title]
REASON_2_DESC: [Detailed description explaining the moment and its significance]
REASON_3_TITLE: [Specific moment/experience title]
REASON_3_DESC: [Detailed description explaining the moment and its significance]

Weekly conversation summaries:
$summariesText

Remember: Titles should be like memory triggers - when the user reads them, they should immediately think "Oh yes, that moment!" Be specific about timing, people, situations, or outcomes mentioned in the conversations.''';
  }

  /// Parse the happiness response from Gemini
  static Map<String, String>? _parseHappinessResponse(String response) {
    try {
      final Map<String, String> result = {};
      final lines = response.split('\n');

      for (final line in lines) {
        if (line.startsWith('REASON_1_TITLE:')) {
          result['reason_1_title'] = line.substring(15).trim();
        } else if (line.startsWith('REASON_1_DESC:')) {
          result['reason_1_description'] = line.substring(14).trim();
        } else if (line.startsWith('REASON_2_TITLE:')) {
          result['reason_2_title'] = line.substring(15).trim();
        } else if (line.startsWith('REASON_2_DESC:')) {
          result['reason_2_description'] = line.substring(14).trim();
        } else if (line.startsWith('REASON_3_TITLE:')) {
          result['reason_3_title'] = line.substring(15).trim();
        } else if (line.startsWith('REASON_3_DESC:')) {
          result['reason_3_description'] = line.substring(14).trim();
        }
      }

      // Validate that all required fields are present
      final requiredKeys = [
        'reason_1_title',
        'reason_1_description',
        'reason_2_title',
        'reason_2_description',
        'reason_3_title',
        'reason_3_description',
      ];

      for (final key in requiredKeys) {
        if (!result.containsKey(key) || result[key]!.isEmpty) {
          log('Missing or empty field: $key');
          return null;
        }
      }

      return result;
    } catch (e) {
      log('Error parsing happiness response: $e');
      return null;
    }
  }

  /// Store weekly happiness in database
  static Future<void> _storeWeeklyHappiness({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
    required Map<String, String> happinessData,
  }) async {
    try {
      await _supabase.from('weekly_happiness_summary').insert({
        'user_id': userId,
        'week_start_date': weekStart.toIso8601String().split('T')[0],
        'week_end_date': weekEnd.toIso8601String().split('T')[0],
        'reason_1_title': happinessData['reason_1_title'],
        'reason_1_description': happinessData['reason_1_description'],
        'reason_2_title': happinessData['reason_2_title'],
        'reason_2_description': happinessData['reason_2_description'],
        'reason_3_title': happinessData['reason_3_title'],
        'reason_3_description': happinessData['reason_3_description'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      log('Weekly happiness stored successfully');
    } catch (e) {
      log('Error storing weekly happiness: $e');
      rethrow;
    }
  }

  /// Get weekly happiness from database
  static Future<Map<String, dynamic>?> _getWeeklyHappiness(
    String userId,
    DateTime weekStart,
  ) async {
    try {
      final response = await _supabase
          .from('weekly_happiness_summary')
          .select()
          .eq('user_id', userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }

      return null;
    } catch (e) {
      log('Error getting weekly happiness from database: $e');
      return null;
    }
  }

  /// Helper method to get the start of the week (Monday)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// Helper method to get the end of the week (Sunday)
  static DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Check if current week has enough data for happiness generation
  static Future<bool> hasEnoughDataForCurrentWeek() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return false;

      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = _getWeekEnd(weekStart);

      final weeklyChats = await _getWeeklyChats(userId, weekStart, weekEnd);
      return weeklyChats.length >= 2; // Need at least 2 chat summaries
    } catch (e) {
      log('Error checking data availability: $e');
      return false;
    }
  }

  /// Delete weekly happiness for current user (for testing)
  static Future<void> clearWeeklyHappinessForCurrentUser() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return;

      await _supabase
          .from('weekly_happiness_summary')
          .delete()
          .eq('user_id', userId);

      log('Weekly happiness cleared for current user');
    } catch (e) {
      log('Error clearing weekly happiness: $e');
    }
  }
}
