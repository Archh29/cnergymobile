class UserModel {
  final int id;
  final String email;
  final String password;
  final int? userTypeId;
  final int? genderId;
  final int failedAttempt;
  final DateTime? lastAttempt;
  final String fname;
  final String mname;
  final String lname;
  final DateTime bday;
  final DateTime? createdAt;
  final bool isPremium; // Added premium status field

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.userTypeId,
    this.genderId,
    this.failedAttempt = 0,
    this.lastAttempt,
    required this.fname,
    required this.mname,
    required this.lname,
    required this.bday,
    this.createdAt,
    this.isPremium = false, // Default to false
  });

  // Get full name
  String get fullName {
    String name = fname;
    if (mname.isNotEmpty) {
      name += ' $mname';
    }
    name += ' $lname';
    return name;
  }

  // Factory constructor to create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      userTypeId: json['user_type_id'] != null ? int.tryParse(json['user_type_id'].toString()) : null,
      genderId: json['gender_id'] != null ? int.tryParse(json['gender_id'].toString()) : null,
      failedAttempt: int.tryParse(json['failed_attempt']?.toString() ?? '0') ?? 0,
      lastAttempt: json['last_attempt'] != null ? DateTime.tryParse(json['last_attempt'].toString()) : null,
      fname: json['fname']?.toString() ?? '',
      mname: json['mname']?.toString() ?? '',
      lname: json['lname']?.toString() ?? '',
      bday: DateTime.tryParse(json['bday']?.toString() ?? '') ?? DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isPremium: json['is_premium'] == true || json['is_premium'] == 1 || json['is_premium'] == '1', // Handle different boolean formats
    );
  }

  // Convert UserModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'user_type_id': userTypeId,
      'gender_id': genderId,
      'failed_attempt': failedAttempt,
      'last_attempt': lastAttempt?.toIso8601String(),
      'fname': fname,
      'mname': mname,
      'lname': lname,
      'bday': bday.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
      'is_premium': isPremium,
    };
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    int? id,
    String? email,
    String? password,
    int? userTypeId,
    int? genderId,
    int? failedAttempt,
    DateTime? lastAttempt,
    String? fname,
    String? mname,
    String? lname,
    DateTime? bday,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      userTypeId: userTypeId ?? this.userTypeId,
      genderId: genderId ?? this.genderId,
      failedAttempt: failedAttempt ?? this.failedAttempt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      fname: fname ?? this.fname,
      mname: mname ?? this.mname,
      lname: lname ?? this.lname,
      bday: bday ?? this.bday,
      createdAt: createdAt ?? this.createdAt,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  String toString() {
    return 'UserModel{id: $id, fullName: $fullName, email: $email, isPremium: $isPremium}';
  }
}

// Additional models for related data
class UserType {
  final int id;
  final String typeName;

  UserType({required this.id, required this.typeName});

  factory UserType.fromJson(Map<String, dynamic> json) {
    return UserType(
      id: int.tryParse(json['id'].toString()) ?? 0,
      typeName: json['type_name']?.toString() ?? '',
    );
  }
}

class Gender {
  final int id;
  final String genderName;

  Gender({required this.id, required this.genderName});

  factory Gender.fromJson(Map<String, dynamic> json) {
    return Gender(
      id: int.tryParse(json['id'].toString()) ?? 0,
      genderName: json['gender_name']?.toString() ?? '',
    );
  }
}
