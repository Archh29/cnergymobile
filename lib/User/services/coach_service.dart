import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coach_model.dart';

class CoachService {
  // Use 10.0.2.2 if running from Android Emulator
  static const String baseUrl = 'https://api.cnergy.site/coach_api.php';

  /// Fetch all available coaches
  static Future<List<CoachModel>> fetchCoaches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=coaches'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> coachesJson = data['coaches'] ?? [];
          return coachesJson.map((json) => CoachModel.fromJson(json)).toList();
        } else {
          throw Exception('API Error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load coaches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coaches: $e');
      rethrow; // Re-throw instead of returning mock data
    }
  }

  /// Send coach hire request - Modified to use coach_member_list table with rate selection
  static Future<Map<String, dynamic>> sendCoachRequest({
    required int userId,
    required int coachId,
    required String rateType,
    required double rate,
    int? sessionCount,
  }) async {
    try {
      print('🔄 Sending coach request - User ID: $userId, Coach ID: $coachId, Rate Type: $rateType, Rate: $rate, Session Count: $sessionCount');
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=hire-coach'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'member_id': userId,
          'coach_id': coachId,
          'rate_type': rateType,
          'rate': rate,
          'session_count': sessionCount,
        }),
      );

      print('📡 Coach request response status: ${response.statusCode}');
      print('📄 Coach request response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('✅ Coach request response data: $responseData');
        
        if (responseData['success'] == true) {
          print('✅ Coach request sent successfully');
          return {'success': true, 'message': responseData['message'] ?? 'Request sent successfully'};
        } else {
          print('❌ Coach request failed: ${responseData['message'] ?? 'Unknown error'}');
          return {'success': false, 'message': responseData['message'] ?? 'Unknown error'};
        }
      } else {
        print('❌ Coach request HTTP error: ${response.statusCode}');
        return {'success': false, 'message': 'Network error. Please try again.'};
      }
    } catch (e) {
      print('❌ Error sending coach request: $e');
      return {'success': false, 'message': 'Error sending request: $e'};
    }
  }

  /// Get user's coach request status
  static Future<Map<String, dynamic>?> getUserCoachRequest(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=user-coach-status&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching coach request: $e');
      return null;
    }
  }

  /// Deduct session usage for session packages
  static Future<Map<String, dynamic>?> deductSessionUsage({
    required int userId,
    required int coachId,
  }) async {
    try {
      print('🔄 Deducting session usage - User ID: $userId, Coach ID: $coachId');
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=deduct-session'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'member_id': userId,
          'coach_id': coachId,
        }),
      );

      print('📡 Session deduction response status: ${response.statusCode}');
      print('📄 Session deduction response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Session deduction response data: $responseData');
        return responseData;
      } else {
        print('❌ Session deduction HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error deducting session usage: $e');
      return null;
    }
  }

  /// Mock data for development (remove in production)
  static List<CoachModel> _getMockCoaches() {
    return [
      CoachModel(
        id: 1,
        name: 'Mike Johnson',
        specialty: 'Strength Training',
        experience: '8 years',
        rating: 4.9,
        totalClients: 127,
        bio: 'Certified strength and conditioning specialist with expertise in powerlifting and functional movement.',
        imageUrl: '',
        isAvailable: true,
        sessionRate: 75.0,
        certifications: ['NASM-CPT', 'CSCS', 'FMS'],
      ),
      CoachModel(
        id: 2,
        name: 'Sarah Williams',
        specialty: 'Weight Loss',
        experience: '6 years',
        rating: 4.8,
        totalClients: 89,
        bio: 'Nutrition and fitness expert specializing in sustainable weight loss and lifestyle transformation.',
        imageUrl: '',
        isAvailable: true,
        sessionRate: 65.0,
        certifications: ['ACE-CPT', 'Precision Nutrition'],
      ),
      CoachModel(
        id: 3,
        name: 'David Chen',
        specialty: 'Bodybuilding',
        experience: '10 years',
        rating: 4.9,
        totalClients: 156,
        bio: 'Former competitive bodybuilder with extensive experience in muscle building and contest preparation.',
        imageUrl: '',
        isAvailable: false,
        sessionRate: 85.0,
        certifications: ['IFBB Pro Card', 'NASM-CPT'],
      ),
      CoachModel(
        id: 4,
        name: 'Lisa Rodriguez',
        specialty: 'Functional Fitness',
        experience: '5 years',
        rating: 4.7,
        totalClients: 73,
        bio: 'Movement specialist focused on functional training, mobility, and injury prevention.',
        imageUrl: '',
        isAvailable: true,
        sessionRate: 60.0,
        certifications: ['FMS', 'SFMA', 'TRX'],
      ),
    ];
  }
}