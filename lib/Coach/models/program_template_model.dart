import 'package:flutter/material.dart';
import '../models/routine.models.dart';


enum ProgramTemplateCategory {
  beginner_friendly,
  weight_loss,
  muscle_building,
  strength_training,
  endurance,
  rehabilitation,
  sports_specific,
  general_fitness,
}

class ProgramTemplateModel {
  final String id;
  final String name;
  final String description;
  final ProgramTemplateCategory category;
  final RoutineDifficulty difficulty;
  final List<RoutineModel> routines;
  final String createdBy;
  final String coachId;
  final String color;
  final List<String> tags;
  final String goal;
  final int estimatedWeeks;
  final String targetAudience;
  final DateTime createdDate;
  final DateTime? lastModified;
  final bool isPublic;
  final bool isFavorite;
  final int timesUsed;
  final double? averageRating;
  final int? totalRatings;
  final List<String> equipment;
  final String notes;
  final Map<String, dynamic> metadata;

  ProgramTemplateModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = ProgramTemplateCategory.general_fitness,
    this.difficulty = RoutineDifficulty.beginner,
    this.routines = const [],
    required this.createdBy,
    required this.coachId,
    required this.color,
    this.tags = const [],
    this.goal = 'General Fitness',
    this.estimatedWeeks = 4,
    this.targetAudience = 'All levels',
    required this.createdDate,
    this.lastModified,
    this.isPublic = false,
    this.isFavorite = false,
    this.timesUsed = 0,
    this.averageRating,
    this.totalRatings,
    this.equipment = const [],
    this.notes = '',
    this.metadata = const {},
  });

  String get categoryText {
    switch (category) {
      case ProgramTemplateCategory.beginner_friendly:
        return 'Beginner Friendly';
      case ProgramTemplateCategory.weight_loss:
        return 'Weight Loss';
      case ProgramTemplateCategory.muscle_building:
        return 'Muscle Building';
      case ProgramTemplateCategory.strength_training:
        return 'Strength Training';
      case ProgramTemplateCategory.endurance:
        return 'Endurance';
      case ProgramTemplateCategory.rehabilitation:
        return 'Rehabilitation';
      case ProgramTemplateCategory.sports_specific:
        return 'Sports Specific';
      case ProgramTemplateCategory.general_fitness:
        return 'General Fitness';
    }
  }

  Color get categoryColor {
    switch (category) {
      case ProgramTemplateCategory.beginner_friendly:
        return Color(0xFF2ECC71);
      case ProgramTemplateCategory.weight_loss:
        return Color(0xFFE74C3C);
      case ProgramTemplateCategory.muscle_building:
        return Color(0xFF4ECDC4);
      case ProgramTemplateCategory.strength_training:
        return Color(0xFF34495E);
      case ProgramTemplateCategory.endurance:
        return Color(0xFF3498DB);
      case ProgramTemplateCategory.rehabilitation:
        return Color(0xFF27AE60);
      case ProgramTemplateCategory.sports_specific:
        return Color(0xFF8E44AD);
      case ProgramTemplateCategory.general_fitness:
        return Color(0xFFF39C12);
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ProgramTemplateCategory.beginner_friendly:
        return Icons.school;
      case ProgramTemplateCategory.weight_loss:
        return Icons.trending_down;
      case ProgramTemplateCategory.muscle_building:
        return Icons.fitness_center;
      case ProgramTemplateCategory.strength_training:
        return Icons.sports_gymnastics;
      case ProgramTemplateCategory.endurance:
        return Icons.directions_run;
      case ProgramTemplateCategory.rehabilitation:
        return Icons.healing;
      case ProgramTemplateCategory.sports_specific:
        return Icons.sports;
      case ProgramTemplateCategory.general_fitness:
        return Icons.accessibility_new;
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

  String get routineCountText {
    return '${routines.length} routine${routines.length != 1 ? 's' : ''}';
  }

  String get estimatedDuration {
    if (routines.isEmpty) return 'No routines';
    
    final totalMinutes = routines.fold(0, (sum, routine) {
      final durationStr = routine.duration.replaceAll(RegExp(r'[^0-9]'), '');
      return sum + (int.tryParse(durationStr) ?? 0);
    });
    
    if (totalMinutes < 60) {
      return '${totalMinutes}min per session';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return '${hours}h ${minutes}min per session';
    }
  }

  factory ProgramTemplateModel.fromJson(Map<String, dynamic> json) {
    return ProgramTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: ProgramTemplateCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ProgramTemplateCategory.general_fitness,
      ),
      difficulty: RoutineDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => RoutineDifficulty.beginner,
      ),
      routines: json['routines'] is List
          ? (json['routines'] as List)
              .map((r) => RoutineModel.fromJson(r))
              .toList()
          : [],
      createdBy: json['created_by'] ?? '',
      coachId: json['coach_id']?.toString() ?? '',
      color: json['color'] ?? '',
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      goal: json['goal'] ?? 'General Fitness',
      estimatedWeeks: json['estimated_weeks'] ?? 4,
      targetAudience: json['target_audience'] ?? 'All levels',
      createdDate: DateTime.tryParse(json['created_date'] ?? '') ?? DateTime.now(),
      lastModified: json['last_modified'] != null 
          ? DateTime.tryParse(json['last_modified']) 
          : null,
      isPublic: json['is_public'] ?? false,
      isFavorite: json['is_favorite'] ?? false,
      timesUsed: json['times_used'] ?? 0,
      averageRating: _safeParseDouble(json['average_rating']),
      totalRatings: json['total_ratings'],
      equipment: json['equipment'] is List 
          ? List<String>.from(json['equipment']) 
          : [],
      notes: json['notes'] ?? '',
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'routines': routines.map((r) => r.toJson()).toList(),
      'created_by': createdBy,
      'coach_id': coachId,
      'color': color,
      'tags': tags,
      'goal': goal,
      'estimated_weeks': estimatedWeeks,
      'target_audience': targetAudience,
      'created_date': createdDate.toIso8601String(),
      'last_modified': lastModified?.toIso8601String(),
      'is_public': isPublic,
      'is_favorite': isFavorite,
      'times_used': timesUsed,
      'average_rating': averageRating,
      'total_ratings': totalRatings,
      'equipment': equipment,
      'notes': notes,
      'metadata': metadata,
    };
  }

  ProgramTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    ProgramTemplateCategory? category,
    RoutineDifficulty? difficulty,
    List<RoutineModel>? routines,
    String? createdBy,
    String? coachId,
    String? color,
    List<String>? tags,
    String? goal,
    int? estimatedWeeks,
    String? targetAudience,
    DateTime? createdDate,
    DateTime? lastModified,
    bool? isPublic,
    bool? isFavorite,
    int? timesUsed,
    double? averageRating,
    int? totalRatings,
    List<String>? equipment,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ProgramTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      routines: routines ?? this.routines,
      createdBy: createdBy ?? this.createdBy,
      coachId: coachId ?? this.coachId,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      goal: goal ?? this.goal,
      estimatedWeeks: estimatedWeeks ?? this.estimatedWeeks,
      targetAudience: targetAudience ?? this.targetAudience,
      createdDate: createdDate ?? this.createdDate,
      lastModified: lastModified ?? this.lastModified,
      isPublic: isPublic ?? this.isPublic,
      isFavorite: isFavorite ?? this.isFavorite,
      timesUsed: timesUsed ?? this.timesUsed,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgramTemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProgramTemplateModel(id: $id, name: $name, category: $categoryText)';
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
