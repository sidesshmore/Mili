import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindmate/services/auth_service.dart';

class AnalyticsDataService {
  static final _supabase = Supabase.instance.client;

  /// Get streak data for the current user for the last 31 days
  /// Returns a list of 31 strings representing emojis for each day
  /// If no data exists for a day, returns an empty string
  static Future<List<String>> getStreakData() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found for streak data');
        return List.filled(31, '');
      }

      // Calculate date range for last 31 days
      final now = DateTime.now();
      final thirtyOneDaysAgo = now.subtract(const Duration(days: 30));

      // Get all summaries for the user within the date range
      final response = await _supabase
          .from('chat_summaries')
          .select('mood_emoji, summary_period_start, summary_period_end')
          .eq('user_id', userId)
          .gte('summary_period_start', thirtyOneDaysAgo.toIso8601String())
          .lte('summary_period_end', now.toIso8601String())
          .order('summary_period_start', ascending: true);

      log('Retrieved ${response.length} summaries for streak data');

      // Create a map to count emojis per day
      final Map<String, Map<String, int>> dailyEmojiCounts = {};

      // Initialize the last 31 days
      for (int i = 0; i < 31; i++) {
        final date = now.subtract(Duration(days: 30 - i));
        final dateKey = _getDateKey(date);
        dailyEmojiCounts[dateKey] = {};
      }

      // Process summaries and count emojis per day
      for (final summary in response) {
        final emoji = summary['mood_emoji'] as String;
        final startDate = DateTime.parse(summary['summary_period_start']);
        final endDate = DateTime.parse(summary['summary_period_end']);

        // Add emoji count for each day the summary spans
        DateTime currentDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

        while (currentDate.isBefore(endDateOnly.add(const Duration(days: 1)))) {
          final dateKey = _getDateKey(currentDate);

          if (dailyEmojiCounts.containsKey(dateKey)) {
            dailyEmojiCounts[dateKey]![emoji] =
                (dailyEmojiCounts[dateKey]![emoji] ?? 0) + 1;
          }

          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      // Convert to list of most frequent emojis per day
      final List<String> streakData = [];

      for (int i = 0; i < 31; i++) {
        final date = now.subtract(Duration(days: 30 - i));
        final dateKey = _getDateKey(date);
        final dayEmojis = dailyEmojiCounts[dateKey] ?? {};

        if (dayEmojis.isEmpty) {
          streakData.add('');
        } else {
          // Find the most frequent emoji for this day
          String mostFrequentEmoji = '';
          int maxCount = 0;

          dayEmojis.forEach((emoji, count) {
            if (count > maxCount) {
              maxCount = count;
              mostFrequentEmoji = emoji;
            }
          });

          streakData.add(mostFrequentEmoji);
        }
      }

      log('Generated streak data: ${streakData.length} days');
      return streakData;
    } catch (e) {
      log('Error getting streak data: $e');
      return List.filled(31, '');
    }
  }

  /// Get mood distribution data for the current user
  /// Returns a map with emoji as key and percentage as value
  static Future<Map<String, double>> getMoodDistribution() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found for mood distribution');
        return {};
      }

      // Get all summaries for the user
      final response = await _supabase
          .from('chat_summaries')
          .select('mood_emoji')
          .eq('user_id', userId);

      log('Retrieved ${response.length} summaries for mood distribution');

      if (response.isEmpty) {
        return {};
      }

      // Count occurrences of each emoji
      final Map<String, int> emojiCounts = {};
      int totalCount = 0;

      for (final summary in response) {
        final emoji = summary['mood_emoji'] as String;
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
        totalCount++;
      }

      // Convert counts to percentages
      final Map<String, double> moodDistribution = {};
      emojiCounts.forEach((emoji, count) {
        moodDistribution[emoji] = (count / totalCount) * 100;
      });

      log('Mood distribution calculated: $moodDistribution');
      return moodDistribution;
    } catch (e) {
      log('Error getting mood distribution: $e');
      return {};
    }
  }

  /// Get mood bar data in the format expected by the existing MoodBar widget
  /// Maps mood emojis to the predefined mood categories and calculates percentages
  static Future<List<double>> getMoodBarData() async {
    try {
      final moodDistribution = await getMoodDistribution();

      if (moodDistribution.isEmpty) {
        // Return default data if no summaries exist
        return [0, 0, 0, 0, 0];
      }

      // Define emoji to mood category mapping
      // You can customize this mapping based on the emojis your AI generates
      final Map<String, int> emojiToIndex = {
        // Happy/Positive emotions - index 0
        '😊': 0, '😄': 0, '😁': 0, '🙂': 0, '😌': 0, '😇': 0, '🥰': 0, '😍': 0,
        '🤗': 0, '😊': 0, '🌟': 0, '✨': 0, '💖': 0, '💕': 0,

        // Sad/Down emotions - index 1
        '😔': 1, '😢': 1, '😭': 1, '🥺': 1, '😞': 1, '😪': 1, '😓': 1,
        '💔': 1, '🌧️': 1, '⛈️': 1, '🌊': 1,

        // Angry/Frustrated emotions - index 2
        '😡': 2, '😤': 2, '🤬': 2, '😠': 2, '👿': 2, '💢': 2, '🔥': 2,
        '⚡': 2, '🌋': 2,

        // Anxious/Worried emotions - index 3
        '😰': 3, '😨': 3, '😱': 3, '🤐': 3, '😬': 3, '🫨': 3, '💭': 3,
        '🌪️': 3, '❄️': 3, '🏔️': 3,

        // Neutral/Mixed/Other emotions - index 4
        '😐': 4, '😑': 4, '🤔': 4, '😕': 4, '😶': 4, '🙃': 4, '🤷': 4,
        '⚖️': 4, '🌈': 4, '🌸': 4, '🍃': 4, '🌙': 4,
      };

      // Initialize mood bar data
      List<double> moodBarData = [0, 0, 0, 0, 0];

      // Map emojis to mood categories and calculate percentages
      moodDistribution.forEach((emoji, percentage) {
        final moodIndex =
            emojiToIndex[emoji] ?? 4; // Default to neutral if not found
        moodBarData[moodIndex] += percentage;
      });

      // Ensure percentages don't exceed 100% due to rounding
      final total = moodBarData.reduce((a, b) => a + b);
      if (total > 100) {
        moodBarData = moodBarData
            .map((value) => (value / total) * 100)
            .toList();
      }

      log('Mood bar data calculated: $moodBarData');
      return moodBarData;
    } catch (e) {
      log('Error getting mood bar data: $e');
      return [0, 0, 0, 0, 0];
    }
  }

  /// Get detailed mood history for the last 7 days
  /// Returns a list of 7 strings representing the most frequent emoji for each day
  static Future<List<String>> getMoodHistory() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        log('No user ID found for mood history');
        return List.filled(7, '');
      }

      // Calculate date range for last 7 days
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 6));

      // Get summaries for the last 7 days
      final response = await _supabase
          .from('chat_summaries')
          .select('mood_emoji, summary_period_start, summary_period_end')
          .eq('user_id', userId)
          .gte('summary_period_start', sevenDaysAgo.toIso8601String())
          .lte('summary_period_end', now.toIso8601String())
          .order('summary_period_start', ascending: true);

      log('Retrieved ${response.length} summaries for mood history');

      // Create a map to count emojis per day
      final Map<String, Map<String, int>> dailyEmojiCounts = {};

      // Initialize the last 7 days
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateKey = _getDateKey(date);
        dailyEmojiCounts[dateKey] = {};
      }

      // Process summaries and count emojis per day
      for (final summary in response) {
        final emoji = summary['mood_emoji'] as String;
        final startDate = DateTime.parse(summary['summary_period_start']);
        final endDate = DateTime.parse(summary['summary_period_end']);

        // Add emoji count for each day the summary spans
        DateTime currentDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );
        final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);

        while (currentDate.isBefore(endDateOnly.add(const Duration(days: 1)))) {
          final dateKey = _getDateKey(currentDate);

          if (dailyEmojiCounts.containsKey(dateKey)) {
            dailyEmojiCounts[dateKey]![emoji] =
                (dailyEmojiCounts[dateKey]![emoji] ?? 0) + 1;
          }

          currentDate = currentDate.add(const Duration(days: 1));
        }
      }

      // Convert to list of most frequent emojis per day
      final List<String> moodHistory = [];

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateKey = _getDateKey(date);
        final dayEmojis = dailyEmojiCounts[dateKey] ?? {};

        if (dayEmojis.isEmpty) {
          moodHistory.add('😐'); // Default neutral emoji if no data
        } else {
          // Find the most frequent emoji for this day
          String mostFrequentEmoji = '😐';
          int maxCount = 0;

          dayEmojis.forEach((emoji, count) {
            if (count > maxCount) {
              maxCount = count;
              mostFrequentEmoji = emoji;
            }
          });

          moodHistory.add(mostFrequentEmoji);
        }
      }

      log('Generated mood history: $moodHistory');
      return moodHistory;
    } catch (e) {
      log('Error getting mood history: $e');
      return List.filled(7, '😐');
    }
  }

  /// Get analytics summary data
  static Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        return {
          'totalSummaries': 0,
          'daysWithData': 0,
          'mostFrequentMood': '😐',
          'moodVariety': 0,
        };
      }

      final response = await _supabase
          .from('chat_summaries')
          .select('mood_emoji, summary_period_start')
          .eq('user_id', userId)
          .order('summary_period_start', ascending: false);

      if (response.isEmpty) {
        return {
          'totalSummaries': 0,
          'daysWithData': 0,
          'mostFrequentMood': '😐',
          'moodVariety': 0,
        };
      }

      // Count unique days with data
      final Set<String> uniqueDays = {};
      final Map<String, int> emojiCounts = {};

      for (final summary in response) {
        final emoji = summary['mood_emoji'] as String;
        final date = DateTime.parse(summary['summary_period_start']);

        uniqueDays.add(_getDateKey(date));
        emojiCounts[emoji] = (emojiCounts[emoji] ?? 0) + 1;
      }

      // Find most frequent mood
      String mostFrequentMood = '😐';
      int maxCount = 0;
      emojiCounts.forEach((emoji, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentMood = emoji;
        }
      });

      return {
        'totalSummaries': response.length,
        'daysWithData': uniqueDays.length,
        'mostFrequentMood': mostFrequentMood,
        'moodVariety': emojiCounts.length,
      };
    } catch (e) {
      log('Error getting analytics summary: $e');
      return {
        'totalSummaries': 0,
        'daysWithData': 0,
        'mostFrequentMood': '😐',
        'moodVariety': 0,
      };
    }
  }

  /// Helper method to generate a consistent date key
  static String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear analytics cache (if needed for testing)
  static Future<void> clearAnalyticsCache() async {
    // This method can be used to clear any cached analytics data
    // Currently, we're fetching fresh data each time, so no cache to clear
    log('Analytics cache cleared (no cache implemented)');
  }
}
