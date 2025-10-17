import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';

class HomeService {
  static const String baseUrl = 'https://api.cnergy.site/';
  static const String homeEndpoint = '$baseUrl/user_home.php';

  // Get current user ID from SharedPreferences
  static Future<int?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? userIdString = prefs.getString('user_id');
      if (userIdString != null && userIdString.isNotEmpty) {
        return int.parse(userIdString);
      }
      
      int? userIdInt = prefs.getInt('user_id');
      if (userIdInt != null) {
        return userIdInt;
      }
      
      return null;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Fetch all home data from single API endpoint
  static Future<Map<String, dynamic>> getHomeData({int? userId}) async {
    try {
      String url = homeEndpoint;
      if (userId != null) {
        url += '?user_id=$userId';
      }
      
      print('🔄 Fetching data from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          Map<String, dynamic> result = {
            'announcements': (data['data']['announcements'] as List)
                .map((item) => AnnouncementItem.fromJson(item))
                .toList(),
            'merchandise': (data['data']['merchandise'] as List)
                .map((item) => MerchItem.fromJson(item))
                .toList(),
            'promotions': (data['data']['promotions'] as List)
                .map((item) => PromotionItem.fromJson(item))
                .toList(),
          };
          
          // Add today's workout if available (for display only)
          if (data['data']['todayWorkout'] != null) {
            result['today_workout'] = TodayWorkout.fromJson(data['data']['todayWorkout']);
          }
          
          return result;
        } else {
          throw Exception('API returned success: false - ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching home data: $e');
      // Return empty data if API fails
      return {
        'announcements': <AnnouncementItem>[],
        'merchandise': <MerchItem>[],
        'promotions': <PromotionItem>[],
        'today_workout': null,
        'weekly_schedule': <WeeklyScheduleItem>[],
      };
    }
  }

}

// Data models
class AnnouncementItem {
  final int id;
  final String title;
  final String description;
  final String icon;
  final String color;
  final bool isImportant;
  final String? datePosted;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isImportant,
    this.datePosted,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'info',
      color: json['color'] ?? '#96CEB4',
      isImportant: json['isImportant'] ?? false,
      datePosted: json['datePosted'],
    );
  }
}

class MerchItem {
  final int id;
  final String name;
  final String price;
  final String description;
  final String color;
  final String icon;
  final String? imageUrl;
  final String? createdAt;

  MerchItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.color,
    required this.icon,
    this.imageUrl,
    this.createdAt,
  });

  factory MerchItem.fromJson(Map<String, dynamic> json) {
    return MerchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '₱0.00',
      description: json['description'] ?? '',
      color: json['color'] ?? '#96CEB4',
      icon: json['icon'] ?? 'fitness_center',
      imageUrl: json['imageUrl'], // API returns 'imageUrl' 
      createdAt: json['createdAt'], // API returns 'createdAt'
    );
  }
}

class PromotionItem {
  final int id;
  final String title;
  final String description;
  final String discount;
  final String validUntil;
  final String color;
  final String icon;
  final String? startDate;
  final String? endDate;
  final String? createdAt;

  PromotionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validUntil,
    required this.color,
    required this.icon,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  factory PromotionItem.fromJson(Map<String, dynamic> json) {
    return PromotionItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discount: json['discount'] ?? 'SPECIAL',
      validUntil: json['validUntil'] ?? '',
      color: json['color'] ?? '#96CEB4',
      icon: json['icon'] ?? 'star',
      startDate: json['startDate'],
      endDate: json['endDate'],
      createdAt: json['createdAt'],
    );
  }
}
