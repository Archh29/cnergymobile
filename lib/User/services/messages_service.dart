import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/messages_model.dart';

class MessageService {
  static const String baseUrl = 'https://api.cnergy.site/messages.php'; // Replace with your actual API URL
  
  // Get all conversations for a user
  static Future<List<Conversation>> getConversations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=conversations&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Conversation> conversations = [];
          for (var item in data['conversations']) {
            conversations.add(Conversation.fromJson(item));
          }
          return conversations;
        } else {
          throw Exception(data['message'] ?? 'Failed to load conversations');
        }
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get messages for a specific conversation
  static Future<List<Message>> getMessages(int conversationId, int currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=messages&conversation_id=$conversationId&user_id=$currentUserId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Message> messages = [];
          for (var item in data['messages']) {
            messages.add(Message.fromJson(item));
          }
          return messages;
        } else {
          throw Exception(data['message'] ?? 'Failed to load messages');
        }
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Send a new message
  static Future<Message> sendMessage(int senderId, int receiverId, String messageText) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=send_message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': messageText,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return Message.fromJson(data['message']);
        } else {
          throw Exception(data['message'] ?? 'Failed to send message');
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Mark messages as read
  static Future<bool> markMessagesAsRead(int conversationId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=mark_read'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'conversation_id': conversationId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get or create conversation between two users
  static Future<int> getOrCreateConversation(int userId1, int userId2) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=get_or_create_conversation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id_1': userId1,
          'user_id_2': userId2,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['conversation_id'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create conversation');
        }
      } else {
        throw Exception('Failed to create conversation');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get approved coach-member relationships for a user (for creating new conversations)
  static Future<List<UserInfo>> getAvailableContacts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=available_contacts&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<UserInfo> contacts = [];
          for (var item in data['contacts']) {
            contacts.add(UserInfo.fromJson(item));
          }
          return contacts;
        } else {
          throw Exception(data['message'] ?? 'Failed to load contacts');
        }
      } else {
        throw Exception('Failed to load contacts');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Search messages across all conversations
  static Future<List<Message>> searchMessages(int userId, String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=search_messages&user_id=$userId&query=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<Message> messages = [];
          for (var item in data['messages']) {
            messages.add(Message.fromJson(item));
          }
          return messages;
        } else {
          throw Exception(data['message'] ?? 'Failed to search messages');
        }
      } else {
        throw Exception('Failed to search messages');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete a message (soft delete - mark as deleted)
  static Future<bool> deleteMessage(int messageId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=delete_message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message_id': messageId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get unread message count for a user
  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=unread_count&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['unread_count'] ?? 0;
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // Update user online status
  static Future<bool> updateOnlineStatus(int userId, bool isOnline) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_online_status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'is_online': isOnline,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}