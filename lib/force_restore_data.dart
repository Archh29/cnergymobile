import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ForceRestoreData {
  static Future<void> forceRestoreAllData() async {
    try {
      print('🚨 === FORCE RESTORING ALL YOUR DATA ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Don't clear everything, just clear weight data
      await prefs.remove('latest_exercise_weights');
      await prefs.remove('exercise_weights');
      await prefs.remove('workout_weights');
      await prefs.remove('user_weights');
      print('🧹 Cleared existing weight data');
      
      // Restore your workout data
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
        ],
        "14": [ // Barbell Bench Press
          {
            "reps": 8,
            "weight": 40.0,
            "timestamp": today.add(Duration(minutes: 18)).toIso8601String()
          },
          {
            "reps": 7,
            "weight": 40.0,
            "timestamp": today.add(Duration(minutes: 20)).toIso8601String()
          },
          {
            "reps": 6,
            "weight": 40.0,
            "timestamp": today.add(Duration(minutes: 22)).toIso8601String()
          }
        ],
        "25": [ // Dumbbell Row
          {
            "reps": 10,
            "weight": 25.0,
            "timestamp": today.add(Duration(minutes: 24)).toIso8601String()
          },
          {
            "reps": 10,
            "weight": 25.0,
            "timestamp": today.add(Duration(minutes: 26)).toIso8601String()
          },
          {
            "reps": 10,
            "weight": 25.0,
            "timestamp": today.add(Duration(minutes: 28)).toIso8601String()
          }
        ],
        "26": [ // Pull-up
          {
            "reps": 8,
            "weight": 0.0,
            "timestamp": today.add(Duration(minutes: 30)).toIso8601String()
          },
          {
            "reps": 6,
            "weight": 0.0,
            "timestamp": today.add(Duration(minutes: 32)).toIso8601String()
          },
          {
            "reps": 5,
            "weight": 0.0,
            "timestamp": today.add(Duration(minutes: 34)).toIso8601String()
          }
        ],
        "27": [ // Bicep Curl
          {
            "reps": 12,
            "weight": 15.0,
            "timestamp": today.add(Duration(minutes: 36)).toIso8601String()
          },
          {
            "reps": 12,
            "weight": 15.0,
            "timestamp": today.add(Duration(minutes: 38)).toIso8601String()
          },
          {
            "reps": 12,
            "weight": 15.0,
            "timestamp": today.add(Duration(minutes: 40)).toIso8601String()
          }
        ]
      };
      
      // Save your workout data in multiple keys
      await prefs.setString('latest_exercise_weights', json.encode(yourWorkoutData));
      await prefs.setString('exercise_weights', json.encode(yourWorkoutData));
      await prefs.setString('workout_weights', json.encode(yourWorkoutData));
      await prefs.setString('user_weights', json.encode(yourWorkoutData));
      
      // Set user ID
      await prefs.setInt('user_id', 61);
      
      // Verify the data was saved
      final savedData = prefs.getString('latest_exercise_weights');
      print('🔍 Verification - saved data: $savedData');
      
      // Also save individual exercise data
      for (final entry in yourWorkoutData.entries) {
        await prefs.setString('exercise_${entry.key}_weights', json.encode(entry.value));
        print('✅ Saved individual data for exercise ${entry.key}');
      }
      
      // Final verification - check if data is actually there
      final finalCheck = prefs.getString('latest_exercise_weights');
      if (finalCheck != null) {
        final parsedData = json.decode(finalCheck) as Map<String, dynamic>;
        print('🔍 Final verification - found ${parsedData.length} exercises');
        for (final entry in parsedData.entries) {
          print('  - Exercise ${entry.key}: ${(entry.value as List).length} sets');
        }
      } else {
        print('❌ ERROR: Data was not saved properly!');
      }
      
      print('✅ FORCE RESTORED your workout data:');
      print('📊 Lat Pulldown: 60kg x 9, 55kg x 10, 55kg x 10');
      print('📊 Seated Cable Row: 80kg x 5, 75kg x 6, 70kg x 7');
      print('📊 Deadlift: 135kg x 6, 130kg x 7, 125kg x 8');
      print('📊 Barbell Bench Press: 40kg x 8, 40kg x 7, 40kg x 6');
      print('📊 Dumbbell Row: 25kg x 10, 25kg x 10, 25kg x 10');
      print('📊 Pull-up: 0kg x 8, 0kg x 6, 0kg x 5');
      print('📊 Bicep Curl: 15kg x 12, 15kg x 12, 15kg x 12');
      print('✅ User ID: 61');
      print('🚨 ALL DATA FORCE RESTORED!');
      
    } catch (e) {
      print('💥 Error force restoring data: $e');
    }
  }
}
