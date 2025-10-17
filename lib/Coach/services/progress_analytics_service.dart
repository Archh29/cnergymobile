import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/progress_tracker_model.dart';
import 'auth_service.dart';

class ProgressAnalyticsService {
  static const String baseUrl = 'https://api.cnergy.site';
  static const String progressEndpoint = '$baseUrl/progress_tracker.php';

  // Save a lift to the database
  static Future<bool> saveLift({
    required String exerciseName,
    required String muscleGroup,
    required double weight,
    required int reps,
    required int sets,
    String? notes,
    String? programName,
    int? programId,
    DateTime? customDate,
  }) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final liftData = ProgressTrackerModel(
        id: 0, // Will be assigned by database
        userId: userId,
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        weight: weight,
        reps: reps,
        sets: sets,
        date: customDate ?? DateTime.now(),
        notes: notes,
        programName: programName,
        programId: programId,
      );

      final response = await http.post(
        Uri.parse(progressEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'save_lift',
          'data': liftData.toJson(),
        }),
      );

      print('Save lift response status: ${response.statusCode}');
      print('Save lift response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error saving lift: $e');
      return false;
    }
  }

  // Get all lifts for a specific exercise
  static Future<List<ProgressTrackerModel>> getExerciseLifts(String exerciseName) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_exercise_lifts&exercise_name=${Uri.encodeComponent(exerciseName)}&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching exercise lifts: $e');
      return [];
    }
  }

  // Get all progress data grouped by exercise
  static Future<Map<String, List<ProgressTrackerModel>>> getAllProgress() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return {};

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_all_progress&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final lifts = data.map((json) => ProgressTrackerModel.fromJson(json)).toList();
          
          // Group by exercise name
          Map<String, List<ProgressTrackerModel>> grouped = {};
          for (final lift in lifts) {
            if (!grouped.containsKey(lift.exerciseName)) {
              grouped[lift.exerciseName] = [];
            }
            grouped[lift.exerciseName]!.add(lift);
          }
          
          // Sort each exercise's lifts by date
          for (final key in grouped.keys) {
            grouped[key]!.sort((a, b) => a.date.compareTo(b.date));
          }
          
          return grouped;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching all progress: $e');
      return {};
    }
  }

  // Get muscle group analytics
  static Future<Map<String, ProgressAnalytics>> getMuscleGroupAnalytics() async {
    try {
      final allProgress = await getAllProgress();
      Map<String, ProgressAnalytics> analytics = {};
      
      for (final exerciseName in allProgress.keys) {
        final exerciseData = allProgress[exerciseName]!;
        if (exerciseData.isNotEmpty) {
          final analyticsData = calculateAnalytics(
            exerciseName: exerciseName,
            muscleGroup: exerciseData.first.muscleGroup,
            data: exerciseData,
            programName: exerciseData.first.programName ?? 'Unknown',
          );
          analytics[exerciseName] = analyticsData;
        }
      }
      
      return analytics;
    } catch (e) {
      print('Error calculating muscle group analytics: $e');
      return {};
    }
  }

  // Get recent lifts
  static Future<List<ProgressTrackerModel>> getRecentLifts({int limit = 10}) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_recent_lifts&user_id=$userId&limit=$limit'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching recent lifts: $e');
      return [];
    }
  }

  // Get progress by program
  static Future<List<ProgressTrackerModel>> getProgressByProgram(int programId) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_progress_by_program&program_id=$programId&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching progress by program: $e');
      return [];
    }
  }

  // Get exercise progress
  static Future<List<ProgressTrackerModel>> getExerciseProgress({
    required String exerciseName,
    int limit = 10,
  }) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return [];

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_exercise_progress&exercise_name=${Uri.encodeComponent(exerciseName)}&user_id=$userId&limit=$limit'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching exercise progress: $e');
      return [];
    }
  }

  // Calculate analytics for a specific exercise
  static ProgressAnalytics calculateAnalytics({
    required String exerciseName,
    required String muscleGroup,
    required List<ProgressTrackerModel> data,
    required String programName,
  }) {
    if (data.isEmpty) {
      return ProgressAnalytics(
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        data: data,
        totalWorkouts: 0,
        hasProgression: false,
        progressionStreak: 0,
        programName: programName,
      );
    }

    // Sort by date
    final sortedData = List<ProgressTrackerModel>.from(data);
    sortedData.sort((a, b) => a.date.compareTo(b.date));

    // Calculate best weight
    final bestWeight = sortedData.map((e) => e.weight).reduce((a, b) => a > b ? a : b);

    // Calculate total volume
    final totalVolume = sortedData.fold(0.0, (sum, lift) => sum + lift.calculatedVolume);

    // Calculate progression streak
    int progressionStreak = 0;
    bool hasProgression = false;

    if (sortedData.length > 1) {
      for (int i = sortedData.length - 1; i > 0; i--) {
        final current = sortedData[i];
        final previous = sortedData[i - 1];
        
        if (current.weight > previous.weight || 
            (current.weight == previous.weight && current.reps > previous.reps)) {
          progressionStreak++;
          hasProgression = true;
        } else {
          break;
        }
      }
    }

    return ProgressAnalytics(
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      data: sortedData,
      bestWeight: bestWeight,
      totalVolume: totalVolume,
      totalWorkouts: sortedData.length,
      hasProgression: hasProgression,
      progressionStreak: progressionStreak,
      programName: programName,
    );
  }
}
