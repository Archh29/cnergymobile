import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'api_error_handler.dart'; // Import error handler

class UserService {
  // Replace with your actual backend URL
  static const String baseUrl = 'https://api.cnergy.site/user.php';
  static const String userEndpoint = baseUrl; // Fixed: was pointing to baseUrl/user.php

  // HTTP client configuration similar to axios
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Axios-style GET request with better error handling
  static Future<Map<String, dynamic>?> _get(String url, {Map<String, String>? params}) async {
    try {
      Uri uri = Uri.parse(url);
      if (params != null) {
        uri = uri.replace(queryParameters: params);
      }
      print('GET Request: $uri');
      
      return await ApiErrorHandler.makeRequest(uri.toString(), headers: _headers);
    } catch (e) {
      print('GET Exception: $e');
      return {
        'success': false,
        'message': 'Request failed: ${e.toString()}',
        'error': 'REQUEST_EXCEPTION'
      };
    }
  }

  // Axios-style POST request with better error handling
  static Future<Map<String, dynamic>?> _post(String url, Map<String, dynamic> data) async {
    try {
      print('POST Request: $url');
      print('POST Data: ${json.encode(data)}');
      
      return await ApiErrorHandler.makeRequest(
        url,
        headers: _headers,
        body: json.encode(data),
        method: 'POST',
      );
    } catch (e) {
      print('POST Exception: $e');
      return {
        'success': false,
        'message': 'POST request failed: ${e.toString()}',
        'error': 'POST_EXCEPTION'
      };
    }
  }

  // FIXED: Fetch user data with better type handling
  static Future<UserModel?> fetchUser(dynamic userId) async {
    try {
      // Handle null userId
      if (userId == null) {
        print('Error: userId is null');
        return null;
      }

      // Convert userId to string to handle both int and String types
      String userIdString = userId.toString();
      print('Fetching user with ID: $userIdString');
      
      final response = await _get(userEndpoint, params: {
        'action': 'fetch',
        'user_id': userIdString,
      });

      if (response != null && response['success'] == true) {
        print('User data received: ${response['data']}');
        final userModel = UserModel.fromJson(response['data']);
        
        // ADDED: Update AuthService with fresh user data
        if (AuthService.getCurrentUserId() == userModel.id) {
          await AuthService.updateUserData(response['data']);
          print('✅ AuthService updated with fresh user data');
        }
        
        return userModel;
      } else {
        print('Error: ${response?['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Exception in fetchUser: $e');
      return null;
    }
  }

  // ADDED: Fetch current user from AuthService
  static Future<UserModel?> fetchCurrentUser() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      print('Error: No current user ID in AuthService');
      return null;
    }
    
    print('Fetching current user with ID: $userId');
    return await fetchUser(userId);
  }

  // ADDED: Get user data safely as strings for UI
  static Map<String, String> getCurrentUserStrings() {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      return {
        'id': '0',
        'fname': 'User',
        'lname': '',
        'mname': '',
        'email': '',
        'user_type_id': '0',
        'gender_id': '0',
        'bday': '',
      };
    }

