import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordRecoveryService {
  static const String baseUrl = 'https://api.cnergy.site';

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Send reset code to email
  static Future<Map<String, dynamic>> sendResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password_recovery.php?action=send_reset_code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to send reset code. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Verify reset code
  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password_recovery.php?action=verify_reset_code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Invalid or expired code. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Resend reset code
  static Future<Map<String, dynamic>> resendResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password_recovery.php?action=resend_code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to resend code. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Validate password strength
  static Map<String, dynamic> validatePassword(String password) {
    List<String> errors = [];
    
    if (password.length < 8) {
      errors.add('At least 8 characters');
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('1 uppercase letter');
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('1 lowercase letter');
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('1 number');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('1 symbol');
    }
    
    if (errors.isEmpty) {
      return {
        'isValid': true,
        'message': 'Password is valid',
        'strength': 'strong',
        'errors': [],
      };
    } else {
      return {
        'isValid': false,
        'message': 'Password must contain: ${errors.join(', ')}',
        'strength': errors.length > 3 ? 'weak' : errors.length > 2 ? 'medium' : 'strong',
        'errors': errors,
      };
    }
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password_recovery.php?action=reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to reset password. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}
