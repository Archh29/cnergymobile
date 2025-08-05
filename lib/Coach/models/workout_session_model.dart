import 'package:flutter/material.dart';

enum SessionStatus {
  scheduled,
  in_progress,
  completed,
  cancelled,
  missed,
  rescheduled,
}

enum SessionType {
  strength,
  cardio,
  flexibility,
  sports,
  rehabilitation,
  assessment,
  consultation,
  group_class,
  personal_training,
  other,
}

enum SessionIntensity {
  low,
  moderate,
  high,
  maximum,
}

class WorkoutSessionModel {
  final int? id;
  final int userId;
  final int? coachId;
  final int? programId;
  final String? programName;
  final SessionType type;
  final SessionStatus status;
  final DateTime scheduledDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? plannedDuration;
  final Duration? actualDuration;
  final SessionIntensity? intensity;
  final String? location;
  final String? notes;
  final String? coachNotes;
  final double? rating;
  final String? feedback;
  final List<String>? exercises;
  final Map<String, dynamic>? sessionData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRecurring;
  final String? recurringPattern;
  final int? caloriesBurned;
  final double? averageHeartRate;
  final double? maxHeartRate;
  final Map<String, dynamic>? performanceMetrics;
  final List<String>? attachments;
  final bool isPublic;

  WorkoutSessionModel({
    this.id,
    required this.userId,
    this.coachId,
    this.programId,
    this.programName,
    this.type = SessionType.other,
    this.status = SessionStatus.scheduled,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.plannedDuration,
    this.actualDuration,
    this.intensity,
    this.location,
    this.notes,
    this.coachNotes,
    this.rating,
    this.feedback,
    this.exercises,
    this.sessionData,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurringPattern,
    this.caloriesBurned,
    this.averageHeartRate,
    this.maxHeartRate,
    this.performanceMetrics,
    this.attachments,
    this.isPublic = false,
  });

  // Computed properties
  bool get completed => status == SessionStatus.completed;
  bool get inProgress => status == SessionStatus.in_progress;
  bool get scheduled => status == SessionStatus.scheduled;
  bool get cancelled => status == SessionStatus.cancelled;
  bool get missed => status == SessionStatus.missed;
  
  bool get isToday {
    final now = DateTime.now();
    final sessionDate = scheduledDate;
    return now.year == sessionDate.year &&
           now.month == sessionDate.month &&
           now.day == sessionDate.day;
  }
  
  bool get isPast => DateTime.now().isAfter(scheduledDate);
  bool get isFuture => DateTime.now().isBefore(scheduledDate);
  bool get isUpcoming => isFuture && scheduledDate.difference(DateTime.now()).inDays <= 7;
  
