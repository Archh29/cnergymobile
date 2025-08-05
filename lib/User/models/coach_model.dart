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
  final double hourlyRate;
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
    required this.hourlyRate,
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
      hourlyRate: (json['hourly_rate'] ?? 0.0).toDouble(),
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
      'hourly_rate': hourlyRate,
      'certifications': certifications,
    };
  }
}
