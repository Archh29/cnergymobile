import 'package:flutter/material.dart';
import '../../utils/date_utils.dart';

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
      targetDate: json['target_date'] != null ? CnergyDateUtils.parseApiDate(json['target_date']) : null,
      status: GoalStatus.fromString(json['status'] ?? 'active'),
      createdAt: CnergyDateUtils.parseApiDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? CnergyDateUtils.parseApiDateTime(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'goal': goal,
      if (targetDate != null) 'target_date': CnergyDateUtils.toApiDate(targetDate!),
      'status': status.value,
      'created_at': CnergyDateUtils.toApiDateTime(createdAt),
      if (updatedAt != null) 'updated_at': CnergyDateUtils.toApiDateTime(updatedAt!),
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
    return CnergyDateUtils.toDisplayDate(targetDate!);
  }

  String get relativeTargetDate {
    if (targetDate == null) return 'No deadline';
    return CnergyDateUtils.getRelativeDate(targetDate!);
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
