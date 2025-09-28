import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'dart:developer';

class CallHelp extends StatefulWidget {
  const CallHelp({super.key});

  @override
  State<CallHelp> createState() => _CallHelpState();
}

class _CallHelpState extends State<CallHelp> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  Future<void> _makeCall() async {
    try {
      const phoneNumber = '988';
      log('Attempting to call: $phoneNumber');

      final bool? result = await FlutterPhoneDirectCaller.callNumber(
        phoneNumber,
      );

      if (result == true) {
        log('Call initiated successfully');
      } else {
        log('Failed to initiate call');
        _showErrorMessage('Unable to make call. Please dial 988 directly.');
      }
    } catch (e) {
      log('Error making call: $e');
      _showErrorMessage('Call error. Please dial 988 for immediate help.');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Copy Number',
          textColor: Colors.white,
          onPressed: () {
            // Copy 988 to clipboard if needed
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(
          bottom: Globals.screenHeight * 0.02,
          left: Globals.screenWidth * 0.04,
          right: Globals.screenWidth * 0.04,
        ),
        child: Container(
          padding: EdgeInsets.all(Globals.screenWidth * 0.05),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade50, Colors.orange.shade50],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Emergency Icon
              Container(
                width: Globals.screenWidth * 0.16,
                height: Globals.screenWidth * 0.16,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.red.shade600,
                  size: Globals.screenWidth * 0.08,
                ),
              ),

              SizedBox(height: Globals.screenHeight * 0.02),

              // Main Message
              Text(
                'Help is available',
                style: TextStyle(
                  fontSize: Globals.screenWidth * 0.055,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Globals.screenHeight * 0.008),

              Text(
                'Speak with someone today',
                style: TextStyle(
                  fontSize: Globals.screenWidth * 0.042,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Globals.screenHeight * 0.025),

              // Call Button
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: GestureDetector(
                      onTap: _makeCall,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: Globals.screenHeight * 0.018,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.red.shade600, Colors.red.shade700],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: Globals.screenWidth * 0.06,
                            ),
                            SizedBox(width: Globals.screenWidth * 0.03),
                            Column(
                              children: [
                                Text(
                                  'Call 988',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: Globals.screenWidth * 0.045,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Suicide & Crisis Lifeline',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: Globals.screenWidth * 0.032,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
