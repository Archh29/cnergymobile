import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GymUtilsService {
  // Safe JSON parsing
  static Map<String, dynamic> safeJsonDecode(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      print('JSON decode error: $e');
      return {};
    }
  }

  // Safe integer parsing
  static int safeParseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Safe double parsing
  static double safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Safe boolean parsing
  static bool safeParseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return defaultValue;
  }

  // Safe DateTime parsing
  static DateTime? safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  // Format date for API
  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  // Format datetime for API
  static String formatDateTimeForApi(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Get stored auth token
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Store auth token
  static Future<bool> setAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('auth_token', token);
    } catch (e) {
      print('Error setting auth token: $e');
      return false;
    }
  }

  // Clear all stored data
  static Future<bool> clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing stored data: $e');
      return false;
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Calculate BMI
  static double calculateBMI(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0.0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  // Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  // Format duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Validate password strength
  static Map<String, dynamic> validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    final score = [hasMinLength, hasUppercase, hasLowercase, hasNumbers, hasSpecialChars]
        .where((criteria) => criteria)
        .length;
    
    String strength;
    if (score <= 2) {
      strength = 'Weak';
    } else if (score <= 3) {
      strength = 'Medium';
    } else {
      strength = 'Strong';
    }
    
    return {
      'isValid': score >= 3,
      'strength': strength,
      'score': score,
      'criteria': {
        'minLength': hasMinLength,
        'uppercase': hasUppercase,
        'lowercase': hasLowercase,
        'numbers': hasNumbers,
        'specialChars': hasSpecialChars,
      }
    };
  }

  // Generate workout heatmap data
  static Map<DateTime, int> generateHeatmapData(List<Map<String, dynamic>> workoutSessions, int days) {
    final Map<DateTime, int> heatmapData = {};
    final now = DateTime.now();
    
    // Initialize all days with 0
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      heatmapData[dateKey] = 0;
    }
    
    // Count workouts per day
    for (final session in workoutSessions) {
      final sessionDate = safeParseDateTime(session['session_date']);
      if (sessionDate != null) {
        final dateKey = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
        if (heatmapData.containsKey(dateKey)) {
          heatmapData[dateKey] = (heatmapData[dateKey] ?? 0) + 1;
        }
      }
    }
    
    return heatmapData;
  }
}
