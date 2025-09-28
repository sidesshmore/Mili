// Create new file: features/Activities/widgets/journeyTimelineScreen.dart

import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/services/summary_insights_service.dart';

class JourneyTimelineScreen extends StatefulWidget {
  const JourneyTimelineScreen({super.key});

  @override
  State<JourneyTimelineScreen> createState() => _JourneyTimelineScreenState();
}

class _JourneyTimelineScreenState extends State<JourneyTimelineScreen> {
  List<Map<String, dynamic>> timelineData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
  }

  Future<void> _loadTimelineData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final data = await SummaryInsightsService.getJourneyTimeline();

      setState(() {
        timelineData = data;
        isLoading = false;
      });

      if (data.isEmpty) {
        setState(() {
          errorMessage =
              'Start chatting with Mili to see your emotional journey unfold here!';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'Unable to load your journey timeline. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Globals.initialize(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Globals.customBlue,
            size: Globals.screenWidth * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Your Journey Timeline',
          style: TextStyle(
            fontSize: Globals.screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: Globals.customBlue,
          ),
        ),
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Globals.customBlue,
                size: Globals.screenWidth * 0.06,
              ),
              onPressed: _loadTimelineData,
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage.isNotEmpty
            ? _buildErrorState()
            : _buildTimelineView(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Globals.customBlue, strokeWidth: 3),
          SizedBox(height: Globals.screenHeight * 0.03),
          Text(
            'Mapping your emotional journey...',
            style: TextStyle(
              fontSize: Globals.screenWidth * 0.04,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Globals.screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(Globals.screenWidth * 0.08),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timeline,
                size: Globals.screenWidth * 0.15,
                color: Colors.blue.shade400,
              ),
            ),
            SizedBox(height: Globals.screenHeight * 0.03),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: Globals.screenWidth * 0.045,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Globals.screenHeight * 0.04),
            SizedBox(
              width: double.infinity,
              height: Globals.screenHeight * 0.06,
              child: ElevatedButton(
                onPressed: _loadTimelineData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Globals.customBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Globals.screenWidth * 0.03,
                    ),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: Globals.screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    return Padding(
      padding: EdgeInsets.all(Globals.screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: Globals.screenHeight * 0.03),
          Expanded(
            child: ListView.builder(
              itemCount: timelineData.length,
              itemBuilder: (context, index) {
                return _buildTimelineItem(timelineData[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    final date = item['date'] as DateTime;
    final mood = item['mood'] as String;
    final summary = item['summary'] as String;
    final messageCount = item['messageCount'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: Globals.screenHeight * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Globals.screenWidth * 0.12,
            child: Column(
              children: [
                Container(
                  width: Globals.screenWidth * 0.08,
                  height: Globals.screenWidth * 0.08,

                  child: Center(
                    child: Text(
                      mood,
                      style: TextStyle(fontSize: Globals.screenWidth * 0.0635),
                    ),
                  ),
                ),
                if (index < timelineData.length - 1)
                  Container(
                    width: 2,
                    height: Globals.screenHeight * 0.08,
                    color: Colors.grey[300],
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(Globals.screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Globals.screenWidth * 0.04),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: Globals.screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Globals.screenHeight * 0.015),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: Globals.screenWidth * 0.038,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    // Positive moods
    if ([
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
    ].contains(mood)) {
      return Colors.green;
    }
    // Anxious/worried moods
    if ([
      '😰',
      '😨',
      '😱',
      '🤯',
      '😬',
      '🫨',
      '🌪️',
      '❄️',
      '🏔️',
    ].contains(mood)) {
      return Colors.orange;
    }
    // Sad moods
    if ([
      '😔',
      '😢',
      '😭',
      '🥺',
      '😞',
      '😪',
      '😓',
      '💔',
      '🌧️',
      '⛈️',
    ].contains(mood)) {
      return Colors.blue;
    }
    // Angry moods
    if (['😡', '😤', '🤬', '😠', '👿', '💢', '🔥', '⚡', '🌋'].contains(mood)) {
      return Colors.red;
    }
    // Default neutral
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '${difference} days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '${weeks} week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    }
  }
}
