import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Activities/widgets/affirmationsScreen.dart';
import 'package:mindmate/features/Activities/widgets/breathingScreen.dart';
import 'package:mindmate/features/Activities/widgets/quotesScreen.dart';
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

  // Updated activities list with widget constructors instead of routes
  final List<Map<String, dynamic>> activities = [
    {
      'title': 'Breathing',
      'icon': Icons.air,
      'color': Colors.blue.shade100,
      'screen': const BreathingScreen(),
    },
    {
      'title': 'Affirmations',
      'icon': Icons.favorite,
      'color': Colors.pink.shade100,
      'screen': const AffirmationsScreen(), // You'll need to create this screen
    },
    {
      'title': 'Quotes',
      'icon': Icons.format_quote,
      'color': Colors.purple.shade100,
      'screen': const QuotesScreen(),
    },
    {
      'title': 'Sounds',
      'icon': Icons.music_note,
      'color': Colors.green.shade100,
      'screen': null, // You'll need to create this screen
    },
    {
      'title': 'Notepad',
      'icon': Icons.edit_note,
      'color': Colors.orange.shade100,
      'screen': null, // You'll need to create this screen
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Text(
          'Activities',
          style: TextStyle(
            fontSize: Globals.screenWidth * 0.05,
            fontWeight: FontWeight.w600,
            color: Globals.customBlue,
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
                  color: Globals.customBlue,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _showUserDetailsModal,
                child: CircleAvatar(
                  backgroundColor: Globals.customBlue,
                  radius: 18,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What would you like to do today?',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: ActivityCard(
                        title: activities[index]['title'],
                        icon: activities[index]['icon'],
                        color: activities[index]['color'],
                        onTap: () {
                          // Check if screen is available
                          if (activities[index]['screen'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    activities[index]['screen'],
                              ),
                            );
                          } else {
                            _showSnackBar(
                              '${activities[index]['title']} coming soon!',
                            );
                          }
                        },
                      ),
                    );
                  },
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
