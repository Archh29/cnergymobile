import '../utils/date_utils.dart';

class User {
  final int? id;
  final String email;
  final String password;
  final int userTypeId;
  final int genderId;
  final String fname;
  final String mname;
  final String lname;
  final DateTime bday;
  final DateTime? createdAt;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.userTypeId,
    required this.genderId,
    required this.fname,
    required this.mname,
    required this.lname,
    required this.bday,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'user_type_id': userTypeId,
      'gender_id': genderId,
      'fname': fname,
      'mname': mname,
      'lname': lname,
      'bday': CnergyDateUtils.toApiDate(bday),
      'created_at': createdAt != null ? CnergyDateUtils.toApiDateTime(createdAt!) : null,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      userTypeId: json['user_type_id'],
      genderId: json['gender_id'],
      fname: json['fname'],
      mname: json['mname'],
      lname: json['lname'],
      bday: CnergyDateUtils.parseApiDate(json['bday']) ?? DateTime.now(),
      createdAt: json['created_at'] != null ? CnergyDateUtils.parseApiDateTime(json['created_at']) : null,
    );
  }
}

class MemberProfileDetails {
  final int? id;
  final int userId;
  final String fitnessLevel;
  final List<String> fitnessGoals;
  final int genderId;
  final DateTime birthdate;
  final double heightCm;
  final double weightKg;
  final double? targetWeight;
  final double? bodyFat;
  final String activityLevel;
  final int workoutDaysPerWeek;
  final String? equipmentAccess;
  final bool profileCompleted;
  final DateTime? profileCompletedAt;
  final DateTime? onboardingCompletedAt;
  final DateTime? createdAt;

  MemberProfileDetails({
    this.id,
    required this.userId,
    required this.fitnessLevel,
    required this.fitnessGoals,
    required this.genderId,
    required this.birthdate,
    required this.heightCm,
    required this.weightKg,
    this.targetWeight,
    this.bodyFat,
    required this.activityLevel,
    required this.workoutDaysPerWeek,
    this.equipmentAccess,
    this.profileCompleted = false,
    this.profileCompletedAt,
    this.onboardingCompletedAt,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fitness_level': fitnessLevel,
      'fitness_goals': fitnessGoals,
      'gender_id': genderId,
      'birthdate': CnergyDateUtils.toApiDate(birthdate),
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_weight': targetWeight,
      'body_fat': bodyFat,
      'activity_level': activityLevel,
      'workout_days_per_week': workoutDaysPerWeek,
      'equipment_access': equipmentAccess,
      'profile_completed': profileCompleted,
      'profile_completed_at': profileCompletedAt != null ? CnergyDateUtils.toApiDateTime(profileCompletedAt!) : null,
      'onboarding_completed_at': onboardingCompletedAt != null ? CnergyDateUtils.toApiDateTime(onboardingCompletedAt!) : null,
      'created_at': createdAt != null ? CnergyDateUtils.toApiDateTime(createdAt!) : null,
    };
  }

  factory MemberProfileDetails.fromJson(Map<String, dynamic> json) {
    return MemberProfileDetails(
      id: json['id'],
      userId: json['user_id'],
      fitnessLevel: json['fitness_level'],
      fitnessGoals: List<String>.from(json['fitness_goals'] ?? []),
      genderId: json['gender_id'],
      birthdate: CnergyDateUtils.parseApiDate(json['birthdate']) ?? DateTime.now(),
      heightCm: double.parse(json['height_cm'].toString()),
      weightKg: double.parse(json['weight_kg'].toString()),
      targetWeight: json['target_weight'] != null ? double.parse(json['target_weight'].toString()) : null,
      bodyFat: json['body_fat'] != null ? double.parse(json['body_fat'].toString()) : null,
      activityLevel: json['activity_level'],
      workoutDaysPerWeek: json['workout_days_per_week'],
      equipmentAccess: json['equipment_access'],
      profileCompleted: json['profile_completed'] == 1,
      profileCompletedAt: json['profile_completed_at'] != null ? CnergyDateUtils.parseApiDateTime(json['profile_completed_at']) : null,
      onboardingCompletedAt: json['onboarding_completed_at'] != null ? CnergyDateUtils.parseApiDateTime(json['onboarding_completed_at']) : null,
      createdAt: json['created_at'] != null ? CnergyDateUtils.parseApiDateTime(json['created_at']) : null,
    );
  }
}

class OnboardingGoal {
  final String title;
  final String description;
  final String iconName;
  final String colorHex;

  OnboardingGoal({
    required this.title,
    required this.description,
    required this.iconName,
    required this.colorHex,
  });

  factory OnboardingGoal.fromJson(Map<String, dynamic> json) {
    return OnboardingGoal(
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
      colorHex: json['color_hex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon_name': iconName,
      'color_hex': colorHex,
    };
  }
}

class ActivityLevelOption {
  final String title;
  final String description;
  final String iconName;

  ActivityLevelOption({
    required this.title,
    required this.description,
    required this.iconName,
  });

  factory ActivityLevelOption.fromJson(Map<String, dynamic> json) {
    return ActivityLevelOption(
      title: json['title'],
      description: json['description'],
      iconName: json['icon_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon_name': iconName,
    };
  }
}

class OnboardingData {
  final User user;
  final MemberProfileDetails profile;

  OnboardingData({
    required this.user,
    required this.profile,
  });

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'profile': profile.toJson(),
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      errors: json['errors'],
    );
  }
}
