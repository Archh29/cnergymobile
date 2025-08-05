class AttendanceModel {
  final int? id;
  final int userId;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String? firstName;
  final String? lastName;

  AttendanceModel({
    this.id,
    required this.userId,
    required this.checkIn,
    this.checkOut,
    this.firstName,
    this.lastName,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.parse(json['user_id'].toString()),
      checkIn: DateTime.parse(json['check_in']),
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out']) : null,
      firstName: json['fname'],
      lastName: json['lname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'check_in': checkIn.toIso8601String(),
      if (checkOut != null) 'check_out': checkOut!.toIso8601String(),
      if (firstName != null) 'fname': firstName,
      if (lastName != null) 'lname': lastName,
    };
  }

  Duration? get sessionDuration {
    if (checkOut == null) return null;
    return checkOut!.difference(checkIn);
  }

  String get formattedDuration {
    final duration = sessionDuration;
    if (duration == null) return 'In progress';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(checkIn).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${checkIn.day}/${checkIn.month}/${checkIn.year}';
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return 'Unknown User';
  }

  bool get isActiveSession => checkOut == null;

  AttendanceModel copyWith({
    int? id,
    int? userId,
    DateTime? checkIn,
    DateTime? checkOut,
    String? firstName,
    String? lastName,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

class AttendanceResponse {
  final bool success;
  final String message;
  final String action;
  final AttendanceModel? data;
  final String? error;

  AttendanceResponse({
    required this.success,
    this.message = '',
    this.action = '',
    this.data,
    this.error,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      action: json['action'] ?? '',
      data: json['data'] != null ? AttendanceModel.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class AttendanceStatus {
  final bool isCheckedIn;
  final AttendanceModel? currentSession;

  AttendanceStatus({
    required this.isCheckedIn,
    this.currentSession,
  });

  factory AttendanceStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceStatus(
      isCheckedIn: json['is_checked_in'] ?? false,
      currentSession: json['current_session'] != null 
          ? AttendanceModel.fromJson(json['current_session'])
          : null,
    );
  }
}
