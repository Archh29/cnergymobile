import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/subscription_model.dart';

class SubscriptionService {
  static const String baseUrl = 'http://localhost/cynergy';
  static const String getPlansUrl = '$baseUrl/get_subscriptionplan.php';

  static const Duration timeoutDuration = Duration(seconds: 30);

  /// ✅ Fetch all subscription plans with enhanced business logic
  static Future<SubscriptionPlansResponse> getSubscriptionPlans({int? userId}) async {
    try {
      final url = userId != null
          ? Uri.parse('$getPlansUrl?action=getPlans&user_id=$userId')
          : Uri.parse('$getPlansUrl?action=getPlans');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        print("[v0] API Response: ${jsonData.toString()}");

        if (jsonData.containsKey('success') && jsonData['success'] == true) {
          final dynamic plansData = jsonData['plans'];
          
          print("[v0] Plans data type: ${plansData.runtimeType}");
          print("[v0] Plans data content: ${plansData.toString()}");
          
          if (plansData == null) {
            throw Exception('Plans data is null in API response');
          }
          
          if (plansData is! List) {
            throw Exception('Plans data is not a list. Received: ${plansData.runtimeType}');
          }
          
          final List<dynamic> plansJson = plansData as List<dynamic>;
          final plans = plansJson
              .map((planJson) => SubscriptionPlan.fromJson(planJson))
              .toList();
          
          return SubscriptionPlansResponse(
            success: true,
            plans: plans,
            userStatus: UserSubscriptionStatus.fromJson(jsonData['user_status'] ?? {}),
            message: jsonData['message'] ?? 'Plans retrieved successfully',
          );
        } else {
          throw Exception('API returned unsuccessful response: ${jsonData['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load subscription plans. Status code: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on HttpException {
      throw Exception('HTTP error occurred. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('Error fetching subscription plans: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Please check your connection and try again.');
      } else {
        throw Exception('Failed to load subscription plans: ${e.toString()}');
      }
    }
  }

  static Future<List<SubscriptionPlan>> getSubscriptionPlansWithRetry({
    int? userId,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final response = await getSubscriptionPlans(userId: userId);
        return response.plans;
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    throw Exception('Failed to fetch subscription plans after $maxRetries attempts');
  }

  static Future<SubscriptionRequestResponse> requestSubscriptionPlan({
    required int userId,
    required int planId,
  }) async {
    try {
      // First check if the plan is available for this user
      final plansResponse = await getSubscriptionPlans(userId: userId);
      final targetPlan = plansResponse.plans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => throw Exception('Plan not found'),
      );
      
      if (!targetPlan.isAvailable) {
        return SubscriptionRequestResponse(
          success: false,
          message: targetPlan.unavailableReason ?? 'This plan is not available for you',
        );
      }

      final response = await http.post(
        Uri.parse('$getPlansUrl?action=requestPlan'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'plan_id': planId,
        }),
      ).timeout(timeoutDuration);

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return SubscriptionRequestResponse.fromJson(responseData);
      } else {
        return SubscriptionRequestResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to request subscription plan',
        );
      }
    } on SocketException {
      return SubscriptionRequestResponse(
        success: false,
        message: 'Network error. Please check your internet connection.',
      );
    } on HttpException {
      return SubscriptionRequestResponse(
        success: false,
        message: 'HTTP error occurred. Please try again.',
      );
    } on FormatException {
      return SubscriptionRequestResponse(
        success: false,
        message: 'Invalid response format from server.',
      );
    } catch (e) {
      print('Error requesting subscription plan: $e');
      if (e.toString().contains('TimeoutException')) {
        return SubscriptionRequestResponse(
          success: false,
          message: 'Request timeout. Please check your connection and try again.',
        );
      } else {
        return SubscriptionRequestResponse(
          success: false,
          message: 'Failed to request subscription plan: ${e.toString()}',
        );
      }
    }
  }

  static Future<bool> cancelSubscription({required int subscriptionId}) async {
    try {
      final response = await http.post(
        Uri.parse('$getPlansUrl?action=cancelSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'subscription_id': subscriptionId,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<SubscriptionEligibility> checkSubscriptionEligibility({
    required int userId,
    required int planId,
  }) async {
    try {
      final plansResponse = await getSubscriptionPlans(userId: userId);
      final targetPlan = plansResponse.plans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => throw Exception('Plan not found'),
      );
      
      return SubscriptionEligibility(
        isEligible: targetPlan.isAvailable,
        reason: targetPlan.unavailableReason,
        plan: targetPlan,
        userStatus: plansResponse.userStatus,
      );
    } catch (e) {
      return SubscriptionEligibility(
        isEligible: false,
        reason: 'Error checking eligibility: ${e.toString()}',
        plan: null,
        userStatus: null,
      );
    }
  }

  static Future<List<UserSubscription>> getUserSubscriptions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$getPlansUrl?action=getUserSubscriptions&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final dynamic subscriptionsData = jsonData['subscriptions'];
          
          print("[v0] Subscriptions data type: ${subscriptionsData.runtimeType}");
          print("[v0] Subscriptions data content: ${subscriptionsData.toString()}");
          
          if (subscriptionsData == null) {
            throw Exception('Subscriptions data is null in API response');
          }
          
          if (subscriptionsData is! List) {
            throw Exception('Subscriptions data is not a list. Received: ${subscriptionsData.runtimeType}');
          }
          
          final List<dynamic> subscriptionsJson = subscriptionsData as List<dynamic>;
          return subscriptionsJson
              .map((subJson) => UserSubscription.fromJson(subJson))
              .toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load user subscriptions');
        }
      } else {
        throw Exception('Failed to load user subscriptions. Status code: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Network error. Please check your internet connection.');
    } on HttpException {
      throw Exception('HTTP error occurred. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } catch (e) {
      print('Error fetching user subscriptions: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Please check your connection and try again.');
      } else {
        throw Exception('Failed to load user subscriptions: ${e.toString()}');
      }
    }
  }

  static Future<bool> checkApiConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse(getPlansUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<SubscriptionPlan?> getSubscriptionPlanById(int planId) async {
    try {
      final response = await getSubscriptionPlans();
      return response.plans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => throw Exception('Plan not found'),
      );
    } catch (e) {
      print('Error getting plan by ID: $e');
      return null;
    }
  }

  static Future<bool> hasPendingSubscriptionRequest(int userId) async {
    try {
      final subscriptions = await getUserSubscriptions(userId);
      return subscriptions.any((sub) => sub.statusName.toLowerCase() == 'pending_approval');
    } catch (e) {
      print('Error checking pending requests: $e');
      return false;
    }
  }
}
