import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_model.dart';
import '../models/workout_session_model.dart';
import '../models/attendance_model.dart';
import '../models/progress_model.dart';
import '../models/personal_record_model.dart';
import '../models/routine.models.dart';

class EnhancedProgressService {
  static const String baseUrl = "http://localhost/cynergy/userprogress.php";
  static const String routinesUrl = "http://localhost/cynergy/routines.php";

  // Get current user ID
  static Future<int> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userIdString = prefs.getString('user_id');
      if (userIdString != null && userIdString.isNotEmpty) {
        return int.parse(userIdString);
      }
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        return userIdInt;
      }
      throw Exception('User not logged in');
    } catch (e) {
      throw Exception('Failed to get user ID: $e');
    }
  }

  // ROUTINE MANAGEMENT - NEW METHODS
  static Future<List<RoutineModel>> fetchAllAvailableRoutines() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$routinesUrl?action=fetch_all_available&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success') && responseData['success']) {
          final List<dynamic> routinesData = responseData['routines'] ?? [];
          return routinesData.map((json) => RoutineModel.fromJson(json)).toList();
        }
        if (responseData is List) {
          return responseData.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching available routines: $e');
      return [];
    }
  }

  static Future<List<RoutineModel>> fetchUserRoutines() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$routinesUrl?action=fetch&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map) {
          // Prefer categorized list if present
          final List<dynamic> my = (responseData['my_routines'] ?? responseData['routines'] ?? []) as List<dynamic>;
          return my.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user routines: $e');
      return [];
    }
  }

  static Future<List<RoutineModel>> fetchCoachRoutines() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$routinesUrl?action=fetch&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map) {
          final List<dynamic> coach = (responseData['coach_assigned'] ?? []) as List<dynamic>;
          return coach.map((json) => RoutineModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching coach routines: $e');
      return [];
    }
  }

  // PROGRESS MANAGEMENT
  static Future<List<ProgressModel>> fetchUserProgress() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_progress&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('error')) {
          print('API Error: ${responseData['error']}');
          return [];
        }
        if (responseData is List) {
          return responseData.map((json) => ProgressModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching progress: $e');
      return [];
    }
  }

  static Future<bool> addProgress(ProgressModel progress) async {
    try {
      final requestBody = {
        "action": "create_progress",
        ...progress.toJson(),
      };
      final response = await http.post(
        Uri.parse('$baseUrl?action=create_progress'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error adding progress: $e');
      return false;
    }
  }

  static Future<bool> updateProgress(ProgressModel progress) async {
    try {
      if (progress.id == null) return false;
      final requestBody = {
        "action": "update_progress",
        ...progress.toJson(),
      };
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_progress'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating progress: $e');
      return false;
    }
  }

  static Future<bool> deleteProgress(int progressId) async {
    try {
      final requestBody = {
        "action": "delete_progress",
        "id": progressId,
      };
      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_progress'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error deleting progress: $e');
      return false;
    }
  }

  // GOALS MANAGEMENT
  static Future<List<GoalModel>> fetchUserGoals() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_goals&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.map((json) => GoalModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  static Future<bool> createGoal(GoalModel goal) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=create_goal'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "create_goal",
          ...goal.toJson(),
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error creating goal: $e');
      return false;
    }
  }

  static Future<bool> updateGoalStatus(int goalId, GoalStatus status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_goal_status'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "update_goal_status",
          "id": goalId,
          "status": status.value,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error updating goal status: $e');
      return false;
    }
  }

  // WORKOUT SESSIONS
  static Future<List<WorkoutSessionModel>> fetchWorkoutSessions() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_sessions&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.map((json) => WorkoutSessionModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching workout sessions: $e');
      return [];
    }
  }

  static Future<bool> logWorkoutSession(WorkoutSessionModel session) async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl?action=create_session'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "create_session",
          "user_id": userId,
          ...session.toJson(),
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error logging workout session: $e');
      return false;
    }
  }

  // ATTENDANCE TRACKING
  static Future<List<AttendanceModel>> fetchAttendanceHistory() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_attendance&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.map((json) => AttendanceModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  static Future<bool> checkIn() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl?action=check_in'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "check_in",
          "user_id": userId,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking in: $e');
      return false;
    }
  }

  static Future<bool> checkOut() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.post(
        Uri.parse('$baseUrl?action=check_out'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "check_out",
          "user_id": userId,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking out: $e');
      return false;
    }
  }

  // COMPREHENSIVE ANALYTICS
  static Future<Map<String, dynamic>> getComprehensiveStats() async {
    try {
      final futures = await Future.wait([
        fetchUserGoals(),
        fetchWorkoutSessions(),
        fetchAttendanceHistory(),
        fetchUserProgress(),
      ]);
      final goals = futures[0] as List<GoalModel>;
      final sessions = futures[1] as List<WorkoutSessionModel>;
      final attendance = futures[2] as List<AttendanceModel>;
      final progress = futures[3] as List<ProgressModel>;
      return {
        'goals': _calculateGoalStats(goals),
        'workouts': _calculateWorkoutStats(sessions),
        'attendance': _calculateAttendanceStats(attendance),
        'progress': _calculateProgressStats(progress),
        'overall': _calculateOverallStats(goals, sessions, attendance, progress),
      };
    } catch (e) {
      print('Error calculating comprehensive stats: $e');
      return {};
    }
  }

  static Map<String, dynamic> _calculateGoalStats(List<GoalModel> goals) {
    final activeGoals = goals.where((g) => g.status == GoalStatus.active).length;
    final achievedGoals = goals.where((g) => g.status == GoalStatus.achieved).length;
    final overdueGoals = goals.where((g) => g.isOverdue).length;
    return {
      'total': goals.length,
      'active': activeGoals,
      'achieved': achievedGoals,
      'overdue': overdueGoals,
      'completionRate': goals.isEmpty ? 0.0 : (achievedGoals / goals.length) * 100,
    };
  }

  static Map<String, dynamic> _calculateWorkoutStats(List<WorkoutSessionModel> sessions) {
    final completedSessions = sessions.where((s) => s.completed).length;
    final thisWeekSessions = sessions.where((s) {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return s.sessionDate.isAfter(weekStart);
    }).length;
    return {
      'total': sessions.length,
      'completed': completedSessions,
      'thisWeek': thisWeekSessions,
      'completionRate': sessions.isEmpty ? 0.0 : (completedSessions / sessions.length) * 100,
    };
  }

  static Map<String, dynamic> _calculateAttendanceStats(List<AttendanceModel> attendance) {
    final thisMonth = attendance.where((a) {
      final now = DateTime.now();
      return a.checkIn.month == now.month && a.checkIn.year == now.year;
    }).length;
    final totalDuration = attendance.fold<Duration>(
      Duration.zero,
      (sum, a) => sum + (a.sessionDuration ?? Duration.zero),
    );
    return {
      'total': attendance.length,
      'thisMonth': thisMonth,
      'totalHours': totalDuration.inHours,
      'averageSession': attendance.isEmpty ? 0 : totalDuration.inMinutes / attendance.length,
    };
  }

  static Map<String, dynamic> _calculateProgressStats(List<ProgressModel> progress) {
    if (progress.isEmpty) return {'entries': 0};
    final weightEntries = progress.where((p) => p.weight != null).toList();
    final weightChange = weightEntries.length >= 2 
        ? weightEntries.last.weight! - weightEntries.first.weight!
        : 0.0;
    return {
      'entries': progress.length,
      'weightChange': weightChange,
      'latestBMI': progress.latest?.bmi,
      'trend': weightChange > 0 ? 'gaining' : weightChange < 0 ? 'losing' : 'stable',
    };
  }

  static Map<String, dynamic> _calculateOverallStats(
    List<GoalModel> goals,
    List<WorkoutSessionModel> sessions,
    List<AttendanceModel> attendance,
    List<ProgressModel> progress,
  ) {
    double fitnessScore = 0;
    // Goals contribution (25%)
    if (goals.isNotEmpty) {
      final achievedGoals = goals.where((g) => g.status == GoalStatus.achieved).length;
      fitnessScore += (achievedGoals / goals.length) * 25;
    }
    // Workout consistency (35%)
    if (sessions.isNotEmpty) {
      final completedSessions = sessions.where((s) => s.completed).length;
      fitnessScore += (completedSessions / sessions.length) * 35;
    }
    // Attendance consistency (25%)
    final thisMonth = DateTime.now();
    final monthlyAttendance = attendance.where((a) =>
      a.checkIn.month == thisMonth.month && a.checkIn.year == thisMonth.year
    ).length;
    fitnessScore += (monthlyAttendance / 20).clamp(0, 1) * 25;
    // Progress tracking (15%)
    if (progress.isNotEmpty) {
      fitnessScore += 15;
    }
    return {
      'fitnessScore': fitnessScore.round(),
      'level': _getFitnessLevel(fitnessScore),
      'streak': _calculateStreak(sessions),
      'nextMilestone': _getNextMilestone(fitnessScore),
    };
  }

  static String _getFitnessLevel(double score) {
    if (score >= 90) return 'Elite Athlete';
    if (score >= 75) return 'Advanced';
    if (score >= 60) return 'Intermediate';
    if (score >= 40) return 'Beginner';
    return 'Getting Started';
  }

  static int _calculateStreak(List<WorkoutSessionModel> sessions) {
    if (sessions.isEmpty) return 0;
    final sortedSessions = sessions
        .where((s) => s.completed)
        .toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    int streak = 0;
    DateTime? lastDate;
    for (final session in sortedSessions) {
      if (lastDate == null) {
        streak = 1;
        lastDate = session.sessionDate;
      } else {
        final difference = lastDate.difference(session.sessionDate).inDays;
        if (difference <= 2) {
          streak++;
          lastDate = session.sessionDate;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  static String _getNextMilestone(double score) {
    if (score < 40) return 'Reach Beginner level (40 points)';
    if (score < 60) return 'Reach Intermediate level (60 points)';
    if (score < 75) return 'Reach Advanced level (75 points)';
    if (score < 90) return 'Reach Elite level (90 points)';
    return 'Maintain Elite status!';
  }

  // UTILITY METHODS
  static Future<ProgressModel?> getLatestProgress() async {
    try {
      final progressList = await fetchUserProgress();
      if (progressList.isEmpty) return null;
      progressList.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      return progressList.first;
    } catch (e) {
      print('Error getting latest progress: $e');
      return null;
    }
  }

  static Future<List<ProgressModel>> getProgressInRange(DateTime startDate, DateTime endDate) async {
    try {
      final allProgress = await fetchUserProgress();
      return allProgress.getEntriesInRange(startDate, endDate);
    } catch (e) {
      print('Error getting progress in range: $e');
      return [];
    }
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      String? userId = prefs.getString('user_id');
      return isLoggedIn && userId != null && userId.isNotEmpty;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // PERSONAL RECORDS MANAGEMENT
  static Future<List<PersonalRecordModel>> fetchPersonalRecords() async {
    try {
      final userId = await getCurrentUserId();
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_personal_records&user_id=$userId'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return responseData.map((json) => PersonalRecordModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching personal records: $e');
      return [];
    }
  }

  // Fetch exercises as dynamic list to avoid import issues
  static Future<List<Map<String, dynamic>>> fetchExercises() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=fetch_exercises'),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List) {
          return List<Map<String, dynamic>>.from(responseData);
        }
      }
      return [];
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  static Future<bool> createPersonalRecord(PersonalRecordModel record) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=create_personal_record'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "create_personal_record",
          ...record.toJson(),
        }),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('success')) {
          return responseData['success'] == true;
        }
      }
      return false;
    } catch (e) {
      print('Error creating personal record: $e');
      return false;
    }
  }
}
