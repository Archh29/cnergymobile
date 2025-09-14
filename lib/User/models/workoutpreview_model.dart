class WorkoutPreviewModel {
  final String routineId;
  final String routineName;
  final List<WorkoutExerciseModel> exercises;
  final WorkoutStatsModel stats;

  WorkoutPreviewModel({
    required this.routineId,
    required this.routineName,
    required this.exercises,
    required this.stats,
  });

  factory WorkoutPreviewModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPreviewModel(
      routineId: json['routine_id']?.toString() ?? '',
      routineName: json['routine_name'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((e) => WorkoutExerciseModel.fromJson(e))
          .toList() ?? [],
      stats: WorkoutStatsModel.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routine_id': routineId,
      'routine_name': routineName,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'stats': stats.toJson(),
    };
  }
}

class WorkoutExerciseModel {
  final int? exerciseId;
  final int? memberWorkoutExerciseId; // Added this field
  final String name;
  final String targetMuscle;
  final String description;
  final String imageUrl;
  final int sets;
  final String reps;
  final double weight;
  final int restTime;
  final String category;
  final String difficulty;
  
  // Progress tracking
  int completedSets;
  bool isCompleted;
  List<WorkoutSetModel> loggedSets;

  WorkoutExerciseModel({
    this.exerciseId,
    this.memberWorkoutExerciseId,
    required this.name,
    this.targetMuscle = '',
    this.description = '',
    this.imageUrl = '',
    required this.sets,
    required this.reps,
    required this.weight,
    this.restTime = 60,
    this.category = '',
    this.difficulty = '',
    this.completedSets = 0,
    this.isCompleted = false,
    List<WorkoutSetModel>? loggedSets,
  }) : loggedSets = loggedSets ?? [];

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseModel(
      exerciseId: json['exercise_id'],
      memberWorkoutExerciseId: json['member_workout_exercise_id'],
      name: json['name'] ?? '',
      targetMuscle: json['target_muscle'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps']?.toString() ?? '0',
      weight: (json['weight'] ?? 0.0).toDouble(),
      restTime: json['rest_time'] ?? 60,
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? '',
      completedSets: json['completed_sets'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      loggedSets: (json['logged_sets'] as List<dynamic>?)
          ?.map((s) => WorkoutSetModel.fromJson(s))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'member_workout_exercise_id': memberWorkoutExerciseId,
      'name': name,
      'target_muscle': targetMuscle,
      'description': description,
      'image_url': imageUrl,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'rest_time': restTime,
      'category': category,
      'difficulty': difficulty,
      'completed_sets': completedSets,
      'is_completed': isCompleted,
      'logged_sets': loggedSets.map((s) => s.toJson()).toList(),
    };
  }

  // Helper methods
  String get formattedWeight {
    if (weight == 0) return '';
    return '${weight.toStringAsFixed(weight.truncateToDouble() == weight ? 0 : 1)} kg';
  }

  String get exerciseDetails {
    return '$sets sets - $reps reps - $formattedWeight';
  }

  double get totalVolume {
    return loggedSets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
  }
}

class WorkoutSetModel {
  final int reps;
  final double weight;
  final int rpe; // Rate of Perceived Exertion
  final String notes;
  final DateTime timestamp;
  final bool isCompleted;

  WorkoutSetModel({
    required this.reps,
    required this.weight,
    this.rpe = 0,
    this.notes = '',
    required this.timestamp,
    this.isCompleted = false,
  });

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSetModel(
      reps: json['reps'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      rpe: json['rpe'] ?? 0,
      notes: json['notes'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      'is_completed': isCompleted,
    };
  }
}

class WorkoutStatsModel {
  final int estimatedDuration; // in minutes
  final int estimatedCalories;
  final double estimatedVolume; // in kg
  final int totalExercises;
  final int totalSets;

  WorkoutStatsModel({
    this.estimatedDuration = 0,
    this.estimatedCalories = 0,
    this.estimatedVolume = 0.0,
    this.totalExercises = 0,
    this.totalSets = 0,
  });

  factory WorkoutStatsModel.fromJson(Map<String, dynamic> json) {
    return WorkoutStatsModel(
      estimatedDuration: json['estimated_duration'] ?? 0,
      estimatedCalories: json['estimated_calories'] ?? 0,
      estimatedVolume: (json['estimated_volume'] ?? 0.0).toDouble(),
      totalExercises: json['total_exercises'] ?? 0,
      totalSets: json['total_sets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_duration': estimatedDuration,
      'estimated_calories': estimatedCalories,
      'estimated_volume': estimatedVolume,
      'total_exercises': totalExercises,
      'total_sets': totalSets,
    };
  }

  String get formattedDuration {
    if (estimatedDuration < 60) {
      return '${estimatedDuration}min';
    } else {
      final hours = estimatedDuration ~/ 60;
      final minutes = estimatedDuration % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }

  String get formattedCalories {
    return '$estimatedCalories kcal';
  }

  String get formattedVolume {
    if (estimatedVolume >= 1000) {
      return '${(estimatedVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${estimatedVolume.toStringAsFixed(0)} kg';
  }
}
