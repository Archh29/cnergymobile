import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DebugDataCheck {
  static Future<void> checkAllData() async {
    try {
      print('🔍 === CHECKING ALL YOUR DATA ===');
      
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      print('📊 Total keys in SharedPreferences: ${allKeys.length}');
      print('📊 All keys: $allKeys');
      
      // Check for workout weights data
      print('\n🔍 === CHECKING WORKOUT WEIGHTS ===');
      
      // Check latest_exercise_weights
      final latestWeights = prefs.getString('latest_exercise_weights');
      if (latestWeights != null) {
        print('✅ Found latest_exercise_weights data!');
        print('📊 Data: $latestWeights');
        
        try {
          final weightsMap = json.decode(latestWeights) as Map<String, dynamic>;
          print('📊 Parsed weights map: ${weightsMap.keys.toList()}');
          
          for (final entry in weightsMap.entries) {
            print('📊 Exercise ID ${entry.key}: ${entry.value}');
          }
        } catch (e) {
          print('💥 Error parsing latest_exercise_weights: $e');
        }
      } else {
        print('⚠️ No latest_exercise_weights found');
      }
      
      // Check other possible weight keys
      final possibleKeys = [
        'exercise_weights',
        'workout_weights', 
        'user_weights',
        'weights',
        'workout_data',
        'exercise_data'
      ];
      
      for (final key in possibleKeys) {
        final data = prefs.getString(key);
        if (data != null) {
          print('✅ Found $key data: $data');
        }
      }
      
      // Check workout sessions
      print('\n🔍 === CHECKING WORKOUT SESSIONS ===');
      for (final key in allKeys) {
        if (key.startsWith('workout_sessions_')) {
          final sessions = prefs.getStringList(key);
          print('✅ Found $key: ${sessions?.length ?? 0} sessions');
          if (sessions != null && sessions.isNotEmpty) {
            print('📊 First session: ${sessions.first}');
          }
        }
      }
      
      print('\n✅ === DATA CHECK COMPLETE ===');
      
    } catch (e) {
      print('💥 Error checking data: $e');
    }
  }
}

