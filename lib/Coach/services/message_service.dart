import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class MessageService {
  static const String baseUrl = 'https://api.cnergy.site/messages.php';

  static Future<List<Message>> getMessages({
    required int conversationId,
    required int userId,
    int? otherUserId,
  }) async {
    try {
      String url = '$baseUrl?action=messages&conversation_id=$conversationId&user_id=$userId';
      
      // For virtual conversations, add other_user_id if provided
      if (conversationId == 0 && otherUserId != null) {
        url += '&other_user_id=$otherUserId';
      }

      print('Fetching messages from: $url');

      final response = await http.get(Uri.parse(url));

      print('Messages response status: ${response.statusCode}');
      print('Messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> messagesJson = data['messages'] ?? [];
          return messagesJson.map((json) => Message.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Failed to load messages');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load messages');
      }
    } catch (e) {
      print('Error in getMessages: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<Message> sendMessage({
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=send_message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
        }),
      );

      print('Send message response status: ${response.statusCode}');
      print('Send message response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return Message.fromJson(data['message']);
        } else {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to send message');
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<void> markMessagesAsRead({
    required int conversationId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=mark_read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': conversationId,
          'user_id': userId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      print('Error in markMessagesAsRead: $e');
      // Don't throw here as this is not critical
    }
  }
}
