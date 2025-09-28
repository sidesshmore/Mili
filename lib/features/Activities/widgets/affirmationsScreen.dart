import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/services/affirmations_service.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  List<String> affirmations = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAffirmations();
  }

  Future<void> _loadAffirmations() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final fetchedAffirmations =
          await AffirmationsService.getWeeklyAffirmations();

      if (fetchedAffirmations != null && fetchedAffirmations.isNotEmpty) {
        setState(() {
          affirmations = fetchedAffirmations;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'No chat data available for this week. Start chatting with MindMate to get personalized affirmations!';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to load affirmations. Please try again.';
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
          'Daily Affirmations',
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
              onPressed: _loadAffirmations,
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage.isNotEmpty
            ? _buildErrorState()
            : _buildAffirmationsList(),
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
            'Creating your personalized affirmations...',
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
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: Globals.screenWidth * 0.15,
                color: Colors.orange.shade400,
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
                onPressed: _loadAffirmations,
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

  Widget _buildAffirmationsList() {
    return Padding(
      padding: EdgeInsets.all(Globals.screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Globals.screenWidth * 0.05),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.pink.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(Globals.screenWidth * 0.04),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.pink.shade400,
                      size: Globals.screenWidth * 0.06,
                    ),
                    SizedBox(width: Globals.screenWidth * 0.02),
                    Text(
                      'Personalized for You',
                      style: TextStyle(
                        fontSize: Globals.screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.pink.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Globals.screenHeight * 0.01),
                Text(
                  'These affirmations are crafted based on your recent conversations and experiences.',
                  style: TextStyle(
                    fontSize: Globals.screenWidth * 0.035,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Globals.screenHeight * 0.03),
          Expanded(
            child: ListView.builder(
              itemCount: affirmations.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: Globals.screenHeight * 0.015,
                  ),
                  child: _buildAffirmationCard(affirmations[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffirmationCard(String affirmation, int index) {
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.purple.shade50,
      Colors.orange.shade50,
      Colors.teal.shade50,
      Colors.pink.shade50,
      Colors.indigo.shade50,
      Colors.amber.shade50,
    ];

    final borderColors = [
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.purple.shade200,
      Colors.orange.shade200,
      Colors.teal.shade200,
      Colors.pink.shade200,
      Colors.indigo.shade200,
      Colors.amber.shade200,
    ];

    final textColors = [
      Colors.blue.shade800,
      Colors.green.shade800,
      Colors.purple.shade800,
      Colors.orange.shade800,
      Colors.teal.shade800,
      Colors.pink.shade800,
      Colors.indigo.shade800,
      Colors.amber.shade800,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Globals.screenWidth * 0.05),
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(Globals.screenWidth * 0.04),
        border: Border.all(color: borderColors[index % borderColors.length]),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Globals.screenWidth * 0.02),
            decoration: BoxDecoration(
              color: textColors[index % textColors.length].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: Globals.screenWidth * 0.035,
                fontWeight: FontWeight.w700,
                color: textColors[index % textColors.length],
              ),
            ),
          ),
          SizedBox(width: Globals.screenWidth * 0.04),
          Expanded(
            child: Text(
              affirmation,
              style: TextStyle(
                fontSize: Globals.screenWidth * 0.042,
                fontWeight: FontWeight.w500,
                color: textColors[index % textColors.length],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
