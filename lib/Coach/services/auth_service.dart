import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';

  // Get current user ID
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIdKey);
      return userId;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Get current user type
  static Future<String?> getCurrentUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userType = prefs.getString(_userTypeKey);
      return userType;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await getCurrentUserId();
    return userId != null;
  }

  // Check if user is a coach
  static Future<bool> isCoach() async {
    final userType = await getCurrentUserType();
    return userType == 'coach';
  }

  // Check if user is a member
  static Future<bool> isMember() async {
    final userType = await getCurrentUserType();
    return userType == 'member';
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userTypeKey);
    } catch (e) {
      print('Error logging out: $e');
    }
  }
}

