import 'dart:convert';
import 'package:http/http.dart' as http;

import 'coach_service.dart';

// Prefixed imports
import '../models/routine.models.dart' as routine_model;
import '../models/exercise_model.dart' as exercise_model;
import '../models/exercise_selection_model.dart' as selection_model;

class RoutineService {
  static const String baseUrl = 'https://api.cnergy.site/coach_routine.php';

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

  static Future<List<Map<String, dynamic>>> getMuscleGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetchMuscles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> muscleGroups = data['data'];
          return muscleGroups.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to load muscle groups');
        }
      } else {
        throw Exception('Failed to load muscle groups');
      }
    } catch (e) {
      throw Exception('Error fetching muscle groups: $e');
    }
  }

  static Future<List<exercise_model.TargetMuscleModel>> fetchMuscleGroups() async {
    try {
      print('🌐 Fetching muscle groups from: $baseUrl?action=fetchMuscles');
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetchMuscles'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> muscleGroups = data['data'];
          print('✅ Successfully parsed ${muscleGroups.length} muscle groups');
          return muscleGroups.map((json) => exercise_model.TargetMuscleModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load muscle groups');
        }
      } else {
        throw Exception('Failed to load muscle groups - HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching muscle groups: $e');
      throw Exception('Error fetching muscle groups: $e');
    }
  }

  static Future<List<exercise_model.ExerciseModel>> getExercisesByMuscleGroup(int muscleGroupId) async {
    try {
      print('🌐 Fetching exercises for muscle group ID: $muscleGroupId');
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetchExercises&muscle_group_id=$muscleGroupId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> exercises = data['data'];
          print('✅ Successfully parsed ${exercises.length} exercises');
          return exercises.map((json) => exercise_model.ExerciseModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load exercises');
        }
      } else {
        throw Exception('Failed to load exercises - HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching exercises: $e');
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
    List<String>? scheduledDays,
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
        'scheduled_days': scheduledDays ?? ['Monday'],
        'exercises': exercises.map((exercise) => {
          'id': exercise.id,
          'name': exercise.name,
          'reps': 10,
          'sets': 3,
          'weight': 0.0,
        }).toList(),
      };

      print('DEBUG - Sending routine data: ${json.encode(routineData)}');

      // Add action to the request body
      final requestData = {
        'action': 'createRoutine',
        ...routineData,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
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
        Uri.parse('$baseUrl?action=getClientRoutines&client_id=$clientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> routines = data['data'];
          return routines.map((json) => routine_model.RoutineModel.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load client routines');
        }
      } else {
        throw Exception('Failed to load client routines - HTTP ${response.statusCode}');
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

      final requestData = {
        'action': 'updateRoutine',
        'routineId': routineIdInt,
        'updates': updates,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
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

      final requestData = {
        'action': 'deleteRoutine',
        'routineId': routineIdInt,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
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


  // ============================================
  // COACH TEMPLATE FUNCTIONS
  // ============================================
  
  static Future<bool> createCoachTemplate({
    required String templateName,
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
      print('DEBUG - createCoachTemplate called with:');
      print('  coachId: "$coachId"');
      print('  templateName: "$templateName"');
      
      // Validate input parameters using helper method
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
      
      if (coachIdInt == null) {
        throw Exception('Coach ID is required and must be a valid number');
      }

      // Create template data
      final templateData = {
        'created_by': coachIdInt,
        'template_name': templateName,
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

      print('DEBUG - Sending template data: ${json.encode(templateData)}');

      // Add action to the request body
      final requestData = {
        'action': 'createTemplate',
        ...templateData,
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('DEBUG - Response status: ${response.statusCode}');
      print('DEBUG - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Failed to create template: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('ERROR in createCoachTemplate: $e');
      throw Exception('Error creating template: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCoachTemplates(String coachId) async {
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
        Uri.parse('$baseUrl?action=getTemplates&coach_id=$coachIdInt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> templates = data['data'];
          return templates.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Failed to load templates');
        }
      } else {
        throw Exception('Failed to load templates - HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching templates: $e');
    }
  }

  static Future<Map<String, dynamic>> getTemplateDetails(String templateId) async {
    try {
      final templateIdInt = _parseId(templateId, 'Template ID');
      if (templateIdInt == null) {
        throw Exception('Template ID is required and must be a valid number');
      }

      final response = await http.get(
        Uri.parse('$baseUrl?action=getTemplateDetails&template_id=$templateIdInt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception(data['message'] ?? 'Failed to load template details');
        }
      } else {
        throw Exception('Failed to load template details - HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching template details: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getCoachClients(String coachId) async {
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
        Uri.parse('$baseUrl?action=getCoachClients&coach_id=$coachIdInt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching coach clients: $e');
      return [];
    }
  }

  static Future<bool> assignTemplateToClient({
    required String templateId,
    required String clientId,
    required String coachId,
    String? customGoal,
    String? customDifficulty,
    int? customDuration,
    String? customNotes,
    List<Map<String, dynamic>>? exerciseModifications,
  }) async {
    try {
      // Validate parameters using helper method
      final templateIdInt = _parseId(templateId, 'Template ID');
      final clientIdInt = _parseId(clientId, 'Client ID');
      
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
      
      if (templateIdInt == null) {
        throw Exception('Template ID is required and must be a valid number');
      }
      
      if (clientIdInt == null) {
        throw Exception('Client ID is required and must be a valid number');
      }
      
      if (coachIdInt == null) {
        throw Exception('Coach ID is required and must be a valid number');
      }

      final requestData = {
        'action': 'assignTemplate',
        'template_id': templateIdInt,
        'client_id': clientIdInt,
        'coach_id': coachIdInt,
        'custom_goal': customGoal,
        'custom_difficulty': customDifficulty,
        'custom_duration': customDuration,
        'custom_notes': customNotes,
        'exercise_modifications': exerciseModifications ?? [],
      };

      print('DEBUG - Sending assignment request: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('DEBUG - Assignment response status: ${response.statusCode}');
      print('DEBUG - Assignment response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('DEBUG - Parsed response data: $data');
        return data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        print('DEBUG - Error response: $errorData');
        throw Exception('Failed to assign template: ${errorData['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Error assigning template: $e');
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
