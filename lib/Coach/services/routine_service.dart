import 'dart:convert';
import 'package:http/http.dart' as http;

import 'coach_service.dart';

// Prefixed imports
import '../models/routine.models.dart' as routine_model;
import '../models/exercise_model.dart' as exercise_model;
import '../models/exercise_selection_model.dart' as selection_model;

class RoutineService {
  static const String baseUrl = 'http://localhost/cynergy/coach_routine.php';

  static int? _parseId(String? id, String fieldName) {
    if (id == null || id.isEmpty) {
      throw Exception('$fieldName is null or empty. Please provide a valid numeric ID.');
    }
    
    // Check if the ID is still a placeholder/variable name
    if (id.contains('_id') || id.contains('current_') || id.contains('user_') || 
        id == 'null' || id == 'undefined') {
      throw Exception('$fieldName appears to be a placeholder: "$id". Please provide actual numeric ID.');
    }
    
    final parsed = int.tryParse(id.trim());
    if (parsed == null) {
      throw Exception('Invalid $fieldName format: "$id". Expected numeric ID but got: ${id.runtimeType}');
    }
    
    if (parsed <= 0) {
      throw Exception('$fieldName must be a positive integer, got: $parsed');
    }
    
    return parsed;
  }

  static Future<List<Map<String, dynamic>>> getTargetMuscles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/target-muscles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load target muscles');
      }
    } catch (e) {
      throw Exception('Error fetching target muscles: $e');
    }
  }

  static Future<List<exercise_model.TargetMuscleModel>> fetchTargetMuscles() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/target-muscles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => exercise_model.TargetMuscleModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load target muscles');
      }
    } catch (e) {
      throw Exception('Error fetching target muscles: $e');
    }
  }

  static Future<List<exercise_model.ExerciseModel>> getExercisesByMuscleGroup(String muscleGroup) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises?muscle_group=$muscleGroup'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => exercise_model.ExerciseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load exercises');
      }
    } catch (e) {
      throw Exception('Error fetching exercises: $e');
    }
  }

  static Future<List<exercise_model.ExerciseModel>> searchExercises(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => exercise_model.ExerciseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search exercises');
      }
    } catch (e) {
      throw Exception('Error searching exercises: $e');
    }
  }

  static Future<bool> createRoutineForClient({
    required String routineName,
    required String clientId,
    required String coachId,
    required List<exercise_model.ExerciseModel> exercises,
    String? description,
    String? duration,
    String? goal,
    String? difficulty,
    String? color,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      // Debug logging
      print('DEBUG - createRoutineForClient called with:');
      print('  clientId: "$clientId"');
      print('  coachId: "$coachId"');
      
      // Validate input parameters using helper method
      final clientIdInt = _parseId(clientId, 'Client ID');
      
      int? coachIdInt;
      
      if (coachId.contains('current_') || coachId.contains('placeholder') || coachId == 'current_coach_id') {
        print('DEBUG - Detected placeholder coach ID, fetching from CoachService');
        final actualCoachId = await CoachService.getCoachId();
        if (actualCoachId == 0) {
          throw Exception('Unable to get current coach ID from session. Please ensure you are logged in as a coach.');
        }
        coachIdInt = actualCoachId;
        print('DEBUG - Retrieved actual coach ID: $coachIdInt');
      } else {
        coachIdInt = _parseId(coachId, 'Coach ID');
      }
      
      if (clientIdInt == null) {
        throw Exception('Client ID is required and must be a valid number');
      }
      
      if (coachIdInt == null) {
        throw Exception('Coach ID is required and must be a valid number');
      }

      // When coach creates routine for client, created_by should be coach's ID
      final routineData = {
        'user_id': clientIdInt,
        'created_by': coachIdInt, // Coach's ID as creator
        'workout_name': routineName,
        'goal': goal ?? 'General Fitness',
        'difficulty': difficulty ?? 'Beginner',
        'color': color ?? '4288073396',
        'tags': tags ?? [],
        'notes': notes ?? description ?? '',
        'duration': duration ?? '30',
        'exercises': exercises.map((exercise) => {
          'id': exercise.id,
          'name': exercise.name,
          'reps': 10,
          'sets': 3,
          'weight': 0.0,
        }).toList(),
      };

      print('DEBUG - Sending routine data: ${json.encode(routineData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/create-routine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );

      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to create routine: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('ERROR in createRoutineForClient: $e');
      throw Exception('Error creating routine: $e');
    }
  }

  static Future<Map<String, dynamic>> createRoutine({
    required String userId,
    required String workoutName,
    required String goal,
    required List<Map<String, dynamic>> exercises,
    String? difficulty,
    String? color,
    List<String>? tags,
    String? notes,
    String? duration,
  }) async {
    try {
      // Debug logging
      print('DEBUG - createRoutine called with userId: "$userId"');
      
      // Validate userId using helper method
      final userIdInt = _parseId(userId, 'User ID');
      
      if (userIdInt == null) {
        throw Exception('User ID is required and must be a valid number');
      }

      // When member creates routine for themselves, created_by should be NULL
      final routineData = {
        'user_id': userIdInt,
        'created_by': null, // NULL when member creates for themselves
        'workout_name': workoutName,
        'goal': goal,
        'difficulty': difficulty ?? 'Beginner',
        'color': color ?? '4288073396',
        'tags': tags ?? [],
        'notes': notes ?? '',
        'duration': duration ?? '30',
        'exercises': exercises,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/create-routine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(routineData),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to create routine: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error creating routine: $e');
    }
  }

  static Future<List<routine_model.RoutineModel>> getClientRoutines(String clientId) async {
    try {
      // Validate clientId using helper method
      final clientIdInt = _parseId(clientId, 'Client ID');
      
      if (clientIdInt == null) {
        throw Exception('Client ID is required and must be a valid number');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/routines?client_id=$clientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => routine_model.RoutineModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load client routines');
      }
    } catch (e) {
      throw Exception('Error fetching client routines: $e');
    }
  }

  static Future<List<routine_model.RoutineModel>> getCoachRoutines(String coachId) async {
    try {
      int? coachIdInt;
      
      if (coachId.contains('current_') || coachId.contains('placeholder') || coachId == 'current_coach_id') {
        final actualCoachId = await CoachService.getCoachId();
        if (actualCoachId == 0) {
          throw Exception('Unable to get current coach ID from session');
        }
        coachIdInt = actualCoachId;
      } else {
        coachIdInt = _parseId(coachId, 'Coach ID');
      }
      
      if (coachIdInt == null) {
        throw Exception('Coach ID is required and must be a valid number');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/routines?coach_id=$coachIdInt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => routine_model.RoutineModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load coach routines');
      }
    } catch (e) {
      throw Exception('Error fetching coach routines: $e');
    }
  }

  static Future<bool> updateRoutine(String routineId, Map<String, dynamic> updates) async {
    try {
      // Validate routineId using helper method
      final routineIdInt = _parseId(routineId, 'Routine ID');
      
      if (routineIdInt == null) {
        throw Exception('Routine ID is required and must be a valid number');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/routines/$routineId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update routine');
      }
    } catch (e) {
      throw Exception('Error updating routine: $e');
    }
  }

  static Future<bool> deleteRoutine(String routineId) async {
    try {
      // Validate routineId using helper method
      final routineIdInt = _parseId(routineId, 'Routine ID');
      
      if (routineIdInt == null) {
        throw Exception('Routine ID is required and must be a valid number');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/routines/$routineId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete routine');
      }
    } catch (e) {
      throw Exception('Error deleting routine: $e');
    }
  }

  static Future<bool> assignRoutineToClient(String routineId, String clientId) async {
    try {
      // Validate parameters using helper method
      final routineIdInt = _parseId(routineId, 'Routine ID');
      final clientIdInt = _parseId(clientId, 'Client ID');
      
      if (routineIdInt == null) {
        throw Exception('Routine ID is required and must be a valid number');
      }
      
      if (clientIdInt == null) {
        throw Exception('Client ID is required and must be a valid number');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/routines/$routineId/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'client_id': clientIdInt}), // Send as integer
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to assign routine');
      }
    } catch (e) {
      throw Exception('Error assigning routine: $e');
    }
  }

  static Future<List<exercise_model.ExerciseModel>> fetchExercisesByMuscle(int muscleGroupId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercises?muscle_group_id=$muscleGroupId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => exercise_model.ExerciseModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load exercises for muscle group');
      }
    } catch (e) {
      throw Exception('Error fetching exercises by muscle: $e');
    }
  }

  static bool validateRoutineData({
    required String clientUserId,
    required String goal,
    required String workoutName,
    required List<Map<String, dynamic>> exercises,
  }) {
    if (clientUserId.isEmpty || goal.isEmpty || workoutName.isEmpty) {
      return false;
    }
    
    if (exercises.isEmpty) {
      return false;
    }
    
    // Check for placeholder values
    if (clientUserId.contains('placeholder') || 
        clientUserId.contains('current_') ||
        clientUserId == 'current_user_id') {
      return false;
    }
    
    return true;
  }
}
