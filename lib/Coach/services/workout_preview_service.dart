import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/routine.models.dart';
import '../models/workout_session_model.dart';
import '../models/exercise_model.dart';
import 'coach_service.dart';

class WorkoutPreviewService {
  static const String baseUrl = 'https://api.cnergy.site';

  // Get workout preview for a routine
  static Future<WorkoutPreview?> getWorkoutPreview(int routineId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workout_preview.php?action=get_preview&routine_id=$routineId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return WorkoutPreview.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching workout preview: $e');
      return null;
    }
  }

  // Get member's workout sessions
  static Future<List<WorkoutSessionModel>> getMemberWorkoutSessions(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workout_preview.php?action=get_member_sessions&member_id=$memberId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => WorkoutSessionModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching member workout sessions: $e');
      return [];
    }
  }

  // Get workout session details
  static Future<WorkoutSessionModel?> getWorkoutSessionDetails(int sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/workout_preview.php?action=get_session_details&session_id=$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return WorkoutSessionModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching workout session details: $e');
      return null;
    }
  }

  // Start workout session for member
  static Future<bool> startWorkoutSession(int memberId, int routineId) async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return false;

      final sessionData = {
        'member_id': memberId,
        'routine_id': routineId,
        'started_by_coach': coachId,
        'start_time': DateTime.now().toIso8601String(),
        'status': 'in_progress',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/workout_preview.php?action=start_session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error starting workout session: $e');
      return false;
    }
  }

  // Complete workout session
  static Future<bool> completeWorkoutSession(int sessionId, Map<String, dynamic> sessionData) async {
    try {
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) return false;

      sessionData['completed_by_coach'] = coachId;
      sessionData['end_time'] = DateTime.now().toIso8601String();
      sessionData['status'] = 'completed';

      final response = await http.put(
        Uri.parse('$baseUrl/workout_preview.php?action=complete_session&session_id=$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sessionData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error completing workout session: $e');
      return false;
    }
  }
}

class WorkoutPreview {
  final int routineId;
  final String routineName;
  final List<ExerciseModel> exercises;
  final String estimatedDuration;
  final String difficulty;
  final String description;

  WorkoutPreview({
    required this.routineId,
    required this.routineName,
    required this.exercises,
    required this.estimatedDuration,
    required this.difficulty,
    required this.description,
  });

  factory WorkoutPreview.fromJson(Map<String, dynamic> json) {
    return WorkoutPreview(
      routineId: json['routine_id'] ?? 0,
      routineName: json['routine_name'] ?? '',
      exercises: (json['exercises'] as List?)
          ?.map((e) => ExerciseModel.fromJson(e))
          .toList() ?? [],
      estimatedDuration: json['estimated_duration'] ?? '',
      difficulty: json['difficulty'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
