import 'dart:convert';
import 'package:flutter/material.dart';
import './exercise_model.dart';

enum RoutineStatus {
  active,
  inactive,
  archived,
  draft,
}

enum RoutineDifficulty {
  beginner,
  intermediate,
  advanced,
  expert,
}

enum RoutineCategory {
  strength,
  cardio,
  hiit,
  yoga,
  pilates,
  crossfit,
  bodyweight,
  powerlifting,
  olympic,
  rehabilitation,
  flexibility,
  sports_specific,
}

class RoutineModel {
  final String id;
  final String name;
  final String description;
  final RoutineCategory category;
  final RoutineDifficulty difficulty;
  final RoutineStatus status;
  final int exercises;
  final String duration;
  final String exerciseList;
  final String createdBy;
  final String? coachId;
  final String? memberId;
  final String color;
  final String lastPerformed;
  final List<String> tags;
  final String goal;
  final int completionRate;
  final int totalSessions;
  final String notes;
  final List<String> scheduledDays;
  final double version;
  final DateTime createdDate;
  final DateTime? lastModified;
  final Map<String, dynamic> exerciseDetails;
  final List<String> equipment;
  final int? estimatedCalories;
  final String? targetMuscleGroups;
  final Map<String, dynamic> progressTracking;
  final List<String> prerequisites;
  final String? videoUrl;
  final List<String> images;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final bool isFavorite;
  final double? averageRating;
  final int? totalRatings;
  final List<ExerciseModel>? detailedExercises;

  RoutineModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = RoutineCategory.strength,
    this.difficulty = RoutineDifficulty.beginner,
    this.status = RoutineStatus.active,
    required this.exercises,
    required this.duration,
    required this.exerciseList,
    required this.createdBy,
    this.coachId,
    this.memberId,
    required this.color,
    this.lastPerformed = 'Never',
    this.tags = const [],
    this.goal = 'General Fitness',
    this.completionRate = 0,
    this.totalSessions = 0,
    this.notes = '',
    this.scheduledDays = const [],
    this.version = 1.0,
    required this.createdDate,
    this.lastModified,
    this.exerciseDetails = const {},
    this.equipment = const [],
    this.estimatedCalories,
    this.targetMuscleGroups,
    this.progressTracking = const {},
    this.prerequisites = const [],
    this.videoUrl,
    this.images = const [],
    this.metadata = const {},
    this.isPublic = false,
    this.isFavorite = false,
    this.averageRating,
    this.totalRatings,
    this.detailedExercises,
  });

  // Computed properties
  bool get isActive => status == RoutineStatus.active;
  bool get isArchived => status == RoutineStatus.archived;
  bool get isDraft => status == RoutineStatus.draft;

  String get formattedCreatedDate {
    final now = DateTime.now();
    final difference = now.difference(createdDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference <= 7) {
      return '$difference days ago';
    } else if (difference <= 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${createdDate.day}/${createdDate.month}/${createdDate.year}';
    }
  }

  String get difficultyText {
    switch (difficulty) {
      case RoutineDifficulty.beginner:
        return 'Beginner';
      case RoutineDifficulty.intermediate:
        return 'Intermediate';
      case RoutineDifficulty.advanced:
        return 'Advanced';
      case RoutineDifficulty.expert:
        return 'Expert';
    }
  }

  String get categoryText {
    switch (category) {
      case RoutineCategory.strength:
        return 'Strength Training';
      case RoutineCategory.cardio:
        return 'Cardio';
      case RoutineCategory.hiit:
        return 'HIIT';
      case RoutineCategory.yoga:
        return 'Yoga';
      case RoutineCategory.pilates:
        return 'Pilates';
      case RoutineCategory.crossfit:
        return 'CrossFit';
      case RoutineCategory.bodyweight:
        return 'Bodyweight';
      case RoutineCategory.powerlifting:
        return 'Powerlifting';
      case RoutineCategory.olympic:
        return 'Olympic Lifting';
      case RoutineCategory.rehabilitation:
        return 'Rehabilitation';
      case RoutineCategory.flexibility:
        return 'Flexibility';
      case RoutineCategory.sports_specific:
        return 'Sports Specific';
    }
  }

  String get statusText {
    switch (status) {
      case RoutineStatus.active:
        return 'Active';
      case RoutineStatus.inactive:
        return 'Inactive';
      case RoutineStatus.archived:
        return 'Archived';
      case RoutineStatus.draft:
        return 'Draft';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case RoutineDifficulty.beginner:
        return Color(0xFF2ECC71);
      case RoutineDifficulty.intermediate:
        return Color(0xFFF39C12);
      case RoutineDifficulty.advanced:
        return Color(0xFFE67E22);
      case RoutineDifficulty.expert:
        return Color(0xFFE74C3C);
    }
  }

  Color get categoryColor {
    switch (category) {
      case RoutineCategory.strength:
        return Color(0xFF4ECDC4);
      case RoutineCategory.cardio:
        return Color(0xFFE74C3C);
      case RoutineCategory.hiit:
        return Color(0xFFFF6B35);
      case RoutineCategory.yoga:
        return Color(0xFF96CEB4);
      case RoutineCategory.pilates:
        return Color(0xFF9B59B6);
      case RoutineCategory.crossfit:
        return Color(0xFF34495E);
      case RoutineCategory.bodyweight:
        return Color(0xFF3498DB);
      case RoutineCategory.powerlifting:
        return Color(0xFF2C3E50);
      case RoutineCategory.olympic:
        return Color(0xFFD35400);
      case RoutineCategory.rehabilitation:
        return Color(0xFF27AE60);
      case RoutineCategory.flexibility:
        return Color(0xFFF39C12);
      case RoutineCategory.sports_specific:
        return Color(0xFF8E44AD);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case RoutineCategory.strength:
        return Icons.fitness_center;
      case RoutineCategory.cardio:
        return Icons.directions_run;
      case RoutineCategory.hiit:
        return Icons.flash_on;
      case RoutineCategory.yoga:
        return Icons.self_improvement;
      case RoutineCategory.pilates:
        return Icons.accessibility_new;
      case RoutineCategory.crossfit:
        return Icons.sports_gymnastics;
      case RoutineCategory.bodyweight:
        return Icons.accessibility;
      case RoutineCategory.powerlifting:
        return Icons.fitness_center;
      case RoutineCategory.olympic:
        return Icons.emoji_events;
      case RoutineCategory.rehabilitation:
        return Icons.healing;
      case RoutineCategory.flexibility:
        return Icons.accessibility_new;
      case RoutineCategory.sports_specific:
        return Icons.sports;
    }
  }

  String get formattedDuration {
    if (duration.toLowerCase().contains('min')) {
      return duration;
    }
    return '$duration min';
  }

  String get exerciseCountText {
    return '$exercises exercise${exercises != 1 ? 's' : ''}';
  }

  List<String> get exerciseListArray {
    if (exerciseList.isEmpty) return [];
    return exerciseList
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // JSON serialization
  static int _parseExerciseCount(Map<String, dynamic> json) {
    print('🔍 EXERCISE COUNT: Parsing exercise count from JSON');
    print('🔍 EXERCISE COUNT: exercise_count: ${json['exercise_count']}');
    print('🔍 EXERCISE COUNT: exercises: ${json['exercises']}');
    print('🔍 EXERCISE COUNT: exercise_list: ${json['exercise_list']}');
    
    // First try to get the count from API fields
    int? count = json['exercise_count'] ?? json['exercises'];
    print('🔍 EXERCISE COUNT: Initial count from API fields: $count');
    
    // If no count provided, try to count from exercise_list
    if (count == null || count == 0) {
      final exerciseList = json['exercise_list'] ?? '';
      print('🔍 EXERCISE COUNT: Checking exercise_list: $exerciseList');
      if (exerciseList.isNotEmpty && exerciseList != 'No exercises added') {
        final exercises = exerciseList.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        print('🔍 EXERCISE COUNT: Parsed exercises from list: $exercises (count: ${exercises.length})');
        return exercises.length;
      }
    }
    
    // If still no count, check workout_details for exercises
    if (count == null || count == 0) {
      if (json['workout_details'] != null && json['workout_details'] is Map) {
        final workoutDetails = json['workout_details'] as Map<String, dynamic>;
        print('🔍 EXERCISE COUNT: Checking workout_details: ${workoutDetails.keys.toList()}');
        if (workoutDetails['exercises'] != null && workoutDetails['exercises'] is List) {
          final exerciseCount = (workoutDetails['exercises'] as List).length;
          print('🔍 EXERCISE COUNT: Found exercises in workout_details: $exerciseCount');
          return exerciseCount;
        }
      }
    }
    
    print('🔍 EXERCISE COUNT: Final count: ${count ?? 0}');
    return count ?? 0;
  }

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    print('🔍 ROUTINE MODEL: Parsing JSON with keys: ${json.keys.toList()}');
    print('🔍 ROUTINE MODEL: Full JSON data: $json');
    print('🔍 ROUTINE MODEL: detailedExercises field: ${json['detailedExercises']}');
    print('🔍 ROUTINE MODEL: detailedExercises type: ${json['detailedExercises'].runtimeType}');
    print('🔍 ROUTINE MODEL: detailedExercises length: ${json['detailedExercises'] is List ? (json['detailedExercises'] as List).length : 'not a list'}');
    
    // Try different possible field names for the routine name
    String routineName = json['name'] ?? 
                        json['title'] ?? 
                        json['program_name'] ?? 
                        json['routine_name'] ?? 
                        json['program_title'] ?? 
                        json['goal'] ?? 
                        json['description'] ?? 
                        'Unnamed Routine';
    
    print('🔍 ROUTINE MODEL: Initial routine name: $routineName');
    print('🔍 ROUTINE MODEL: name field: ${json['name']}');
    print('🔍 ROUTINE MODEL: title field: ${json['title']}');
    print('🔍 ROUTINE MODEL: program_name field: ${json['program_name']}');
    print('🔍 ROUTINE MODEL: routine_name field: ${json['routine_name']}');
    print('🔍 ROUTINE MODEL: goal field: ${json['goal']}');
    print('🔍 ROUTINE MODEL: description field: ${json['description']}');
    
    // Check if workout_details contains the name
    if (json['workout_details'] != null && json['workout_details'] is Map) {
      final workoutDetails = json['workout_details'] as Map<String, dynamic>;
      print('🔍 ROUTINE MODEL: workout_details keys: ${workoutDetails.keys.toList()}');
      print('🔍 ROUTINE MODEL: workout_details name: ${workoutDetails['name']}');
      routineName = workoutDetails['name'] ?? routineName;
      print('🔍 ROUTINE MODEL: Final routine name after workout_details: $routineName');
    }
    
    // Also check routine_name field
    if (json['routine_name'] != null && json['routine_name'].toString().isNotEmpty) {
      routineName = json['routine_name'].toString();
      print('🔍 ROUTINE MODEL: Using routine_name: $routineName');
    }
    
    return RoutineModel(
      id: json['id']?.toString() ?? json['routine_id']?.toString() ?? '',
      name: routineName,
      description: json['description'] ?? '',
      category: RoutineCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => RoutineCategory.strength,
      ),
      difficulty: RoutineDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (json['difficulty']?.toString().toLowerCase() ?? 'beginner'),
        orElse: () => RoutineDifficulty.beginner,
      ),
      status: RoutineStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => RoutineStatus.active,
      ),
      exercises: _parseExerciseCount(json),
      duration: json['duration'] ?? '',
      exerciseList: json['exercise_list'] ?? '',
      createdBy: json['created_by']?.toString() ?? json['creator_name']?.toString() ?? '',
      coachId: json['coach_id']?.toString(),
      memberId: json['member_id']?.toString(),
      color: json['color'] ?? '',
      lastPerformed: json['last_performed'] ?? 'Never',
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      goal: json['goal'] ?? 'General Fitness',
      completionRate: json['completion_rate'] ?? 0,
      totalSessions: json['total_sessions'] ?? 0,
      notes: json['notes'] ?? '',
      scheduledDays: json['scheduled_days'] is List 
          ? List<String>.from(json['scheduled_days']) 
          : [],
      version: json['version']?.toDouble() ?? 1.0,
      createdDate: DateTime.tryParse(json['created_at'] ?? json['created_date'] ?? '') ?? DateTime.now(),
      lastModified: json['last_modified'] != null 
          ? DateTime.tryParse(json['last_modified']) 
          : null,
      exerciseDetails: json['exercise_details'] is Map 
          ? Map<String, dynamic>.from(json['exercise_details']) 
          : {},
      equipment: json['equipment'] is List 
          ? List<String>.from(json['equipment']) 
          : [],
      estimatedCalories: json['estimated_calories'],
      targetMuscleGroups: json['target_muscle_groups'],
      progressTracking: json['progress_tracking'] is Map 
          ? Map<String, dynamic>.from(json['progress_tracking']) 
          : {},
      prerequisites: json['prerequisites'] is List 
          ? List<String>.from(json['prerequisites']) 
          : [],
      videoUrl: json['video_url'],
      images: json['images'] is List 
          ? List<String>.from(json['images']) 
          : [],
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata']) 
          : {},
      isPublic: json['is_public'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      averageRating: _safeParseDouble(json['average_rating']),
      totalRatings: json['total_ratings'],
      detailedExercises: json['detailedExercises'] != null && json['detailedExercises'] is List
          ? (() {
              print('🔍 ROUTINE MODEL: Parsing detailedExercises, count: ${(json['detailedExercises'] as List).length}');
              final exercises = (json['detailedExercises'] as List)
                  .map((e) {
                    print('🔍 ROUTINE MODEL: Parsing exercise: $e');
                    return ExerciseModel.fromJson(e);
                  })
                  .toList();
              print('🔍 ROUTINE MODEL: Successfully parsed ${exercises.length} exercises');
              return exercises;
            })()
          : (() {
              print('🔍 ROUTINE MODEL: No detailedExercises found or not a list');
              return null;
            })(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'status': status.toString().split('.').last,
      'exercises': exercises,
      'duration': duration,
      'exercise_list': exerciseList,
      'created_by': createdBy,
      'coach_id': coachId,
      'member_id': memberId,
      'color': color,
      'last_performed': lastPerformed,
      'tags': tags,
      'goal': goal,
      'completion_rate': completionRate,
      'total_sessions': totalSessions,
      'notes': notes,
      'scheduled_days': scheduledDays,
      'version': version,
      'created_date': createdDate.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'exercise_details': exerciseDetails,
      'equipment': equipment,
      'estimated_calories': estimatedCalories,
      'target_muscle_groups': targetMuscleGroups,
      'progress_tracking': progressTracking,
      'prerequisites': prerequisites,
      'video_url': videoUrl,
      'images': images,
      'metadata': metadata,
      'is_public': isPublic,
      'is_favorite': isFavorite,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'detailedExercises': detailedExercises?.map((e) => e.toJson()).toList(),
    };
  }

  // Copy method
  RoutineModel copyWith({
    String? id,
    String? name,
    String? description,
    RoutineCategory? category,
    RoutineDifficulty? difficulty,
    RoutineStatus? status,
    int? exercises,
    String? duration,
    String? exerciseList,
    String? createdBy,
    String? coachId,
    String? memberId,
    String? color,
    String? lastPerformed,
    List<String>? tags,
    String? goal,
    int? completionRate,
    int? totalSessions,
    String? notes,
    List<String>? scheduledDays,
    double? version,
    DateTime? createdDate,
    DateTime? lastModified,
    Map<String, dynamic>? exerciseDetails,
    List<String>? equipment,
    int? estimatedCalories,
    String? targetMuscleGroups,
    Map<String, dynamic>? progressTracking,
    List<String>? prerequisites,
    String? videoUrl,
    List<String>? images,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    bool? isFavorite,
    double? averageRating,
    int? totalRatings,
    List<ExerciseModel>? detailedExercises,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      duration: duration ?? this.duration,
      exerciseList: exerciseList ?? this.exerciseList,
      createdBy: createdBy ?? this.createdBy,
      coachId: coachId ?? this.coachId,
      memberId: memberId ?? this.memberId,
      color: color ?? this.color,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      tags: tags ?? this.tags,
      goal: goal ?? this.goal,
      completionRate: completionRate ?? this.completionRate,
      totalSessions: totalSessions ?? this.totalSessions,
      notes: notes ?? this.notes,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      version: version ?? this.version,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      exerciseDetails: exerciseDetails ?? this.exerciseDetails,
      equipment: equipment ?? this.equipment,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      progressTracking: progressTracking ?? this.progressTracking,
      prerequisites: prerequisites ?? this.prerequisites,
      videoUrl: videoUrl ?? this.videoUrl,
      images: images ?? this.images,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      detailedExercises: detailedExercises ?? this.detailedExercises,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutineModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoutineModel(id: $id, name: $name, category: $categoryText, difficulty: $difficultyText)';
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
