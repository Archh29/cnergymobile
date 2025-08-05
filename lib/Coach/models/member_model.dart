import 'dart:convert';

class MemberModel {
  final int id;
  final String fname;
  final String mname;
  final String lname;
  final String email;
  final DateTime bday;
  final DateTime createdAt;
  final int? genderId;
  final String? genderName;
  
  // Coach-Member Connection Fields (from coach_member_list table)
  final int? coachId;
  final String? coachApproval;      // pending, approved, rejected
  final String? staffApproval;      // pending, approved, rejected
  final String? status;             // pending, approved, rejected
  final DateTime? requestedAt;
  final DateTime? coachApprovedAt;
  final DateTime? staffApprovedAt;
  final int? handledByCoach;
  final int? handledByStaff;
  final int? requestId;
  
  // Subscription info (from subscription table)
  final String? subscriptionStatus;
  final String? planName;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;

  MemberModel({
    required this.id,
    required this.fname,
    required this.mname,
    required this.lname,
    required this.email,
    required this.bday,
    required this.createdAt,
    this.genderId,
    this.genderName,
    this.coachId,
    this.coachApproval,
    this.staffApproval,
    this.status,
    this.requestedAt,
    this.coachApprovedAt,
    this.staffApprovedAt,
    this.handledByCoach,
    this.handledByStaff,
    this.requestId,
    this.subscriptionStatus,
    this.planName,
    this.subscriptionStart,
    this.subscriptionEnd,
  });

  String get fullName => '$fname $mname $lname'.trim().replaceAll(RegExp(r'\s+'), ' ');
  
  String get initials {
    String first = fname.isNotEmpty ? fname[0] : '';
    String last = lname.isNotEmpty ? lname[0] : '';
    return '$first$last'.toUpperCase();
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - bday.year;
    if (now.month < bday.month || (now.month == bday.month && now.day < bday.day)) {
      age--;
    }
    return age;
  }

  // Based on subscription status
  bool get hasActiveSubscription => subscriptionStatus == 'approved' && 
      subscriptionEnd != null && subscriptionEnd!.isAfter(DateTime.now());

  // Based on subscription plan
  bool get hasPaidPlan => planName != null && planName != 'Member Fee';

  // Approval status helpers based on coach_member_list table
  bool get isPendingCoachApproval => coachApproval == 'pending';
  bool get isPendingStaffApproval => coachApproval == 'approved' && staffApproval == 'pending';
  bool get isFullyApproved => coachApproval == 'approved' && staffApproval == 'approved';
  bool get isRejected => coachApproval == 'rejected' || staffApproval == 'rejected';

  // Check if member is new (joined within 30 days)
  bool get isNewMember => DateTime.now().difference(createdAt).inDays <= 30;

  String get currentApprovalStep {
    if (coachApproval == 'pending') {
      return 'coach_review';
    } else if (coachApproval == 'approved' && staffApproval == 'pending') {
      return 'staff_review';
    } else if (staffApproval == 'approved') {
      return 'completed';
    } else if (coachApproval == 'rejected' || staffApproval == 'rejected') {
      return 'rejected';
    }
    return 'unknown';
  }

  String get approvalStatusMessage {
    switch (currentApprovalStep) {
      case 'coach_review':
        return 'Waiting for coach approval';
      case 'staff_review':
        return 'Waiting for staff approval';
      case 'completed':
        return 'Fully approved';
      case 'rejected':
        return 'Request rejected';
      default:
        return 'Status unknown';
    }
  }

  // ENHANCED: Helper method to safely parse values with better string handling
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return null;
      // Remove surrounding quotes and whitespace
      final cleanValue = value.replaceAll(RegExp(r'^"|"$'), '').trim();
      if (cleanValue.isEmpty) return null;
      return int.tryParse(cleanValue);
    }
    return null;
  }

  static DateTime? _parseDateTimeSafely(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      // Remove surrounding quotes and whitespace
      final cleanValue = value.replaceAll(RegExp(r'^"|"$'), '').trim();
      if (cleanValue.isEmpty) return null;
      return DateTime.tryParse(cleanValue);
    }
    return null;
  }

  static String _parseStringSafely(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) {
      // Remove surrounding quotes and return trimmed value
      final cleanValue = value.replaceAll(RegExp(r'^"|"$'), '').trim();
      return cleanValue.isEmpty ? defaultValue : cleanValue;
    }
    return value.toString();
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    try {
      return MemberModel(
        id: _parseIntSafely(json['id']) ?? 0,
        fname: _parseStringSafely(json['fname']),
        mname: _parseStringSafely(json['mname']),
        lname: _parseStringSafely(json['lname']),
        email: _parseStringSafely(json['email']),
        bday: _parseDateTimeSafely(json['bday']) ?? DateTime.now().subtract(Duration(days: 365 * 25)),
        createdAt: _parseDateTimeSafely(json['created_at']) ?? DateTime.now(),
        genderId: _parseIntSafely(json['gender_id']),
        genderName: _parseStringSafely(json['gender_name']).isEmpty ? null : _parseStringSafely(json['gender_name']),
        coachId: _parseIntSafely(json['coach_id']),
        coachApproval: _parseStringSafely(json['coach_approval']).isEmpty ? null : _parseStringSafely(json['coach_approval']),
        staffApproval: _parseStringSafely(json['staff_approval']).isEmpty ? null : _parseStringSafely(json['staff_approval']),
        status: _parseStringSafely(json['status']).isEmpty ? null : _parseStringSafely(json['status']),
        requestedAt: _parseDateTimeSafely(json['requested_at']),
        coachApprovedAt: _parseDateTimeSafely(json['coach_approved_at']),
        staffApprovedAt: _parseDateTimeSafely(json['staff_approved_at']),
        handledByCoach: _parseIntSafely(json['handled_by_coach']),
        handledByStaff: _parseIntSafely(json['handled_by_staff']),
        requestId: _parseIntSafely(json['request_id']),
        subscriptionStatus: _parseStringSafely(json['subscription_status']).isEmpty ? null : _parseStringSafely(json['subscription_status']),
        planName: _parseStringSafely(json['plan_name']).isEmpty ? null : _parseStringSafely(json['plan_name']),
        subscriptionStart: _parseDateTimeSafely(json['subscription_start']),
        subscriptionEnd: _parseDateTimeSafely(json['subscription_end']),
      );
    } catch (e, stackTrace) {
      print('Error in MemberModel.fromJson: $e');
      print('Stack trace: $stackTrace');
      print('Problematic JSON: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'mname': mname,
      'lname': lname,
      'email': email,
      'bday': bday.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'gender_id': genderId,
      'gender_name': genderName,
      'coach_id': coachId,
      'coach_approval': coachApproval,
      'staff_approval': staffApproval,
      'status': status,
      'requested_at': requestedAt?.toIso8601String(),
      'coach_approved_at': coachApprovedAt?.toIso8601String(),
      'staff_approved_at': staffApprovedAt?.toIso8601String(),
      'handled_by_coach': handledByCoach,
      'handled_by_staff': handledByStaff,
      'request_id': requestId,
      'subscription_status': subscriptionStatus,
      'plan_name': planName,
      'subscription_start': subscriptionStart?.toIso8601String(),
      'subscription_end': subscriptionEnd?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MemberModel(id: $id, fullName: $fullName, email: $email, approvalStep: $currentApprovalStep, subscriptionStatus: $subscriptionStatus)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
