class RoutineModel {
  final String id;
  final String name;
  final int exercises;
  final String duration;
  final String difficulty;
  final String createdBy;
  final String exerciseList;
  final String color;
  final String lastPerformed;
  final List<String> tags;
  final String goal;
  final int completionRate;
  final int totalSessions;
  final String notes;
  final List<String> scheduledDays;
  final double version;
  final List<ExerciseModel>? detailedExercises;

  RoutineModel({
    required this.id,
    required this.name,
    required this.exercises,
    required this.duration,
    required this.difficulty,
    required this.createdBy,
    required this.exerciseList,
    required this.color,
    required this.lastPerformed,
    required this.tags,
    required this.goal,
    required this.completionRate,
    required this.totalSessions,
    required this.notes,
    required this.scheduledDays,
    required this.version,
    this.detailedExercises,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      exercises: json['exercises'] ?? 0,
      duration: json['duration'] ?? '',
      difficulty: json['difficulty'] ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      exerciseList: json['exerciseList'] ?? '',
      color: json['color'] ?? '0xFF96CEB4',
      lastPerformed: json['lastPerformed'] ?? 'Never',
      tags: List<String>.from(json['tags'] ?? []),
      goal: json['goal'] ?? '',
      completionRate: json['completionRate'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      notes: json['notes'] ?? '',
      scheduledDays: List<String>.from(json['scheduledDays'] ?? []),
      version: (json['version'] ?? 1.0).toDouble(),
      detailedExercises: json['detailedExercises'] != null
          ? (json['detailedExercises'] as List)
              .map((e) => ExerciseModel.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises,
      'duration': duration,
      'difficulty': difficulty,
      'createdBy': createdBy,
      'exerciseList': exerciseList,
      'color': color,
      'lastPerformed': lastPerformed,
      'tags': tags,
      'goal': goal,
      'completionRate': completionRate,
      'totalSessions': totalSessions,
      'notes': notes,
      'scheduledDays': scheduledDays,
      'version': version,
      'detailedExercises': detailedExercises?.map((e) => e.toJson()).toList(),
    };
  }
}

class ExerciseModel {
  final int? id; // Database ID
  final String name;
  final int targetSets;
  final String targetReps;
  final String targetWeight;
  int completedSets;
  List<ExerciseSet> sets;
  bool completed;
  final String category;
  final String difficulty;
  final String color;
  final int restTime;
  String notes;
  final String targetMuscle; // New field for muscle group
  final String description; // Exercise description
  final String imageUrl; // Exercise image

  ExerciseModel({
    this.id,
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    this.completedSets = 0,
    List<ExerciseSet>? sets,
    this.completed = false,
    required this.category,
    required this.difficulty,
    required this.color,
    required this.restTime,
    this.notes = '',
    this.targetMuscle = '',
    this.description = '',
    this.imageUrl = '',
  }) : sets = sets ?? [];

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'],
      name: json['name'] ?? '',
      targetSets: json['target_sets'] ?? json['targetSets'] ?? 0,
      targetReps: json['target_reps']?.toString() ?? json['targetReps']?.toString() ?? '',
      targetWeight: json['target_weight']?.toString() ?? json['targetWeight']?.toString() ?? '',
      completedSets: json['completed_sets'] ?? json['completedSets'] ?? 0,
      sets: json['sets'] != null
          ? (json['sets'] as List).map((s) => ExerciseSet.fromJson(s)).toList()
          : [],
      completed: json['completed'] ?? false,
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? '',
      color: json['color'] ?? '0xFF96CEB4',
      restTime: json['rest_time'] ?? json['restTime'] ?? 60,
      notes: json['notes'] ?? '',
      targetMuscle: json['target_muscle'] ?? json['targetMuscle'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'completed_sets': completedSets,
      'sets': sets.map((s) => s.toJson()).toList(),
      'completed': completed,
      'category': category,
      'difficulty': difficulty,
      'color': color,
      'rest_time': restTime,
      'notes': notes,
      'target_muscle': targetMuscle,
      'description': description,
      'image_url': imageUrl,
    };
  }

  double get totalVolume {
    return sets.fold(0.0, (sum, set) {
      double weight = double.tryParse(set.weight.replaceAll('kg', '')) ?? 0;
      int reps = int.tryParse(set.reps.toString()) ?? 0;
      return sum + (weight * reps);
    });
  }
}

class ExerciseSet {
  final String reps;
  final String weight;
  final int rpe;
  final String duration;
  final DateTime timestamp;

  ExerciseSet({
    required this.reps,
    required this.weight,
    this.rpe = 0,
    this.duration = '',
    required this.timestamp,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      reps: json['reps']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      rpe: json['rpe'] ?? 0,
      duration: json['duration']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reps': reps,
      'weight': weight,
      'rpe': rpe,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class TargetMuscleModel {
  final int id;
  final String name;
  final String imageUrl;

  TargetMuscleModel({
    required this.id,
    required this.name,
    this.imageUrl = '',
  });

  factory TargetMuscleModel.fromJson(Map<String, dynamic> json) {
    return TargetMuscleModel(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }
}

class RoutineResponse {
  final bool success;
  final List<RoutineModel> routines;
  final int totalRoutines;
  final bool isPremium;
  final Map<String, dynamic>? membershipStatus;
  final String? error;

  RoutineResponse({
    required this.success,
    required this.routines,
    required this.totalRoutines,
    required this.isPremium,
    this.membershipStatus,
    this.error,
  });

  factory RoutineResponse.fromJson(Map<String, dynamic> json) {
    return RoutineResponse(
      success: json['success'] ?? false,
      routines: json['routines'] != null 
          ? (json['routines'] as List).map((r) => RoutineModel.fromJson(r)).toList()
          : [],
      totalRoutines: json['total_routines'] ?? 0,
      isPremium: json['is_premium'] ?? false,
      membershipStatus: json['membership_status'],
      error: json['error'],
    );
  }
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final String routineName;
  final int duration;
  final int exercises;
  final double totalVolume;
  final int calories;
  final int rating;
  final String bodyPart;
  final String notes;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.routineName,
    required this.duration,
    required this.exercises,
    required this.totalVolume,
    required this.calories,
    required this.rating,
    required this.bodyPart,
    required this.notes,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id']?.toString() ?? '',
      date: DateTime.parse(json['date']),
      routineName: json['routine'] ?? '',
      duration: json['duration'] ?? 0,
      exercises: json['exercises'] ?? 0,
      totalVolume: (json['totalVolume'] ?? 0.0).toDouble(),
      calories: json['calories'] ?? 0,
      rating: json['rating'] ?? 0,
      bodyPart: json['bodyPart'] ?? '',
      notes: json['notes'] ?? '',
    );
  }
}
