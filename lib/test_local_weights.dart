import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './User/services/local_weights_service.dart';

class TestLocalWeights {
  static Future<void> testLocalWeights() async {
    try {
      print('🧪 === TESTING LOCAL WEIGHTS SERVICE ===');
      
      // Test data
      final testWeights = [
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
      ];
      
      // Save using LocalWeightsService
      await LocalWeightsService.saveLatestWeights(23, testWeights);
      print('✅ Saved test weights using LocalWeightsService');
      
      // Retrieve using LocalWeightsService
      final retrievedWeights = await LocalWeightsService.getLatestWeights(23);
      print('✅ Retrieved weights: ${retrievedWeights.length} sets');
      for (final weight in retrievedWeights) {
        print('  - ${weight['reps']} reps x ${weight['weight']}kg');
      }
      
      // Also test direct SharedPreferences access
      final prefs = await SharedPreferences.getInstance();
      final directData = prefs.getString('latest_exercise_weights');
      print('🔍 Direct SharedPreferences data: $directData');
      
    } catch (e) {
      print('💥 Error in test: $e');
    }
  }
}

