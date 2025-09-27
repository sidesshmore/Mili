import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-7.dart';
import 'package:mindmate/services/onboarding_service.dart';
// Import your home screen here - replace with actual path
// import 'package:mindmate/features/Home/ui/home_screen.dart';

class OnboardingEight extends StatefulWidget {
  const OnboardingEight({super.key});

  @override
  State<OnboardingEight> createState() => _OnboardingEightState();
}

class _OnboardingEightState extends State<OnboardingEight> {
  String? selectedAnxietyExperience;
  bool _isLoading = false;

  Widget _buildAnxietyButton(String text) {
    bool isSelected = selectedAnxietyExperience == text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAnxietyExperience = text;
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected
                ? Globals.customLightBlue
                : const Color(0xffF3F3F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    if (selectedAnxietyExperience == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select an option')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Save anxiety experience
    OnboardingService.setAnxietyExperience(selectedAnxietyExperience!);

    // Save all data to database
    final error = await OnboardingService.saveToDatabase();

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $error'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to home screen
    // Replace this with your actual home screen navigation
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home', // Replace with your home route
      (route) => false,
    );

    // Alternative if you're using direct navigation:
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (context) => HomeScreen()),
    //   (route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0, right: 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: screenHeight * 0.07),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Are you experiencing anxiety, panic attacks or have any phobias?",
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  _buildAnxietyButton("Yes"),
                  SizedBox(height: screenHeight * 0.01),
                  _buildAnxietyButton("No"),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MaterialButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OnboardingSeven(),
                                  ),
                                );
                              },
                        color: const Color(0xffDFE2E8),
                        textColor: Colors.white,
                        padding: const EdgeInsets.all(10),
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          backgroundColor: Globals.customBlue,
                        ),
                        onPressed: _isLoading ? null : _finishOnboarding,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Finish',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
