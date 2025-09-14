import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workoutpreview_model.dart';

class WorkoutPreviewService {
  static const String baseUrl = "https://api.cnergy.site/workout_preview.php";
  
  // Get current user ID from SharedPreferences
  static Future<int> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? userIdString = prefs.getString('user_id');
      if (userIdString != null && userIdString.isNotEmpty) {
        int userId = int.parse(userIdString);
        print('Retrieved user ID from SharedPreferences: $userId');
        return userId;
      }
      
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        print('Retrieved user ID (int) from SharedPreferences: $userIdInt');
        return userIdInt;
      }
      
      print('No user ID found in SharedPreferences - user may not be logged in');
      throw Exception('User not logged in - no user ID found');
      
    } catch (e) {
      print('Error getting user ID: $e');
      throw Exception('Failed to get user ID: $e');
    }
  }

  // Enhanced logExerciseSet with better error handling and validation
  static Future<bool> logExerciseSet(int memberWorkoutExerciseId, int setNumber, int reps, double weight) async {
    try {
      print('📝 Logging exercise set: memberWorkoutExerciseId=$memberWorkoutExerciseId, set=$setNumber, reps=$reps, weight=$weight');
      
      // Validate inputs
      if (memberWorkoutExerciseId <= 0) {
        print('❌ Invalid memberWorkoutExerciseId: $memberWorkoutExerciseId');
        return false;
      }
      
      if (setNumber <= 0) {
        print('❌ Invalid setNumber: $setNumber');
        return false;
      }
      
      if (reps <= 0) {
        print('❌ Invalid reps: $reps');
        return false;
      }
      
      int currentUserId = await getCurrentUserId();
      
      final requestData = {
        "action": "logExerciseSet",
        "user_id": currentUserId,
        "member_workout_exercise_id": memberWorkoutExerciseId,
        "set_number": setNumber,
        "reps": reps,
        "weight": weight,
      };
      
      print('📤 Log set request: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: json.encode(requestData),
      );
      
      print('📊 Log set response status: ${response.statusCode}');
      print('📋 Log set response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          
          if (responseData['success'] == true) {
            print('✅ Set logged successfully to database');
            return true;
          } else {
            print('❌ Server returned error: ${responseData['error'] ?? 'Unknown error'}');
            return false;
          }
        } catch (jsonError) {
          print('❌ Failed to parse JSON response: $jsonError');
          print('Raw response: ${response.body}');
          return false;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('💥 Error logging exercise set: $e');
      return false;
    }
  }

  // Rest of your existing methods remain the same...
  static Future<WorkoutPreviewModel> getWorkoutPreview(String routineId) async {
    try {
      print('🔍 Fetching workout preview for routine ID: $routineId');
      
      int currentUserId = await getCurrentUserId();
      
      final url = '$baseUrl?action=getWorkoutPreview&routine_id=$routineId&user_id=$currentUserId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return WorkoutPreviewModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch workout preview');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching workout preview: $e');
      throw Exception('Failed to load workout preview: $e');
    }
  }

  // Enhanced completeWorkoutSession with better error handling
  static Future<bool> completeWorkoutSession(String routineId, List<WorkoutExerciseModel> exercises, int duration) async {
    try {
      print('✅ Completing workout session for routine: $routineId');
      
      int currentUserId = await getCurrentUserId();
      
      // Calculate workout stats
      final totalVolume = exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
      final completedExercises = exercises.where((e) => e.isCompleted).length;
      final totalSets = exercises.fold(0, (sum, exercise) => sum + exercise.completedSets);
      
      final requestData = {
        "action": "completeWorkout",
        "routine_id": routineId,
        "user_id": currentUserId,
        "duration": duration,
        "total_volume": totalVolume,
        "completed_exercises": completedExercises,
        "total_exercises": exercises.length,
        "total_sets": totalSets,
        "exercises": exercises.map((exercise) => {
          "exercise_id": exercise.exerciseId,
          "member_workout_exercise_id": exercise.memberWorkoutExerciseId,
          "completed_sets": exercise.completedSets,
          "is_completed": exercise.isCompleted,
          "logged_sets": exercise.loggedSets.map((set) => set.toJson()).toList(),
        }).toList(),
      };
      
      print('📤 Complete workout request: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );
      
      print('📊 Complete workout response status: ${response.statusCode}');
      print('📋 Complete workout response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('💥 Error completing workout session: $e');
      return false;
    }
  }
}
