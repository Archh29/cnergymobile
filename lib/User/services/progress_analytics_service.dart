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
      final userId = AuthService.getCurrentUserId();
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

      // Save lift response (${response.statusCode})
      // Save lift response received

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
  static Future<List<ProgressTrackerModel>> getExerciseProgress({
    required String exerciseName,
    String? muscleGroup,
    int? limit,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final url = '$progressEndpoint?action=get_exercise_progress&user_id=$userId&exercise_name=${Uri.encodeComponent(exerciseName)}${muscleGroup != null ? '&muscle_group=${Uri.encodeComponent(muscleGroup)}' : ''}${limit != null ? '&limit=$limit' : ''}';
      // API URL: $url
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

       // Exercise progress response (${response.statusCode})
      // Exercise progress response received

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> lifts = data['data'] ?? [];
          print('✅ Successfully parsed ${lifts.length} records from API');
          return lifts.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        } else {
          print('❌ API returned success=false: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ API returned status code: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ Error getting exercise progress: $e');
      print('❌ Error type: ${e.runtimeType}');
      return [];
    }
  }

  // Get all lifts grouped by exercise
  static Future<Map<String, List<ProgressTrackerModel>>> getAllProgress() async {
    try {
      final userId = AuthService.getCurrentUserId();
      // Get all progress for user: $userId
      if (userId == null) {
        print('⚠️ No user ID from AuthService, using fallback ID 13');
        // Fallback to user ID 13 for testing
        final fallbackUserId = 13;
        final url = '$progressEndpoint?action=get_all_progress&user_id=$fallbackUserId';
        // Fallback API URL
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        // Response received (${response.statusCode})

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            final Map<String, dynamic> progressData = data['data'] ?? {};
            final Map<String, List<ProgressTrackerModel>> result = {};
            
            progressData.forEach((exerciseName, liftsData) {
              if (liftsData is List) {
                result[exerciseName] = liftsData
                    .map((json) => ProgressTrackerModel.fromJson(json))
                    .toList();
              }
            });
            
            return result;
          }
        }
        return {};
      }

      final url = '$progressEndpoint?action=get_all_progress&user_id=$userId';
      // API URL: $url
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Response received (${response.statusCode})

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> progressData = data['data'] ?? {};
          final Map<String, List<ProgressTrackerModel>> result = {};
          
          progressData.forEach((exerciseName, liftsData) {
            if (liftsData is List) {
              result[exerciseName] = liftsData
                  .map((json) => ProgressTrackerModel.fromJson(json))
                  .toList();
            }
          });
          
          return result;
        }
      }
      return {};
    } catch (e) {
      print('Error getting all progress: $e');
      return {};
    }
  }

  // Calculate analytics for a specific exercise
  static ProgressAnalytics calculateAnalytics({
    required String exerciseName,
    required String muscleGroup,
    required List<ProgressTrackerModel> data,
    String? programName,
  }) {
    if (data.isEmpty) {
      return ProgressAnalytics(
        exerciseName: exerciseName,
        muscleGroup: muscleGroup,
        data: data,
        totalWorkouts: 0,
        progressionData: [],
        programName: programName,
      );
    }

    // Sort data by date
    final sortedData = List<ProgressTrackerModel>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Calculate bests
    final bestWeight = sortedData.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final bestVolume = sortedData.map((e) => e.calculatedVolume).reduce((a, b) => a > b ? a : b);
    final bestOneRepMax = sortedData.map((e) => e.calculatedOneRepMax).reduce((a, b) => a > b ? a : b);

    // Calculate averages
    final averageWeight = sortedData.map((e) => e.weight).reduce((a, b) => a + b) / sortedData.length;
    final averageVolume = sortedData.map((e) => e.calculatedVolume).reduce((a, b) => a + b) / sortedData.length;
    final totalVolume = sortedData.map((e) => e.calculatedVolume).reduce((a, b) => a + b);

    // Calculate progress percentage
    double? progressPercentage;
    if (sortedData.length >= 2) {
      final first = sortedData.first;
      final last = sortedData.last;
      final weightProgress = ((last.weight - first.weight) / first.weight) * 100;
      final volumeProgress = ((last.calculatedVolume - first.calculatedVolume) / first.calculatedVolume) * 100;
      progressPercentage = (weightProgress + volumeProgress) / 2;
    }

    // Create progression data
    final progressionData = <ProgressionData>[];
    double currentBestWeight = 0;
    double currentBestVolume = 0;
    double currentBestOneRepMax = 0;

    for (int i = 0; i < sortedData.length; i++) {
      final lift = sortedData[i];
      final isPersonalBest = lift.weight > currentBestWeight || 
                           (lift.weight == currentBestWeight && lift.calculatedVolume > currentBestVolume);

      if (isPersonalBest) {
        currentBestWeight = lift.weight;
        currentBestVolume = lift.calculatedVolume;
        currentBestOneRepMax = lift.calculatedOneRepMax;
      }

      progressionData.add(ProgressionData(
        date: lift.date,
        weight: lift.weight,
        reps: lift.reps,
        volume: lift.calculatedVolume,
        oneRepMax: lift.calculatedOneRepMax,
        isPersonalBest: isPersonalBest,
        notes: lift.notes,
      ));
    }

    return ProgressAnalytics(
      exerciseName: exerciseName,
      muscleGroup: muscleGroup,
      data: sortedData,
      bestWeight: bestWeight,
      bestVolume: bestVolume,
      bestOneRepMax: bestOneRepMax,
      averageWeight: averageWeight,
      averageVolume: averageVolume,
      totalVolume: totalVolume,
      totalWorkouts: sortedData.length,
      progressPercentage: progressPercentage,
      progressionData: progressionData,
      programName: programName,
    );
  }

  // Get muscle group analytics
  static Future<Map<String, ProgressAnalytics>> getMuscleGroupAnalytics() async {
    try {
      final allProgress = await getAllProgress();
      final Map<String, ProgressAnalytics> muscleGroupAnalytics = {};

      allProgress.forEach((exerciseName, lifts) {
        if (lifts.isNotEmpty) {
          final muscleGroup = lifts.first.muscleGroup;
          final programName = lifts.first.programName;
          
          if (!muscleGroupAnalytics.containsKey(muscleGroup)) {
            muscleGroupAnalytics[muscleGroup] = calculateAnalytics(
              exerciseName: muscleGroup,
              muscleGroup: muscleGroup,
              data: [],
              programName: programName,
            );
          }

          // Add lifts to muscle group
          final currentAnalytics = muscleGroupAnalytics[muscleGroup]!;
          final updatedData = List<ProgressTrackerModel>.from(currentAnalytics.data)
            ..addAll(lifts);
          
          muscleGroupAnalytics[muscleGroup] = calculateAnalytics(
            exerciseName: muscleGroup,
            muscleGroup: muscleGroup,
            data: updatedData,
            programName: programName,
          );
        }
      });

      return muscleGroupAnalytics;
    } catch (e) {
      print('Error getting muscle group analytics: $e');
      return {};
    }
  }

  // Get recent lifts (last 30 days)
  static Future<List<ProgressTrackerModel>> getRecentLifts({int days = 30}) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_recent_lifts&user_id=$userId&days=$days'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> lifts = data['data'] ?? [];
          return lifts.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting recent lifts: $e');
      return [];
    }
  }

  // Get progress data for a specific program
  static Future<List<ProgressTrackerModel>> getProgressByProgram(int programId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$progressEndpoint?action=get_progress_by_program&user_id=$userId&program_id=$programId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> progress = data['data'] ?? [];
          return progress.map((json) => ProgressTrackerModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting program progress: $e');
      return [];
    }
  }
}
