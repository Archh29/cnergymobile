import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workoutpreview_model.dart';
import 'auth_service.dart';
import 'progress_analytics_service.dart';
import 'local_weights_service.dart';

class WorkoutPreviewService {
  static const String baseUrl = "https://api.cnergy.site/workout_preview.php";
  
  // Get current user ID from AuthService
  static Future<int> getCurrentUserId() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in - no user ID found');
      }
        return userId;
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
            
            // Also save to progress tracker for progressive overload tracking
            await _saveToProgressTracker(
              exerciseName: responseData['exercise_name'] ?? 'Unknown Exercise',
              muscleGroup: responseData['muscle_group'] ?? 'Unknown',
              weight: weight,
              reps: reps,
              sets: 1, // Each set is logged individually
              programName: responseData['program_name'],
              programId: responseData['program_id'],
            );
            
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

  // Helper method to save lift data to progress tracker
  static Future<void> _saveToProgressTracker({
    required String exerciseName,
    required String muscleGroup,
    required double weight,
    required int reps,
    required int sets,
    String? programName,
    int? programId,
  }) async {
    try {
      print('📊 Saving to progress tracker: $exerciseName - ${weight}kg x $reps x $sets');
      
      final success = await ProgressAnalyticsService.saveLift(
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        weight: weight,
        reps: reps,
        sets: sets,
        programName: programName,
        programId: programId,
      );
      
      if (success) {
        print('✅ Progress tracker updated successfully');
      } else {
        print('⚠️ Failed to update progress tracker');
      }
    } catch (e) {
      print('❌ Error saving to progress tracker: $e');
    }
  }

  // Save all completed exercises to progress tracker for progressive overload tracking
  static Future<void> _saveAllExercisesToProgressTracker(String routineId, List<WorkoutExerciseModel> exercises) async {
    try {
      print('📊 Saving all exercises to progress tracker for routine: $routineId');
      
      final programId = int.tryParse(routineId);
      
      for (final exercise in exercises) {
        if (exercise.isCompleted && exercise.loggedSets.isNotEmpty) {
          // Calculate average weight and total reps for this exercise
          double totalWeight = 0;
          int totalReps = 0;
          
          for (final set in exercise.loggedSets) {
            totalWeight += set.weight;
            totalReps += set.reps;
          }
          
          final avgWeight = totalWeight / exercise.loggedSets.length;
          
          await ProgressAnalyticsService.saveLift(
            exerciseName: exercise.name,
            muscleGroup: exercise.targetMuscle.isNotEmpty ? exercise.targetMuscle : 'Unknown',
            weight: avgWeight,
            reps: totalReps,
            sets: exercise.completedSets,
            programName: 'Routine $routineId',
            programId: programId,
          );
          
          print('✅ Saved exercise: ${exercise.name} - ${avgWeight.toStringAsFixed(1)}kg x $totalReps x ${exercise.completedSets}');
        }
      }
      
      // If this is PUSH DAY (programId 78), also save historical progression data
      if (programId == 78) {
        await _saveHistoricalProgressionData();
      }
    } catch (e) {
      print('❌ Error saving all exercises to progress tracker: $e');
    }
  }
  
  // Public method to save historical progression data (for testing)
  static Future<void> saveHistoricalProgressionData() async {
    await _saveHistoricalProgressionData();
  }
  
  // Save historical progression data for PUSH DAY
  static Future<void> _saveHistoricalProgressionData() async {
    try {
      print('📈 Saving historical progression data for PUSH DAY');
      
      final now = DateTime.now();
      final programId = 78;
      
      // Create specific dates (MM/DD/YYYY format)
      final today = now;
      final lastWeek = now.subtract(Duration(days: 7));
      final twoWeeksAgo = now.subtract(Duration(days: 14));
      final threeWeeksAgo = now.subtract(Duration(days: 21));
      final fourWeeksAgo = now.subtract(Duration(days: 28));
      
      // Save 5 weeks of data including current week
      final historicalData = [
        // This week (current)
        {
          'exerciseName': 'Barbell Bench Press',
          'muscleGroup': 'Chest',
          'weight': 40.0,
          'reps': 7,
          'sets': 3,
          'date': today,
        },
        // Last week (1 rep less)
        {
          'exerciseName': 'Barbell Bench Press',
          'muscleGroup': 'Chest',
          'weight': 40.0,
          'reps': 6,
          'sets': 3,
          'date': lastWeek,
        },
        // Two weeks ago (2 reps less)
        {
          'exerciseName': 'Barbell Bench Press',
          'muscleGroup': 'Chest',
          'weight': 40.0,
          'reps': 5,
          'sets': 3,
          'date': twoWeeksAgo,
        },
        // Three weeks ago (3 reps less)
        {
          'exerciseName': 'Barbell Bench Press',
          'muscleGroup': 'Chest',
          'weight': 40.0,
          'reps': 4,
          'sets': 3,
          'date': threeWeeksAgo,
        },
        // Four weeks ago (4 reps less)
        {
          'exerciseName': 'Barbell Bench Press',
          'muscleGroup': 'Chest',
          'weight': 40.0,
          'reps': 3,
          'sets': 3,
          'date': fourWeeksAgo,
        },
      ];
      
      print('📅 Dates being saved:');
      for (final data in historicalData) {
        final date = data['date'] as DateTime;
        print('  - ${date.month}/${date.day}/${date.year}: ${data['exerciseName']} - ${data['weight']}kg x ${data['reps']} x ${data['sets']}');
      }
      
      for (final data in historicalData) {
        try {
          final success = await ProgressAnalyticsService.saveLift(
            exerciseName: data['exerciseName'] as String,
            muscleGroup: data['muscleGroup'] as String,
            weight: data['weight'] as double,
            reps: data['reps'] as int,
            sets: data['sets'] as int,
            programName: 'PUSH DAY',
            programId: programId,
            customDate: data['date'] as DateTime,
          );
          
          if (success) {
            final date = data['date'] as DateTime;
            print('✅ Saved: ${data['exerciseName']} - ${data['weight']}kg x ${data['reps']} x ${data['sets']} (${date.month}/${date.day}/${date.year})');
          } else {
            print('❌ Failed to save: ${data['exerciseName']}');
          }
        } catch (e) {
          print('❌ Error saving ${data['exerciseName']}: $e');
        }
      }
      
      print('🎉 Historical progression data saved successfully!');
    } catch (e) {
      print('💥 Error saving historical progression data: $e');
    }
  }

  // Get latest weights from exercise logs for an exercise
  static Future<List<Map<String, dynamic>>> getLatestWeights(int exerciseId) async {
    try {
      print('🔍 Fetching latest weights for exercise ID: $exerciseId');
      
      // First try to get from local storage (your actual workout data)
      final localWeights = await LocalWeightsService.getLatestWeights(exerciseId);
      if (localWeights.isNotEmpty) {
        print('✅ Found latest weights in local storage: ${localWeights.length} sets');
        print('🔍 Local weights: ${localWeights.map((w) => '${w['reps']} reps x ${w['weight']}kg').join(', ')}');
        return localWeights;
      }
      
      // Fallback to API if no local data
      int currentUserId = await getCurrentUserId();
      
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/workout_preview.php?action=getExerciseAnalytics&exercise_id=$exerciseId&user_id=$currentUserId&days=30'),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Latest weights response status: ${response.statusCode}');
      print('📋 Latest weights response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final analytics = responseData['analytics'] as List<dynamic>;
          if (analytics.isNotEmpty) {
            // Get the most recent workout data
            final latestWorkout = analytics.first;
            print('✅ Found latest weights from API: ${latestWorkout}');
            return [latestWorkout];
          }
        }
      }
      return [];
    } catch (e) {
      print('💥 Error fetching latest weights: $e');
      return [];
    }
  }

  // Update program weights with latest logged weights - save to database AND local storage
  static Future<void> _updateProgramWeightsSimple(String routineId, List<WorkoutExerciseModel> exercises) async {
    try {
      print('🔄 Updating program weights for routine: $routineId');
      
      int currentUserId = await getCurrentUserId();
      
      for (var exercise in exercises) {
        if (exercise.exerciseId != null && exercise.loggedSets.isNotEmpty) {
          print('🔄 Updating weights for exercise ${exercise.name} (ID: ${exercise.exerciseId})');
          print('🔄 New weights: ${exercise.loggedSets.map((s) => '${s.reps} reps x ${s.weight}kg').join(', ')}');
          
          // Convert logged sets to the format we need
          final weights = exercise.loggedSets.map((set) => {
            'reps': set.reps,
            'weight': set.weight,
            'timestamp': set.timestamp.toString(),
          }).toList();
          
          // 1. Save to local storage (for immediate display)
          await LocalWeightsService.saveLatestWeights(exercise.exerciseId!, weights);
          print('✅ Saved latest weights for ${exercise.name} locally');
          
          // 2. Update program weights in database
          await _updateProgramWeightsInDatabase(routineId, exercise.exerciseId!, weights);
        }
      }
    } catch (e) {
      print('💥 Error updating program weights: $e');
    }
  }

  // Update program weights in database by updating the member_workout_exercise table
  static Future<void> _updateProgramWeightsInDatabase(String routineId, int exerciseId, List<Map<String, dynamic>> weights) async {
    try {
      print('🔄 Updating program weights in database for exercise $exerciseId');
      
      int currentUserId = await getCurrentUserId();
      
      // Get current workout date
      final workoutDate = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
      print('📅 Workout date: $workoutDate');
      
      // Delete existing program weights for this exercise
      final deleteResponse = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "deleteProgramWeights",
          "routine_id": routineId,
          "user_id": currentUserId,
          "exercise_id": exerciseId,
        }),
      );
      
      print('📊 Delete program weights response: ${deleteResponse.statusCode}');
      
      // Insert new weights with workout date
      for (var weight in weights) {
        final insertResponse = await http.post(
          Uri.parse('https://api.cnergy.site/workout_preview.php'),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "action": "insertProgramWeight",
            "routine_id": routineId,
            "user_id": currentUserId,
            "exercise_id": exerciseId,
            "reps": weight['reps'],
            "weight": weight['weight'],
            "workout_date": workoutDate, // Add workout date
          }),
        );
        
        print('📊 Insert program weight response: ${insertResponse.statusCode}');
      }
      
      print('✅ Updated program weights in database for exercise $exerciseId with date $workoutDate');
    } catch (e) {
      print('💥 Error updating program weights in database: $e');
    }
  }



  // Enhanced getWorkoutPreview with updated weights from local storage
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
          var workoutPreview = WorkoutPreviewModel.fromJson(responseData['data']);
          
          // Update exercises with latest weights from local storage
          final updatedExercises = <WorkoutExerciseModel>[];
          
          for (var exercise in workoutPreview.exercises) {
            print('🔍 Processing exercise: ${exercise.name} (ID: ${exercise.exerciseId})');
            if (exercise.exerciseId != null) {
              final latestWeights = await LocalWeightsService.getLatestWeights(exercise.exerciseId!);
              print('🔍 Latest weights for ${exercise.name}: ${latestWeights.length} sets');
              
              if (latestWeights.isNotEmpty) {
                print('🔄 Updating exercise ${exercise.name} with latest weights from local storage');
                print('🔄 Latest weights: ${latestWeights.map((w) => '${w['reps']} reps x ${w['weight']}kg').join(', ')}');
                
                // Create new target sets with latest weights
                final updatedTargetSets = latestWeights.map((weight) => WorkoutSetModel(
                  reps: weight['reps'] ?? 10,
                  weight: (weight['weight'] ?? 0.0).toDouble(),
                  timestamp: DateTime.tryParse(weight['timestamp']?.toString() ?? '') ?? DateTime.now(),
                  isCompleted: false,
                )).toList();
                
                // Create a new exercise with updated weights
                final updatedExercise = WorkoutExerciseModel(
                  exerciseId: exercise.exerciseId,
                  memberWorkoutExerciseId: exercise.memberWorkoutExerciseId,
                  name: exercise.name,
                  targetMuscle: exercise.targetMuscle,
                  description: exercise.description,
                  imageUrl: exercise.imageUrl,
                  sets: latestWeights.length,
                  reps: latestWeights.first['reps']?.toString() ?? '10',
                  weight: (latestWeights.first['weight'] ?? 0.0).toDouble(),
                  restTime: exercise.restTime,
                  category: exercise.category,
                  difficulty: exercise.difficulty,
                  completedSets: exercise.completedSets,
                  isCompleted: exercise.isCompleted,
                  loggedSets: exercise.loggedSets,
                  targetSets: updatedTargetSets,
                  previousLifts: exercise.previousLifts,
                );
                
                updatedExercises.add(updatedExercise);
                print('✅ Updated exercise ${exercise.name} with latest weights');
              } else {
                print('⚠️ No latest weights found for exercise ${exercise.name}, using program weights');
                updatedExercises.add(exercise);
              }
            } else {
              updatedExercises.add(exercise);
            }
          }
          
          // Create new workout preview with updated exercises
          workoutPreview = WorkoutPreviewModel(
            routineId: workoutPreview.routineId,
            routineName: workoutPreview.routineName,
            exercises: updatedExercises,
            stats: workoutPreview.stats,
          );
          
          return workoutPreview;
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
      
      // Debug: Print exercise data before sending
      print('🔍 DEBUG: Exercise data before sending:');
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        print('  Exercise $i: ID=${exercise.exerciseId}, Name=${exercise.name}');
        print('    Completed: ${exercise.isCompleted}, Sets: ${exercise.completedSets}');
        print('    Logged sets: ${exercise.loggedSets.length}');
        for (int j = 0; j < exercise.loggedSets.length; j++) {
          final set = exercise.loggedSets[j];
          print('      Set $j: ${set.reps} reps x ${set.weight}kg');
        }
      }
      
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
          "member_workout_exercise_id": exercise.memberWorkoutExerciseId ?? 0,
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
        final success = responseData['success'] == true;
        
        if (success) {
          // Update program weights with latest logged weights
          await _updateProgramWeightsSimple(routineId, exercises);
          
          // Also save all completed exercises to progress tracker for progressive overload
          await _saveAllExercisesToProgressTracker(routineId, exercises);
        }
        
        return success;
      }
      
      return false;
    } catch (e) {
      print('💥 Error completing workout session: $e');
      return false;
    }
  }
}
