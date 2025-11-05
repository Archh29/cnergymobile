import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userTypeKey = 'user_type';

  // Get current user ID
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId;
      
      // Try to get as int first - wrapped in try-catch because getInt throws if value is string
      try {
        userId = prefs.getInt(_userIdKey);
      } catch (e) {
        print('⚠️ user_id is not stored as int, trying as string: $e');
        userId = null; // Ensure it's null to trigger string fallback
      }
      
      // If not found or null, try to get as string and convert
      if (userId == null) {
        final userIdString = prefs.getString(_userIdKey);
        if (userIdString != null) {
          userId = int.tryParse(userIdString);
          // Convert back to int for future consistency
          if (userId != null) {
            await prefs.setInt(_userIdKey, userId);
          }
        }
      }
      
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

