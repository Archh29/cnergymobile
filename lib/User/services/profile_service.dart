import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = 'https://api.cnergy.site';
  static const String profileEndpoint = '$baseUrl/profile_management.php';

  // Change password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse(profileEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'change_password',
          'user_id': userId.toString(),
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );

      print('Change password response status: ${response.statusCode}');
      print('Change password response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$profileEndpoint?action=get_profile&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Get profile response status: ${response.statusCode}');
      print('Get profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String fname,
    required String mname,
    required String lname,
    required String email,
    required String bday,
    required String genderId,
    required String fitnessLevel,
    required String heightCm,
    required String weightKg,
    required String targetWeight,
    required String bodyFat,
    required String activityLevel,
    required String workoutDaysPerWeek,
    required String equipmentAccess,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse(profileEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'action': 'update_profile',
          'user_id': userId.toString(),
          'fname': fname,
          'mname': mname,
          'lname': lname,
          'email': email,
          'bday': bday,
          'gender_id': genderId,
          'fitness_level': fitnessLevel,
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'target_weight': targetWeight,
          'body_fat': bodyFat,
          'activity_level': activityLevel,
          'workout_days_per_week': workoutDaysPerWeek,
          'equipment_access': equipmentAccess,
        },
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Get available genders
  static Future<List<Map<String, dynamic>>> getGenders() async {
    try {
      final response = await http.get(
        Uri.parse('$profileEndpoint?action=get_genders'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Get genders response status: ${response.statusCode}');
      print('Get genders response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting genders: $e');
      rethrow;
    }
  }
}
