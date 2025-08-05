import 'package:flutter/material.dart';

class GoalModel {
  final int? id;
  final int userId;
  final String goal;
  final DateTime? targetDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GoalModel({
    this.id,
    required this.userId,
    required this.goal,
    this.targetDate,
    this.status = GoalStatus.active,
    required this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.parse(json['user_id'].toString()),
      goal: json['goal'] ?? '',
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      status: GoalStatus.fromString(json['status'] ?? 'active'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'goal': goal,
      if (targetDate != null) 'target_date': targetDate!.toIso8601String().split('T')[0],
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  int? get daysRemaining {
    if (targetDate == null) return null;
    final now = DateTime.now();
    return targetDate!.difference(now).inDays;
  }

  bool get isOverdue {
    if (targetDate == null || status != GoalStatus.active) return false;
    return DateTime.now().isAfter(targetDate!);
  }

  Color get statusColor {
    switch (status) {
      case GoalStatus.achieved:
        return Colors.green;
      case GoalStatus.cancelled:
        return Colors.red;
      case GoalStatus.active:
        if (isOverdue) return Colors.red;
        final days = daysRemaining;
        if (days == null) return Color(0xFF4ECDC4);
        if (days <= 7) return Colors.orange;
        return Color(0xFF4ECDC4);
    }
  }

  String get formattedTargetDate {
    if (targetDate == null) return 'No deadline';
    final now = DateTime.now();
    final difference = targetDate!.difference(now).inDays;
    
    if (difference == 0) return 'Due today';
    if (difference == 1) return 'Due tomorrow';
    if (difference > 0) return 'Due in $difference days';
    return 'Overdue by ${-difference} days';
  }
}

enum GoalStatus {
  active('active'),
  achieved('achieved'),
  cancelled('cancelled');

  const GoalStatus(this.value);
  final String value;

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => GoalStatus.active,
    );
  }
}
