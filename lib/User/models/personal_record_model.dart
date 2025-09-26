class PersonalRecordModel {
  final int? id;
  final int userId;
  final int exerciseId;
  final double? maxWeight;
  final DateTime? achievedOn;
  final String? exerciseName;
  final String? exerciseDescription;
  final String? primaryMuscleGroup;

  PersonalRecordModel({
    this.id,
    required this.userId,
    required this.exerciseId,
    this.maxWeight,
    this.achievedOn,
    this.exerciseName,
    this.exerciseDescription,
    this.primaryMuscleGroup,
  });

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.parse(json['user_id'].toString()),
      exerciseId: int.parse(json['exercise_id'].toString()),
      maxWeight: json['max_weight'] != null ? double.tryParse(json['max_weight'].toString()) : null,
      achievedOn: json['achieved_on'] != null ? DateTime.parse(json['achieved_on']) : null,
      exerciseName: json['exercise_name']?.toString(),
      exerciseDescription: json['exercise_description']?.toString(),
      primaryMuscleGroup: json['primary_muscle_group']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      if (maxWeight != null) 'max_weight': maxWeight,
      if (achievedOn != null) 'achieved_on': achievedOn!.toIso8601String().split('T')[0],
    };
  }

  String get formattedWeight {
    if (maxWeight == null) return '--';
    return '${maxWeight!.toStringAsFixed(1)} kg';
  }

  String get formattedDate {
    if (achievedOn == null) return '--';
    final now = DateTime.now();
    final difference = now.difference(achievedOn!).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${achievedOn!.day}/${achievedOn!.month}/${achievedOn!.year}';
  }
}
