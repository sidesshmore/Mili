import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-1.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-4.dart';
import 'package:mindmate/services/onboarding_service.dart';

class OnboardingThree extends StatefulWidget {
  const OnboardingThree({super.key});

  @override
  State<OnboardingThree> createState() => _OnboardingThreeState();
}

class _OnboardingThreeState extends State<OnboardingThree> {
  String? selectedHobby;

  Widget _buildHobbyButton(String text) {
    bool isSelected = selectedHobby == text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedHobby = text;
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
                      Text(
                        "How do you spend your \nfree time?",
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  _buildHobbyButton("Enjoying Being Alone"),
                  SizedBox(height: screenHeight * 0.01),
                  _buildHobbyButton("With friends & family"),
                  SizedBox(height: screenHeight * 0.01),
                  _buildHobbyButton("Watching Short Videos"),
                  SizedBox(height: screenHeight * 0.01),
                  _buildHobbyButton("Staying Productive"),
                ],
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MaterialButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OnboardingOne(),
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
                        onPressed: () {
                          if (selectedHobby == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select an option'),
                              ),
                            );
                            return;
                          }

                          OnboardingService.setFreeTimeActivity(selectedHobby!);

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OnboardingFour(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            'Next',
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
