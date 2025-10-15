import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription_model.dart';
import 'auth_service.dart';

class SubscriptionService {
  static const String baseUrl = 'https://api.cnergy.site/subscription_history.php';
  static const String subscriptionBaseUrl = 'https://api.cnergy.site/subscription_plans.php';

  // Get subscription history for a user
  static Future<Map<String, dynamic>?> getSubscriptionHistory(int userId) async {
    try {
      print('Debug: Getting subscription history for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=get-subscription-history&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Subscription history response status: ${response.statusCode}');
      print('Debug: Subscription history response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Debug: Successfully decoded subscription history JSON response');
          if (data['success'] == true) {
            return data;
          } else {
            print('Error: ${data['message']}');
            return null;
          }
        } catch (e) {
          print('Error decoding subscription history JSON response: $e');
          print('Response body: ${response.body}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting subscription history: $e');
      return null;
    }
  }

  // Get current subscription status
  static Future<Map<String, dynamic>?> getCurrentSubscription(int userId) async {
    try {
      print('Debug: Getting current subscription for user: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=get-current-subscription&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Current subscription response status: ${response.statusCode}');
      print('Debug: Current subscription response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Debug: Successfully decoded current subscription JSON response');
          if (data['success'] == true) {
            // If there's an active coach, get more detailed coach data
            if (data['active_coach'] != null) {
              final coachId = data['active_coach']['coach_id'];
              if (coachId != null) {
                final detailedCoachData = await _getDetailedCoachData(userId, coachId);
                if (detailedCoachData != null) {
                  data['active_coach'] = detailedCoachData;
                }
              }
            }
            return data;
          } else {
            print('Error: ${data['message']}');
            return null;
          }
        } catch (e) {
          print('Error decoding current subscription JSON response: $e');
          print('Response body: ${response.body}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current subscription: $e');
      return null;
    }
  }

