class ExerciseModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> targetMuscles;

  ExerciseModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.videoUrl,
    this.targetMuscles = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
      targetMuscles: json['target_muscles'] != null 
          ? List<String>.from(json['target_muscles'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      'target_muscles': targetMuscles,
    };
  }
}
