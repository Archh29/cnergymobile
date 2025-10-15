import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugWeightsTest {
  static Future<void> testWeights() async {
    try {
      print('🔍 Testing weights for user 61, exercise 23...');
      
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/debug_weights.php?user_id=61&exercise_id=23'),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Debug response status: ${response.statusCode}');
      print('📋 Debug response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Debug data received:');
        print('  - Logged sets count: ${data['logged_sets_count']}');
        print('  - Program weights count: ${data['program_weights_count']}');
        print('  - Logged sets: ${json.encode(data['logged_sets'])}');
        print('  - Program weights: ${json.encode(data['program_weights'])}');
      }
    } catch (e) {
      print('💥 Error testing weights: $e');
    }
  }
}






