import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost/cynergy/';
  static const String notificationEndpoint = '${baseUrl}notifications.php';

  // Get notifications with pagination
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$notificationEndpoint?action=get_notifications&user_id=$userId&page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Get notifications response status: ${response.statusCode}');
      print('Get notifications response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$notificationEndpoint?action=get_unread_count&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['unread_count'];
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0; // Return 0 on error to avoid breaking the UI
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('$notificationEndpoint?action=mark_as_read&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notification_id': notificationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('$notificationEndpoint?action=mark_all_as_read&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  // Delete notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('$notificationEndpoint?action=delete_notification&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notification_id': notificationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('$notificationEndpoint?action=clear_all&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return;
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
      rethrow;
    }
  }
}