  Duration? get sessionDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return actualDuration ?? plannedDuration;
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${difference.abs()} days ago';
    }
  }

  String get formattedTime {
    final hour = scheduledDate.hour;
    final minute = scheduledDate.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedDateTime {
    return '${formattedDate} at ${formattedTime}';
  }

  String get formattedDuration {
    final duration = sessionDuration;
    if (duration == null) return 'Not set';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Color get statusColor {
    switch (status) {
      case SessionStatus.completed:
        return Colors.green;
      case SessionStatus.in_progress:
        return Colors.blue;
      case SessionStatus.scheduled:
        return Colors.orange;
      case SessionStatus.cancelled:
        return Colors.grey;
      case SessionStatus.missed:
        return Colors.red;
      case SessionStatus.rescheduled:
        return Colors.purple;
    }
  }

  Color get intensityColor {
    switch (intensity) {
      case SessionIntensity.low:
        return Colors.green;
      case SessionIntensity.moderate:
        return Colors.orange;
      case SessionIntensity.high:
        return Colors.red;
      case SessionIntensity.maximum:
        return Colors.deepPurple;
      case null:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case SessionType.strength:
        return Icons.fitness_center;
      case SessionType.cardio:
        return Icons.directions_run;
      case SessionType.flexibility:
        return Icons.self_improvement;
      case SessionType.sports:
        return Icons.sports_soccer;
      case SessionType.rehabilitation:
        return Icons.healing;
      case SessionType.assessment:
        return Icons.assessment;
      case SessionType.consultation:
        return Icons.chat;
      case SessionType.group_class:
        return Icons.group;
      case SessionType.personal_training:
        return Icons.person;
      case SessionType.other:
        return Icons.fitness_center;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case SessionStatus.completed:
        return Icons.check_circle;
      case SessionStatus.in_progress:
        return Icons.play_circle;
      case SessionStatus.scheduled:
        return Icons.schedule;
      case SessionStatus.cancelled:
        return Icons.cancel;
      case SessionStatus.missed:
        return Icons.error;
      case SessionStatus.rescheduled:
        return Icons.update;
    }
  }

  String get statusDisplay {
    switch (status) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.in_progress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
      case SessionStatus.missed:
        return 'Missed';
      case SessionStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  String get typeDisplay {
    switch (type) {
      case SessionType.strength:
        return 'Strength Training';
      case SessionType.cardio:
        return 'Cardio';
      case SessionType.flexibility:
        return 'Flexibility';
      case SessionType.sports:
        return 'Sports';
      case SessionType.rehabilitation:
        return 'Rehabilitation';
      case SessionType.assessment:
        return 'Assessment';
      case SessionType.consultation:
        return 'Consultation';
      case SessionType.group_class:
        return 'Group Class';
      case SessionType.personal_training:
        return 'Personal Training';
      case SessionType.other:
        return 'Other';
    }
  }

  String get intensityDisplay {
    switch (intensity) {
      case SessionIntensity.low:
        return 'Low';
      case SessionIntensity.moderate:
        return 'Moderate';
      case SessionIntensity.high:
        return 'High';
      case SessionIntensity.maximum:
        return 'Maximum';
      case null:
        return 'Not Set';
    }
  }

  // Factory constructor from JSON
  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      coachId: json['coach_id'],
      programId: json['program_id'],
      programName: json['program_name'],
      type: _parseSessionType(json['type']),
      status: _parseSessionStatus(json['status']),
      scheduledDate: json['scheduled_date'] != null 
          ? DateTime.parse(json['scheduled_date']) 
          : DateTime.now(),
      startTime: json['start_time'] != null 
          ? DateTime.parse(json['start_time']) 
          : null,
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : null,
      plannedDuration: json['planned_duration'] != null 
          ? Duration(minutes: json['planned_duration']) 
          : null,
      actualDuration: json['actual_duration'] != null 
          ? Duration(minutes: json['actual_duration']) 
          : null,
      intensity: _parseSessionIntensity(json['intensity']),
      location: json['location'],
      notes: json['notes'],
      coachNotes: json['coach_notes'],
      rating: json['rating']?.toDouble(),
      feedback: json['feedback'],
      exercises: json['exercises'] != null 
          ? List<String>.from(json['exercises']) 
          : null,
      sessionData: json['session_data'] is Map 
          ? Map<String, dynamic>.from(json['session_data']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isRecurring: json['is_recurring'] ?? false,
      recurringPattern: json['recurring_pattern'],
      caloriesBurned: json['calories_burned'],
      averageHeartRate: json['average_heart_rate']?.toDouble(),
      maxHeartRate: json['max_heart_rate']?.toDouble(),
      performanceMetrics: json['performance_metrics'] is Map 
          ? Map<String, dynamic>.from(json['performance_metrics']) 
          : null,
      attachments: json['attachments'] != null 
          ? List<String>.from(json['attachments']) 
          : null,
      isPublic: json['is_public'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coach_id': coachId,
      'program_id': programId,
      'program_name': programName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduled_date': scheduledDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'planned_duration': plannedDuration?.inMinutes,
      'actual_duration': actualDuration?.inMinutes,
      'intensity': intensity?.toString().split('.').last,
      'location': location,
      'notes': notes,
      'coach_notes': coachNotes,
      'rating': rating,
      'feedback': feedback,
      'exercises': exercises,
      'session_data': sessionData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'calories_burned': caloriesBurned,
      'average_heart_rate': averageHeartRate,
      'max_heart_rate': maxHeartRate,
      'performance_metrics': performanceMetrics,
      'attachments': attachments,
      'is_public': isPublic,
    };
  }

  // Helper methods to parse enums from strings
  static SessionType _parseSessionType(dynamic type) {
    if (type == null) return SessionType.other;
    
    switch (type.toString().toLowerCase()) {
      case 'strength':
        return SessionType.strength;
      case 'cardio':
        return SessionType.cardio;
      case 'flexibility':
        return SessionType.flexibility;
      case 'sports':
        return SessionType.sports;
      case 'rehabilitation':
        return SessionType.rehabilitation;
      case 'assessment':
        return SessionType.assessment;
      case 'consultation':
        return SessionType.consultation;
      case 'group_class':
        return SessionType.group_class;
      case 'personal_training':
        return SessionType.personal_training;
      default:
        return SessionType.other;
    }
  }

  static SessionStatus _parseSessionStatus(dynamic status) {
    if (status == null) return SessionStatus.scheduled;
    
    switch (status.toString().toLowerCase()) {
      case 'in_progress':
        return SessionStatus.in_progress;
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'missed':
        return SessionStatus.missed;
      case 'rescheduled':
        return SessionStatus.rescheduled;
      case 'scheduled':
      default:
        return SessionStatus.scheduled;
    }
  }

  static SessionIntensity? _parseSessionIntensity(dynamic intensity) {
    if (intensity == null) return null;
    
    switch (intensity.toString().toLowerCase()) {
      case 'low':
        return SessionIntensity.low;
      case 'moderate':
        return SessionIntensity.moderate;
      case 'high':
        return SessionIntensity.high;
      case 'maximum':
        return SessionIntensity.maximum;
      default:
        return null;
    }
  }

  // Copy with method for immutable updates
  WorkoutSessionModel copyWith({
    int? id,
    int? userId,
    int? coachId,
    int? programId,
    String? programName,
    SessionType? type,
    SessionStatus? status,
    DateTime? scheduledDate,
    DateTime? startTime,
    DateTime? endTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    SessionIntensity? intensity,
    String? location,
    String? notes,
    String? coachNotes,
    double? rating,
    String? feedback,
    List<String>? exercises,
    Map<String, dynamic>? sessionData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurringPattern,
    int? caloriesBurned,
    double? averageHeartRate,
    double? maxHeartRate,
    Map<String, dynamic>? performanceMetrics,
    List<String>? attachments,
    bool? isPublic,
  }) {
    return WorkoutSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coachId: coachId ?? this.coachId,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      intensity: intensity ?? this.intensity,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      coachNotes: coachNotes ?? this.coachNotes,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      exercises: exercises ?? this.exercises,
      sessionData: sessionData ?? this.sessionData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      attachments: attachments ?? this.attachments,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkoutSessionModel && 
           other.id == id && 
           other.userId == userId &&
           other.scheduledDate == scheduledDate;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ scheduledDate.hashCode;

  @override
  String toString() {
    return 'WorkoutSessionModel(id: $id, type: $type, status: $status, date: $scheduledDate)';
  }
}
