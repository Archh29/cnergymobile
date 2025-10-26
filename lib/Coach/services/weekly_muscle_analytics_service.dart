import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weekly_muscle_analytics_model.dart';
import 'auth_service.dart';

class WeeklyMuscleAnalyticsService {
  static const String baseUrl = 'https://api.cnergy.site';

  static Future<WeeklyMuscleAnalyticsData> getWeekly({DateTime? weekStart, int? userId}) async {
    final targetUserId = userId ?? AuthService.getCurrentUserId();
    if (targetUserId == null) {
      throw Exception('User not logged in');
    }
    
    print('🔍 🔍 🔍 LOADING WEEKLY ANALYTICS FOR USER ID: $targetUserId 🔍 🔍 🔍');
    
    final params = <String, String>{
      'action': 'weekly',
      'user_id': targetUserId.toString(),
    };
    if (weekStart != null) {
      params['week_start'] = weekStart.toIso8601String().substring(0, 10);
    }
    final uri = Uri.parse('$baseUrl/weekly_muscle_analytics.php').replace(queryParameters: params);
    
    print('🔍 API URL: $uri');
    
    try {
      final response = await http.get(uri, headers: { 'Content-Type': 'application/json' });
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      
      final jsonMap = json.decode(response.body) as Map<String, dynamic>;
      
      if (jsonMap['success'] != true) {
        throw Exception(jsonMap['error'] ?? 'Unknown error');
      }
      
      final data = jsonMap['data'] as Map<String, dynamic>;
      
      // Debug: Log first few keys and their types
      print('🔍 === WEEKLY ANALYTICS DEBUG START ===');
      print('🔍 tracked_muscle_groups type: ${data['tracked_muscle_groups'].runtimeType}');
      print('🔍 tracked_muscle_groups value: ${data['tracked_muscle_groups']}');
      
      if (data['groups'] != null && (data['groups'] as List).isNotEmpty) {
        final firstGroup = (data['groups'] as List)[0];
        print('🔍 First group sample: $firstGroup');
        print('🔍 First group_id type: ${firstGroup['group_id'].runtimeType}');
        print('🔍 First group_id value: ${firstGroup['group_id']}');
      }
      
      if (data['muscles'] != null && (data['muscles'] as List).isNotEmpty) {
        final firstMuscle = (data['muscles'] as List)[0];
        print('🔍 First muscle sample keys: ${firstMuscle.keys.toList()}');
        print('🔍 First muscle_id type: ${firstMuscle['muscle_id'].runtimeType}');
        print('🔍 First muscle_id value: ${firstMuscle['muscle_id']}');
      }
      
      print('🔍 === ABOUT TO PARSE ===');
      
      return WeeklyMuscleAnalyticsData.fromJson(data);
    } catch (e) {
      // ignore: avoid_print
      print('Error in getWeekly: $e');
      rethrow;
    }
  }
}



