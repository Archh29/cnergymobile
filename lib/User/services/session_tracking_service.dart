import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionTrackingService {
  static const String baseUrl = 'https://api.cnergy.site/coach_api.php';

  /// Check if user can start a workout (has remaining sessions or valid monthly subscription)
  static Future<SessionStatus> checkSessionAvailability({
    required int userId,
    required int coachId,
  }) async {
    try {
      print('🔍 Checking session availability - User ID: $userId, Coach ID: $coachId');
      
      final response = await http.get(
        Uri.parse('$baseUrl?action=check-session-availability&user_id=$userId&coach_id=$coachId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📡 Session check response status: ${response.statusCode}');
      print('📄 Session check response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Session check response data: $responseData');
        
        if (responseData['success'] == true) {
          return SessionStatus.fromJson(responseData['data']);
        } else {
          return SessionStatus(
            canStartWorkout: false,
            reason: responseData['message'] ?? 'Session check failed',
            remainingSessions: 0,
            subscriptionType: 'none',
            expiresAt: null,
          );
        }
      } else {
        print('❌ Session check HTTP error: ${response.statusCode}');
        return SessionStatus(
          canStartWorkout: false,
          reason: 'Failed to check session availability',
          remainingSessions: 0,
          subscriptionType: 'none',
          expiresAt: null,
        );
      }
    } catch (e) {
      print('❌ Error checking session availability: $e');
      return SessionStatus(
        canStartWorkout: false,
        reason: 'Error checking session availability: $e',
        remainingSessions: 0,
        subscriptionType: 'none',
        expiresAt: null,
      );
    }
  }

  /// Deduct a session when user starts a workout (only once per day)
  static Future<SessionDeductionResult> deductSession({
    required int userId,
    required int coachId,
  }) async {
    try {
      print('🔄 Deducting session - User ID: $userId, Coach ID: $coachId');
      
      // Check if already deducted today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      final lastDeductionKey = 'last_session_deduction_${userId}_$coachId';
      final lastDeductionDate = prefs.getString(lastDeductionKey);
      
      if (lastDeductionDate == today) {
        print('⚠️ Session already deducted today for this coach');
        return SessionDeductionResult(
          success: true,
          message: 'Session already deducted today',
          remainingSessions: await _getRemainingSessions(userId, coachId),
          alreadyDeductedToday: true,
        );
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl?action=deduct-session'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'member_id': userId,
          'coach_id': coachId,
        }),
      );

      print('📡 Session deduction response status: ${response.statusCode}');
      print('📄 Session deduction response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Session deduction response data: $responseData');
        
        if (responseData['success'] == true) {
          // Store today's date to prevent double deduction
          await prefs.setString(lastDeductionKey, today);
          
          return SessionDeductionResult(
            success: true,
            message: responseData['message'] ?? 'Session deducted successfully',
            remainingSessions: responseData['remaining_sessions'] ?? 0,
            alreadyDeductedToday: false,
          );
        } else {
          return SessionDeductionResult(
            success: false,
            message: responseData['message'] ?? 'Failed to deduct session',
            remainingSessions: 0,
            alreadyDeductedToday: false,
          );
        }
      } else {
        print('❌ Session deduction HTTP error: ${response.statusCode}');
        return SessionDeductionResult(
          success: false,
          message: 'Failed to deduct session',
          remainingSessions: 0,
          alreadyDeductedToday: false,
        );
      }
    } catch (e) {
      print('❌ Error deducting session: $e');
      return SessionDeductionResult(
        success: false,
        message: 'Error deducting session: $e',
        remainingSessions: 0,
        alreadyDeductedToday: false,
      );
    }
  }

  /// Get remaining sessions for a user-coach pair
  static Future<int> _getRemainingSessions(int userId, int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get-remaining-sessions&user_id=$userId&coach_id=$coachId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['remaining_sessions'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting remaining sessions: $e');
      return 0;
    }
  }

  /// Check if user has already used a session today
  static Future<bool> hasUsedSessionToday(int userId, int coachId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      final lastDeductionKey = 'last_session_deduction_${userId}_$coachId';
      final lastDeductionDate = prefs.getString(lastDeductionKey);
      
      return lastDeductionDate == today;
    } catch (e) {
      print('Error checking if session used today: $e');
      return false;
    }
  }

  /// Clear session deduction history (for testing or admin purposes)
  static Future<void> clearSessionHistory(int userId, int coachId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDeductionKey = 'last_session_deduction_${userId}_$coachId';
      await prefs.remove(lastDeductionKey);
      print('✅ Cleared session history for user $userId and coach $coachId');
    } catch (e) {
      print('Error clearing session history: $e');
    }
  }
}

class SessionStatus {
  final bool canStartWorkout;
  final String reason;
  final int remainingSessions;
  final String subscriptionType; // 'package', 'monthly', 'none'
  final DateTime? expiresAt;

  SessionStatus({
    required this.canStartWorkout,
    required this.reason,
    required this.remainingSessions,
    required this.subscriptionType,
    this.expiresAt,
  });

  factory SessionStatus.fromJson(Map<String, dynamic> json) {
    return SessionStatus(
      canStartWorkout: json['can_start_workout'] ?? false,
      reason: json['reason'] ?? '',
      remainingSessions: json['remaining_sessions'] ?? 0,
      subscriptionType: json['subscription_type'] ?? 'none',
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get statusMessage {
    if (!canStartWorkout) {
      return reason;
    }
    
    switch (subscriptionType) {
      case 'package':
        return 'Sessions remaining: $remainingSessions';
      case 'monthly':
        if (expiresAt != null) {
          final daysLeft = expiresAt!.difference(DateTime.now()).inDays;
          return 'Monthly subscription active (${daysLeft} days left)';
        }
        return 'Monthly subscription active';
      default:
        return 'No active subscription';
    }
  }
}

class SessionDeductionResult {
  final bool success;
  final String message;
  final int remainingSessions;
  final bool alreadyDeductedToday;

  SessionDeductionResult({
    required this.success,
    required this.message,
    required this.remainingSessions,
    required this.alreadyDeductedToday,
  });
}












