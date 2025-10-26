import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.models.dart';
import 'coach_service.dart';
import 'auth_service.dart';

class RoutineServices {
  static const String baseUrl = 'https://api.cnergy.site';

  // Get all routines for a coach
  static Future<List<RoutineModel>> getCoachRoutines() async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/coach_routine.php?action=get_coach_routines&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching coach routines: $e');
      return [];
    }
  }

  // Get member routines assigned by coach
  static Future<List<RoutineModel>> getMemberRoutines(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coach_routine.php?action=get_member_routines&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member routines: $e');
      return [];
    }
  }

  // Create routine for member
  static Future<bool> createRoutineForMember(RoutineModel routine, int memberId) async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return false;

      final routineData = routine.toJson();
      routineData['member_id'] = memberId;
      routineData['created_by_coach'] = coachId;

      final response = await http.post(
        Uri.parse('$baseUrl/coach_routine.php?action=create_routine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error creating routine for member: $e');
      return false;
    }
  }

  // Update routine
  static Future<bool> updateRoutine(int routineId, Map<String, dynamic> updates) async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return false;

      updates['updated_by_coach'] = coachId;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await http.put(
        Uri.parse('$baseUrl/coach_routine.php?action=update_routine&routine_id=$routineId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating routine: $e');
      return false;
    }
  }

  // Delete routine
  static Future<bool> deleteRoutine(int routineId) async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/coach_routine.php?action=delete_routine&routine_id=$routineId&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error deleting routine: $e');
      return false;
    }
  }

  // Get workout history
  static Future<List<WorkoutSession>> getWorkoutHistory() async {
    try {
      int? currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];
      
      final prefs = await SharedPreferences.getInstance();
      
      String userKey = 'workout_sessions_$currentUserId';
      List<String> sessions = prefs.getStringList(userKey) ?? [];
      
      return sessions.map((sessionStr) {
        final sessionData = json.decode(sessionStr);
        return WorkoutSession.fromJson(sessionData);
      }).toList();
    } catch (e) {
      print('Error loading workout history: $e');
      return [];
    }
  }

  // Calculate routine statistics
  static Map<String, dynamic> calculateRoutineStats(List<WorkoutSession> sessions, String routineName) {
    final routineSessions = sessions.where((s) => s.routineName == routineName).toList();
    
    if (routineSessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageDuration': 0,
        'totalVolume': 0.0,
        'averageRating': 0.0,
        'lastPerformed': 'Never',
      };
    }

    final totalDuration = routineSessions.fold<int>(0, (sum, s) => sum + s.duration);
    final totalVolume = routineSessions.fold<double>(0, (sum, s) => sum + s.totalVolume);
    final totalRating = routineSessions.fold<int>(0, (sum, s) => sum + s.rating);

    return {
      'totalSessions': routineSessions.length,
      'averageDuration': (totalDuration / routineSessions.length).round(),
      'totalVolume': totalVolume,
      'averageRating': totalRating / routineSessions.length,
      'lastPerformed': formatDate(routineSessions.first.date),
    };
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

