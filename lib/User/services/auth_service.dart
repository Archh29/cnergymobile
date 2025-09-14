import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/onboarding_service.dart';

class AuthService {
  static int? _currentUserId;
  static Map<String, dynamic>? _currentUser;
  static const String _userIdKey = 'current_user_id';
  static const String _userDataKey = 'current_user_data';
  static const String _profileCompletedKey = 'profile_completed';
  static const String baseUrl = 'https://api.cnergy.site/user.php';
    
  // Add initialization status tracking
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  // Initialize auth service - call this in main() or app startup
  static Future<void> initialize() async {
    print('🔄 Initializing AuthService...');
    await _loadUserFromStorage();
        
    // If ID is saved but user data is missing, fetch it
    if (_currentUserId != null && _currentUser == null) {
      print('📡 User ID found but data missing, fetching from server...');
      try {
        await _fetchUserFromServer(_currentUserId!);
      } catch (e) {
        print('❌ Failed to fetch user data during initialization: $e');
        // Don't clear user data here, just log the error
      }
    }
        
    _isInitialized = true;
        
    // Debug logging
    print('✅ AuthService initialized');
    print('👤 Current User ID: $_currentUserId');
    print('📊 Current User Data: ${_currentUser != null ? 'Available' : 'Not Available'}');
    print('🔐 Is Logged In: ${isLoggedIn()}');
        
    // Only check profile completion if user is logged in
    if (isLoggedIn()) {
      try {
        print('📋 Profile Completed: ${await isProfileCompleted()}');
        print('🔐 Account Status: ${getAccountStatus()}');
      } catch (e) {
        print('❌ Error checking profile completion during init: $e');
      }
    }
  }

