// Create new file: services/summary_insights_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindmate/services/auth_service.dart';

class SummaryInsightsService {
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

  /// Get journey timeline data with key moments and mood progression
  static Future<List<Map<String, dynamic>>> getJourneyTimeline() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return [];

      final summaries = await _supabase
          .from('chat_summaries')
          .select()
          .eq('user_id', userId)
          .order('summary_period_start', ascending: false);

      return summaries
          .map(
            (summary) => {
              'id': summary['id'],
              'date': DateTime.parse(summary['summary_period_start']),
              'summary': summary['summary'],
              'mood': summary['mood_emoji'],
              'messageCount': summary['message_count_at_summary'],
            },
          )
          .toList();
    } catch (e) {
      log('Error getting journey timeline: $e');
      return [];
    }
  }

  /// Get personalized activity recommendations based on recent mood
  static Future<List<Map<String, dynamic>>>
  getMoodBasedRecommendations() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return [];

      // Get last 3 summaries to understand recent state
      final recentSummaries = await _supabase
          .from('chat_summaries')
          .select('mood_emoji, summary')
          .eq('user_id', userId)
          .order('summary_period_start', ascending: false)
          .limit(3);

      if (recentSummaries.isEmpty) {
        return _getDefaultRecommendations();
      }

      return _generateMoodBasedRecommendations(recentSummaries);
    } catch (e) {
      log('Error getting mood recommendations: $e');
      return _getDefaultRecommendations();
    }
  }

  static List<Map<String, dynamic>> _generateMoodBasedRecommendations(
    List<dynamic> summaries,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze recent mood patterns
    final recentMoods = summaries
        .map((s) => s['mood_emoji'] as String)
        .toList();
    final anxiousEmojis = ['😰', '😨', '😱', '🤯', '😬', '🫨'];
    final sadEmojis = ['😔', '😢', '😭', '🥺', '😞', '😪', '😓'];
    final happyEmojis = ['😊', '😄', '😁', '🙂', '😌', '😇', '🥰'];

    final isAnxious = recentMoods.any((mood) => anxiousEmojis.contains(mood));
    final isSad = recentMoods.any((mood) => sadEmojis.contains(mood));
    final isHappy = recentMoods.any((mood) => happyEmojis.contains(mood));

    if (isAnxious) {
      recommendations.addAll([
        {
          'title': 'Breathing Exercise',
          'description': 'Calm your mind with guided breathing',
          'icon': 'air',
          'action': 'breathing',
          'priority': 'high',
        },
        {
          'title': 'Grounding Technique',
          'description': '5-4-3-2-1 sensory grounding exercise',
          'icon': 'psychology',
          'action': 'grounding',
          'priority': 'high',
        },
      ]);
    }

    if (isSad) {
      recommendations.addAll([
        {
          'title': 'Gratitude Practice',
          'description': 'Focus on positive aspects of your day',
          'icon': 'favorite',
          'action': 'gratitude',
          'priority': 'medium',
        },
        {
          'title': 'Gentle Movement',
          'description': 'Light stretching or a short walk',
          'icon': 'directions_walk',
          'action': 'movement',
          'priority': 'medium',
        },
      ]);
    }

    if (isHappy) {
      recommendations.addAll([
        {
          'title': 'Celebrate Progress',
          'description': 'Acknowledge your positive moments',
          'icon': 'celebration',
          'action': 'celebration',
          'priority': 'low',
        },
      ]);
    }

    // Always include some general recommendations
    recommendations.addAll([
      {
        'title': 'Mindful Journaling',
        'description': 'Reflect on your thoughts and feelings',
        'icon': 'edit_note',
        'action': 'journaling',
        'priority': 'medium',
      },
      {
        'title': 'Memory Garden',
        'description': 'Visit your collection of positive moments',
        'icon': 'local_florist',
        'action': 'memory_garden',
        'priority': 'low',
      },
    ]);

    return recommendations;
  }

  static List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'title': 'Start Your Journey',
        'description': 'Have a conversation with Mili to begin',
        'icon': 'chat',
        'action': 'chat',
        'priority': 'high',
      },
      {
        'title': 'Breathing Exercise',
        'description': 'Begin with mindful breathing',
        'icon': 'air',
        'action': 'breathing',
        'priority': 'medium',
      },
    ];
  }

  /// Get positive moments for Memory Garden
  static Future<List<Map<String, dynamic>>> getMemoryGardenMoments() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) return [];

      final positiveEmojis = [
        '😊',
        '😄',
        '😁',
        '🙂',
        '😌',
        '😇',
        '🥰',
        '😍',
        '🤗',
        '🌟',
        '✨',
      ];

      final summaries = await _supabase
          .from('chat_summaries')
          .select()
          .eq('user_id', userId)
          .order('summary_period_start', ascending: false);

      return summaries
          .where((s) => positiveEmojis.contains(s['mood_emoji']))
          .map(
            (s) => {
              'id': s['id'],
              'date': DateTime.parse(s['summary_period_start']),
              'summary': s['summary'],
              'mood': s['mood_emoji'],
              'type': _categorizePositiveMoment(s['summary']),
            },
          )
          .toList();
    } catch (e) {
      log('Error getting memory garden moments: $e');
      return [];
    }
  }

  static String _categorizePositiveMoment(String summary) {
    final summaryLower = summary.toLowerCase();

    if (summaryLower.contains('achievement') ||
        summaryLower.contains('accomplished') ||
        summaryLower.contains('success')) {
      return 'achievement';
    } else if (summaryLower.contains('relationship') ||
        summaryLower.contains('friend') ||
        summaryLower.contains('family')) {
      return 'relationship';
    } else if (summaryLower.contains('breakthrough') ||
        summaryLower.contains('realization') ||
        summaryLower.contains('insight')) {
      return 'breakthrough';
    } else if (summaryLower.contains('grateful') ||
        summaryLower.contains('thankful') ||
        summaryLower.contains('appreciation')) {
      return 'gratitude';
    } else {
      return 'general_positive';
    }
  }
}
