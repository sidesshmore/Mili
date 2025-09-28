import 'package:flutter/material.dart';
import 'package:mindmate/services/weekly_happiness_service.dart';

class WeeklyHappiness extends StatefulWidget {
  const WeeklyHappiness({super.key});

  @override
  State<WeeklyHappiness> createState() => _WeeklyHappinessState();
}

class _WeeklyHappinessState extends State<WeeklyHappiness> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.9,
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Highlights',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            FutureBuilder<Map<String, dynamic>?>(
              future: WeeklyHappinessService.generateWeeklyHappiness(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return _buildNoDataState(screenWidth, screenHeight);
                }

                final data = snapshot.data!;
                return Column(
                  children: [
                    _buildHighlightItem(
                      screenWidth,
                      0,
                      data['reason_1_title'] ?? '',
                      data['reason_1_description'] ?? '',
                    ),
                    _buildDivider(screenWidth),
                    _buildHighlightItem(
                      screenWidth,
                      1,
                      data['reason_2_title'] ?? '',
                      data['reason_2_description'] ?? '',
                    ),
                    _buildDivider(screenWidth),
                    _buildHighlightItem(
                      screenWidth,
                      2,
                      data['reason_3_title'] ?? '',
                      data['reason_3_description'] ?? '',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(
    double screenWidth,
    int index,
    String title,
    String description,
  ) {
    final isExpanded = expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedIndex = isExpanded ? null : index;
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: screenWidth * 0.01),
              Text(
                description,
                style: TextStyle(
                  fontSize: screenWidth * 0.033,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (description.length > 100) ...[
                SizedBox(height: screenWidth * 0.01),
                Text(
                  isExpanded ? 'Show less' : 'Show more',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double screenWidth) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      color: Colors.grey.shade200,
    );
  }

  Widget _buildNoDataState(double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
        child: Column(
          children: [
            Icon(
              Icons.timeline,
              size: screenWidth * 0.12,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              'Keep chatting to see highlights',
              style: TextStyle(
                fontSize: screenWidth * 0.037,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
