import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalWeightsService {
  static const String _weightsKey = 'latest_exercise_weights';
  
  // Save latest weights for an exercise
  static Future<void> saveLatestWeights(int exerciseId, List<Map<String, dynamic>> weights) async {
    try {
      print('🔍 Saving weights for exercise $exerciseId: ${weights.length} sets');
      print('🔍 Weights data: ${json.encode(weights)}');
      
      final prefs = await SharedPreferences.getInstance();
      final weightsMap = await getLatestWeightsMap();
      
      weightsMap[exerciseId.toString()] = weights;
      
      print('🔍 Updated weights map: ${json.encode(weightsMap)}');
      
      await prefs.setString(_weightsKey, json.encode(weightsMap));
      print('✅ Saved latest weights for exercise $exerciseId: ${weights.length} sets');
    } catch (e) {
      print('💥 Error saving latest weights: $e');
    }
  }
  
  // Get latest weights for an exercise
  static Future<List<Map<String, dynamic>>> getLatestWeights(int exerciseId) async {
    try {
      print('🔍 Getting weights for exercise $exerciseId');
      final weightsMap = await getLatestWeightsMap();
      print('🔍 Current weights map: ${json.encode(weightsMap)}');
      
      final weights = weightsMap[exerciseId.toString()];
      
      if (weights != null) {
        print('✅ Found latest weights for exercise $exerciseId: ${weights.length} sets');
        print('🔍 Weights data: ${json.encode(weights)}');
        return List<Map<String, dynamic>>.from(weights);
      }
      
      print('⚠️ No latest weights found for exercise $exerciseId');
      return [];
    } catch (e) {
      print('💥 Error getting latest weights: $e');
      return [];
    }
  }
  
  // Get all latest weights
  static Future<Map<String, dynamic>> getLatestWeightsMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightsJson = prefs.getString(_weightsKey);
      
      print('🔍 LocalWeightsService: Looking for key: $_weightsKey');
      print('🔍 LocalWeightsService: Found data: $weightsJson');
      
      if (weightsJson != null) {
        final decoded = Map<String, dynamic>.from(json.decode(weightsJson));
        print('🔍 LocalWeightsService: Decoded data: ${json.encode(decoded)}');
        return decoded;
      }
      
      print('🔍 LocalWeightsService: No data found for key $_weightsKey');
      return {};
    } catch (e) {
      print('💥 Error getting latest weights map: $e');
      return {};
    }
  }
  
  // Clear all weights
  static Future<void> clearAllWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_weightsKey);
      print('✅ Cleared all latest weights');
    } catch (e) {
      print('💥 Error clearing weights: $e');
    }
  }
}
