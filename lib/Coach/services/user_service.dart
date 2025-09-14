import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService {
  static const String baseUrl = 'https://api.cnergy.site/user.php';
  
  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get authenticated headers with token
  static Future<Map<String, String>> get _authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = Map<String, String>.from(_headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Fetch user by ID
  static Future<UserModel?> fetchUser(int userId) async {
    try {
      print('Fetching user with ID: $userId');
      
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        } else if (data['data'] != null) {
          // Alternative response structure
          return UserModel.fromJson(data['data']);
        } else {
          // Direct user data
          return UserModel.fromJson(data);
        }
      } else if (response.statusCode == 404) {
        print('User not found');
        return null;
      } else {
        print('Error fetching user: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchUser: $e');
      
      // Return mock data for development/testing
      if (userId == 1) {
        return UserModel(
          id: 1,
          fname: 'John',
          mname: 'Michael',
          lname: 'Smith',
          email: 'coach.john@gym.com',
          bday: DateTime(1985, 5, 15),
          role: 'coach',
          createdAt: DateTime.now().subtract(Duration(days: 365)),
          profileImage: null,
          isActive: true,
          preferences: {
            'notifications': true,
            'theme': 'dark',
            'language': 'en',
          },
          metadata: {
            'specialization': 'Strength Training',
            'experience_years': 8,
            'certifications': ['NASM-CPT', 'CSCS'],
          },
        );
      }
      
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Fetch current authenticated user
  static Future<UserModel?> fetchCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdString = prefs.getString('user_id');
      
      if (userIdString == null) {
        throw Exception('No user ID found in preferences');
      }
      
      final userId = int.tryParse(userIdString);
      if (userId == null) {
        throw Exception('Invalid user ID format');
      }
      
      return await fetchUser(userId);
    } catch (e) {
      print('Error fetching current user: $e');
      throw Exception('Failed to fetch current user: $e');
    }
  }

  // Update user profile
  static Future<UserModel?> updateUser(int userId, Map<String, dynamic> updates) async {
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        } else if (data['data'] != null) {
          return UserModel.fromJson(data['data']);
        }
      }
      
      throw Exception('Failed to update user: ${response.statusCode}');
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Update user profile picture
  static Future<String?> updateProfilePicture(int userId, String imagePath) async {
    try {
      final headers = await _authHeaders;
      headers.remove('Content-Type'); // Let http handle multipart content type
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/profile-picture'),
      );
      
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('profile_image', imagePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['profile_image_url'] != null) {
          return data['profile_image_url'];
        }
      }
      
      throw Exception('Failed to update profile picture: ${response.statusCode}');
    } catch (e) {
      print('Error updating profile picture: $e');
      throw Exception('Failed to update profile picture: $e');
    }
  }

  // Change user password
  static Future<bool> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/change-password'),
        headers: headers,
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Get user preferences
  static Future<Map<String, dynamic>?> getUserPreferences(int userId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/preferences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['preferences'] != null) {
          return Map<String, dynamic>.from(data['preferences']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching user preferences: $e');
      return null;
    }
  }

  // Update user preferences
  static Future<bool> updateUserPreferences(int userId, Map<String, dynamic> preferences) async {
    try {
      final headers = await _authHeaders;
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/preferences'),
        headers: headers,
        body: json.encode({'preferences': preferences}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // Delete user account
  static Future<bool> deleteUser(int userId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Search users (for admin/coach functionality)
  static Future<List<UserModel>> searchUsers(String query, {String? role, int limit = 20}) async {
    try {
      final headers = await _authHeaders;
      final queryParams = {
        'q': query,
        'limit': limit.toString(),
      };
      
      if (role != null) {
        queryParams['role'] = role;
      }
      
      final uri = Uri.parse('$baseUrl/users/search').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['users'] != null) {
          return (data['users'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList();
        } else if (data['data'] != null) {
          return (data['data'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get users by role
  static Future<List<UserModel>> getUsersByRole(String role, {int limit = 50}) async {
    try {
      final headers = await _authHeaders;
      final queryParams = {
        'role': role,
        'limit': limit.toString(),
      };
      
      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['users'] != null) {
          return (data['users'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList();
        } else if (data['data'] != null) {
          return (data['data'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Validate user session
  static Future<bool> validateSession() async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }

  // Logout user
  static Future<bool> logout() async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: headers,
      );

      // Clear local storage regardless of API response
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('isLoggedIn', false);
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error during logout: $e');
      
      // Still clear local storage on error
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setBool('isLoggedIn', false);
      
      return false;
    }
  }

  // Get user statistics (for coaches/admins)
  static Future<Map<String, dynamic>?> getUserStatistics(int userId) async {
    try {
      final headers = await _authHeaders;
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['statistics'] != null) {
          return Map<String, dynamic>.from(data['statistics']);
        } else if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching user statistics: $e');
      return null;
    }
  }
}
