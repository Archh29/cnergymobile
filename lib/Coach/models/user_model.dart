class UserModel {
  final int id;
  final String fname;
  final String mname;
  final String lname;
  final String email;
  final DateTime bday;
  final String? profileImage;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.fname,
    required this.mname,
    required this.lname,
    required this.email,
    required this.bday,
    this.profileImage,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.preferences,
    this.metadata,
  });

  // Computed properties
  String get fullName {
    String name = fname;
    if (mname.isNotEmpty) name += ' $mname';
    name += ' $lname';
    return name.trim();
  }

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

  bool get isCoach => role.toLowerCase() == 'coach';
  bool get isMember => role.toLowerCase() == 'member' || role.toLowerCase() == 'user';
  bool get isAdmin => role.toLowerCase() == 'admin';

  String get displayRole {
    switch (role.toLowerCase()) {
      case 'coach':
        return 'Coach';
      case 'admin':
        return 'Administrator';
      case 'member':
      case 'user':
        return 'Member';
      default:
        return 'User';
    }
  }

  // Factory constructor for JSON deserialization
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fname: json['fname'] ?? '',
      mname: json['mname'] ?? '',
      lname: json['lname'] ?? '',
      email: json['email'] ?? '',
      bday: DateTime.tryParse(json['bday'] ?? '') ?? DateTime.now(),
      profileImage: json['profile_image'],
      role: json['role'] ?? 'user',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
      isActive: json['is_active'].toString() == '0' ? false : true,
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences']) 
          : null,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
    );
  }

  // Method to convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'mname': mname,
      'lname': lname,
      'email': email,
      'bday': bday.toIso8601String(),
      'profile_image': profileImage,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'preferences': preferences,
      'metadata': metadata,
    };
  }

  // Method to create a copy with updated fields
  UserModel copyWith({
    int? id,
    String? fname,
    String? mname,
    String? lname,
    String? email,
    DateTime? bday,
    String? profileImage,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      fname: fname ?? this.fname,
      mname: mname ?? this.mname,
      lname: lname ?? this.lname,
      email: email ?? this.email,
      bday: bday ?? this.bday,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for user roles (optional, for type safety)
enum UserRole {
  admin,
  coach,
  member,
  user,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.coach:
        return 'coach';
      case UserRole.member:
        return 'member';
      case UserRole.user:
        return 'user';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.coach:
        return 'Coach';
      case UserRole.member:
        return 'Member';
      case UserRole.user:
        return 'User';
    }
  }
}
