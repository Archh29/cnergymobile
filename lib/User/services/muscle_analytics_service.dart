import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/muscle_analytics_model.dart';
import 'auth_service.dart';

class MuscleAnalyticsService {
  static const String baseUrl = 'http://localhost/cynergy';
  
  // Get weekly muscle group statistics
  static Future<MuscleAnalyticsData> getWeeklyStats() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/muscle_analytics.php?action=weekly_stats&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Weekly stats response status: ${response.statusCode}');
      print('Weekly stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MuscleAnalyticsData.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weekly stats: $e');
      rethrow;
    }
  }

  // Get monthly muscle group statistics
  static Future<MuscleAnalyticsData> getMonthlyStats() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/muscle_analytics.php?action=monthly_stats&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Monthly stats response status: ${response.statusCode}');
      print('Monthly stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MuscleAnalyticsData.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching monthly stats: $e');
      rethrow;
    }
  }

  // Get sub-muscles of a primary muscle group
  static Future<SubMusclesData> getSubMuscles(
    int parentMuscleId, 
    String period
  ) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/muscle_analytics.php?action=sub_muscles&user_id=$userId&parent_muscle_id=$parentMuscleId&period=$period'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Sub muscles response status: ${response.statusCode}');
      print('Sub muscles response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SubMusclesData.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sub muscles: $e');
      rethrow;
    }
  }

  // Get detailed analytics for a specific muscle group
  static Future<DetailedMuscleAnalytics> getDetailedAnalytics(
    String muscleGroup, 
    String period
  ) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/muscle_analytics.php?action=detailed_analytics&user_id=$userId&muscle_group=${Uri.encodeComponent(muscleGroup)}&period=$period'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Detailed analytics response status: ${response.statusCode}');
      print('Detailed analytics response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return DetailedMuscleAnalytics.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching detailed analytics: $e');
      rethrow;
    }
  }

  // Helper method to get muscle group color
  static int getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return 0xFF4ECDC4; // Teal
      case 'back':
        return 0xFF96CEB4; // Green
      case 'shoulders':
        return 0xFFFF6B35; // Orange
      case 'biceps':
        return 0xFF45B7D1; // Blue
      case 'triceps':
        return 0xFF9B59B6; // Purple
      case 'legs':
        return 0xFFE74C3C; // Red
      case 'glutes':
        return 0xFFF39C12; // Orange
      case 'abs':
        return 0xFF2ECC71; // Green
      case 'forearms':
        return 0xFF34495E; // Dark Blue
      case 'calves':
        return 0xFFE67E22; // Orange
      default:
        return 0xFF95A5A6; // Gray
    }
  }

  // Helper method to get muscle group icon
  static String getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return '💪';
      case 'back':
        return '🦾';
      case 'shoulders':
        return '🏋️';
      case 'biceps':
        return '💪';
      case 'triceps':
        return '💪';
      case 'legs':
        return '🦵';
      case 'glutes':
        return '🍑';
      case 'abs':
        return '🔥';
      case 'forearms':
        return '🤏';
      case 'calves':
        return '🦵';
      default:
        return '💪';
    }
  }
}
