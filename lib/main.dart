import 'dart:developer';

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
import 'package:mindmate/services/chat_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive storage
  try {
    await ChatStorageService.init();
    log('Hive storage initialized successfully');
  } catch (e) {
    log('Error initializing Hive storage: $e');
  }

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
      home: const SplashScreen(), // Always start with splash screen
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
