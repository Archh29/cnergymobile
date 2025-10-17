const Object _undefined = Object();

class ScheduleModel {
  final int? scheduleId;
  final String dayOfWeek;
  final int? workoutId;
  final String? workoutName;
  final String? workoutDuration;
  final String? scheduledTime;
  final bool isRestDay;
  final String? notes;
  final bool isActive;
  final bool isCompleted;

  ScheduleModel({
    this.scheduleId,
    required this.dayOfWeek,
    this.workoutId,
    this.workoutName,
    this.workoutDuration,
    this.scheduledTime,
    this.isRestDay = false,
    this.notes,
    this.isActive = true,
    this.isCompleted = false,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      scheduleId: json['schedule_id'],
      dayOfWeek: json['day_of_week'] ?? '',
      workoutId: json['workout_id'],
      workoutName: json['workout_name'],
      workoutDuration: json['workout_duration'],
      scheduledTime: json['scheduled_time'],
      isRestDay: json['is_rest_day'] ?? false,
      notes: json['notes'],
      isActive: json['is_active'] ?? true,
      isCompleted: json['is_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'day_of_week': dayOfWeek,
      'workout_id': workoutId,
      'workout_name': workoutName,
      'workout_duration': workoutDuration,
      'scheduled_time': scheduledTime,
      'is_rest_day': isRestDay,
      'notes': notes,
      'is_active': isActive,
      'is_completed': isCompleted,
    };
  }

  ScheduleModel copyWith({
    int? scheduleId,
    String? dayOfWeek,
    Object? workoutId = _undefined,
    Object? workoutName = _undefined,
    Object? workoutDuration = _undefined,
    Object? scheduledTime = _undefined,
    bool? isRestDay,
    Object? notes = _undefined,
    bool? isActive,
    bool? isCompleted,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      workoutId: workoutId == _undefined ? this.workoutId : workoutId as int?,
      workoutName: workoutName == _undefined ? this.workoutName : workoutName as String?,
      workoutDuration: workoutDuration == _undefined ? this.workoutDuration : workoutDuration as String?,
      scheduledTime: scheduledTime == _undefined ? this.scheduledTime : scheduledTime as String?,
      isRestDay: isRestDay ?? this.isRestDay,
      notes: notes == _undefined ? this.notes : notes as String?,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ProgramForScheduling {
  final int programId;
  final String goal;
  final String difficulty;
  final int totalWorkouts;
  final List<WorkoutForScheduling> workouts;
  final String createdAt;
  final String? createdBy;
  final int? createdByTypeId;

  ProgramForScheduling({
    required this.programId,
    required this.goal,
    required this.difficulty,
    required this.totalWorkouts,
    required this.workouts,
    required this.createdAt,
    this.createdBy,
    this.createdByTypeId,
  });

  factory ProgramForScheduling.fromJson(Map<String, dynamic> json) {
    return ProgramForScheduling(
      programId: json['program_id'] ?? 0,
      goal: json['goal'] ?? 'General Fitness',
      difficulty: json['difficulty'] ?? 'Beginner',
      totalWorkouts: json['total_workouts'] ?? 0,
      workouts: (json['workouts'] as List<dynamic>? ?? [])
          .map((workout) => WorkoutForScheduling.fromJson(workout))
          .toList(),
      createdAt: json['created_at'] ?? '',
      createdBy: json['created_by']?.toString(),
      createdByTypeId: json['created_by_type_id'] != null 
          ? int.tryParse(json['created_by_type_id'].toString())
          : null,
    );
  }
}

class WorkoutForScheduling {
  final int workoutId;
  final String name;
  final String duration;

  WorkoutForScheduling({
    required this.workoutId,
    required this.name,
    required this.duration,
  });

  factory WorkoutForScheduling.fromJson(Map<String, dynamic> json) {
    return WorkoutForScheduling(
      workoutId: json['workout_id'] ?? 0,
      name: json['name'] ?? 'Unnamed Workout',
      duration: json['duration'] ?? '30',
    );
  }
}

class TodayWorkout {
  final int? scheduleId;
  final String dayOfWeek;
  final int? workoutId;
  final int? routineId;
  final String? workoutName;
  final String? workoutDuration;
  final String? scheduledTime;
  final bool isRestDay;
  final String? notes;
  final String? programGoal;
  final String? programDifficulty;
  final int? programId;

  TodayWorkout({
    this.scheduleId,
    required this.dayOfWeek,
    this.workoutId,
    this.routineId,
    this.workoutName,
    this.workoutDuration,
    this.scheduledTime,
    this.isRestDay = false,
    this.notes,
    this.programGoal,
    this.programDifficulty,
    this.programId,
  });

  factory TodayWorkout.fromJson(Map<String, dynamic> json) {
    return TodayWorkout(
      scheduleId: json['scheduleId'],
      dayOfWeek: json['dayOfWeek'] ?? '',
      workoutId: json['workoutId'],
      routineId: json['routineId'],
      workoutName: json['workoutName'],
      workoutDuration: json['workoutDuration'],
      scheduledTime: json['scheduledTime'],
      isRestDay: json['isRestDay'] ?? false,
      notes: json['notes'],
      programGoal: json['programGoal'],
      programDifficulty: json['programDifficulty'],
      programId: json['programId'],
    );
  }
}

class WeeklyScheduleItem {
  final String dayOfWeek;
  final String workoutName;
  final bool isRestDay;

  WeeklyScheduleItem({
    required this.dayOfWeek,
    required this.workoutName,
    required this.isRestDay,
  });

  factory WeeklyScheduleItem.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItem(
      dayOfWeek: json['day_of_week'] ?? '',
      workoutName: json['workout_name'] ?? 'Rest Day',
      isRestDay: json['is_rest_day'] ?? false,
    );
  }
}
