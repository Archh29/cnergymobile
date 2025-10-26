class CoachModel {
  final int id;
  final String name;
  final String specialty;
  final String experience;
  final double rating;
  final int totalClients;
  final String bio;
  final String imageUrl;
  final bool isAvailable;
  final double sessionRate;
  final double? monthlyRate;
  final double? sessionPackageRate;
  final int? sessionPackageCount;
  final List<String> certifications;

  CoachModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.rating,
    required this.totalClients,
    required this.bio,
    required this.imageUrl,
    required this.isAvailable,
    required this.sessionRate,
    this.monthlyRate,
    this.sessionPackageRate,
    this.sessionPackageCount,
    required this.certifications,
  });

  factory CoachModel.fromJson(Map<String, dynamic> json) {
    return CoachModel(
      id: _safeParseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      experience: json['experience'] ?? '',
      rating: _safeParseDouble(json['rating']) ?? 0.0,
      totalClients: _safeParseInt(json['total_clients']) ?? 0,
      bio: json['bio'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isAvailable: json['is_available'] ?? true,
      sessionRate: _safeParseDouble(json['hourly_rate']) ?? 0.0,
      monthlyRate: json['monthly_rate'] != null ? _safeParseDouble(json['monthly_rate']) : null,
      sessionPackageRate: json['session_package_rate'] != null ? _safeParseDouble(json['session_package_rate']) : null,
      sessionPackageCount: _safeParseInt(json['session_package_count']),
      certifications: List<String>.from(json['certifications'] ?? []),
    );
  }

  // Helper method to safely parse double values from API responses
  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
        return null;
      }
    }
    return null;
  }

  // Helper method to safely parse int values from API responses
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $value');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'experience': experience,
      'rating': rating,
      'total_clients': totalClients,
      'bio': bio,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'hourly_rate': sessionRate,
      'monthly_rate': monthlyRate,
      'session_package_rate': sessionPackageRate,
      'session_package_count': sessionPackageCount,
      'certifications': certifications,
    };
  }
}
