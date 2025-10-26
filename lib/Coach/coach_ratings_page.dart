import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

class CoachRatingsPage extends StatefulWidget {
  const CoachRatingsPage({Key? key}) : super(key: key);

  @override
  _CoachRatingsPageState createState() => _CoachRatingsPageState();
}

class _CoachRatingsPageState extends State<CoachRatingsPage> {
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final coachId = await AuthService.getCurrentUserId();
      if (coachId == null) return;

      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_rating.php?action=get_coach_ratings&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _averageRating = _safeParseDouble(data['average_rating']) ?? 0.0;
            _totalReviews = _safeParseInt(data['total_reviews']) ?? 0;
            _ratingDistribution = Map<int, int>.from(
              data['rating_distribution'] ?? {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
            );
            _reviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading ratings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Ratings & Reviews',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
          : RefreshIndicator(
              onRefresh: _loadRatings,
              color: Color(0xFF4ECDC4),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Rating Card
                    _buildOverallRatingCard(),
                    SizedBox(height: 20),

                    // Rating Distribution
                    _buildRatingDistribution(),
                    SizedBox(height: 32),

                    // Reviews List
                    Text(
                      'Member Reviews ($_totalReviews)',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    if (_reviews.isEmpty)
                      _buildEmptyState()
                    else
                      ..._reviews.map((review) => _buildReviewCard(review)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverallRatingCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Rating',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            _averageRating.toStringAsFixed(1),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < _averageRating.round() ? Icons.star : Icons.star_border,
                color: Colors.white,
                size: 28,
              );
            }),
          ),
          SizedBox(height: 12),
          Text(
            'Based on $_totalReviews ${_totalReviews == 1 ? 'review' : 'reviews'}',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Distribution',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = _ratingDistribution[rating] ?? 0;
            final percentage = _totalReviews > 0 ? (count / _totalReviews) : 0.0;
            return _buildRatingBar(rating, count, percentage);
          }),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, int count, double percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$rating',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          ),
          SizedBox(width: 4),
          Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
          SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: percentage,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _safeParseInt(review['rating']) ?? 0;
    final feedback = review['feedback'] ?? '';
    final memberName = review['member_name'] ?? 'Anonymous';
    final createdAt = review['last_modified'] ?? '';
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                ),
                child: Center(
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(createdAt),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: index < rating ? Color(0xFFFFD700) : Colors.grey[600],
                    size: 18,
                  );
                }),
              ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              feedback,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          SizedBox(height: 20),
          Text(
            'No Reviews Yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'When members rate your coaching, their reviews will appear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} weeks ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  // Helper method to safely parse double values from API responses
  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
        return null;
      }
    }
    return null;
  }

  // Helper method to safely parse int values from API responses
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $value');
        return null;
      }
    }
    return null;
  }
}

