import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/progress_model.dart';
import 'auth_service.dart';

class BodyMeasurementsService {
  static const String baseUrl = "https://api.cnergy.site/body_measurements_api.php";

  // Get current user ID from AuthService
  static Future<int> getCurrentUserId() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      return userId;
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }

  // Get all body measurements for a user
  static Future<List<ProgressModel>> getBodyMeasurements() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_measurements&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      print('🔍 Body measurements API response status: ${response.statusCode}');
      print('🔍 Body measurements API response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProgressModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch body measurements: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching body measurements: $e');
      return [];
    }
  }

  // Add a new body measurement (or update if exists for today)
  static Future<Map<String, dynamic>> addBodyMeasurement({
    required double weight,
    double? bodyFatPercentage,
    double? bmi,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? armsCm,
    double? thighsCm,
    String? notes,
  }) async {
    try {
      final userId = await getCurrentUserId();
      
      final requestBody = {
        'user_id': userId,
        'weight': weight,
        'body_fat_percentage': bodyFatPercentage,
        'bmi': bmi,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'arms_cm': armsCm,
        'thighs_cm': thighsCm,
        'notes': notes,
      };

      print('🔍 Adding body measurement: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl?action=add_measurement'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      print('🔍 Add measurement API response status: ${response.statusCode}');
      print('🔍 Add measurement API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] == true,
          'message': responseData['message'] ?? 'Weight saved',
          'action': responseData['action'] ?? 'created',
          'id': responseData['id'],
        };
      } else {
        throw Exception('Failed to add body measurement: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding body measurement: $e');
      return {
        'success': false,
        'message': 'Error: $e',
        'action': 'error',
        'id': null,
      };
    }
  }

  // Update an existing body measurement
  static Future<bool> updateBodyMeasurement({
    required int id,
    double? weight,
    double? bodyFatPercentage,
    double? bmi,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? armsCm,
    double? thighsCm,
    String? notes,
  }) async {
    try {
      final userId = await getCurrentUserId();
      
      final requestBody = {
        'id': id,
        'user_id': userId,
        'weight': weight,
        'body_fat_percentage': bodyFatPercentage,
        'bmi': bmi,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'arms_cm': armsCm,
        'thighs_cm': thighsCm,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl?action=update_measurement'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to update body measurement: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating body measurement: $e');
      return false;
    }
  }

  // Delete a body measurement
  static Future<bool> deleteBodyMeasurement(int id) async {
    try {
      final userId = await getCurrentUserId();
      
      final requestBody = {
        'id': id,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_measurement'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        throw Exception('Failed to delete body measurement: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting body measurement: $e');
      return false;
    }
  }

  // Get the latest weight entry
  static Future<double?> getLatestWeight() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_latest_weight&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['weight']?.toDouble();
      } else {
        throw Exception('Failed to get latest weight: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting latest weight: $e');
      return null;
    }
  }
}
