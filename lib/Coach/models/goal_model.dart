import 'package:flutter/material.dart';

enum GoalStatus {
  active,
  achieved,
  paused,
  cancelled,
  overdue,
}

enum GoalType {
  weight,
  strength,
  endurance,
  flexibility,
  skill,
  habit,
  performance,
  body_composition,
  health,
  other,
}

enum GoalPriority {
  low,
  medium,
  high,
  critical,
}

class GoalModel {
  final int? id;
  final int userId;
  final String goal;
  final String? description;
  final GoalType type;
  final GoalStatus status;
  final GoalPriority priority;
  final DateTime targetDate;
  final DateTime? achievedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? targetValue;
  final double? currentValue;
  final String? unit;
  final List<String>? milestones;
  final Map<String, dynamic>? metadata;
  final int? createdByCoachId;
  final String? notes;
  final bool isPublic;
  final List<String>? tags;

  GoalModel({
    this.id,
    required this.userId,
    required this.goal,
    this.description,
    this.type = GoalType.other,
    this.status = GoalStatus.active,
    this.priority = GoalPriority.medium,
    required this.targetDate,
    this.achievedDate,
    required this.createdAt,
    required this.updatedAt,
    this.targetValue,
    this.currentValue,
    this.unit,
    this.milestones,
    this.metadata,
    this.createdByCoachId,
    this.notes,
    this.isPublic = false,
    this.tags,
  });

  // Computed properties
  bool get isAchieved => status == GoalStatus.achieved;
  bool get isActive => status == GoalStatus.active;
  bool get isOverdue => status == GoalStatus.overdue || 
      (status == GoalStatus.active && DateTime.now().isAfter(targetDate));
  
  Duration get timeRemaining => targetDate.difference(DateTime.now());
  Duration get timeElapsed => DateTime.now().difference(createdAt);
  
  int get daysRemaining => timeRemaining.inDays;
  int get daysElapsed => timeElapsed.inDays;
  
  bool get isExpiringSoon => daysRemaining <= 7 && daysRemaining > 0;
  
  double get progressPercentage {
    if (targetValue == null || currentValue == null) return 0.0;
    if (targetValue == 0) return 100.0;
    return ((currentValue! / targetValue!) * 100).clamp(0.0, 100.0);
  }

