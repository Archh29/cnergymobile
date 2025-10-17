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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      experience: json['experience'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalClients: json['total_clients'] ?? 0,
      bio: json['bio'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isAvailable: json['is_available'] ?? true,
      sessionRate: (json['hourly_rate'] ?? 0.0).toDouble(),
      monthlyRate: json['monthly_rate'] != null ? (json['monthly_rate'] as num).toDouble() : null,
      sessionPackageRate: json['session_package_rate'] != null ? (json['session_package_rate'] as num).toDouble() : null,
      sessionPackageCount: json['session_package_count'],
      certifications: List<String>.from(json['certifications'] ?? []),
    );
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
