import 'package:flutter/material.dart';
import '../models/exercise_selection_model.dart';
import '../models/exercise_model.dart';

class ExerciseSelectionService {
  // Convert SelectedExerciseWithConfig to ExerciseModel for routine creation
  static List<ExerciseModel> convertToExerciseModels(
      List<SelectedExerciseWithConfig> selectedExercises,
      Color selectedColor,
      ) {
    return selectedExercises.map((config) => config.toExerciseModel(selectedColor)).toList();
  }

  // Get exercise count by muscle group
  static Map<String, int> getExerciseCountByMuscle(List<SelectedExerciseWithConfig> exercises) {
    final Map<String, int> counts = {};

    for (var exercise in exercises) {
      final muscle = exercise.exercise.targetMuscle;
      counts[muscle] = (counts[muscle] ?? 0) + 1;
    }

    return counts;
  }

  // Calculate total estimated workout time
  static int calculateEstimatedDuration(List<SelectedExerciseWithConfig> exercises) {
    int totalTime = 0;

    for (var exercise in exercises) {
      // Estimate: (sets * 30 seconds per set) + (rest time * (sets - 1))
      final setTime = exercise.sets * 30; // 30 seconds per set
      final restTime = exercise.restTime * (exercise.sets - 1);
      totalTime += setTime + restTime;
    }

    // Add 5 minutes for transitions between exercises
    totalTime += exercises.length * 5 * 60;

    return (totalTime / 60).round(); // Return in minutes
  }

  // Validate exercise configuration
  static List<String> validateExerciseConfiguration(List<SelectedExerciseWithConfig> exercises) {
    List<String> errors = [];

    if (exercises.isEmpty) {
      errors.add('At least one exercise is required');
      return errors;
    }

    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final exerciseName = exercise.exercise.name;

      if (exercise.sets <= 0) {
        errors.add('$exerciseName: Sets must be greater than 0');
      }

      if (exercise.reps.isEmpty) {
        errors.add('$exerciseName: Reps cannot be empty');
      }

      if (exercise.restTime < 0) {
        errors.add('$exerciseName: Rest time cannot be negative');
      }
    }

    return errors;
  }

  // Convert existing ExerciseModel list to SelectedExerciseWithConfig
  static List<SelectedExerciseWithConfig> convertFromExerciseModels(List<ExerciseModel> exercises) {
    return exercises.map((exercise) {
      return SelectedExerciseWithConfig(
        exercise: ExerciseSelectionModel.fromExerciseModel(exercise),
        sets: exercise.targetSets,
        reps: exercise.targetReps,
        weight: exercise.targetWeight,
        restTime: exercise.restTime,
        notes: exercise.notes,
      );
    }).toList();
  }
}
