import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine.models.dart';

class RoutineService {
  static const String baseUrl = "https://api.cnergy.site/routines.php";
  static const String exerciseUrl = "https://api.cnergy.site/exercises.php";

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

  // Fetch target muscles from database
  static Future<List<TargetMuscleModel>> fetchTargetMuscles() async {
    try {
      print('🔍 Fetching target muscles...');
      
      final url = '$exerciseUrl?action=fetchMuscles';
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
          final List<dynamic> musclesData = responseData['muscles'] ?? [];
          
          return musclesData.map((muscle) => TargetMuscleModel.fromJson(muscle)).toList();
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch muscles');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching target muscles: $e');
      throw Exception('Failed to load muscle groups: $e');
    }
  }

  // Fetch exercises by muscle group (null for all exercises)
  static Future<List<ExerciseModel>> fetchExercisesByMuscle([int? muscleId]) async {
    try {
      print('🔍 Fetching exercises for muscle ID: ${muscleId ?? "All"}');
      
      String url = '$exerciseUrl?action=fetchExercises';
      if (muscleId != null) {
        url += '&muscle_id=$muscleId';
      }
      
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
          final List<dynamic> exercisesData = responseData['exercises'] ?? [];
          
          print('📋 Fetched ${exercisesData.length} exercises');
          for (var exercise in exercisesData) {
            print('Exercise: ${exercise['name']}');
            print('  - target_muscle field: "${exercise['target_muscle']}"');
            print('  - targetMuscle field: "${exercise['targetMuscle']}"');
            print('  - All keys: ${exercise.keys.toList()}');
          }
          
          return exercisesData.map((exercise) => ExerciseModel.fromJson(exercise)).toList();
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch exercises');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching exercises: $e');
      throw Exception('Failed to load exercises: $e');
    }
  }

  // Enhanced fetch method that properly captures membership status
  static Future<RoutineResponse> fetchUserRoutinesWithStatus() async {
    try {
      int currentUserId = await getCurrentUserId();
      print('🔍 Fetching routines for user ID: $currentUserId');
      
      final url = '$baseUrl?action=fetch&user_id=$currentUserId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['error'] != null) {
          print('❌ API Error: ${responseData['error']}');
          return RoutineResponse(
            success: false,
            routines: [],
            myRoutines: const [],
            coachAssigned: const [],
            templateRoutines: const [],
            totalRoutines: 0,
            isPremium: false,
            error: responseData['error'],
          );
        }
        
        final routineResponse = RoutineResponse.fromJson(responseData);
        
        print('✅ Parsed response:');
        print('   - Success: ${routineResponse.success}');
        print('   - Routines count: ${routineResponse.routines.length}');
        print('   - Total routines: ${routineResponse.totalRoutines}');
        print('   - Is Premium: ${routineResponse.isPremium}');
        
        await _cacheMembershipStatus(
          routineResponse.isPremium,
          routineResponse.membershipStatus?['subscription_details']
        );
        
        return routineResponse;
        
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load routines: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching routines: $e');
      
      final cachedMembership = await _getCachedMembershipStatus();
      return RoutineResponse(
        success: false,
        routines: const [],
        myRoutines: const [],
        coachAssigned: const [],
        templateRoutines: const [],
        totalRoutines: 0,
        isPremium: cachedMembership['is_premium'] ?? false,
        error: e.toString(),
      );
    }
  }

  // Fetch ONLY user-created routines (for Tab 1)
  static Future<RoutineResponse> fetchUserCreatedRoutines() async {
    try {
      int currentUserId = await getCurrentUserId();
      print('🔍 Fetching USER-ONLY routines for user ID: $currentUserId');
      
      final url = '$baseUrl?action=user_routines&user_id=$currentUserId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['error'] != null) {
          print('❌ API Error: ${responseData['error']}');
          return RoutineResponse(
            success: false,
            routines: [],
            myRoutines: const [],
            coachAssigned: const [],
            templateRoutines: const [],
            totalRoutines: 0,
            isPremium: false,
            error: responseData['error'],
          );
        }
        
        final routineResponse = RoutineResponse.fromJson(responseData);
        
        print('✅ Parsed USER-ONLY response:');
        print('   - Success: ${routineResponse.success}');
        print('   - My Routines count: ${routineResponse.myRoutines.length}');
        print('   - Coach Assigned count: ${routineResponse.coachAssigned.length}');
        print('   - Template Routines count: ${routineResponse.templateRoutines.length}');
        print('   - Is Premium: ${routineResponse.isPremium}');
        
        await _cacheMembershipStatus(
          routineResponse.isPremium,
          routineResponse.membershipStatus?['subscription_details']
        );
        
        return routineResponse;
        
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load user routines: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching user routines: $e');
      
      final cachedMembership = await _getCachedMembershipStatus();
      return RoutineResponse(
        success: false,
        routines: const [],
        myRoutines: const [],
        coachAssigned: const [],
        templateRoutines: const [],
        totalRoutines: 0,
        isPremium: cachedMembership['is_premium'] ?? false,
        error: e.toString(),
      );
    }
  }

  // Fetch ONLY coach-created routines (for Tab 2)
  static Future<RoutineResponse> fetchCoachCreatedRoutines() async {
    try {
      int currentUserId = await getCurrentUserId();
      print('🔍 Fetching COACH-ONLY routines for user ID: $currentUserId');
      
      final url = '$baseUrl?action=coach_routines&user_id=$currentUserId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['error'] != null) {
          print('❌ API Error: ${responseData['error']}');
          return RoutineResponse(
            success: false,
            routines: [],
            myRoutines: const [],
            coachAssigned: const [],
            templateRoutines: const [],
            totalRoutines: 0,
            isPremium: false,
            error: responseData['error'],
          );
        }
        
        final routineResponse = RoutineResponse.fromJson(responseData);
        
        print('✅ Parsed COACH-ONLY response:');
        print('   - Success: ${routineResponse.success}');
        print('   - My Routines count: ${routineResponse.myRoutines.length}');
        print('   - Coach Assigned count: ${routineResponse.coachAssigned.length}');
        print('   - Template Routines count: ${routineResponse.templateRoutines.length}');
        print('   - Is Premium: ${routineResponse.isPremium}');
        
        return routineResponse;
        
      } else {
        print('❌ HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load coach routines: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching coach routines: $e');
      
      return RoutineResponse(
        success: false,
        routines: const [],
        myRoutines: const [],
        coachAssigned: const [],
        templateRoutines: const [],
        totalRoutines: 0,
        isPremium: true, // Coach routines don't have membership restrictions
        error: e.toString(),
      );
    }
  }

  // Enhanced create routine with database schema integration
  static Future<Map<String, dynamic>> createRoutine(RoutineModel routine) async {
    try {
      print('🔨 Creating routine: ${routine.name}');
      
      int currentUserId = await getCurrentUserId();
      print('👤 Using user ID: $currentUserId');
      
      // Create Member_ProgramHdr entry
      final programHdrData = {
        "action": "createRoutine",
        "user_id": currentUserId,
        "name": routine.name,
        "duration": routine.duration,
        "difficulty": routine.difficulty,
        "goal": routine.goal,
        "color": routine.color,
        "tags": routine.tags,
        "notes": routine.notes,
        "scheduled_days": routine.scheduledDays,
        "total_sessions": routine.totalSessions,
        "completion_rate": routine.completionRate,
        "exercises": routine.detailedExercises?.map((exercise) => {
          "exercise_id": exercise.id,
          "name": exercise.name,
          "sets": exercise.sets.map((set) => {
            "reps": set.reps,
            "weight": set.weight,
            "timestamp": set.timestamp.toIso8601String(),
          }).toList(),
          "target_sets": exercise.targetSets,
          "target_reps": exercise.targetReps,
          "target_weight": exercise.targetWeight,
          "rest_time": exercise.restTime,
          "notes": exercise.notes,
        }).toList() ?? [],
      };
      
      print('📤 Request body: ${json.encode(programHdrData)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(programHdrData),
      );
      
      print('📊 Create response status: ${response.statusCode}');
      print('📋 Create response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          print('✅ Routine created successfully with ID: ${responseData['id']}');
          return {
            'success': true,
            'id': responseData['id'],
            'message': responseData['message'],
            'is_premium': responseData['is_premium'],
            'membership_status': responseData['membership_status']
          };
        } else {
          print('❌ Create error: ${responseData['error']}');
          return {
            'success': false,
            'error': responseData['error'],
            'membership_required': responseData['membership_required'] ?? false,
            'is_premium': responseData['is_premium'] ?? false
          };
        }
      }
      
      print('❌ Create failed with status: ${response.statusCode}');
      return {
        'success': false,
        'error': 'Failed to create routine'
      };
    } catch (e) {
      print('💥 Error creating routine: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  // Backward compatibility method
  static Future<List<RoutineModel>> fetchUserRoutines() async {
    final response = await fetchUserRoutinesWithStatus();
    return response.routines;
  }

  // Get membership status with enhanced logging
  static Future<bool> getMembershipStatus() async {
    try {
      print('🔍 Getting membership status...');
      
      final response = await fetchUserRoutinesWithStatus();
      
      if (response.success) {
        print('✅ Got fresh membership status: ${response.isPremium}');
        return response.isPremium;
      } else {
        print('⚠️ Failed to get fresh data, using cached status');
        final cachedData = await _getCachedMembershipStatus();
        return cachedData['is_premium'] ?? false;
      }
    } catch (e) {
      print('💥 Error getting membership status: $e');
      final cachedData = await _getCachedMembershipStatus();
      return cachedData['is_premium'] ?? false;
    }
  }

  // Force refresh membership status (clear cache and fetch fresh)
  static Future<bool> forceRefreshMembershipStatus() async {
    try {
      print('🔄 Force refreshing membership status...');
      
      // Clear cached membership status
      await _clearCachedMembershipStatus();
      
      // Fetch fresh data
      final response = await fetchUserRoutinesWithStatus();
      
      if (response.success) {
        print('✅ Force refreshed membership status: ${response.isPremium}');
        return response.isPremium;
      } else {
        print('❌ Failed to get fresh data after cache clear');
        return false;
      }
    } catch (e) {
      print('💥 Error force refreshing membership status: $e');
      return false;
    }
  }

  // Clear cached membership status
  static Future<void> _clearCachedMembershipStatus() async {
    try {
      int currentUserId = await getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();
      
      String membershipKey = 'is_pro_member_$currentUserId';
      String subscriptionKey = 'subscription_details_$currentUserId';
      String lastCheckedKey = 'membership_last_checked_$currentUserId';
      
      await prefs.remove(membershipKey);
      await prefs.remove(subscriptionKey);
      await prefs.remove(lastCheckedKey);
      
      print('🗑️ Cleared cached membership status for user $currentUserId');
    } catch (e) {
      print('💥 Error clearing cached membership status: $e');
    }
  }

  // Cache membership status locally
  static Future<void> _cacheMembershipStatus(bool isPremium, Map<String, dynamic>? subscriptionDetails) async {
    try {
      int currentUserId = await getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();
      
      String membershipKey = 'is_pro_member_$currentUserId';
      String subscriptionKey = 'subscription_details_$currentUserId';
      String lastCheckedKey = 'membership_last_checked_$currentUserId';
      
      await prefs.setBool(membershipKey, isPremium);
      await prefs.setString(lastCheckedKey, DateTime.now().toIso8601String());
      
      if (subscriptionDetails != null) {
        await prefs.setString(subscriptionKey, json.encode(subscriptionDetails));
      }
      
      print('💾 Cached membership status: ${isPremium ? 'PREMIUM' : 'BASIC'} for user $currentUserId');
    } catch (e) {
      print('💥 Error caching membership status: $e');
    }
  }

  // Get cached membership status
  static Future<Map<String, dynamic>> _getCachedMembershipStatus() async {
    try {
      int currentUserId = await getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();
      
      String membershipKey = 'is_pro_member_$currentUserId';
      String subscriptionKey = 'subscription_details_$currentUserId';
      String lastCheckedKey = 'membership_last_checked_$currentUserId';
      
      bool isPremium = prefs.getBool(membershipKey) ?? false;
      String? subscriptionDetailsStr = prefs.getString(subscriptionKey);
      String? lastChecked = prefs.getString(lastCheckedKey);
      
      Map<String, dynamic>? subscriptionDetails;
      if (subscriptionDetailsStr != null) {
        subscriptionDetails = json.decode(subscriptionDetailsStr);
      }
      
      print('📱 Retrieved cached membership: ${isPremium ? 'PREMIUM' : 'BASIC'} for user $currentUserId');
      
      return {
        'is_premium': isPremium,
        'subscription_details': subscriptionDetails,
        'last_checked': lastChecked,
        'from_cache': true
      };
    } catch (e) {
      print('💥 Error getting cached membership status: $e');
      return {
        'is_premium': false,
        'subscription_details': null,
        'last_checked': null,
        'from_cache': true
      };
    }
  }

  // Update routine progress
  static Future<bool> updateRoutineProgress(String routineId, int completionRate, int totalSessions) async {
    try {
      int currentUserId = await getCurrentUserId();
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "updateProgress",
          "id": routineId,
          "userId": currentUserId,
          "completionRate": completionRate,
          "totalSessions": totalSessions,
          "lastPerformed": DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error updating routine progress: $e');
      return false;
    }
  }

  // Fetch routine details for editing
  static Future<RoutineModel?> fetchRoutineDetails(String routineId) async {
    try {
      int currentUserId = await getCurrentUserId();
      
      print('🔍 Fetching routine details for ID: $routineId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_routine_details&routine_id=$routineId&user_id=$currentUserId'),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Fetch response status: ${response.statusCode}');
      print('📋 Fetch response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final routineData = responseData['routine'];
          if (routineData != null) {
            print('✅ Found routine with ${routineData['exercises'] ?? 0} exercises');
            return RoutineModel.fromJson(routineData);
          } else {
            print('❌ No routine data in response');
            return null;
          }
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch routine details');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching routine details: $e');
      rethrow;
    }
  }

  // Delete routine
  static Future<bool> deleteRoutine(String routineId) async {
    try {
      int currentUserId = await getCurrentUserId();
      
      print('🗑️ Deleting routine ID: $routineId for user: $currentUserId');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "delete",
          "id": routineId,
          "userId": currentUserId,
        }),
      );
      
      print('📊 Delete response status: ${response.statusCode}');
      print('📋 Delete response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Routine deleted successfully');
          return true;
        } else {
          print('❌ Delete failed: ${responseData['error']}');
          throw Exception(responseData['error'] ?? 'Failed to delete routine');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error deleting routine: $e');
      rethrow; // Re-throw to let the UI handle the error
    }
  }

  // Store user ID after login
  static Future<void> setCurrentUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId.toString());
    print('Stored user ID: $userId');
  }

  // Clear user session
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_token');
    
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.contains('workout_sessions_') ||
          key.contains('is_pro_member_') ||
          key.contains('subscription_details_') ||
          key.contains('membership_last_checked_')) {
        await prefs.remove(key);
      }
    }
  }

  // Save workout session
  static Future<bool> saveWorkoutSession(WorkoutSession session) async {
    try {
      int currentUserId = await getCurrentUserId();
      final prefs = await SharedPreferences.getInstance();
      
      String userKey = 'workout_sessions_$currentUserId';
      List<String> sessions = prefs.getStringList(userKey) ?? [];
      
      sessions.insert(0, json.encode({
        'id': session.id,
        'userId': currentUserId,
        'date': session.date.toIso8601String(),
        'routine': session.routineName,
        'duration': session.duration,
        'exercises': session.exercises,
        'totalVolume': session.totalVolume,
        'calories': session.calories,
        'rating': session.rating,
        'bodyPart': session.bodyPart,
        'notes': session.notes,
      }));
      
      if (sessions.length > 50) {
        sessions = sessions.take(50).toList();
      }
      
      return await prefs.setStringList(userKey, sessions);
    } catch (e) {
      print('Error saving workout session: $e');
      return false;
    }
  }

  // Get workout history
  static Future<List<WorkoutSession>> getWorkoutHistory() async {
    try {
      int currentUserId = await getCurrentUserId();
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
