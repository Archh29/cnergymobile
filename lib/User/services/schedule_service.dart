import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'auth_service.dart';

class ScheduleService {
  static const String baseUrl = 'https://api.cnergy.site/routines.php';

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

  // Get all programs available for scheduling
  static Future<List<ProgramForScheduling>> getProgramsForScheduling() async {
    try {
      final userId = await getCurrentUserId();
      print('🔍 Fetching programs for scheduling for user: $userId');
      
      final url = '$baseUrl?action=get_programs_for_scheduling&user_id=$userId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> programsData = data['programs'] ?? [];
          return programsData
              .map((program) => ProgramForScheduling.fromJson(program))
              .toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch programs');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching programs for scheduling: $e');
      throw Exception('Failed to load programs: $e');
    }
  }

  // Create or update weekly schedule
  static Future<bool> createSchedule(
      int memberProgramId, Map<String, Map<String, dynamic>> schedule) async {
    try {
      final userId = await getCurrentUserId();
      print('📅 Creating schedule for program: $memberProgramId, user: $userId');
      
      final requestBody = {
        'action': 'create_schedule',
        'user_id': userId,
        'member_program_id': memberProgramId,
        'schedule': schedule,
      };
      
      print('📤 Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Schedule created successfully');
          return true;
        } else {
          throw Exception(data['error'] ?? 'Failed to create schedule');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating schedule: $e');
      throw Exception('Failed to create schedule: $e');
    }
  }

  // Get weekly schedule for a program
  static Future<Map<String, ScheduleModel>> getSchedule(int memberProgramId) async {
    try {
      final userId = await getCurrentUserId();
      print('📅 Fetching schedule for program: $memberProgramId, user: $userId');
      
      final url = '$baseUrl?action=get_schedule&user_id=$userId&member_program_id=$memberProgramId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, dynamic> scheduleData = data['weekly_schedule'] ?? {};
          Map<String, ScheduleModel> weeklySchedule = {};
          
          scheduleData.forEach((day, dayData) {
            weeklySchedule[day] = ScheduleModel.fromJson({
              ...dayData,
              'day_of_week': day,
            });
          });
          
          return weeklySchedule;
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch schedule');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching schedule: $e');
      throw Exception('Failed to load schedule: $e');
    }
  }

  // Get today's workout
  static Future<TodayWorkout?> getTodayWorkout(int memberProgramId) async {
    try {
      final userId = await getCurrentUserId();
      print('📅 Fetching today\'s workout for program: $memberProgramId, user: $userId');
      
      final url = '$baseUrl?action=get_today_workout&user_id=$userId&member_program_id=$memberProgramId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final todayWorkoutData = data['today_workout'];
          if (todayWorkoutData != null) {
            return TodayWorkout.fromJson(todayWorkoutData);
          }
          return null;
        } else {
          throw Exception(data['error'] ?? 'Failed to fetch today\'s workout');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching today\'s workout: $e');
      throw Exception('Failed to load today\'s workout: $e');
    }
  }

  // Helper method to get all user's active programs
  static Future<List<ProgramForScheduling>> getUserActivePrograms() async {
    try {
      return await getProgramsForScheduling();
    } catch (e) {
      print('❌ Error fetching user active programs: $e');
      return [];
    }
  }

  // Get today's workout from any active program
  static Future<TodayWorkout?> getTodayWorkoutFromAnyProgram() async {
    try {
      print('📅 ScheduleService: Getting programs for scheduling...');
      final programs = await getProgramsForScheduling();
      print('📅 ScheduleService: Found ${programs.length} programs');
      
      // Check each program for today's workout
      for (final program in programs) {
        try {
          print('📅 ScheduleService: Checking program ${program.programId} (${program.goal})');
          final todayWorkout = await getTodayWorkout(program.programId);
          if (todayWorkout != null) {
            print('📅 ScheduleService: Found today\'s workout: ${todayWorkout.isRestDay ? "Rest Day" : todayWorkout.workoutName}');
            return todayWorkout;
          }
        } catch (e) {
          print('❌ Error checking program ${program.programId} for today\'s workout: $e');
          continue;
        }
      }
      
      print('📅 ScheduleService: No workout found for today');
      return null; // No workout found for today
    } catch (e) {
      print('❌ Error fetching today\'s workout from any program: $e');
      return null;
    }
  }

  // Helper method to format schedule for API
  static Map<String, Map<String, dynamic>> formatScheduleForApi(
      Map<String, ScheduleModel> schedule) {
    Map<String, Map<String, dynamic>> formattedSchedule = {};
    
    schedule.forEach((day, scheduleModel) {
      formattedSchedule[day] = {
        'workout_id': scheduleModel.workoutId,
        'scheduled_time': scheduleModel.scheduledTime ?? '09:00:00',
        'is_rest_day': scheduleModel.isRestDay,
        'notes': scheduleModel.notes,
      };
    });
    
    return formattedSchedule;
  }

  // Get default week days
  static List<String> getWeekDays() {
    return [
      'Monday',
      'Tuesday', 
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
  }

  // Create empty schedule template
  static Map<String, ScheduleModel> createEmptySchedule() {
    Map<String, ScheduleModel> schedule = {};
    
    for (String day in getWeekDays()) {
      schedule[day] = ScheduleModel(
        dayOfWeek: day,
        isRestDay: true,
        scheduledTime: '09:00:00',
      );
    }
    
    return schedule;
  }
}






