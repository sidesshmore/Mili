import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindmate/services/auth_service.dart';

class AffirmationsService {
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

  /// Get personalized affirmations for the current week
  static Future<List<String>?> getWeeklyAffirmations() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found for affirmations generation');
        return null;
      }

      // Calculate current week dates (Monday to Sunday)
      final now = DateTime.now();
      final currentWeekStart = _getWeekStart(now);
      final currentWeekEnd = _getWeekEnd(currentWeekStart);

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

      // Generate affirmations using Gemini
      final affirmationsList = await _generateAffirmationsWithGemini(
        weeklyChats,
      );

      return affirmationsList;
    } catch (e) {
      log('Error generating weekly affirmations: $e');
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

      log('Retrieved ${response.length} chat summaries for affirmations');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('Error getting weekly chats for affirmations: $e');
      return [];
    }
  }

  /// Generate affirmations using Gemini API
  static Future<List<String>?> _generateAffirmationsWithGemini(
    List<Map<String, dynamic>> weeklyChats,
  ) async {
    try {
      final service = AffirmationsService();

      // Create summary text from chat summaries
      final summariesText = _formatSummariesForAffirmations(weeklyChats);

      // Create affirmations generation prompt
      final prompt = _createAffirmationsPrompt(summariesText);

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
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1000,
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
          return _parseAffirmationsResponse(generatedText);
        }
      }

      log(
        'Failed to generate affirmations with Gemini: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      log('Error generating affirmations with Gemini: $e');
      return null;
    }
  }

  /// Format chat summaries for affirmations generation
  static String _formatSummariesForAffirmations(
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

  static String _createAffirmationsPrompt(String summariesText) {
    return '''
You are creating personalized affirmations for someone based on their week of mental health conversations with their AI companion MindMate. 

Based on these conversation summaries, create 7-8 positive, empowering affirmations that:

1. Acknowledge their specific struggles and validate their experiences
2. Reinforce their strengths and resilience shown this week
3. Address specific challenges or growth areas mentioned
4. Celebrate progress, however small
5. Provide encouragement for their ongoing journey
6. Use "I am" or "I" statements in present tense
7. Feel personal and relevant to their specific situation

IMPORTANT GUIDELINES:
- Make them specific to this person's experiences, not generic
- Keep each affirmation to 1-2 sentences maximum
- Use warm, supportive, but not overly emotional language
- Focus on their inherent worth and capabilities
- Acknowledge both their struggles and strengths
- Make them feel empowering and realistic

Please provide your response as a simple numbered list:
1. [First affirmation]
2. [Second affirmation]
3. [Third affirmation]
... and so on

Weekly conversation summaries:
$summariesText

Remember: These affirmations should feel like they were written specifically for this person based on their actual experiences and conversations this week.''';
  }

  /// Parse the affirmations response from Gemini
  static List<String>? _parseAffirmationsResponse(String response) {
    try {
      final List<String> affirmations = [];
      final lines = response.split('\n');

      for (final line in lines) {
        final trimmedLine = line.trim();
        // Look for numbered list items
        final RegExp numberRegex = RegExp(r'^\d+\.\s*(.+)$');
        final match = numberRegex.firstMatch(trimmedLine);

        if (match != null) {
          final affirmation = match.group(1)?.trim();
          if (affirmation != null && affirmation.isNotEmpty) {
            affirmations.add(affirmation);
          }
        }
      }

      // If numbered parsing didn't work, try bullet points or simple lines
      if (affirmations.isEmpty) {
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isNotEmpty &&
              !trimmedLine.toLowerCase().contains('affirmation') &&
              !trimmedLine.toLowerCase().contains('weekly conversation') &&
              trimmedLine.length > 10) {
            // Remove any bullet points or numbers at the start
            final cleanedLine = trimmedLine
                .replaceAll(RegExp(r'^[-•*]\s*'), '')
                .replaceAll(RegExp(r'^\d+\.\s*'), '');
            if (cleanedLine.trim().isNotEmpty) {
              affirmations.add(cleanedLine.trim());
            }
          }
        }
      }

      if (affirmations.isNotEmpty) {
        log('Parsed ${affirmations.length} affirmations');
        return affirmations.take(8).toList(); // Limit to 8 affirmations
      }

      log('Could not parse any affirmations from response');
      return null;
    } catch (e) {
      log('Error parsing affirmations response: $e');
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

  /// Check if current week has enough data for affirmations generation
  static Future<bool> hasEnoughDataForCurrentWeek() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return false;

      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = _getWeekEnd(weekStart);

      final weeklyChats = await _getWeeklyChats(userId, weekStart, weekEnd);
      return weeklyChats.isNotEmpty; // Need at least 1 chat summary
    } catch (e) {
      log('Error checking data availability for affirmations: $e');
      return false;
    }
  }
}
