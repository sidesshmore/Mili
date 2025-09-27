import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Otp/ui/otpScreen.dart';
import 'package:mindmate/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final error = await AuthService.signInWithOTP(email);

    setState(() {
      _isLoading = false;
    });

    if (error == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: email)),
      );
    } else {
      _showSnackBar('Error: $error');
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Globals.customBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Globals for this context
    Globals.initialize(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Globals.screenWidth * 0.06,
              vertical: Globals.screenHeight * 0.02,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: Globals.screenHeight * 0.23,
                ),
                // SizedBox(height: Globals.screenHeight * 0.04),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: Globals.screenWidth * 0.07,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.01),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: Globals.screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.06),
                Container(
                  width: Globals.screenWidth * 0.88,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Globals.customBlue,
                        size: Globals.screenWidth * 0.06,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Globals.screenWidth * 0.03,
                        ),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Globals.screenWidth * 0.03,
                        ),
                        borderSide: BorderSide(
                          color: Globals.customBlue,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(
                        color: Globals.customBlue,
                        fontSize: Globals.screenWidth * 0.04,
                      ),
                      hintStyle: TextStyle(
                        fontSize: Globals.screenWidth * 0.035,
                        color: Colors.grey[500],
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: Globals.screenHeight * 0.02,
                        horizontal: Globals.screenWidth * 0.04,
                      ),
                    ),
                    style: TextStyle(fontSize: Globals.screenWidth * 0.04),
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.03),
                SizedBox(
                  width: Globals.screenWidth * 0.88,
                  height: Globals.screenHeight * 0.065,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Globals.customBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Globals.customBlue.withOpacity(
                        0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Globals.screenWidth * 0.03,
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: Globals.screenWidth * 0.06,
                            height: Globals.screenWidth * 0.06,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: Globals.screenWidth * 0.035,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: Globals.screenWidth * 0.02,
                          vertical: Globals.screenHeight * 0.005,
                        ),
                      ),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Globals.customBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: Globals.screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
