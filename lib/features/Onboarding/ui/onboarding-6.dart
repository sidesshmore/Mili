import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-5.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-7.dart';
import 'package:mindmate/services/onboarding_service.dart';

class OnboardingSix extends StatefulWidget {
  const OnboardingSix({super.key});

  @override
  State<OnboardingSix> createState() => _OnboardingSixState();
}

class _OnboardingSixState extends State<OnboardingSix> {
  String? selectedTherapyExperience;

  Widget _buildTherapyButton(String text) {
    bool isSelected = selectedTherapyExperience == text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTherapyExperience = text;
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
                        "Have you ever been in \ntherapy before?",
                        style: TextStyle(
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  _buildTherapyButton("Yes"),
                  SizedBox(height: screenHeight * 0.01),
                  _buildTherapyButton("No"),
                  SizedBox(height: screenHeight * 0.01),
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
                              builder: (context) => OnboardingFive(),
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
                          if (selectedTherapyExperience == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please select an option'),
                              ),
                            );
                            return;
                          }

                          OnboardingService.setTherapyExperience(
                            selectedTherapyExperience!,
                          );

                          // Navigate to next screen (relationship status)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OnboardingSeven(),
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
