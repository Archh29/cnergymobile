import 'dart:convert';
import 'package:http/http.dart' as http;

class CoachRatingService {
  static const String baseUrl = 'https://api.cnergy.site';

  // Fetch coach ratings and reviews
  static Future<Map<String, dynamic>> getCoachRatings(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coach_rating.php?action=get_coach_ratings&coach_id=$coachId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load coach ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coach ratings: $e');
      return {
        'success': false,
        'message': 'Failed to load ratings',
        'average_rating': 0.0,
        'total_reviews': 0,
        'rating_distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        'reviews': []
      };
    }
  }

  // Check if user has already reviewed this coach
  static Future<Map<String, dynamic>> checkExistingReview(int userId, int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/coach_rating.php?action=check_review&user_id=$userId&coach_id=$coachId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to check existing review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking existing review: $e');
      return {
        'success': false,
        'has_review': false
      };
    }
  }
}