    return {
      'id': (currentUser['id'] ?? 0).toString(),
      'fname': (currentUser['fname'] ?? 'User').toString(),
      'lname': (currentUser['lname'] ?? '').toString(),
      'mname': (currentUser['mname'] ?? '').toString(),
      'email': (currentUser['email'] ?? '').toString(),
      'user_type_id': (currentUser['user_type_id'] ?? 0).toString(),
      'gender_id': (currentUser['gender_id'] ?? 0).toString(),
      'bday': (currentUser['bday'] ?? '').toString(),
    };
  }

  // Update user data (only fields that exist in your database)
  static Future<bool> updateUser(UserModel user) async {
    try {
      final updateData = {
        'action': 'update',
        'id': user.id,
        'email': user.email,
        'user_type_id': user.userTypeId,
        'gender_id': user.genderId,
        'fname': user.fname,
        'mname': user.mname,
        'lname': user.lname,
        'bday': user.bday.toIso8601String().split('T')[0], // YYYY-MM-DD format
      };

      final response = await _post(userEndpoint, updateData);
      
      if (response != null && response['success'] == true) {
        print('User updated successfully');
        
        // ADDED: Update AuthService with new data
        if (AuthService.getCurrentUserId() == user.id) {
          await AuthService.updateUserData(user.toJson());
          print('✅ AuthService updated after user update');
        }
        
        return true;
      } else {
        print('Update failed: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Exception in updateUser: $e');
      return false;
    }
  }

  // FIXED: Update specific user fields with better error handling
  static Future<bool> updateUserFields(dynamic userId, Map<String, dynamic> fields) async {
    try {
      // Handle null userId
      if (userId == null) {
        print('Error: userId is null');
        return false;
      }

      // Convert userId to int
      int userIdInt;
      if (userId is int) {
        userIdInt = userId;
      } else if (userId is String) {
        userIdInt = int.tryParse(userId) ?? 0;
      } else {
        userIdInt = int.tryParse(userId.toString()) ?? 0;
      }

      if (userIdInt == 0) {
        print('Error: Invalid userId');
        return false;
      }

      // Only include fields that exist in your database
      final allowedFields = ['email', 'user_type_id', 'gender_id', 'fname', 'mname', 'lname', 'bday'];
      final filteredFields = <String, dynamic>{};
      
      fields.forEach((key, value) {
        if (allowedFields.contains(key) && value != null) {
          filteredFields[key] = value;
        }
      });

      if (filteredFields.isEmpty) {
        print('No valid fields to update');
        return false;
      }

      final updateData = {
        'action': 'update',
        'id': userIdInt,
        ...filteredFields,
      };

      final response = await _post(userEndpoint, updateData);
      
      if (response != null && response['success'] == true) {
        print('User fields updated successfully');
        
        // ADDED: Update AuthService if it's the current user
        if (AuthService.getCurrentUserId() == userIdInt) {
          await AuthService.updateUserData(filteredFields);
          print('✅ AuthService updated after field update');
        }
        
        return true;
      } else {
        print('Update failed: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Exception in updateUserFields: $e');
      return false;
    }
  }

  // Update premium status
  static Future<bool> updatePremiumStatus(dynamic userId, bool isPremium) async {
    try {
      if (userId == null) {
        print('Error: userId is null');
        return false;
      }

      final response = await _post(userEndpoint, {
        'action': 'update_premium',
        'user_id': userId.toString(),
        'is_premium': isPremium,
      });

      if (response != null && response['success'] == true) {
        print('Premium status updated successfully');
        
        // Update AuthService if it's the current user
        final currentUserId = AuthService.getCurrentUserId();
        if (currentUserId != null && currentUserId.toString() == userId.toString()) {
          await AuthService.updateUserData({'is_premium': isPremium});
          print('✅ AuthService updated with premium status');
        }
        
        return true;
      } else {
        print('Premium status update failed: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Exception in updatePremiumStatus: $e');
      return false;
    }
  }

  // Upload avatar/profile picture
  static Future<String?> uploadAvatar(dynamic userId, String imagePath) async {
    try {
      if (userId == null) {
        print('Error: userId is null');
        return null;
      }

      final uri = Uri.parse(userEndpoint);
      
      var request = http.MultipartRequest('POST', uri);
      request.fields['action'] = 'upload_avatar';
      request.fields['user_id'] = userId.toString();
      
      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('avatar', imagePath));
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('Upload Response: $responseBody');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(responseBody);
        
        if (jsonData['success'] == true) {
          final avatarUrl = jsonData['avatar_url'];
          
          // Update AuthService if it's the current user
          final currentUserId = AuthService.getCurrentUserId();
          if (currentUserId != null && currentUserId.toString() == userId.toString()) {
            await AuthService.updateUserData({'avatar_url': avatarUrl});
            print('✅ AuthService updated with avatar URL');
          }
          
          return avatarUrl;
        } else {
          print('Avatar upload failed: ${jsonData['message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception in uploadAvatar: $e');
      return null;
    }
  }

  // Delete user account
  static Future<bool> deleteUser(dynamic userId) async {
    try {
      if (userId == null) {
        print('Error: userId is null');
        return false;
      }

      final response = await _post(userEndpoint, {
        'action': 'delete',
        'user_id': userId.toString(),
      });

      if (response != null && response['success'] == true) {
        print('User deleted successfully');
        
        // Clear AuthService if it's the current user
        final currentUserId = AuthService.getCurrentUserId();
        if (currentUserId != null && currentUserId.toString() == userId.toString()) {
          await AuthService.clearCurrentUser();
          print('✅ AuthService cleared after user deletion');
        }
        
        return true;
      } else {
        print('Delete failed: ${response?['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Exception in deleteUser: $e');
      return false;
    }
  }

  // Fetch user types (for dropdown/selection)
  static Future<List<UserType>> fetchUserTypes() async {
    try {
      // You'll need to create a separate endpoint for this or modify your PHP
      final response = await _get('$baseUrl/user_types.php');
      
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => UserType.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Exception in fetchUserTypes: $e');
      return [];
    }
  }

  // Fetch genders (for dropdown/selection)
  static Future<List<Gender>> fetchGenders() async {
    try {
      // You'll need to create a separate endpoint for this or modify your PHP
      final response = await _get('$baseUrl/genders.php');
      
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'];
        return data.map((json) => Gender.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Exception in fetchGenders: $e');
      return [];
    }
  }
}
