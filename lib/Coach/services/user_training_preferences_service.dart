import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserTrainingPreferencesService {
  static const String baseUrl = 'https://api.cnergy.site';

  // Get user training preferences
  static Future<Map<String, dynamic>> getPreferences(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_training_preferences.php?action=get_preferences&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to load preferences');
    } catch (e) {
      throw Exception('Error loading preferences: $e');
    }
  }

  // Save user training preferences
  static Future<bool> savePreferences({
    required int userId,
    required String trainingFocus,
    List<int>? customMuscleGroups,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'training_focus': trainingFocus,
        'custom_muscle_groups': customMuscleGroups,
      };
      
      final url = '$baseUrl/user_training_preferences.php?action=save_preferences';
      
      print('🔍 SERVICE - Saving preferences:');
      print('   Full URL: $url');
      print('   Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('🔍 SERVICE - Response status: ${response.statusCode}');
      print('🔍 SERVICE - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error saving preferences: $e');
    }
  }

  // Dismiss a warning
  static Future<bool> dismissWarning({
    required int userId,
    required int muscleGroupId,
    required String warningType,
    bool isPermanent = false,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user_training_preferences.php?action=dismiss_warning'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'muscle_group_id': muscleGroupId,
          'warning_type': warningType,
          'is_permanent': isPermanent,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error dismissing warning: $e');
    }
  }

  // Reset dismissals
  static Future<bool> resetDismissals({
    required int userId,
    int? muscleGroupId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user_training_preferences.php?action=reset_dismissals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'muscle_group_id': muscleGroupId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Error resetting dismissals: $e');
    }
  }

  // Get all muscle groups for custom selection
  static Future<List<Map<String, dynamic>>> getMuscleGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_training_preferences.php?action=get_muscle_groups'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        throw Exception('API returned success=false: ${data['message'] ?? 'Unknown error'}');
      }
      throw Exception('Failed to load muscle groups - HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error loading muscle groups: $e');
    }
  }

  // Get dismissed warnings
  static Future<List<Map<String, dynamic>>> getDismissedWarnings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user_training_preferences.php?action=get_dismissals&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to load dismissed warnings');
    } catch (e) {
      throw Exception('Error loading dismissed warnings: $e');
    }
  }
}