  String get formattedTargetDate {
    final now = DateTime.now();
    final difference = targetDate.difference(now).inDays;
    
    if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference > 0) {
      return 'Due in $difference days';
    } else {
      return 'Overdue by ${difference.abs()} days';
    }
  }

  String get formattedProgress {
    if (targetValue == null || currentValue == null) {
      return status == GoalStatus.achieved ? 'Completed' : 'In Progress';
    }
    
    final unitStr = unit != null ? ' $unit' : '';
    return '${currentValue!.toStringAsFixed(1)}${unitStr} / ${targetValue!.toStringAsFixed(1)}${unitStr}';
  }

  Color get statusColor {
    switch (status) {
      case GoalStatus.achieved:
        return Colors.green;
      case GoalStatus.active:
        return isOverdue ? Colors.red : Colors.blue;
      case GoalStatus.paused:
        return Colors.orange;
      case GoalStatus.cancelled:
        return Colors.grey;
      case GoalStatus.overdue:
        return Colors.red;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case GoalPriority.low:
        return Colors.grey;
      case GoalPriority.medium:
        return Colors.blue;
      case GoalPriority.high:
        return Colors.orange;
      case GoalPriority.critical:
        return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case GoalType.weight:
        return Icons.monitor_weight;
      case GoalType.strength:
        return Icons.fitness_center;
      case GoalType.endurance:
        return Icons.directions_run;
      case GoalType.flexibility:
        return Icons.self_improvement;
      case GoalType.skill:
        return Icons.psychology;
      case GoalType.habit:
        return Icons.repeat;
      case GoalType.performance:
        return Icons.trending_up;
      case GoalType.body_composition:
        return Icons.accessibility_new;
      case GoalType.health:
        return Icons.favorite;
      case GoalType.other:
        return Icons.flag;
    }
  }

  String get statusDisplay {
    switch (status) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.achieved:
        return 'Achieved';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.cancelled:
        return 'Cancelled';
      case GoalStatus.overdue:
        return 'Overdue';
    }
  }

  String get typeDisplay {
    switch (type) {
      case GoalType.weight:
        return 'Weight';
      case GoalType.strength:
        return 'Strength';
      case GoalType.endurance:
        return 'Endurance';
      case GoalType.flexibility:
        return 'Flexibility';
      case GoalType.skill:
        return 'Skill';
      case GoalType.habit:
        return 'Habit';
      case GoalType.performance:
        return 'Performance';
      case GoalType.body_composition:
        return 'Body Composition';
      case GoalType.health:
        return 'Health';
      case GoalType.other:
        return 'Other';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case GoalPriority.low:
        return 'Low';
      case GoalPriority.medium:
        return 'Medium';
      case GoalPriority.high:
        return 'High';
      case GoalPriority.critical:
        return 'Critical';
    }
  }

  // Factory constructor from JSON
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      goal: json['goal'] ?? '',
      description: json['description'],
      type: _parseGoalType(json['type']),
      status: _parseGoalStatus(json['status']),
      priority: _parseGoalPriority(json['priority']),
      targetDate: json['target_date'] != null 
          ? DateTime.parse(json['target_date']) 
          : DateTime.now().add(Duration(days: 30)),
      achievedDate: json['achieved_date'] != null 
          ? DateTime.parse(json['achieved_date']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      targetValue: json['target_value']?.toDouble(),
      currentValue: json['current_value']?.toDouble(),
      unit: json['unit'],
      milestones: json['milestones'] != null 
          ? List<String>.from(json['milestones']) 
          : null,
      metadata: json['metadata'] is Map 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      createdByCoachId: json['created_by_coach_id'],
      notes: json['notes'],
      isPublic: json['is_public'] ?? false,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal': goal,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'target_date': targetDate.toIso8601String(),
      'achieved_date': achievedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'milestones': milestones,
      'metadata': metadata,
      'created_by_coach_id': createdByCoachId,
      'notes': notes,
      'is_public': isPublic,
      'tags': tags,
    };
  }

  // Helper methods to parse enums from strings
  static GoalType _parseGoalType(dynamic type) {
    if (type == null) return GoalType.other;
    
    switch (type.toString().toLowerCase()) {
      case 'weight':
        return GoalType.weight;
      case 'strength':
        return GoalType.strength;
      case 'endurance':
        return GoalType.endurance;
      case 'flexibility':
        return GoalType.flexibility;
      case 'skill':
        return GoalType.skill;
      case 'habit':
        return GoalType.habit;
      case 'performance':
        return GoalType.performance;
      case 'body_composition':
        return GoalType.body_composition;
      case 'health':
        return GoalType.health;
      default:
        return GoalType.other;
    }
  }

  static GoalStatus _parseGoalStatus(dynamic status) {
    if (status == null) return GoalStatus.active;
    
    switch (status.toString().toLowerCase()) {
      case 'achieved':
        return GoalStatus.achieved;
      case 'paused':
        return GoalStatus.paused;
      case 'cancelled':
        return GoalStatus.cancelled;
      case 'overdue':
        return GoalStatus.overdue;
      case 'active':
      default:
        return GoalStatus.active;
    }
  }

  static GoalPriority _parseGoalPriority(dynamic priority) {
    if (priority == null) return GoalPriority.medium;
    
    switch (priority.toString().toLowerCase()) {
      case 'low':
        return GoalPriority.low;
      case 'high':
        return GoalPriority.high;
      case 'critical':
        return GoalPriority.critical;
      case 'medium':
      default:
        return GoalPriority.medium;
    }
  }

  // Copy with method for immutable updates
  GoalModel copyWith({
    int? id,
    int? userId,
    String? goal,
    String? description,
    GoalType? type,
    GoalStatus? status,
    GoalPriority? priority,
    DateTime? targetDate,
    DateTime? achievedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? targetValue,
    double? currentValue,
    String? unit,
    List<String>? milestones,
    Map<String, dynamic>? metadata,
    int? createdByCoachId,
    String? notes,
    bool? isPublic,
    List<String>? tags,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goal: goal ?? this.goal,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      targetDate: targetDate ?? this.targetDate,
      achievedDate: achievedDate ?? this.achievedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      milestones: milestones ?? this.milestones,
      metadata: metadata ?? this.metadata,
      createdByCoachId: createdByCoachId ?? this.createdByCoachId,
      notes: notes ?? this.notes,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GoalModel && 
           other.id == id && 
           other.userId == userId &&
           other.goal == goal;
  }

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ goal.hashCode;

  @override
  String toString() {
    return 'GoalModel(id: $id, goal: $goal, status: $status, targetDate: $targetDate)';
  }
}
