import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/onboarding_model.dart';

class OnboardingService {
  static const String baseUrl = 'http://localhost/cynergy/onboarding_api.php'; // Replace with your actual URL
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Check if user type is customer (4) and profile setup is needed
  Future<ApiResponse<bool>> checkUserEligibility(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-user-eligibility.php?user_id=$userId'),
        headers: _headers,
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: jsonResponse['success'],
          message: jsonResponse['message'],
          data: jsonResponse['data'],
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to check user eligibility',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get fitness goals from backend
  Future<ApiResponse<List<OnboardingGoal>>> getFitnessGoals() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-fitness-goals.php'),
        headers: _headers,
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success']) {
        List<OnboardingGoal> goals = (jsonResponse['data'] as List)
            .map((goal) => OnboardingGoal.fromJson(goal))
            .toList();
        
        return ApiResponse<List<OnboardingGoal>>(
          success: true,
          message: jsonResponse['message'],
          data: goals,
        );
      } else {
        return ApiResponse<List<OnboardingGoal>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch fitness goals',
        );
      }
    } catch (e) {
      return ApiResponse<List<OnboardingGoal>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get activity levels from backend
  Future<ApiResponse<List<ActivityLevelOption>>> getActivityLevels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-activity-levels.php'),
        headers: _headers,
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success']) {
        List<ActivityLevelOption> levels = (jsonResponse['data'] as List)
            .map((level) => ActivityLevelOption.fromJson(level))
            .toList();
        
        return ApiResponse<List<ActivityLevelOption>>(
          success: true,
          message: jsonResponse['message'],
          data: levels,
        );
      } else {
        return ApiResponse<List<ActivityLevelOption>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch activity levels',
        );
      }
    } catch (e) {
      return ApiResponse<List<ActivityLevelOption>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Complete onboarding setup
  Future<ApiResponse<Map<String, dynamic>>> completeOnboarding(OnboardingData onboardingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complete-onboarding.php'),
        headers: _headers,
        body: json.encode(onboardingData.toJson()),
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'],
          message: jsonResponse['message'],
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to complete onboarding',
          errors: jsonResponse['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Update existing user profile (for customers who already have accounts)
  Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(int userId, MemberProfileDetails profile) async {
    try {
      final Map<String, dynamic> requestData = {
        'user_id': userId,
        'profile': profile.toJson(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/update-user-profile.php'),
        headers: _headers,
        body: json.encode(requestData),
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: jsonResponse['success'],
          message: jsonResponse['message'],
          data: jsonResponse['data'],
          errors: jsonResponse['errors'],
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to update profile',
          errors: jsonResponse['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Get user profile details
  Future<ApiResponse<MemberProfileDetails>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-user-profile.php?user_id=$userId'),
        headers: _headers,
      ).timeout(timeoutDuration);

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      if (response.statusCode == 200 && jsonResponse['success']) {
        MemberProfileDetails profile = MemberProfileDetails.fromJson(jsonResponse['data']);
        
        return ApiResponse<MemberProfileDetails>(
          success: true,
          message: jsonResponse['message'],
          data: profile,
        );
      } else {
        return ApiResponse<MemberProfileDetails>(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to fetch user profile',
        );
      }
    } catch (e) {
      return ApiResponse<MemberProfileDetails>(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Helper method to convert gender string to ID
  int getGenderId(String gender) {
    return gender.toLowerCase() == 'male' ? 1 : 2;
  }

  // Helper method to validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Helper method to validate password strength
  bool isValidPassword(String password) {
    return password.length >= 8;
  }
}
