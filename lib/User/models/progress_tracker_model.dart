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
      'date': CnergyDateUtils.toApiDate(date),
      'notes': notes,
      'volume': volume,
      'one_rep_max': oneRepMax,
      'program_name': programName,
      'program_id': programId,
    };
  }

  // Calculate volume (weight * reps) - each record represents 1 set
  double get calculatedVolume => weight * reps;

  // Calculate estimated 1RM using Epley formula
  double get calculatedOneRepMax {
    if (reps == 1) return weight;
    return weight * (1 + (reps / 30.0));
  }

  // Get formatted date
  String get formattedDate => CnergyDateUtils.toDisplayDate(date);

  // Get relative date
  String get relativeDate => CnergyDateUtils.getRelativeDate(date);

  // Get formatted weight
  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';

  // Get formatted volume
  String get formattedVolume => '${calculatedVolume.toStringAsFixed(1)} kg';

  // Get formatted 1RM
  String get formattedOneRepMax => '${calculatedOneRepMax.toStringAsFixed(1)} kg';
}

class ProgressAnalytics {
  final String exerciseName;
  final String muscleGroup;
  final List<ProgressTrackerModel> data;
  final double? bestWeight;
  final double? bestVolume;
  final double? bestOneRepMax;
  final double? averageWeight;
  final double? averageVolume;
  final double? totalVolume;
  final int totalWorkouts;
  final double? progressPercentage;
  final List<ProgressionData> progressionData;
  final String? programName;

  ProgressAnalytics({
    required this.exerciseName,
    required this.muscleGroup,
    required this.data,
    this.bestWeight,
    this.bestVolume,
    this.bestOneRepMax,
    this.averageWeight,
    this.averageVolume,
    this.totalVolume,
    required this.totalWorkouts,
    this.progressPercentage,
    required this.progressionData,
    this.programName,
  });

  // Calculate if there's progression (weight or reps increased)
  bool get hasProgression {
    if (data.length < 2) return false;
    
    final sortedData = List<ProgressTrackerModel>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    for (int i = 1; i < sortedData.length; i++) {
      final current = sortedData[i];
      final previous = sortedData[i - 1];
      
      if (current.weight > previous.weight || 
          (current.weight == previous.weight && current.reps > previous.reps)) {
        return true;
      }
    }
    return false;
  }

  // Get progression streak (consecutive improvements)
  int get progressionStreak {
    if (data.length < 2) return 0;
    
    final sortedData = List<ProgressTrackerModel>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    int streak = 0;
    for (int i = sortedData.length - 1; i > 0; i--) {
      final current = sortedData[i];
      final previous = sortedData[i - 1];
      
      if (current.weight > previous.weight || 
          (current.weight == previous.weight && current.reps > previous.reps)) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class ProgressionData {
  final DateTime date;
  final double weight;
  final int reps;
  final double volume;
  final double oneRepMax;
  final bool isPersonalBest;
  final String? notes;

  ProgressionData({
    required this.date,
    required this.weight,
    required this.reps,
    required this.volume,
    required this.oneRepMax,
    required this.isPersonalBest,
    this.notes,
  });

  String get formattedDate => CnergyDateUtils.toDisplayDate(date);
  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';
  String get formattedVolume => '${volume.toStringAsFixed(1)} kg';
  String get formattedOneRepMax => '${oneRepMax.toStringAsFixed(1)} kg';
}
