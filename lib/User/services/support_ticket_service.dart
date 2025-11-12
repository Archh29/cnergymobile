import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket_model.dart';

class SupportTicketService {
  static const String baseUrl = 'https://api.cnergy.site/support_tickets.php';

  // Create a new support ticket
  static Future<Map<String, dynamic>> createTicket({
    required int userId,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=create_ticket'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'subject': subject,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to create ticket',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Get all tickets for a user
  static Future<List<SupportTicket>> getUserTickets(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_user_tickets&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Get tickets response status: ${response.statusCode}');
      print('Get tickets response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Get tickets parsed data: $data');
        
        if (data['success'] == true) {
          final List<dynamic> ticketsJson = data['tickets'] ?? [];
          print('Found ${ticketsJson.length} tickets');
          final tickets = ticketsJson.map((json) {
            try {
              return SupportTicket.fromJson(json);
            } catch (e) {
              print('Error parsing ticket: $e');
              print('Ticket JSON: $json');
              rethrow;
            }
          }).toList();
          return tickets;
        } else {
          print('API returned success: false, error: ${data['error']}');
          throw Exception(data['error'] ?? 'Failed to fetch tickets');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        throw Exception('Failed to fetch tickets: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tickets: $e');
      rethrow;
    }
  }

  // Get a specific ticket
  static Future<SupportTicket?> getTicket(int ticketId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_ticket&ticket_id=$ticketId&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['ticket'] != null) {
          return SupportTicket.fromJson(data['ticket']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching ticket: $e');
      return null;
    }
  }

  // Get messages for a ticket
  static Future<List<SupportTicketMessage>> getTicketMessages(int ticketId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_ticket_messages&ticket_id=$ticketId&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> messagesJson = data['messages'] ?? [];
          return messagesJson.map((json) => SupportTicketMessage.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching ticket messages: $e');
      return [];
    }
  }

  // Send a message in a ticket
  static Future<Map<String, dynamic>> sendMessage({
    required int ticketId,
    required int senderId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=send_message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticket_id': ticketId,
          'sender_id': senderId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // Update ticket status (admin only)
  static Future<Map<String, dynamic>> updateStatus({
    required int ticketId,
    required String status,
    required int adminId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl?action=update_status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticket_id': ticketId,
          'status': status,
          'admin_id': adminId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
}

