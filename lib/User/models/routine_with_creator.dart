import 'package:flutter/material.dart';
import './routine.models.dart';

class RoutineWithCreator {
  final RoutineModel routine;
  final String creatorType; // 'user' or 'coach'
  final String? creatorName;

  RoutineWithCreator({
    required this.routine,
    required this.creatorType,
    this.creatorName,
  });

  String get displayName {
    if (creatorType == 'coach' && creatorName != null) {
      return '${routine.name} (by $creatorName)';
    }
    return routine.name;
  }

  IconData get creatorIcon {
    return creatorType == 'coach' ? Icons.school : Icons.person;
  }

  Color get creatorColor {
    return creatorType == 'coach' ? Color(0xFFFFD700) : Color(0xFF4ECDC4);
  }

  // Delegate all RoutineModel properties with null safety
  String get id => routine.id;
  String get name => routine.name;
  int get exercises => routine.exercises;
  String get duration => routine.duration;
  String get difficulty => routine.difficulty;
  String get goal => routine.goal;
  List<String> get tags => routine.tags ?? [];
  List<ExerciseModel> get detailedExercises => routine.detailedExercises ?? [];
}
