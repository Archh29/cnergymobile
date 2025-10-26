import '../../utils/date_utils.dart';

class NotificationModel {
  final int id;
  final String message;
  final String timestamp;
  final String statusName;
  final String typeName;
  final bool isUnread;

  NotificationModel({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.statusName,
    required this.typeName,
    required this.isUnread,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      statusName: json['status_name'] ?? 'Unknown',
      typeName: json['type_name'] ?? 'info',
      isUnread: json['is_unread'] == 1 || json['is_unread'] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp,
      'status_name': statusName,
      'type_name': typeName,
      'is_unread': isUnread ? 1 : 0,
    };
  }

  // Helper method to get notification icon based on type
  String getIconName() {
    switch (typeName.toLowerCase()) {
      case 'info':
        return 'info';
      case 'warning':
        return 'warning';
      case 'success':
        return 'check_circle';
      case 'error':
        return 'error';
      default:
        return 'notifications';
    }
  }

  // Helper method to get notification color based on type
  String getColorHex() {
    switch (typeName.toLowerCase()) {
      case 'info':
        return '#4ECDC4';
      case 'warning':
        return '#FFB74D';
      case 'success':
        return '#96CEB4';
      case 'error':
        return '#FF6B6B';
      default:
        return '#9E9E9E';
    }
  }

  // Helper method to strip leading question marks from message for display
  String getDisplayMessage() {
    // Strip leading '?' or '??' from the message without modifying original data
    return message.replaceFirst(RegExp(r'^\?+\s*'), '');
  }

  // Helper method to format timestamp
  String getFormattedTime() {
    try {
      final dateTime = CnergyDateUtils.parseApiDateTime(timestamp) ?? DateTime.now();
      return CnergyDateUtils.getRelativeDate(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  // Get formatted date (MM/DD/YYYY)
  String getFormattedDate() {
    try {
      final dateTime = CnergyDateUtils.parseApiDateTime(timestamp) ?? DateTime.now();
      return CnergyDateUtils.toDisplayDate(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }

  // Get formatted datetime (MM/DD/YYYY HH:mm)
  String getFormattedDateTime() {
    try {
      final dateTime = CnergyDateUtils.parseApiDateTime(timestamp) ?? DateTime.now();
      return CnergyDateUtils.toDisplayDateTime(dateTime);
    } catch (e) {
      return 'Unknown';
    }
  }
}
