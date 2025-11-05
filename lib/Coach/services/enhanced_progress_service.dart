import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.models.dart';
import '../models/progress_tracker_model.dart';
import 'auth_service.dart';

class EnhancedProgressService {
  static const String baseUrl = 'https://api.cnergy.site';

  // Get current user ID
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      return userId;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Fetch user routines
  static Future<List<RoutineModel>> fetchUserRoutines() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_routines&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('error')) {
          print('API Error: ${responseData['error']}');
          return [];
        }
        if (responseData is List) {
          return responseData.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user routines: $e');
      return [];
    }
  }

  // Fetch member programs (for coach perspective)
  static Future<List<RoutineModel>> fetchMemberPrograms() async {
    try {
      final coachId = await getCurrentUserId();
      if (coachId == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_member_programs&coach_id=$coachId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('error')) {
          print('API Error: ${responseData['error']}');
          return [];
        }
        if (responseData is List) {
          return responseData.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member programs: $e');
      return [];
    }
  }

  // Get progress data for a specific member
  static Future<List<ProgressTrackerModel>> getMemberProgress(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_member_progress&member_id=$memberId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member progress: $e');
      return [];
    }
  }

  // Get all members' progress for coach
  static Future<Map<int, List<ProgressTrackerModel>>> getAllMembersProgress() async {
    try {
      final coachId = await getCurrentUserId();
      if (coachId == null) return {};

      final response = await http.get(
        Uri.parse('$baseUrl?action=get_all_members_progress&coach_id=$coachId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map) {
          Map<int, List<ProgressTrackerModel>> result = {};
          for (final entry in responseData.entries) {
            final memberId = int.tryParse(entry.key) ?? 0;
            if (entry.value is List) {
              result[memberId] = (entry.value as List)
                  .map((json) => ProgressTrackerModel.fromJson(json))
                  .toList();
            }
          }
          return result;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching all members progress: $e');
      return {};
    }
  }

  // Get muscle group for exercise name
  static String _getMuscleGroup(String exerciseName) {
    final lowerName = exerciseName.toLowerCase();
    
    if (lowerName.contains('bench') || lowerName.contains('press') || lowerName.contains('chest')) {
      return 'Chest';
    } else if (lowerName.contains('squat') || lowerName.contains('leg') || lowerName.contains('quad')) {
      return 'Legs';
    } else if (lowerName.contains('deadlift') || lowerName.contains('back') || lowerName.contains('row')) {
      return 'Back';
    } else if (lowerName.contains('shoulder') || lowerName.contains('deltoid')) {
      return 'Shoulders';
    } else if (lowerName.contains('bicep') || lowerName.contains('curl')) {
      return 'Biceps';
    } else if (lowerName.contains('tricep') || lowerName.contains('extension')) {
      return 'Triceps';
    } else if (lowerName.contains('core') || lowerName.contains('ab') || lowerName.contains('plank')) {
      return 'Core';
    } else {
      return 'Other';
    }
  }
}

  