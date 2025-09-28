import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> quotes = [
    {
      'quote':
          'You are stronger than you know, braver than you believe, and more capable than you can imagine.',
      'author': 'Unknown',
    },
    {
      'quote':
          'The only way out is through. Keep going, keep growing, keep glowing.',
      'author': 'Robert Frost',
    },
    {
      'quote':
          'Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.',
      'author': 'Unknown',
    },
    {
      'quote':
          'Healing isn\'t about erasing your past, it\'s about learning to live with it and grow beyond it.',
      'author': 'Unknown',
    },
    {
      'quote': 'Progress, not perfection. Every small step forward counts.',
      'author': 'Unknown',
    },
    {
      'quote':
          'It\'s okay to not be okay. What\'s not okay is staying in that place forever.',
      'author': 'Unknown',
    },
    {
      'quote':
          'You have been assigned this mountain to show others it can be moved.',
      'author': 'Mel Robbins',
    },
    {
      'quote':
          'Mental health is not a destination, but a process. It\'s about how you drive, not where you\'re going.',
      'author': 'Noam Shpancer',
    },
  ];

  void _onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
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
          'Inspirational Quotes',
          style: TextStyle(
            fontSize: Globals.screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: Globals.customBlue,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Globals.customBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Globals.customBlue.withOpacity(0.2)),
            ),
            child: Text(
              '${currentIndex + 1}/${quotes.length}',
              style: TextStyle(
                color: Globals.customBlue,
                fontSize: Globals.screenWidth * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Globals.screenWidth * 0.04),
          child: Column(
            children: [
              // Quotes PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: Globals.screenWidth * 0.02,
                      ),
                      padding: EdgeInsets.all(Globals.screenWidth * 0.08),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          Globals.screenWidth * 0.06,
                        ),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_quote,
                            size: Globals.screenWidth * 0.12,
                            color: Globals.customBlue.withOpacity(0.3),
                          ),

                          SizedBox(height: Globals.screenHeight * 0.04),

                          Text(
                            quotes[index]['quote']!,
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.05,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                              height: 1.5,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          SizedBox(height: Globals.screenHeight * 0.04),

                          Container(
                            height: 1,
                            width: Globals.screenWidth * 0.2,
                            color: Globals.customBlue.withOpacity(0.3),
                          ),

                          SizedBox(height: Globals.screenHeight * 0.03),

                          Text(
                            '— ${quotes[index]['author']}',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.04,
                              fontWeight: FontWeight.w500,
                              color: Globals.customBlue,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: Globals.screenHeight * 0.02),

              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  quotes.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentIndex == index
                          ? Globals.customBlue
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              SizedBox(height: Globals.screenHeight * 0.02),

              Text(
                'Swipe left or right for more quotes',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Globals.screenWidth * 0.035,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
