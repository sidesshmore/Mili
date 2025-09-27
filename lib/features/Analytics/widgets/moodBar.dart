import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mindmate/services/analytics_data_service.dart';

class MoodBar extends StatelessWidget {
  const MoodBar({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: screenWidth * 0.9,
      height: screenHeight * 0.4, // Reduced height for cleaner look
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
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.04,
          screenWidth * 0.04,
          screenWidth * 0.04,
          screenWidth * 0.08,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: AnalyticsDataService.getMoodDistribution(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final moodData = snapshot.data ?? {};

                  if (moodData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mood,
                            size: screenWidth * 0.15,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            'No mood data available',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort emojis by percentage (highest first)
                  final sortedEntries = moodData.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  // Prepare data for chart
                  final emojis = sortedEntries.map((e) => e.key).toList();
                  final percentages = sortedEntries
                      .map((e) => e.value)
                      .toList();

                  // Calculate better Y-axis maximum
                  final maxY = _calculateYAxisMax(percentages);
                  final interval = _calculateInterval(maxY);

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < emojis.length) {
                              return BarTooltipItem(
                                '${emojis[groupIndex]}\n${rod.toY.toStringAsFixed(1)}%',
                                TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.035,
                                  height: 1.2,
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: screenWidth * 0.15,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < emojis.length) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    top: screenHeight * 0.01,
                                  ),
                                  child: Text(
                                    emojis[index],
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: screenWidth * 0.12,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey.shade600,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barGroups: _generateBarGroups(percentages, screenWidth),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate a user-friendly Y-axis maximum value
  double _calculateYAxisMax(List<double> percentages) {
    if (percentages.isEmpty) return 50.0;

    final maxValue = percentages.first;

    // Round up to the next "nice" number
    if (maxValue <= 10) return 10.0;
    if (maxValue <= 20) return 20.0;
    if (maxValue <= 25) return 25.0;
    if (maxValue <= 30) return 30.0;
    if (maxValue <= 40) return 40.0;
    if (maxValue <= 50) return 50.0;
    if (maxValue <= 60) return 60.0;
    if (maxValue <= 75) return 75.0;
    if (maxValue <= 80) return 80.0;
    if (maxValue <= 100) return 100.0;

    // For values above 100, round up to nearest 25
    return ((maxValue / 25).ceil() * 25).toDouble();
  }

  /// Calculate interval based on Y-axis maximum for better grid lines
  double _calculateInterval(double maxY) {
    if (maxY <= 10) return 2.0;
    if (maxY <= 20) return 5.0;
    if (maxY <= 25) return 5.0;
    if (maxY <= 30) return 5.0;
    if (maxY <= 40) return 10.0;
    if (maxY <= 50) return 10.0;
    if (maxY <= 60) return 10.0;
    if (maxY <= 75) return 15.0;
    if (maxY <= 80) return 20.0;
    if (maxY <= 100) return 20.0;

    // For larger values, use 25 as interval
    return 25.0;
  }

  List<BarChartGroupData> _generateBarGroups(
    List<double> percentages,
    double screenWidth,
  ) {
    // Generate colors dynamically based on the number of emojis
    final colors = _generateColors(percentages.length);

    return List.generate(percentages.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: percentages[index],
            color: colors[index % colors.length],
            width: _calculateBarWidth(screenWidth, percentages.length),
            borderRadius: BorderRadius.circular(screenWidth * 0.015),
          ),
        ],
      );
    });
  }

  double _calculateBarWidth(double screenWidth, int numberOfBars) {
    // Adjust bar width based on number of bars (max 5 now)
    if (numberOfBars <= 3) return screenWidth * 0.1;
    if (numberOfBars <= 5) return screenWidth * 0.08;
    return screenWidth * 0.06;
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      const Color(0xFFFFB300), // Orange
      const Color(0xFF64B5F6), // Blue
      const Color(0xFFE57373), // Red
      const Color(0xFFBA68C8), // Purple
      const Color(0xFF81C784), // Green
      const Color(0xFFFFD54F), // Yellow
      const Color(0xFFFF8A65), // Deep Orange
      const Color(0xFF4FC3F7), // Light Blue
      const Color(0xFFAED581), // Light Green
      const Color(0xFFDCE775), // Lime
      const Color(0xFFFF9800), // Amber
      const Color(0xFF9C27B0), // Deep Purple
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFF44336), // Red
    ];

    // If we need more colors than we have, generate variations
    if (count <= baseColors.length) {
      return baseColors.take(count).toList();
    }

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final baseColor = baseColors[i % baseColors.length];
      // Create variations by adjusting opacity or brightness
      if (i < baseColors.length) {
        colors.add(baseColor);
      } else {
        colors.add(baseColor.withOpacity(0.7));
      }
    }
    return colors;
  }
}