  // Get detailed coach data including start date
  static Future<Map<String, dynamic>?> _getDetailedCoachData(int userId, int coachId) async {
    try {
      print('Debug: Getting detailed coach data for user: $userId, coach: $coachId');
      
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_api.php?action=get-user-coach-request&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Detailed coach response status: ${response.statusCode}');
      print('Debug: Detailed coach response body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['success'] == true && data['coach_request'] != null) {
            return data['coach_request'];
          }
        } catch (e) {
          print('Error decoding detailed coach data: $e');
        }
      }
      return null;
    } catch (e) {
      print('Error getting detailed coach data: $e');
      return null;
    }
  }

  // Get user ID from AuthService
  static Future<int> getUserId() async {
    try {
      print('Debug: Getting user ID from AuthService...');
      
      // First try to get from AuthService
      final authUserId = AuthService.getCurrentUserId();
      if (authUserId != null) {
        print('Debug: Retrieved user ID from AuthService: $authUserId');
        return authUserId;
      }
      
      print('Debug: No user ID found in AuthService, trying SharedPreferences as fallback...');
      
      // Fallback to SharedPreferences with multiple key attempts
      final prefs = await SharedPreferences.getInstance();
      
      // Try different possible keys
      final keys = ['current_user_id', 'user_id', 'userId'];
      
      for (final key in keys) {
        // Try as integer first
        final intValue = prefs.getInt(key);
        if (intValue != null) {
          print('Debug: Found user ID as integer with key "$key": $intValue');
          return intValue;
        }
        
        // Try as string
        final stringValue = prefs.getString(key);
        if (stringValue != null && stringValue.isNotEmpty) {
          final cleanValue = stringValue.trim();
          if (RegExp(r'^\d+$').hasMatch(cleanValue)) {
            final parsedValue = int.parse(cleanValue);
            print('Debug: Found user ID as string with key "$key": $parsedValue');
            return parsedValue;
          }
        }
      }
      
      print('Debug: No user ID found in any location, returning 0');
      return 0;
    } catch (e) {
      print('Error getting user ID: $e');
      print('Error type: ${e.runtimeType}');
      return 0;
    }
  }

  // Helper method to format date (MM/DD/YYYY)
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Helper method to format date with time (MM/DD/YYYY HH:mm)
  static String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} $displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Helper method to get status color
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'pending approval':
        return '#FF9800'; // Orange
      case 'expired':
        return '#F44336'; // Red
      case 'disconnected':
        return '#9E9E9E'; // Grey
      case 'rejected':
        return '#F44336'; // Red
      default:
        return '#2196F3'; // Blue
    }
  }

  // Helper method to get status icon
  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return '✓';
      case 'pending approval':
        return '⏳';
      case 'expired':
        return '⏰';
      case 'disconnected':
        return '❌';
      case 'rejected':
        return '❌';
      default:
        return '❓';
    }
  }

  // Get available subscription plans for a specific user (with business logic)
  static Future<List<SubscriptionPlan>> getAvailablePlansForUser(int userId, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Debug: Getting available subscription plans for user $userId (attempt $attempt)');
        
        final response = await http.get(
          Uri.parse('$subscriptionBaseUrl?action=available-plans&user_id=$userId'),
          headers: {'Content-Type': 'application/json'},
        );
        
        print('Debug: Available plans response status: ${response.statusCode}');
        print('Debug: Available plans response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['plans'] != null) {
            return (data['plans'] as List<dynamic>)
                .map((planJson) => SubscriptionPlan.fromJson(planJson))
                .toList();
          }
        }
        
        if (attempt < maxRetries) {
          print('Debug: Retrying in 2 seconds...');
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('Error getting available subscription plans (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
    
    print('Debug: Failed to get available subscription plans after $maxRetries attempts');
    return [];
  }

  // Get subscription plans with retry logic (all plans - for admin use)
  static Future<List<SubscriptionPlan>> getSubscriptionPlansWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Debug: Getting subscription plans (attempt $attempt)');
        
        final response = await http.get(
          Uri.parse('$subscriptionBaseUrl?action=get-plans'),
          headers: {'Content-Type': 'application/json'},
        );
        
        print('Debug: Subscription plans response status: ${response.statusCode}');
        print('Debug: Subscription plans response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['plans'] != null) {
            return (data['plans'] as List<dynamic>)
                .map((planJson) => SubscriptionPlan.fromJson(planJson))
                .toList();
          }
        }
        
        if (attempt < maxRetries) {
          print('Debug: Retrying in 2 seconds...');
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('Error getting subscription plans (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }
    
    print('Debug: Failed to get subscription plans after $maxRetries attempts');
    return [];
  }

  // Get user subscriptions
  static Future<List<UserSubscription>> getUserSubscriptions(int userId) async {
    try {
      print('Debug: Getting user subscriptions for user: $userId');
      
      final response = await http.get(
        Uri.parse('$subscriptionBaseUrl?action=get-user-subscriptions&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: User subscriptions response status: ${response.statusCode}');
      print('Debug: User subscriptions response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['subscriptions'] != null) {
          return (data['subscriptions'] as List<dynamic>)
              .map((subJson) => UserSubscription.fromJson(subJson))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting user subscriptions: $e');
      return [];
    }
  }

  // Request subscription plan
  static Future<SubscriptionRequestResponse> requestSubscriptionPlan({
    required int userId,
    required int planId,
    String? paymentMethod,
  }) async {
    try {
      print('Debug: Requesting subscription plan for user: $userId, plan: $planId');
      
      final response = await http.post(
        Uri.parse('$subscriptionBaseUrl?action=request-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'plan_id': planId,
          'payment_method': paymentMethod ?? 'cash',
        }),
      );
      
      print('Debug: Request subscription response status: ${response.statusCode}');
      print('Debug: Request subscription response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionRequestResponse.fromJson(data);
      }
      
      return SubscriptionRequestResponse(
        success: false,
        message: 'Failed to request subscription'
      );
    } catch (e) {
      print('Error requesting subscription plan: $e');
      return SubscriptionRequestResponse(
        success: false,
        message: 'Error requesting subscription: $e'
      );
    }
  }

  // Get subscription plan details
  static Future<SubscriptionPlan?> getSubscriptionPlan(int planId) async {
    try {
      print('Debug: Getting subscription plan details for plan: $planId');
      
      final response = await http.get(
        Uri.parse('$subscriptionBaseUrl?action=get-plan&plan_id=$planId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Subscription plan response status: ${response.statusCode}');
      print('Debug: Subscription plan response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['plan'] != null) {
          return SubscriptionPlan.fromJson(data['plan']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting subscription plan: $e');
      return null;
    }
  }

  // Cancel subscription
  static Future<SubscriptionRequestResponse> cancelSubscription(int subscriptionId) async {
    try {
      print('Debug: Cancelling subscription: $subscriptionId');
      
      final response = await http.post(
        Uri.parse('$subscriptionBaseUrl?action=cancel-subscription'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subscription_id': subscriptionId,
        }),
      );
      
      print('Debug: Cancel subscription response status: ${response.statusCode}');
      print('Debug: Cancel subscription response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionRequestResponse.fromJson(data);
      }
      
      return SubscriptionRequestResponse(
        success: false,
        message: 'Failed to cancel subscription'
      );
    } catch (e) {
      print('Error cancelling subscription: $e');
      return SubscriptionRequestResponse(
        success: false,
        message: 'Error cancelling subscription: $e'
      );
    }
  }

  // Get user's pending request
  static Future<Map<String, dynamic>?> getUserPendingRequest(int userId) async {
    try {
      print('Debug: Getting pending request for user: $userId');
      
      final response = await http.get(
        Uri.parse('$subscriptionBaseUrl?action=get-pending-request&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Debug: Pending request URL: $subscriptionBaseUrl?action=get-pending-request&user_id=$userId');
      
      print('Debug: Pending request response status: ${response.statusCode}');
      print('Debug: Pending request response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data;
        }
      }
      return null;
    } catch (e) {
      print('Error getting pending request: $e');
      return null;
    }
  }

  // Cancel pending request
  static Future<SubscriptionRequestResponse> cancelPendingRequest(int userId) async {
    try {
      print('Debug: Cancelling pending request for user: $userId');
      
      final response = await http.post(
        Uri.parse('$subscriptionBaseUrl?action=cancel-pending-request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
        }),
      );
      
      print('Debug: Cancel pending request response status: ${response.statusCode}');
      print('Debug: Cancel pending request response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionRequestResponse.fromJson(data);
      }
      
      return SubscriptionRequestResponse(
        success: false,
        message: 'Failed to cancel pending request'
      );
    } catch (e) {
      print('Error cancelling pending request: $e');
      return SubscriptionRequestResponse(
        success: false,
        message: 'Error cancelling pending request: $e'
      );
    }
  }

  // Auto-expire old requests (admin function)
  static Future<SubscriptionRequestResponse> autoExpireRequests() async {
    try {
      print('Debug: Auto-expiring old requests');
      
      final response = await http.post(
        Uri.parse('$subscriptionBaseUrl?action=auto-expire-requests'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      
      print('Debug: Auto-expire requests response status: ${response.statusCode}');
      print('Debug: Auto-expire requests response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SubscriptionRequestResponse.fromJson(data);
      }
      
      return SubscriptionRequestResponse(
        success: false,
        message: 'Failed to auto-expire requests'
      );
    } catch (e) {
      print('Error auto-expiring requests: $e');
      return SubscriptionRequestResponse(
        success: false,
        message: 'Error auto-expiring requests: $e'
      );
    }
  }
}