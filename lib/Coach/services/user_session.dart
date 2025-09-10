import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'role';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _emailKey = 'email';
  static const String _jwtTokenKey = 'jwt_token';

  // Get current user's numeric ID
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString(_userIdKey);
      
      if (userIdString != null && userIdString.isNotEmpty) {
        return int.tryParse(userIdString);
      }
      return null;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  // Get current coach's numeric ID (same as user ID for coaches)
  static Future<int?> getCurrentCoachId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_roleKey);
      
      // Only return ID if user is actually a coach
      if (role?.toLowerCase() == 'coach') {
        return await getCurrentUserId();
      }
      return null;
    } catch (e) {
      print('Error getting current coach ID: $e');
      return null;
    }
  }

  // Check if current user is a coach
  static Future<bool> isCurrentUserCoach() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_roleKey);
      return role?.toLowerCase() == 'coach';
    } catch (e) {
      print('Error checking if user is coach: $e');
      return false;
    }
  }

  // Get user role
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Get JWT token
  static Future<String?> getJwtToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_jwtTokenKey);
    } catch (e) {
      print('Error getting JWT token: $e');
      return null;
    }
  }

  // Clear all session data
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_jwtTokenKey);
    } catch (e) {
      print('Error clearing session: $e');
    }
  }
}
