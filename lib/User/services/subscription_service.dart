import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/subscription_model.dart';

class SubscriptionService {
  static const String baseUrl = 'http://localhost/cynergy';
  static const String getPlansUrl = '$baseUrl/get_subscriptionplan.php';

  static const Duration timeoutDuration = Duration(seconds: 30);

  /// ✅ Fetch all subscription plans, unlocks member-only if user is premium
  static Future<List<SubscriptionPlan>> getSubscriptionPlans({int? userId}) async {
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

        if (jsonData.containsKey('success') && jsonData['success'] == true) {
          final List<dynamic> plansJson = jsonData['plans'] as List<dynamic>;
          return plansJson
              .map((planJson) => SubscriptionPlan.fromJson(planJson))
              .toList();
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
        return await getSubscriptionPlans(userId: userId);
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
          final List<dynamic> subscriptionsJson = jsonData['subscriptions'] as List<dynamic>;
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
      final plans = await getSubscriptionPlans();
      return plans.firstWhere(
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
