import 'package:flutter/material.dart';

class MemberModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImage;
  final DateTime? joinDate;
  final String status;
  final Map<String, dynamic> fitnessGoals;
  final Map<String, dynamic> preferences;
  final int? requestId;
  final String? phone;
  final DateTime? birthDate;
  final String? gender;
  final double? height;
  final double? weight;
  final String? fitnessLevel;
  final List<String> medicalConditions;
  final Map<String, dynamic> progressData;
  final DateTime? requestedAt;
  final String? genderName;
  final String? planName;
  final int age;

  MemberModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImage,
    this.joinDate,
    this.status = 'active',
    this.fitnessGoals = const {},
    this.preferences = const {},
    this.requestId,
    this.phone,
    this.birthDate,
    this.gender,
    this.height,
    this.weight,
    this.fitnessLevel,
    this.medicalConditions = const [],
    this.progressData = const {},
    this.requestedAt,
    this.genderName,
    this.planName,
    this.age = 0,
  });

  String get fullName => '$firstName $lastName';
  
  String get fname => firstName;
  
  String? get subscriptionStatus => status;
  
  DateTime get createdAt => joinDate ?? DateTime.now();
  
  String get initials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  String get formattedJoinDate {
    if (joinDate == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(joinDate!).inDays;
    
    if (difference < 30) {
      return '$difference days ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
        return Color(0xFF2ECC71);
      case 'inactive':
        return Color(0xFFE74C3C);
      case 'pending':
        return Color(0xFFF39C12);
      case 'suspended':
        return Color(0xFF95A5A6);
      default:
        return Color(0xFF95A5A6);
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'inactive':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      case 'suspended':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }

  bool get hasActiveSubscription => status.toLowerCase() == 'active';
  bool get hasPaidPlan => planName != null && planName!.isNotEmpty;
  bool get isNewMember {
    if (joinDate == null) return false;
    final daysSinceJoin = DateTime.now().difference(joinDate!).inDays;
    return daysSinceJoin <= 30;
  }
  bool get isFullyApproved => status.toLowerCase() == 'approved';
  bool get isPendingCoachApproval => status.toLowerCase() == 'pending_coach';
  bool get isPendingStaffApproval => status.toLowerCase() == 'pending_staff';
  bool get isRejected => status.toLowerCase() == 'rejected';
  
  String get approvalStatusMessage {
    if (isFullyApproved) return 'Fully approved and active';
    if (isPendingStaffApproval) return 'Pending staff approval';
    if (isPendingCoachApproval) return 'Pending coach approval';
    if (isRejected) return 'Application rejected';
    return 'Status unknown';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? json['user_id'] ?? 0,
      firstName: json['first_name'] ?? json['fname'] ?? '',
      lastName: json['last_name'] ?? json['lname'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile_image'] ?? json['profile_picture'],
      joinDate: json['join_date'] != null ? DateTime.tryParse(json['join_date']) : null,
      status: json['status'] ?? 'active',
      fitnessGoals: json['fitness_goals'] is Map ? Map<String, dynamic>.from(json['fitness_goals']) : {},
      preferences: json['preferences'] is Map ? Map<String, dynamic>.from(json['preferences']) : {},
      requestId: json['request_id'],
      phone: json['phone'],
      birthDate: json['birth_date'] != null ? DateTime.tryParse(json['birth_date']) : null,
      gender: json['gender'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      fitnessLevel: json['fitness_level'],
      medicalConditions: json['medical_conditions'] is List 
          ? List<String>.from(json['medical_conditions']) 
          : [],
      progressData: json['progress_data'] is Map 
          ? Map<String, dynamic>.from(json['progress_data']) 
          : {},
      requestedAt: json['requested_at'] != null ? DateTime.tryParse(json['requested_at']) : null,
      genderName: json['gender_name'] ?? json['gender'],
      planName: json['plan_name'],
      age: json['age'] ?? _calculateAge(json['birth_date']),
    );
  }

  static int _calculateAge(String? birthDateString) {
    if (birthDateString == null) return 0;
    final birthDate = DateTime.tryParse(birthDateString);
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'profile_image': profileImage,
      'join_date': joinDate?.toIso8601String(),
      'status': status,
      'fitness_goals': fitnessGoals,
      'preferences': preferences,
      'request_id': requestId,
      'phone': phone,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'fitness_level': fitnessLevel,
      'medical_conditions': medicalConditions,
      'progress_data': progressData,
      'requested_at': requestedAt?.toIso8601String(),
      'gender_name': genderName,
      'plan_name': planName,
      'age': age,
    };
  }

  MemberModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? profileImage,
    DateTime? joinDate,
    String? status,
    Map<String, dynamic>? fitnessGoals,
    Map<String, dynamic>? preferences,
    int? requestId,
    String? phone,
    DateTime? birthDate,
    String? gender,
    double? height,
    double? weight,
    String? fitnessLevel,
    List<String>? medicalConditions,
    Map<String, dynamic>? progressData,
    DateTime? requestedAt,
    String? genderName,
    String? planName,
    int? age,
  }) {
    return MemberModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      preferences: preferences ?? this.preferences,
      requestId: requestId ?? this.requestId,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      progressData: progressData ?? this.progressData,
      requestedAt: requestedAt ?? this.requestedAt,
      genderName: genderName ?? this.genderName,
      planName: planName ?? this.planName,
      age: age ?? this.age,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MemberModel(id: $id, name: $fullName, email: $email, status: $status)';
  }
}
