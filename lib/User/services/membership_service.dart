import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MembershipService {
  static const String baseUrl = 'http://localhost/cynergy/';
  static const String membershipEndpoint = '${baseUrl}membership_info.php';

  // Get membership information
  static Future<Map<String, dynamic>> getMembershipInfo() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$membershipEndpoint?action=get_membership&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Get membership response status: ${response.statusCode}');
      print('Get membership response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting membership info: $e');
      rethrow;
    }
  }
}
