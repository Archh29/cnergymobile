// Helper function to safely parse integers from dynamic JSON values
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.parse(value);
  if (value is num) return value.toInt();
  return 0;
}

class WeeklyExerciseStat {
  final int exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double load;

  WeeklyExerciseStat({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.load,
  });

  factory WeeklyExerciseStat.fromJson(Map<String, dynamic> json) {
    try {
      return WeeklyExerciseStat(
        exerciseId: _parseInt(json['exercise_id'] ?? 0),
        exerciseName: (json['exercise_name'] ?? '') as String,
        sets: _parseInt(json['sets'] ?? 0),
        reps: _parseInt(json['reps'] ?? 0),
        load: ((json['load'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      print('❌ Error in WeeklyExerciseStat.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class WeeklyMuscleGroupStat {
  final int groupId;
  final String groupName;
  final double totalLoad;
  final int totalSets;
  final int totalExercises;
  final int? totalReps;
  final String? imageUrl;
  final List<WeeklyExerciseStat> exercises;
  final int sessions;

  WeeklyMuscleGroupStat({
    required this.groupId,
    required this.groupName,
    required this.totalLoad,
    required this.totalSets,
    required this.totalExercises,
    this.totalReps,
    this.imageUrl,
    this.exercises = const [],
    this.sessions = 0,
  });

  factory WeeklyMuscleGroupStat.fromJson(Map<String, dynamic> json) {
    try {
      final ex = ((json['exercises'] ?? []) as List)
          .map((e) => WeeklyExerciseStat.fromJson(e as Map<String, dynamic>))
          .toList();
      return WeeklyMuscleGroupStat(
        groupId: _parseInt(json['group_id'] ?? 0),
        groupName: (json['group_name'] ?? '') as String,
        totalLoad: ((json['total_load'] ?? 0) as num).toDouble(),
        totalSets: _parseInt(json['total_sets'] ?? 0),
        totalExercises: _parseInt(json['total_exercises'] ?? 0),
        totalReps: (json['total_reps'] == null) ? null : _parseInt(json['total_reps']),
        imageUrl: json['image_url'] as String?,
        exercises: ex,
        sessions: _parseInt(json['sessions'] ?? 0),
      );
    } catch (e) {
      print('❌ Error in WeeklyMuscleGroupStat.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class WeeklyMuscleStat {
  final int muscleId;
  final String muscleName;
   final int? groupId;
  final double totalLoad;
  final int totalSets;
  final int totalExercises;
  final String? firstDate;
  final String? lastDate;
  final int? totalReps;
  final String? imageUrl;
  final List<WeeklyExerciseStat> exercises;
  final int sessions;

  WeeklyMuscleStat({
    required this.muscleId,
    required this.muscleName,
    this.groupId,
    required this.totalLoad,
    required this.totalSets,
    required this.totalExercises,
    this.firstDate,
    this.lastDate,
    this.totalReps,
    this.imageUrl,
    this.exercises = const [],
    this.sessions = 0,
  });

  factory WeeklyMuscleStat.fromJson(Map<String, dynamic> json) {
    try {
      final ex = ((json['exercises'] ?? []) as List)
          .map((e) => WeeklyExerciseStat.fromJson(e as Map<String, dynamic>))
          .toList();
      return WeeklyMuscleStat(
        muscleId: _parseInt(json['muscle_id'] ?? 0),
        muscleName: (json['muscle_name'] ?? '') as String,
        groupId: json['group_id'] == null ? null : _parseInt(json['group_id']),
        totalLoad: ((json['total_load'] ?? 0) as num).toDouble(),
        totalSets: _parseInt(json['total_sets'] ?? 0),
        totalExercises: _parseInt(json['total_exercises'] ?? 0),
        firstDate: json['first_date'] as String?,
        lastDate: json['last_date'] as String?,
        totalReps: (json['total_reps'] == null) ? null : _parseInt(json['total_reps']),
        imageUrl: json['image_url'] as String?,
        exercises: ex,
        sessions: _parseInt(json['sessions'] ?? 0),
      );
    } catch (e) {
      print('❌ Error in WeeklyMuscleStat.fromJson: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class WeeklyMuscleAnalyticsData {
  final String weekStart;
  final String weekEnd;
  final List<WeeklyMuscleStat> muscles;
  final List<WeeklyMuscleGroupStat> groups;
  final double avgGroupLoad;
  final double avgGroupSets;
  final String summary;
  final List<String> focusedGroups;
  final List<String> neglectedGroups;
  final List<Map<String, dynamic>>? warnings;
  final String? trainingFocus;
  final List<int>? trackedMuscleGroups;

  WeeklyMuscleAnalyticsData({
    required this.weekStart,
    required this.weekEnd,
    required this.muscles,
    required this.groups,
    required this.avgGroupLoad,
    required this.avgGroupSets,
    required this.summary,
    required this.focusedGroups,
    required this.neglectedGroups,
    this.warnings,
    this.trainingFocus,
    this.trackedMuscleGroups,
  });

  factory WeeklyMuscleAnalyticsData.fromJson(Map<String, dynamic> json) {
    try {
      final data = json;
      
      print('🔍 Parsing muscles...');
      final muscles = ((data['muscles'] ?? []) as List)
          .map((e) => WeeklyMuscleStat.fromJson(e as Map<String, dynamic>))
          .toList();
      
      print('🔍 Parsing groups...');
      final groups = ((data['groups'] ?? []) as List)
          .map((e) => WeeklyMuscleGroupStat.fromJson(e as Map<String, dynamic>))
          .toList();
      
      print('🔍 Parsing averages...');
      final averages = (data['averages'] ?? {}) as Map<String, dynamic>;
      
      print('🔍 Parsing warnings...');
      // Safe parsing of warnings
      final warnings = data['warnings'] != null
          ? ((data['warnings'] as List).map((e) => e as Map<String, dynamic>).toList())
          : null;
      
      print('🔍 Parsing tracked_muscle_groups...');
      print('Type: ${data['tracked_muscle_groups'].runtimeType}');
      print('Value: ${data['tracked_muscle_groups']}');
      // Safe parsing of tracked muscle groups - handle both int and string
      List<int>? trackedGroups;
      if (data['tracked_muscle_groups'] != null) {
        trackedGroups = ((data['tracked_muscle_groups'] as List)
            .map((e) => _parseInt(e))
            .toList());
      }
      
      print('🔍 Creating final object...');
      return WeeklyMuscleAnalyticsData(
        weekStart: (data['week_start'] ?? '') as String,
        weekEnd: (data['week_end'] ?? '') as String,
        muscles: muscles,
        groups: groups,
        avgGroupLoad: ((averages['avg_group_load'] ?? 0) as num).toDouble(),
        avgGroupSets: ((averages['avg_group_sets'] ?? 0) as num).toDouble(),
        summary: (data['summary'] ?? '') as String,
        focusedGroups: ((data['focused_groups'] ?? []) as List).map((e) => e.toString()).toList(),
        neglectedGroups: ((data['neglected_groups'] ?? []) as List).map((e) => e.toString()).toList(),
        warnings: warnings,
        trainingFocus: data['training_focus'] as String?,
        trackedMuscleGroups: trackedGroups,
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('❌ WEEKLY ANALYTICS ERROR: $e');
      // ignore: avoid_print
      print('Stack: $stackTrace');
      rethrow;
    }
  }
}


