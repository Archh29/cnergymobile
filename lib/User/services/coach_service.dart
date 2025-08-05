import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coach_model.dart';

class CoachService {
  // Use 10.0.2.2 if running from Android Emulator
  static const String baseUrl = 'http://localhost/cynergy/coach_api.php';

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
        final List<dynamic> coachesJson = data['coaches'] ?? [];
        return coachesJson.map((json) => CoachModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load coaches: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coaches: $e');
      return _getMockCoaches();
    }
  }

  /// Send coach hire request - Modified to use coach_member_list table
  static Future<bool> sendCoachRequest({
    required int userId,
    required int coachId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=hire-coach'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'member_id': userId,
          'coach_id': coachId,
          'message': message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error sending coach request: $e');
      return false;
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
        hourlyRate: 75.0,
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
        hourlyRate: 65.0,
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
        hourlyRate: 85.0,
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
        hourlyRate: 60.0,
        certifications: ['FMS', 'SFMA', 'TRX'],
      ),
    ];
  }
}