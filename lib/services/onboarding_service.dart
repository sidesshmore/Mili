import 'package:mindmate/services/auth_service.dart';

class OnboardingService {
  static final Map<String, dynamic> _onboardingData = {};

  // Store first name and last name
  static void setName(String firstName, String lastName) {
    _onboardingData['firstName'] = firstName;
    _onboardingData['lastName'] = lastName;
  }

  // Store free time activity
  static void setFreeTimeActivity(String activity) {
    _onboardingData['freeTimeActivity'] = activity;
  }

  // Store sleep duration
  static void setSleepDuration(String duration) {
    _onboardingData['sleepDuration'] = duration;
  }

  // Store energy level
  static void setEnergyLevel(String energyLevel) {
    _onboardingData['energyLevel'] = energyLevel;
  }

  // Store therapy experience
  static void setTherapyExperience(String experience) {
    _onboardingData['therapyExperience'] = experience;
  }

  // Store relationship status
  static void setRelationshipStatus(String status) {
    _onboardingData['relationshipStatus'] = status;
  }

  // Store anxiety experience
  static void setAnxietyExperience(String experience) {
    _onboardingData['anxietyExperience'] = experience;
  }

  // Get all collected data
  static Map<String, dynamic> getAllData() {
    return Map<String, dynamic>.from(_onboardingData);
  }

  // Save all data to Supabase
  static Future<String?> saveToDatabase() async {
    if (_onboardingData.isEmpty) {
      return 'No onboarding data to save';
    }

    // Check if all required fields are present
    if (!isComplete()) {
      return 'Please complete all required fields';
    }

    final error = await AuthService.storeOnboardingData(_onboardingData);

    if (error == null) {
      // Clear local data after successful save
      _onboardingData.clear();
    }

    return error;
  }

  // Clear all data
  static void clearData() {
    _onboardingData.clear();
  }

  // Check if all required data is collected
  static bool isComplete() {
    final requiredFields = [
      'firstName',
      'lastName',
      'freeTimeActivity',
      'sleepDuration',
      'energyLevel',
      'therapyExperience',
      'relationshipStatus',
      'anxietyExperience',
    ];

    for (String field in requiredFields) {
      if (!_onboardingData.containsKey(field) ||
          _onboardingData[field] == null ||
          _onboardingData[field].toString().trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  // Get current progress percentage
  static double getProgress() {
    final totalFields = 8; // All 8 fields are now required
    final completedFields = _onboardingData.length;
    return completedFields / totalFields;
  }

  // Get specific field value
  static String? getField(String fieldName) {
    return _onboardingData[fieldName];
  }

  // Check if a specific field is completed
  static bool isFieldCompleted(String fieldName) {
    return _onboardingData.containsKey(fieldName) &&
        _onboardingData[fieldName] != null &&
        _onboardingData[fieldName].toString().trim().isNotEmpty;
  }
}
