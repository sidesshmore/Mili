import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mindmate/features/BottomNav/ui/bottomNavbar.dart';
import 'package:mindmate/features/LogIn/ui/loginScreen.dart';
import 'package:mindmate/features/Otp/ui/otpScreen.dart';
import 'package:mindmate/features/SignUp/ui/signupScreen.dart';
import 'package:mindmate/features/SplashScreen/ui/splashScreen.dart';
import 'package:mindmate/features/Home/ui/homeScreen.dart';
import 'package:mindmate/features/Onboarding/ui/onboarding-1.dart';
import 'package:mindmate/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Mate',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffFAFAFA),
        primaryColor: const Color(0xff87A2FF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff87A2FF)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: AuthService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          if (snapshot.data == true) {
            // User is logged in, check if onboarding is completed
            return FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getOnboardingData(),
              builder: (context, onboardingSnapshot) {
                if (onboardingSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SplashScreen();
                }

                if (onboardingSnapshot.data == null) {
                  // User hasn't completed onboarding
                  return const OnboardingOne();
                } else {
                  // User has completed onboarding
                  return const Navbar();
                }
              },
            );
          } else {
            return const SplashScreen();
          }
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/navbar': (context) => const Navbar(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingOne(),
        '/otp': (context) => const OTPScreen(email: ''),
      },
    );
  }
}
