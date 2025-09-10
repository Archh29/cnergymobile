class MuscleGroupStats {
  final String muscleGroup;
  final int muscleGroupId;
  final int exerciseCount;
  final int workoutSessions;
  final int totalReps;
  final double avgWeight;
  final String lastWorked;
  final double intensityScore;

  MuscleGroupStats({
    required this.muscleGroup,
    required this.muscleGroupId,
    required this.exerciseCount,
    required this.workoutSessions,
    required this.totalReps,
    required this.avgWeight,
    required this.lastWorked,
    required this.intensityScore,
  });

  factory MuscleGroupStats.fromJson(Map<String, dynamic> json) {
    return MuscleGroupStats(
      muscleGroup: json['muscle_group'] ?? '',
      muscleGroupId: json['muscle_group_id'] ?? 0,
      exerciseCount: json['exercise_count'] ?? 0,
      workoutSessions: json['workout_sessions'] ?? 0,
      totalReps: json['total_reps'] ?? 0,
      avgWeight: (json['avg_weight'] ?? 0.0).toDouble(),
      lastWorked: json['last_worked'] ?? '',
      intensityScore: (json['intensity_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muscle_group': muscleGroup,
      'muscle_group_id': muscleGroupId,
      'exercise_count': exerciseCount,
      'workout_sessions': workoutSessions,
      'total_reps': totalReps,
      'avg_weight': avgWeight,
      'last_worked': lastWorked,
      'intensity_score': intensityScore,
    };
  }
}

class SubMuscleStats {
  final String muscleName;
  final int muscleId;
  final int exerciseCount;
  final int workoutSessions;
  final int totalReps;
  final double avgWeight;
  final String lastWorked;
  final double intensityScore;

  SubMuscleStats({
    required this.muscleName,
    required this.muscleId,
    required this.exerciseCount,
    required this.workoutSessions,
    required this.totalReps,
    required this.avgWeight,
    required this.lastWorked,
    required this.intensityScore,
  });

  factory SubMuscleStats.fromJson(Map<String, dynamic> json) {
    return SubMuscleStats(
      muscleName: json['muscle_name'] ?? '',
      muscleId: json['muscle_id'] ?? 0,
      exerciseCount: json['exercise_count'] ?? 0,
      workoutSessions: json['workout_sessions'] ?? 0,
      totalReps: json['total_reps'] ?? 0,
      avgWeight: (json['avg_weight'] ?? 0.0).toDouble(),
      lastWorked: json['last_worked'] ?? '',
      intensityScore: (json['intensity_score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muscle_name': muscleName,
      'muscle_id': muscleId,
      'exercise_count': exerciseCount,
      'workout_sessions': workoutSessions,
      'total_reps': totalReps,
      'avg_weight': avgWeight,
      'last_worked': lastWorked,
      'intensity_score': intensityScore,
    };
  }
}

class SubMusclesData {
  final String parentMuscle;
  final int parentMuscleId;
  final String period;
  final String startDate;
  final String endDate;
  final List<SubMuscleStats> subMuscles;

  SubMusclesData({
    required this.parentMuscle,
    required this.parentMuscleId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.subMuscles,
  });

  factory SubMusclesData.fromJson(Map<String, dynamic> json) {
    final periodDates = json['period_dates'] ?? {};
    
    return SubMusclesData(
      parentMuscle: json['parent_muscle'] ?? '',
      parentMuscleId: json['parent_muscle_id'] ?? 0,
      period: json['period'] ?? '',
      startDate: periodDates['start'] ?? '',
      endDate: periodDates['end'] ?? '',
      subMuscles: (json['sub_muscles'] as List<dynamic>?)
          ?.map((item) => SubMuscleStats.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_muscle': parentMuscle,
      'parent_muscle_id': parentMuscleId,
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
      'sub_muscles': subMuscles.map((item) => item.toJson()).toList(),
    };
  }
}

class MuscleAnalyticsData {
  final String periodType; // 'week' or 'month'
  final String startDate;
  final String endDate;
  final int totalWorkouts;
  final List<MuscleGroupStats> muscleGroups;

  MuscleAnalyticsData({
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.totalWorkouts,
    required this.muscleGroups,
  });

  factory MuscleAnalyticsData.fromJson(Map<String, dynamic> json) {
    final periodData = json['week_period'] ?? json['month_period'] ?? {};
    final periodType = json['week_period'] != null ? 'week' : 'month';
    
    return MuscleAnalyticsData(
      periodType: periodType,
      startDate: periodData['start'] ?? '',
      endDate: periodData['end'] ?? '',
      totalWorkouts: json['total_workouts'] ?? 0,
      muscleGroups: (json['muscle_groups'] as List<dynamic>?)
          ?.map((item) => MuscleGroupStats.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_type': periodType,
      'start_date': startDate,
      'end_date': endDate,
      'total_workouts': totalWorkouts,
      'muscle_groups': muscleGroups.map((item) => item.toJson()).toList(),
    };
  }
}

class ExerciseDetail {
  final String exerciseName;
  final int sets;
  final int reps;
  final double weight;
  final String workoutDate;
  final String workoutGoal;
  final double totalVolume;

  ExerciseDetail({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.workoutDate,
    required this.workoutGoal,
    required this.totalVolume,
  });

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) {
    return ExerciseDetail(
      exerciseName: json['exercise_name'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? 0,
      weight: (json['weight'] ?? 0.0).toDouble(),
      workoutDate: json['workout_date'] ?? '',
      workoutGoal: json['workout_goal'] ?? '',
      totalVolume: (json['total_volume'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'workout_date': workoutDate,
      'workout_goal': workoutGoal,
      'total_volume': totalVolume,
    };
  }
}

class DetailedMuscleAnalytics {
  final String muscleGroup;
  final String period;
  final String startDate;
  final String endDate;
  final List<ExerciseDetail> exercises;

  DetailedMuscleAnalytics({
    required this.muscleGroup,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.exercises,
  });

  factory DetailedMuscleAnalytics.fromJson(Map<String, dynamic> json) {
    final periodDates = json['period_dates'] ?? {};
    
    return DetailedMuscleAnalytics(
      muscleGroup: json['muscle_group'] ?? '',
      period: json['period'] ?? '',
      startDate: periodDates['start'] ?? '',
      endDate: periodDates['end'] ?? '',
      exercises: (json['exercises'] as List<dynamic>?)
          ?.map((item) => ExerciseDetail.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muscle_group': muscleGroup,
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
      'exercises': exercises.map((item) => item.toJson()).toList(),
    };
  }
}
