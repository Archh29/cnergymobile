import 'package:flutter/material.dart';
import './routine.models.dart';

// Enhanced muscle group model for selection
class MuscleGroupModel {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final bool isSelected;

  MuscleGroupModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description = '',
    this.isSelected = false,
  });

  MuscleGroupModel copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    bool? isSelected,
  }) {
    return MuscleGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory MuscleGroupModel.fromTargetMuscle(TargetMuscleModel muscle) {
    return MuscleGroupModel(
      id: muscle.id,
      name: muscle.name,
      imageUrl: muscle.imageUrl ?? '', // Handle null with default
    );
  }
}

// Exercise model for selection process
class ExerciseSelectionModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final String targetMuscle;
  final String category;
  final String difficulty;
  final bool isSelected;

  ExerciseSelectionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    this.videoUrl = '',
    required this.targetMuscle,
    this.category = 'General',
    this.difficulty = 'Intermediate',
    this.isSelected = false,
  });

  ExerciseSelectionModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? videoUrl,
    String? targetMuscle,
    String? category,
    String? difficulty,
    bool? isSelected,
  }) {
    return ExerciseSelectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory ExerciseSelectionModel.fromExerciseModel(ExerciseModel exercise) {
    return ExerciseSelectionModel(
      id: exercise.id ?? 0,
      name: exercise.name,
      description: exercise.description ?? '', // Handle null with default
      imageUrl: exercise.imageUrl ?? '', // Handle null with default
      targetMuscle: exercise.targetMuscle ?? '', // Handle null with default
      category: exercise.category ?? 'General', // Handle null with default
      difficulty: exercise.difficulty ?? 'Intermediate', // Handle null with default
    );
  }
}

// Exercise with configuration (sets, reps, weight)
class SelectedExerciseWithConfig {
  final ExerciseSelectionModel exercise;
  final int sets;
  final String reps;
  final String weight;
  final int restTime;
  final String notes;

  SelectedExerciseWithConfig({
    required this.exercise,
    this.sets = 3,
    this.reps = '10',
    this.weight = '',
    this.restTime = 60,
    this.notes = '',
  });

  SelectedExerciseWithConfig copyWith({
    ExerciseSelectionModel? exercise,
    int? sets,
    String? reps,
    String? weight,
    int? restTime,
    String? notes,
  }) {
    return SelectedExerciseWithConfig(
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
    );
  }

  // Convert to ExerciseModel for routine creation
  ExerciseModel toExerciseModel(Color selectedColor) {
    return ExerciseModel(
      id: exercise.id,
      name: exercise.name,
      targetSets: sets,
      targetReps: reps,
      targetWeight: weight,
      category: exercise.category,
      difficulty: exercise.difficulty,
      color: selectedColor.value.toString(),
      restTime: restTime,
      notes: notes,
      targetMuscle: exercise.targetMuscle,
      description: exercise.description,
      imageUrl: exercise.imageUrl,
    );
  }
}
