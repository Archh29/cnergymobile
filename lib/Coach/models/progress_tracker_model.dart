import '../../utils/date_utils.dart';

class ProgressTrackerModel {
  final int id;
  final int userId;
  final String exerciseName;
  final String muscleGroup;
  final double weight;
  final int reps;
  final int sets;
  final int? setNumber; // Set number from database (1, 2, 3, etc.)
  final DateTime date;
  final String? notes;
  final double? volume; // weight * reps * sets
  final double? oneRepMax; // Estimated 1RM
  final String? programName;
  final int? programId;

  ProgressTrackerModel({
    required this.id,
    required this.userId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.weight,
    required this.reps,
    required this.sets,
    this.setNumber,
    required this.date,
    this.notes,
    this.volume,
    this.oneRepMax,
    this.programName,
    this.programId,
  });

  factory ProgressTrackerModel.fromJson(Map<String, dynamic> json) {
    return ProgressTrackerModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      exerciseName: json['exercise_name'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      weight: double.tryParse(json['weight'].toString()) ?? 0.0,
      reps: int.tryParse(json['reps'].toString()) ?? 0,
      sets: int.tryParse(json['sets'].toString()) ?? 0,
      setNumber: json['set_number'] != null ? int.tryParse(json['set_number'].toString()) : null,
      date: CnergyDateUtils.parseApiDateTime(json['date'] ?? json['created_at']) ?? DateTime.now(),
      notes: json['notes'],
      volume: json['volume'] != null ? double.tryParse(json['volume'].toString()) : null,
      oneRepMax: json['one_rep_max'] != null ? double.tryParse(json['one_rep_max'].toString()) : null,
      programName: json['program_name'],
      programId: json['program_id'] != null ? int.tryParse(json['program_id'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_name': exerciseName,
      'muscle_group': muscleGroup,
      'weight': weight,
      'reps': reps,
      'sets': sets,
      'set_number': setNumber,
      'date': date.toIso8601String(),
      'notes': notes,
      'volume': volume,
      'one_rep_max': oneRepMax,
      'program_name': programName,
      'program_id': programId,
    };
  }

  // Helper methods
  double get calculatedVolume => weight * reps * sets;
  
  String get formattedVolume => '${calculatedVolume.toStringAsFixed(0)} kg';
  
  String get relativeDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}

class ProgressAnalytics {
  final String exerciseName;
  final String muscleGroup;
  final List<ProgressTrackerModel> data;
  final double? bestWeight;
  final double? totalVolume;
  final int totalWorkouts;
  final bool hasProgression;
  final int progressionStreak;
  final String programName;

  ProgressAnalytics({
    required this.exerciseName,
    required this.muscleGroup,
    required this.data,
    this.bestWeight,
    this.totalVolume,
    required this.totalWorkouts,
    required this.hasProgression,
    required this.progressionStreak,
    required this.programName,
  });
}

class ProgressiveOverloadData {
  final DateTime date;
  final double value;
  final String exerciseName;
  final String programName;
  final int userId;

  ProgressiveOverloadData({
    required this.date,
    required this.value,
    required this.exerciseName,
    required this.programName,
    required this.userId,
  });

  factory ProgressiveOverloadData.fromJson(Map<String, dynamic> json) {
    return ProgressiveOverloadData(
      date: CnergyDateUtils.parseApiDateTime(json['date']) ?? DateTime.now(),
      value: double.tryParse(json['value'].toString()) ?? 0.0,
      exerciseName: json['exercise_name'] ?? '',
      programName: json['program_name'] ?? '',
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
    );
  }
}

