import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../../widgets/attendance_success_modal.dart';

/// Attendance Service
/// 
/// Usage example with success modal:
/// ```dart
/// final response = await AttendanceService.scanQRCode(qrData);
/// if (response.success) {
///   showAttendanceSuccessModal(context, response);
/// } else {
///   // Show error message
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(content: Text(response.error ?? 'Failed')),
///   );
/// }
/// ```
/// 
/// Import the modal helper:
/// ```dart
/// import '../../widgets/attendance_success_modal.dart';
/// ```

class AttendanceService {
  static const String baseUrl = 'https://api.cnergy.site/attendance_api.php';
    
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

  // Scan QR code with automatic modal display (recommended for UI usage)
  static Future<void> scanQRCodeWithModal(BuildContext context, String qrData) async {
    final response = await scanQRCode(qrData);
    if (response.success) {
      showAttendanceSuccessModal(context, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Failed to scan QR code'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

  // Manual check-in with automatic modal display
  static Future<void> checkInWithModal(BuildContext context, int userId) async {
    final response = await checkIn(userId);
    if (response.success) {
      showAttendanceSuccessModal(context, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Check-in failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
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

  // Manual check-out with automatic modal display
  static Future<void> checkOutWithModal(BuildContext context, int userId) async {
    final response = await checkOut(userId);
    if (response.success) {
      showAttendanceSuccessModal(context, response);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Check-out failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Get attendance history
  static Future<List<AttendanceModel>> getAttendanceHistory(int userId, {int limit = 50}) async {
    try {
      final url = '$baseUrl?action=history&user_id=$userId&limit=$limit';
      print('📡 Fetching attendance history from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📡 Parsed data: $data');
        
        if (data['success'] == true) {
          final List<dynamic> attendanceList = data['data'] ?? [];
          print('📡 Attendance list length: ${attendanceList.length}');
          
          if (attendanceList.isEmpty) {
            print('⚠️ Attendance list is empty');
            return [];
          }
          
          final result = attendanceList.map((item) {
            print('📡 Processing item: $item');
            return AttendanceModel.fromJson(item);
          }).toList();
          
          print('✅ Successfully parsed ${result.length} attendance records');
          return result;
        } else {
          print('⚠️ API returned success: false, error: ${data['error']}');
        }
      } else {
        print('⚠️ HTTP error: ${response.statusCode}');
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching attendance history: $e');
      print('Stack trace: $stackTrace');
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