// features/Analytics/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:mindmate/features/Analytics/widgets/moodBar.dart';

import 'package:mindmate/features/Analytics/widgets/streakJournal.dart';
import 'package:mindmate/services/analytics_data_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Updated mood labels to represent the 5 categories
  final List<String> moodLabels = ['😊', '😔', '😡', '😰', '😐'];

  late Future<Map<String, dynamic>> analyticsData;

  @override
  void initState() {
    super.initState();
    analyticsData = AnalyticsDataService.getAnalyticsSummary();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mood Analytics',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              setState(() {
                analyticsData = AnalyticsDataService.getAnalyticsSummary();
              });
            },
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              analyticsData = AnalyticsDataService.getAnalyticsSummary();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Main Analytics Widgets
                const StreakJournal(),
                const MoodBar(),

                // Additional spacing at bottom
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
