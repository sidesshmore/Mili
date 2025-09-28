import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Activities/widgets/breathingScreen.dart';
import 'package:mindmate/features/Activities/widgets/journeyTimelineScreen.dart';
import 'package:mindmate/services/auth_service.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String? userId;
  String? userEmail;
  Map<String, dynamic>? onboardingData;
  bool isLoading = true;

  // PageController for quotes
  final PageController _pageController = PageController();
  int currentQuoteIndex = 0;

  // Updated activities list without quotes
  final List<Map<String, dynamic>> activities = [
    {
      'title': 'Emotional Journey',
      'subtitle': 'Your emotional journey over time',
      'icon': Icons.timeline,
      'color': Colors.blue.shade100,
      'screen': const JourneyTimelineScreen(),
    },
    {
      'title': 'Breathing',
      'subtitle': 'Guided breathing exercises',
      'icon': Icons.air,
      'color': Colors.teal.shade100,
      'screen': const BreathingScreen(),
    },
  ];

  // Quotes data
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

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    try {
      // Fetch user details from SharedPreferences
      userId = await AuthService.getUserId();
      userEmail = await AuthService.getUserEmail();

      // Fetch onboarding data from Supabase
      onboardingData = await AuthService.getOnboardingData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading user details: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Globals.customBlue),
    );
  }

  String _getDisplayName() {
    if (onboardingData != null) {
      final firstName = onboardingData!['first_name'] ?? '';
      final lastName = onboardingData!['last_name'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      }
    }
    return userEmail?.split('@')[0] ?? 'User';
  }

  void _onQuotePageChanged(int index) {
    setState(() {
      currentQuoteIndex = index;
    });
  }

  void _showUserDetailsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Globals.screenWidth * 0.06),
              topRight: Radius.circular(Globals.screenWidth * 0.06),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Globals.screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.03),

                // Welcome Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(Globals.screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: Globals.customBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      Globals.screenWidth * 0.04,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(),
                        style: TextStyle(
                          fontSize: Globals.screenWidth * 0.06,
                          fontWeight: FontWeight.w600,
                          color: Globals.customBlue,
                        ),
                      ),
                      if (userEmail != null) ...[
                        SizedBox(height: Globals.screenHeight * 0.01),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: Globals.screenWidth * 0.04,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: Globals.screenWidth * 0.02),
                            Expanded(
                              child: Text(
                                userEmail!,
                                style: TextStyle(
                                  fontSize: Globals.screenWidth * 0.035,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: Globals.screenHeight * 0.03),

                // User Details Section
                if (onboardingData != null) ...[
                  Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: Globals.screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: Globals.screenHeight * 0.02),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Globals.screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(
                        Globals.screenWidth * 0.04,
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          'Sleep Duration',
                          onboardingData!['sleep_duration'],
                        ),
                        _buildProfileItem(
                          'Energy Level',
                          onboardingData!['energy_level'],
                        ),
                        _buildProfileItem(
                          'Free Time Activity',
                          onboardingData!['free_time_activity'],
                        ),
                        _buildProfileItem(
                          'Therapy Experience',
                          onboardingData!['therapy_experience'],
                        ),
                        _buildProfileItem(
                          'Relationship Status',
                          onboardingData!['relationship_status'],
                        ),
                        _buildProfileItem(
                          'Anxiety Experience',
                          onboardingData!['anxiety_experience'],
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: Globals.screenHeight * 0.03),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: Globals.screenHeight * 0.06,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context); // Close modal first
                      await AuthService.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Globals.screenWidth * 0.03,
                        ),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(
                      Icons.logout_rounded,
                      size: Globals.screenWidth * 0.05,
                    ),
                    label: Text(
                      'Logout',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Globals for this context
    Globals.initialize(context);

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Activities',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.black54,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.black87,
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              onPressed: _showUserDetailsModal,
              tooltip: 'Profile',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activities List
              ...activities
                  .map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ActivityCard(
                        title: activity['title'],
                        subtitle: activity['subtitle'],
                        icon: activity['icon'],
                        color: activity['color'],
                        onTap: () {
                          if (activity['screen'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => activity['screen'],
                              ),
                            );
                          } else {
                            _showSnackBar('${activity['title']} coming soon!');
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),

              const SizedBox(height: 24),

              // Quotes Section - Expanded to fill remaining space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Quotes Container
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purple.shade50,
                              Colors.purple.shade100.withOpacity(0.7),
                              Colors.pink.shade50.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onQuotePageChanged,
                          itemCount: quotes.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(28.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Quote icon with better styling
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade200.withOpacity(
                                        0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.format_quote,
                                      size: 32,
                                      color: Colors.purple.shade400,
                                    ),
                                  ),

                                  // Quote text with better typography
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        quotes[index]['quote']!,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.055,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          height: 1.5,
                                          letterSpacing: 0.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        quotes.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentQuoteIndex == index ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: currentQuoteIndex == index
                                ? Colors.purple.shade400
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Swipe hint with better styling
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Swipe for more inspiration',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, dynamic value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: Globals.screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value?.toString() ?? 'Not specified',
                style: TextStyle(
                  fontSize: Globals.screenWidth * 0.035,
                  color: value != null ? Colors.grey[800] : Colors.grey[500],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          SizedBox(height: Globals.screenHeight * 0.015),
          Divider(color: Colors.grey[300], thickness: 1),
          SizedBox(height: Globals.screenHeight * 0.015),
        ],
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: subtitle != null ? 120 : 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.black87),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
