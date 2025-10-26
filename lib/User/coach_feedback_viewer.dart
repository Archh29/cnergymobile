import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/coach_rating_service.dart';

class CoachFeedbackViewer extends StatefulWidget {
  final int coachId;
  final String coachName;
  final double currentRating;
  final int totalReviews;

  const CoachFeedbackViewer({
    Key? key,
    required this.coachId,
    required this.coachName,
    required this.currentRating,
    required this.totalReviews,
  }) : super(key: key);

  @override
  _CoachFeedbackViewerState createState() => _CoachFeedbackViewerState();
}

class _CoachFeedbackViewerState extends State<CoachFeedbackViewer> {
  bool _loading = true;
  Map<String, dynamic>? _ratingData;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final data = await CoachRatingService.getCoachRatings(widget.coachId);
      if (data['success'] == true) {
        setState(() {
          _ratingData = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['message'] ?? 'Failed to load feedback';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading feedback: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.coachName}\'s Reviews',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4ECDC4),
              ),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        _error,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_ratingData == null) return Container();

    final averageRating = _safeParseDouble(_ratingData!['average_rating']) ?? 0.0;
    final totalReviews = _safeParseInt(_ratingData!['total_reviews']) ?? 0;
    final ratingDistribution = _ratingData!['rating_distribution'] ?? {};
    final reviews = _ratingData!['reviews'] ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Rating Summary
          _buildRatingSummary(averageRating, totalReviews),
          SizedBox(height: 24),
          
          // Rating Distribution
          _buildRatingDistribution(ratingDistribution),
          SizedBox(height: 24),
          
          // Reviews List
          _buildReviewsList(reviews),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(double averageRating, int totalReviews) {
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
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.star, color: Colors.white, size: 32),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Rating',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            color: Color(0xFF4ECDC4),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        ...List.generate(5, (index) {
                          return Icon(
                            index < averageRating ? Icons.star : Icons.star_border,
                            color: Color(0xFFFFD700),
                            size: 20,
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Based on $totalReviews review${totalReviews != 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(Map<String, dynamic> distribution) {
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(5, (index) {
            final rating = 5 - index;
            final count = distribution[rating.toString()] ?? 0;
            final total = distribution.values.fold(0, (sum, value) => sum + (value as int));
            final percentage = total > 0 ? (count / total) * 100 : 0.0;
            
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    '$rating',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF4ECDC4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '$count',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.reviews, color: Colors.grey[400], size: 64),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reviews',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _safeParseInt(review['rating']) ?? 0;
    final feedback = review['feedback'] ?? '';
    final memberName = '${review['fname'] ?? ''} ${review['lname'] ?? ''}'.trim();
    final createdAt = review['last_modified'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF4ECDC4),
                child: Text(
                  memberName.isNotEmpty ? memberName[0].toUpperCase() : 'U',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName.isNotEmpty ? memberName : 'Anonymous',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Color(0xFFFFD700),
                            size: 16,
                          );
                        }),
                        SizedBox(width: 8),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            SizedBox(height: 12),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateString;
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
