import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';

class AttendanceService {
  static const String baseUrl = 'http://localhost/cynergy/api/attendance_api.php';
    
  // Scan QR code and handle check-in/check-out automatically
  static Future<AttendanceResponse> scanQRCode(String qrData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'scan',
          'qr_data': qrData
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        return AttendanceResponse(
          success: false,
          error: error['error'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Manual check-in
  static Future<AttendanceResponse> checkIn(int userId) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'checkin',
          'user_id': userId
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        return AttendanceResponse(
          success: false,
          error: error['error'] ?? 'Check-in failed',
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Manual check-out
  static Future<AttendanceResponse> checkOut(int userId) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'checkout',
          'user_id': userId
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceResponse.fromJson(data);
      } else {
        final error = json.decode(response.body);
        return AttendanceResponse(
          success: false,
          error: error['error'] ?? 'Check-out failed',
        );
      }
    } catch (e) {
      return AttendanceResponse(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  // Get attendance history
  static Future<List<AttendanceModel>> getAttendanceHistory(int userId, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=history&user_id=$userId&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> attendanceList = data['data'];
          return attendanceList.map((item) => AttendanceModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching attendance history: $e');
      return [];
    }
  }

  // Get current attendance status
  static Future<AttendanceStatus?> getAttendanceStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=status&user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AttendanceStatus.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching attendance status: $e');
      return null;
    }
  }

  // Get all attendance records (for admin)
  static Future<List<AttendanceModel>> getAllAttendanceRecords({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=all&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> attendanceList = data['data'];
          return attendanceList.map((item) => AttendanceModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching all attendance records: $e');
      return [];
    }
  }
}