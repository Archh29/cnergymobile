import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TestSaveData {
  static Future<void> testSaveAndVerify() async {
    try {
      print('🧪 === TESTING DATA SAVE AND VERIFY ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Test data
      final testData = {
        "23": [ // Lat Pulldown
          {
            "reps": 9,
            "weight": 60.0,
            "timestamp": DateTime.now().toIso8601String()
          },
          {
            "reps": 10,
            "weight": 55.0,
            "timestamp": DateTime.now().toIso8601String()
          }
        ],
        "24": [ // Seated Cable Row
          {
            "reps": 5,
            "weight": 80.0,
            "timestamp": DateTime.now().toIso8601String()
          }
        ]
      };
      
      // Save test data
      await prefs.setString('latest_exercise_weights', json.encode(testData));
      print('✅ Test data saved');
      
      // Verify it was saved
      final savedData = prefs.getString('latest_exercise_weights');
      if (savedData != null) {
        final parsedData = json.decode(savedData) as Map<String, dynamic>;
        print('✅ Data verification successful:');
        print('  - Found ${parsedData.length} exercises');
        for (final entry in parsedData.entries) {
          print('  - Exercise ${entry.key}: ${(entry.value as List).length} sets');
        }
      } else {
        print('❌ Data verification failed - no data found');
      }
      
    } catch (e) {
      print('💥 Error in test: $e');
    }
  }
}

