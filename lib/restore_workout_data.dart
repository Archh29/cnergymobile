import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RestoreWorkoutData {
  static Future<void> restoreYourWorkoutData() async {
    try {
      print('🔧 === RESTORING YOUR WORKOUT DATA ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Your actual workout data from today - with proper timestamps
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30); // 2:30 PM today
      
      final yourWorkoutData = {
        "23": [ // Lat Pulldown
          {
            "reps": 9,
            "weight": 60.0,
            "timestamp": today.add(Duration(minutes: 0)).toIso8601String()
          },
          {
            "reps": 10,
            "weight": 55.0,
            "timestamp": today.add(Duration(minutes: 2)).toIso8601String()
          },
          {
            "reps": 10,
            "weight": 55.0,
            "timestamp": today.add(Duration(minutes: 4)).toIso8601String()
          }
        ],
        "24": [ // Seated Cable Row
          {
            "reps": 5,
            "weight": 80.0,
            "timestamp": today.add(Duration(minutes: 6)).toIso8601String()
          },
          {
            "reps": 6,
            "weight": 75.0,
            "timestamp": today.add(Duration(minutes: 8)).toIso8601String()
          },
          {
            "reps": 7,
            "weight": 70.0,
            "timestamp": today.add(Duration(minutes: 10)).toIso8601String()
          }
        ],
        "32": [ // Deadlift
          {
            "reps": 6,
            "weight": 135.0,
            "timestamp": today.add(Duration(minutes: 12)).toIso8601String()
          },
          {
            "reps": 7,
            "weight": 130.0,
            "timestamp": today.add(Duration(minutes: 14)).toIso8601String()
          },
          {
            "reps": 8,
            "weight": 125.0,
            "timestamp": today.add(Duration(minutes: 16)).toIso8601String()
          }
        ]
      };
      
      // Save your workout data
      await prefs.setString('latest_exercise_weights', json.encode(yourWorkoutData));
      
      print('✅ Restored your workout data:');
      print('📊 Lat Pulldown: 60kg x 9, 55kg x 10, 55kg x 10');
      print('📊 Seated Cable Row: 80kg x 5, 75kg x 6, 70kg x 7');
      print('📊 Deadlift: 135kg x 6, 130kg x 7, 125kg x 8');
      
      // Also save as backup keys
      await prefs.setString('exercise_weights', json.encode(yourWorkoutData));
      await prefs.setString('workout_weights', json.encode(yourWorkoutData));
      
      // Force clear any cached workout data to force refresh
      await prefs.remove('cached_workout_preview');
      await prefs.remove('workout_preview_cache');
      
      print('✅ Data restored successfully!');
      print('🔄 Cleared workout cache to force refresh');
      
    } catch (e) {
      print('💥 Error restoring workout data: $e');
    }
  }
}
