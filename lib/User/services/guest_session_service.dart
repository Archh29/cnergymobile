import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuestSessionService {
  static const String baseUrl = 'https://api.cnergy.site';
  
  // Create a new guest session
  static Future<Map<String, dynamic>> createGuestSession({
    required String guestName,
    required String guestType,
    required double amountPaid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/guest_session_api.php'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'action': 'create_guest_session',
          'guest_name': guestName,
          'guest_type': guestType,
          'amount_paid': amountPaid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Check guest session status
  static Future<Map<String, dynamic>> checkGuestSessionStatus(String qrToken) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/guest_session_api.php?action=check_status&qr_token=$qrToken'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Get guest session by ID
  static Future<Map<String, dynamic>> getGuestSession(dynamic sessionId) async {
    try {
      // Convert sessionId to string for URL
      final sessionIdStr = sessionId.toString();
      final response = await http.get(
        Uri.parse('$baseUrl/guest_session_api.php?action=get_session&session_id=$sessionIdStr'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Save guest session data locally
  static Future<void> saveGuestSessionData(Map<String, dynamic> sessionData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_session_data', jsonEncode(sessionData));
  }

  // Get guest session data from local storage
  static Future<Map<String, dynamic>?> getGuestSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionDataString = prefs.getString('guest_session_data');
    if (sessionDataString != null) {
      return jsonDecode(sessionDataString);
    }
    return null;
  }

  // Clear guest session data
  static Future<void> clearGuestSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guest_session_data');
  }

  // Check if guest session is still valid (not expired)
  static bool isGuestSessionValid(Map<String, dynamic> sessionData) {
    try {
      final validUntil = DateTime.parse(sessionData['valid_until']);
      final now = DateTime.now();
      return now.isBefore(validUntil);
    } catch (e) {
      return false;
    }
  }

}
