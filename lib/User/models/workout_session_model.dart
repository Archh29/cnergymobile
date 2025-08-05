import 'package:flutter/material.dart';

class WorkoutSessionModel {
  final int? id;
  final int memberProgramHdrId;
  final DateTime sessionDate;
  final String? notes;
  final bool completed;
  final String? programName;
  final String? programGoal;
  final String? scheduledDay;
  final String? focus;

  WorkoutSessionModel({
    this.id,
    required this.memberProgramHdrId,
    required this.sessionDate,
    this.notes,
    this.completed = false,
    this.programName,
    this.programGoal,
    this.scheduledDay,
    this.focus,
  });

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      memberProgramHdrId: int.parse(json['member_program_hdr_id'].toString()),
      sessionDate: DateTime.parse(json['session_date']),
      notes: json['notes'],
      completed: json['completed'] == 1 || json['completed'] == true,
      programName: json['program_name'],
      programGoal: json['program_goal'],
      scheduledDay: json['scheduled_day']?.toString(),
      focus: json['focus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'member_program_hdr_id': memberProgramHdrId,
      'session_date': sessionDate.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      'completed': completed,
      if (scheduledDay != null) 'scheduled_day': scheduledDay,
      if (focus != null) 'focus': focus,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(sessionDate).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${sessionDate.day}/${sessionDate.month}/${sessionDate.year}';
  }

  Color get statusColor {
    if (completed) return Colors.green;
    if (sessionDate.isBefore(DateTime.now())) return Colors.red;
    return Color(0xFF4ECDC4);
  }

  String get workoutTitle {
    if (focus != null && focus!.isNotEmpty) {
      return focus!;
    }
    if (scheduledDay != null) {
      return '$scheduledDay Workout';
    }
    return programName ?? 'Workout Session';
  }

  String get nextWorkoutDay {
    if (scheduledDay == null) return 'No day assigned';
    
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday, 7 = Sunday
    final targetWeekday = _getWeekdayFromString(scheduledDay!);
    
    int daysUntil = targetWeekday - currentWeekday;
    if (daysUntil <= 0) {
      daysUntil += 7; // Next week
    }
    
    if (daysUntil == 1) return 'Tomorrow';
    if (daysUntil == 7) return 'Next $scheduledDay';
    return 'In $daysUntil days';
  }

  int _getWeekdayFromString(String day) {
    switch (day.toLowerCase()) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: return 1;
    }
  }
}