  // Load from SharedPreferences
  static Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIdKey);
      final userDataString = prefs.getString(_userDataKey);
            
      print('📱 Retrieved user ID from SharedPreferences: $userId');
            
      if (userId != null) {
        _currentUserId = userId;
        print('🆔 Loading user data for ID: $userId');
                
        if (userDataString != null) {
          _currentUser = json.decode(userDataString);
          print('✅ User data loaded from storage');
        } else {
          print('⚠️ User ID found but no user data in storage');
        }
      } else {
        print('❌ No user ID found in storage');
      }
    } catch (e) {
      print('❌ Error loading user from storage: $e');
    }
  }

  // Fetch user from server by ID
  static Future<void> _fetchUserFromServer(int userId) async {
    try {
      final url = Uri.parse('$baseUrl?action=fetch&user_id=$userId');
      print('📡 Fetching user from backend: $url');
            
      final response = await http.get(url);
            
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
                
        if (jsonResponse['success'] == true) {
          final userData = jsonResponse['data'];
          
          // Update both user ID and data
          _currentUserId = userId;
          _currentUser = userData;
          
          // Save to storage
          await _saveUserToStorage();
          
          print('✅ User data fetched and saved successfully');
          print('📊 Account Status: ${userData['account_status']}');
        } else {
          print('❌ Backend error: ${jsonResponse['message']}');
          // If server says user doesn't exist, clear local data
          await clearCurrentUser();
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to fetch user from server: $e');
      throw e; // Re-throw to handle in calling method
    }
  }

  // Save user data to SharedPreferences
  static Future<void> _saveUserToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null && _currentUser != null) {
        await prefs.setInt(_userIdKey, _currentUserId!);
        await prefs.setString(_userDataKey, json.encode(_currentUser!));
        print('💾 User data saved to storage');
      }
    } catch (e) {
      print('❌ Error saving user to storage: $e');
    }
  }

  static int _getUserTypeFromString(String userType) {
    switch (userType.toLowerCase()) {
      case 'admin': return 1;
      case 'staff': return 2;
      case 'coach': return 3;
      case 'customer':
      case 'member': return 4;
      default: return 0;
    }
  }

  // Helper method to get user type as integer
  static int _getUserTypeAsInt(Map<String, dynamic> user) {
    var userType = user['user_type_id'];
    if (userType != null) {
      if (userType is int) return userType;
      if (userType is String) {
        int? parsed = int.tryParse(userType);
        if (parsed != null) return parsed;
      }
    }
        
    userType = user['user_type'];
    if (userType != null) {
      if (userType is int) return userType;
      if (userType is String) {
        int? parsed = int.tryParse(userType);
        if (parsed != null) return parsed;
        
        return _getUserTypeFromString(userType);
      }
    }

    userType = user['user_role'];
    if (userType != null && userType is String) {
      return _getUserTypeFromString(userType);
    }
        
    return 0;
  }

  // Get account status
  static String getAccountStatus() {
    if (_currentUser == null) return 'unknown';
    return _currentUser!['account_status'] ?? 'pending';
  }

  // Check if account is approved
  static bool isAccountApproved() {
    if (_currentUser == null) return false;
    
    final userType = _getUserTypeAsInt(_currentUser!);
    
    // Non-customers are automatically considered "approved" for account verification
    if (userType != 4) {
      return true;
    }
    
    // For customers, check actual status
    return getAccountStatus() == 'approved';
  }

  // Check if account is pending
  static bool isAccountPending() {
    if (_currentUser == null) return false;
    
    final userType = _getUserTypeAsInt(_currentUser!);
    
    // Non-customers never have pending status
    if (userType != 4) {
      return false;
    }
    
    // For customers, check actual status
    return getAccountStatus() == 'pending';
  }

  // Check if account is rejected
  static bool isAccountRejected() {
    if (_currentUser == null) return false;
    
    final userType = _getUserTypeAsInt(_currentUser!);
    
    // Non-customers never have rejected status
    if (userType != 4) {
      return false;
    }
    
    // For customers, check actual status
    return getAccountStatus() == 'rejected';
  }

  // NEW: Add the missing checkAccountStatusFromServer method
  static Future<String> checkAccountStatusFromServer() async {
    if (_currentUserId != null) {
      try {
        print('🔄 Checking account status from server for user: $_currentUserId');
        await _fetchUserFromServer(_currentUserId!);
        final status = getAccountStatus();
        print('📊 Account status from server: $status');
        return status;
      } catch (e) {
        print('❌ Error checking account status from server: $e');
        return 'unknown';
      }
    }
    print('❌ Cannot check account status: no current user ID');
    return 'unknown';
  }

  // Check if current user's profile is completed
  static Future<bool> isProfileCompleted() async {
    try {
      if (_currentUser == null) {
        print('❌ No current user for profile completion check');
        return false;
      }
            
      final userType = _getUserTypeAsInt(_currentUser!);
      print('🔍 Checking profile completion for user type: $userType');
            
      // Only customers (user_type_id = 4) need profile completion
      if (userType != 4) {
        print('✅ Non-customer user, profile completion not required');
        return true;
      }
            
      // Check local storage first
      final prefs = await SharedPreferences.getInstance();
      final localProfileCompleted = prefs.getBool(_profileCompletedKey) ?? false;
            
      // Also check user data for profile completion flags
      final userProfileCompleted = _currentUser!['profile_completed'] == true ||
                                  _currentUser!['profile_completed'] == 1 ||
                                  _currentUser!['profileCompleted'] == true ||
                                  _currentUser!['profileCompleted'] == 1;
            
      if (localProfileCompleted || userProfileCompleted) {
        print('✅ Profile marked as completed in local storage or user data');
        return true;
      }
            
      // If not in local storage, check with backend
      final userId = _currentUserId;
      if (userId != null) {
        print('📡 Checking profile completion with backend for user: $userId');
        try {
          final onboardingService = OnboardingService();
          final response = await onboardingService.checkUserEligibility(userId);
                
          if (response.success) {
            // If user doesn't need setup, profile is completed
            final needsSetup = response.data ?? false;
            final isCompleted = !needsSetup;
                    
            print('🔍 Backend says needs setup: $needsSetup, completed: $isCompleted');
                    
            // Cache the result
            await prefs.setBool(_profileCompletedKey, isCompleted);
                    
            // Update user data
            if (isCompleted) {
              _currentUser!['profile_completed'] = true;
              _currentUser!['profileCompleted'] = true;
              await _saveUserToStorage();
            }
                    
            return isCompleted;
          } else {
            print('❌ Failed to check profile completion with backend: ${response.message}');
          }
        } catch (e) {
          print('❌ Error calling onboarding service: $e');
        }
      }
            
      print('❌ Profile completion check failed, defaulting to false');
      return false;
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      return false;
    }
  }

  // Mark profile as completed
  static Future<void> markProfileCompleted() async {
    try {
      print('✅ Marking profile as completed');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_profileCompletedKey, true);
            
      // Update current user data
      if (_currentUser != null) {
        _currentUser!['profile_completed'] = true;
        _currentUser!['profileCompleted'] = true;
        await _saveUserToStorage();
        print('💾 Profile completion status saved to user data');
      }
    } catch (e) {
      print('❌ Error marking profile as completed: $e');
    }
  }

  // Get user type as string
  static String getUserType() {
    if (_currentUser == null) return 'unknown';
        
    final userTypeId = _getUserTypeAsInt(_currentUser!);
    switch (userTypeId) {
      case 1: return 'admin';
      case 2: return 'staff';
      case 3: return 'coach';
      case 4: return 'customer';
      default: return 'unknown';
    }
  }

  // Check if user is customer
  static bool isCustomer() {
    return _getUserTypeAsInt(_currentUser ?? {}) == 4;
  }

  // Check if user is coach
  static bool isCoach() {
    return _getUserTypeAsInt(_currentUser ?? {}) == 3;
  }

  // Check if user is admin
  static bool isAdmin() {
    return _getUserTypeAsInt(_currentUser ?? {}) == 1;
  }

  // Check if user is staff
  static bool isStaff() {
    return _getUserTypeAsInt(_currentUser ?? {}) == 2;
  }

  // Method to check if user needs first-time setup
  static Future<bool> needsFirstTimeSetup() async {
    if (!isLoggedIn() || !isCustomer()) {
      return false;
    }
        
    final profileCompleted = await isProfileCompleted();
    final needsSetup = !profileCompleted;
        
    print('🔍 User needs first-time setup: $needsSetup');
    return needsSetup;
  }

  static int? getCurrentUserId() => _currentUserId;
  static Map<String, dynamic>? getCurrentUser() => _currentUser;

  static String getUserFirstName() {
    if (_currentUser == null) return 'User';
    return _currentUser!['fname'] ?? _currentUser!['first_name'] ?? 'User';
  }

  static String getUserFullName() {
    if (_currentUser == null) return 'User';
    final fname = _currentUser!['fname'] ?? '';
    final lname = _currentUser!['lname'] ?? '';
    return ('$fname $lname').trim().isEmpty ? 'User' : ('$fname $lname').trim();
  }

  static String getUserEmail() {
    if (_currentUser == null) return '';
    return _currentUser!['email'] ?? '';
  }

  static Future<void> setCurrentUser(int userId, Map<String, dynamic> userData) async {
    _currentUserId = userId;
    _currentUser = userData;
    
    final userTypeInt = _getUserTypeAsInt(userData);
    _currentUser!['user_type_id'] = userTypeInt;
    
    await _saveUserToStorage();
    print('👤 Current user set: ID=$userId, Name=${getUserFirstName()}, Type=${getUserType()}, Status=${getAccountStatus()}');
  }

  static Future<void> clearCurrentUser() async {
    print('🧹 Clearing current user data');
    _currentUserId = null;
    _currentUser = null;
        
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_profileCompletedKey);
        
    print('🧹 All user data cleared from storage');
  }

  // Logout method
  static Future<void> logout() async {
    print('🚪 Logging out user...');
    await clearCurrentUser();
        
    // Also clear any additional logout-specific data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('role');
    await prefs.remove('jwt_token');
    
    // Clear routine service cache
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId != null) {
        String membershipKey = 'is_pro_member_$currentUserId';
        String subscriptionKey = 'subscription_details_$currentUserId';
        String lastCheckedKey = 'membership_last_checked_$currentUserId';
        
        await prefs.remove(membershipKey);
        await prefs.remove(subscriptionKey);
        await prefs.remove(lastCheckedKey);
        
        print('🗑️ Cleared routine service cache on logout');
      }
    } catch (e) {
      print('⚠️ Error clearing routine service cache: $e');
    }
        
    print('✅ User logged out successfully');
  }

  static bool isLoggedIn() {
    final loggedIn = _currentUserId != null && _currentUser != null;
    print('🔐 Checking login status: $loggedIn (UserID: $_currentUserId, UserData: ${_currentUser != null})');
    return loggedIn;
  }

  static bool isUserMember() {
    if (_currentUser == null) return false;
    // Only check for actual membership indicators, not just customer status
    return _currentUser!['user_type'] == 'member' ||
           _currentUser!['is_member'] == true ||
           _currentUser!['is_member'] == 1 ||
           _currentUser!['membership_status'] == 'active' ||
           _currentUser!['member_status'] == 'active' ||
           _currentUser!['has_active_membership'] == true ||
           _currentUser!['has_active_membership'] == 1;
  }

  static String getMembershipStatus() {
    if (_currentUser == null) return 'Not a member';
    return isUserMember() ? 'Active Member' : 'Not a member';
  }

  static Future<void> updateUserData(Map<String, dynamic> newUserData) async {
    if (_currentUser != null) {
      _currentUser!.addAll(newUserData);
      await _saveUserToStorage();
      print('📝 User data updated: ${newUserData.keys.join(', ')}');
    }
  }

  // Refresh user data from server
  static Future<bool> refreshUserData() async {
    if (_currentUserId != null) {
      print('🔄 Refreshing user data for ID: $_currentUserId');
      try {
        await _fetchUserFromServer(_currentUserId!);
        
        // Verify the data was actually updated
        final newAccountStatus = getAccountStatus();
        print('✅ User data refreshed - New Account Status: $newAccountStatus');
        
        return isLoggedIn();
      } catch (e) {
        print('❌ Error refreshing user data: $e');
        return false;
      }
    }
    print('❌ Cannot refresh user data: no current user ID');
    return false;
  }

  // Debug method to print all user data
  static void debugPrintUserData() {
    print('=== AuthService Debug Info ===');
    print('Initialized: $_isInitialized');
    print('Logged In: ${isLoggedIn()}');
    print('User ID: $_currentUserId');
    print('User Type: ${getUserType()}');
    print('User Name: ${getUserFullName()}');
    print('User Email: ${getUserEmail()}');
    print('Account Status: ${getAccountStatus()}');
    print('Is Customer: ${isCustomer()}');
    print('Is Coach: ${isCoach()}');
    print('Is Admin: ${isAdmin()}');
    print('Is Staff: ${isStaff()}');
    print('User Data: $_currentUser');
    print('==============================');
  }

  // NEW: Check if user needs account verification (only customers)
  static bool needsAccountVerification() {
    if (_currentUser == null) return false;
    
    final userType = _getUserTypeAsInt(_currentUser!);
    print('🔍 Checking if user type $userType needs account verification');
    
    // Only customers (user_type_id = 4) need account verification
    if (userType != 4) {
      print('✅ Non-customer user, account verification not required');
      return false;
    }
    
    // For customers, check if account is not approved
    final status = getAccountStatus();
    final needsVerification = status != 'approved';
    print('📊 Customer account status: $status, needs verification: $needsVerification');
    
    return needsVerification;
  }
}
