import 'package:flutter/material.dart';
import 'package:mindmate/services/analytics_data_service.dart';

class StreakJournal extends StatelessWidget {
  const StreakJournal({super.key});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Text(
              'Mood Streak (Last 31 Days)',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          FutureBuilder<List<String>>(
            future: AnalyticsDataService.getStreakData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              final streakData = snapshot.data ?? List.filled(31, '');

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: screenWidth * 0.02,
                    mainAxisSpacing: screenWidth * 0.02,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    final moodEmoji = streakData[index];
                    final hasData = moodEmoji.isNotEmpty;

                    final availableWidth =
                        (screenWidth * 0.9 -
                            (screenWidth * 0.08) -
                            (6 * screenWidth * 0.02)) /
                        7;

                    return Container(
                      width: availableWidth,
                      height: availableWidth,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: hasData
                            ? null
                            : Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: hasData
                          ? Center(
                              child: Text(
                                moodEmoji,
                                style: TextStyle(
                                  fontSize: availableWidth * 0.95,
                                  height: 0.95,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Center(
                              child: Container(
                                width: availableWidth * 0.15,
                                height: availableWidth * 0.15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              );
            },
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
