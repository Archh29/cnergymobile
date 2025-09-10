import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AchievementsService {
  static const String baseUrl = 'http://localhost/cynergy/';
  static const String achievementsEndpoint = '${baseUrl}achievements.php';

  // Get all achievements for a user
  static Future<AchievementsData> getAchievements() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$achievementsEndpoint?action=get_achievements&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Achievements response status: ${response.statusCode}');
      print('Achievements response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AchievementsData.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching achievements: $e');
      rethrow;
    }
  }

  // Get user statistics
  static Future<UserStats> getUserStats() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$achievementsEndpoint?action=get_user_stats&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return UserStats.fromJson(data['data']);
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user stats: $e');
      rethrow;
    }
  }

  // Check for new achievements
  static Future<List<NewAchievement>> checkNewAchievements() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$achievementsEndpoint?action=check_achievements&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data']['new_achievements'] as List)
              .map((item) => NewAchievement.fromJson(item))
              .toList();
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking new achievements: $e');
      rethrow;
    }
  }

  // Force check achievements (for debugging)
  static Future<Map<String, dynamic>> forceCheckAchievements() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.get(
        Uri.parse('$achievementsEndpoint?action=force_check&user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Force check response status: ${response.statusCode}');
      print('Force check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw Exception('API returned error: ${data['error']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error force checking achievements: $e');
      rethrow;
    }
  }

  // Helper method to get achievement icon
  static String getAchievementIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'log-in':
        return 'login';
      case 'calendar':
        return 'event';
      case 'dumbbell':
        return 'fitness_center';
      case 'star':
        return 'star';
      case 'medal':
        return 'emoji_events';
      case 'award':
        return 'military_tech';
      case 'clipboard':
        return 'assignment';
      case 'barbell':
        return 'sports_gymnastics';
      case 'trophy':
        return 'trophy';
      case 'flag':
        return 'flag';
      case 'handshake':
        return 'handshake';
      case 'message-circle':
        return 'message';
      default:
        return 'emoji_events';
    }
  }

  // Helper method to get achievement color
  static int getAchievementColor(String category) {
    switch (category.toLowerCase()) {
      case 'attendance':
        return 0xFF4ECDC4;
      case 'membership':
        return 0xFF45B7D1;
      case 'fitness':
        return 0xFFFF6B35;
      case 'strength':
        return 0xFFE74C3C;
      case 'goals':
        return 0xFF96CEB4;
      case 'community':
        return 0xFF9B59B6;
      default:
        return 0xFF4ECDC4;
    }
  }
}

class Achievement {
  final int id;
  final String title;
  final String description;
  final String icon;
  final double progress;
  final String level;
  final bool unlocked;
  final int points;
  final String category;
  final int color;
  final String? awardedAt;
  final String createdAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.level,
    required this.unlocked,
    required this.points,
    required this.category,
    required this.color,
    this.awardedAt,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'emoji_events',
      progress: (json['progress'] ?? 0.0).toDouble(),
      level: json['level'] ?? 'Bronze',
      unlocked: json['unlocked'] ?? false,
      points: json['points'] ?? 0,
      category: json['category'] ?? 'General',
      color: json['color'] ?? 0xFF4ECDC4,
      awardedAt: json['awarded_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'progress': progress,
      'level': level,
      'unlocked': unlocked,
      'points': points,
      'category': category,
      'color': color,
      'awarded_at': awardedAt,
      'created_at': createdAt,
    };
  }
}

class AchievementsData {
  final List<Achievement> achievements;
  final int totalPoints;
  final int unlockedCount;
  final int totalCount;

  AchievementsData({
    required this.achievements,
    required this.totalPoints,
    required this.unlockedCount,
    required this.totalCount,
  });

  factory AchievementsData.fromJson(Map<String, dynamic> json) {
    return AchievementsData(
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((item) => Achievement.fromJson(item))
          .toList() ?? [],
      totalPoints: json['total_points'] ?? 0,
      unlockedCount: json['unlocked_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievements': achievements.map((item) => item.toJson()).toList(),
      'total_points': totalPoints,
      'unlocked_count': unlockedCount,
      'total_count': totalCount,
    };
  }
}

class UserStats {
  final int totalCheckins;
  final int totalWorkouts;
  final int totalSets;
  final double maxWeight;
  final String? firstMembership;
  final String? lastMembership;
  final int goalsSet;
  final int goalsAchieved;
  final int coachAssigned;
  final int reviewsGiven;

  UserStats({
    required this.totalCheckins,
    required this.totalWorkouts,
    required this.totalSets,
    required this.maxWeight,
    this.firstMembership,
    this.lastMembership,
    required this.goalsSet,
    required this.goalsAchieved,
    required this.coachAssigned,
    required this.reviewsGiven,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalCheckins: json['total_checkins'] ?? 0,
      totalWorkouts: json['total_workouts'] ?? 0,
      totalSets: json['total_sets'] ?? 0,
      maxWeight: (json['max_weight'] ?? 0.0).toDouble(),
      firstMembership: json['first_membership'],
      lastMembership: json['last_membership'],
      goalsSet: json['goals_set'] ?? 0,
      goalsAchieved: json['goals_achieved'] ?? 0,
      coachAssigned: json['coach_assigned'] ?? 0,
      reviewsGiven: json['reviews_given'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_checkins': totalCheckins,
      'total_workouts': totalWorkouts,
      'total_sets': totalSets,
      'max_weight': maxWeight,
      'first_membership': firstMembership,
      'last_membership': lastMembership,
      'goals_set': goalsSet,
      'goals_achieved': goalsAchieved,
      'coach_assigned': coachAssigned,
      'reviews_given': reviewsGiven,
    };
  }
}

class NewAchievement {
  final int id;
  final String awardedAt;

  NewAchievement({
    required this.id,
    required this.awardedAt,
  });

  factory NewAchievement.fromJson(Map<String, dynamic> json) {
    return NewAchievement(
      id: json['id'] ?? 0,
      awardedAt: json['awarded_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'awarded_at': awardedAt,
    };
  }
}
