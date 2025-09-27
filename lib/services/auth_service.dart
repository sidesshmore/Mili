import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;

  static Future<void> setLoggedIn(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', status);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Store user ID in SharedPreferences
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    log('User ID set: $userId');
  }

  // Get user ID from SharedPreferences
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Store user email in SharedPreferences
  static Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  // Get user email from SharedPreferences
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  static Future<String?> signUpWithOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
      await setUserEmail(email);
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> signInWithOTP(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: false);
      await setUserEmail(email);
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> verifyOTP(String email, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null) {
        await setLoggedIn(true);
        await setUserId(response.user!.id);
        await setUserEmail(email);
        return null; // Success
      } else {
        return 'Invalid OTP';
      }
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    await setLoggedIn(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userEmail');
  }

  // Store onboarding data in Supabase
  static Future<String?> storeOnboardingData(
    Map<String, dynamic> onboardingData,
  ) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return 'User not authenticated';
      }

      await _supabase.from('user_onboarding').upsert({
        'user_id': userId,
        'first_name': onboardingData['firstName'],
        'last_name': onboardingData['lastName'],
        'free_time_activity': onboardingData['freeTimeActivity'],
        'sleep_duration': onboardingData['sleepDuration'],
        'energy_level': onboardingData['energyLevel'],
        'therapy_experience': onboardingData['therapyExperience'],
        'relationship_status': onboardingData['relationshipStatus'],
        'anxiety_experience': onboardingData['anxietyExperience'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Get onboarding data from Supabase
  static Future<Map<String, dynamic>?> getOnboardingData() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return null;
      }

      final response = await _supabase
          .from('user_onboarding')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }
}
