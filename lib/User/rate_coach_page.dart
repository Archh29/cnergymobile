import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/auth_service.dart';

class RateCoachPage extends StatefulWidget {
  final int coachId;
  final String coachName;

  const RateCoachPage({
    Key? key,
    required this.coachId,
    required this.coachName,
  }) : super(key: key);

  @override
  _RateCoachPageState createState() => _RateCoachPageState();
}

class _RateCoachPageState extends State<RateCoachPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasExistingReview = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_rating.php?action=check_review&user_id=$userId&coach_id=${widget.coachId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted && data['success'] == true && data['has_review'] == true) {
          setState(() {
            _hasExistingReview = true;
            _rating = _safeParseInt(data['review']['rating']) ?? 0;
            _feedbackController.text = data['review']['feedback'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error checking existing review: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      _showError('Please select a rating');
      return;
    }

    if (_feedbackController.text.trim().isEmpty) {
      _showError('Please provide feedback');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        _showError('User not logged in');
        return;
      }

      final response = await http.post(
        Uri.parse('https://api.cnergy.site/coach_rating.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': _hasExistingReview ? 'update_review' : 'submit_review',
          'user_id': userId,
          'coach_id': widget.coachId,
          'rating': _rating,
          'feedback': _feedbackController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_hasExistingReview ? 'Review updated successfully!' : 'Thank you for your feedback!'),
                backgroundColor: Color(0xFF4ECDC4),
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          _showError(data['message'] ?? 'Failed to submit rating');
        }
      } else {
        _showError('Server error. Please try again.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
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
          _hasExistingReview ? 'Update Review' : 'Rate Your Coach',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach Info Card
                  Container(
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
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                            ),
                          ),
                          child: Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.coachName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your Coach',
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
                  ),
                  SizedBox(height: 32),

                  // Rating Section
                  Text(
                    'How would you rate ${widget.coachName}?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: index < _rating ? Color(0xFFFFD700) : Colors.grey[600],
                            size: 48,
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0) ...[
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        _getRatingText(_rating),
                        style: GoogleFonts.poppins(
                          color: Color(0xFF4ECDC4),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 32),

                  // Feedback Section
                  Text(
                    'Share your experience',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF4ECDC4), width: 2),
                    ),
                    child: TextField(
                      controller: _feedbackController,
                      maxLines: 8,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tell us about your experience with ${widget.coachName}...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _hasExistingReview ? 'Update Review' : 'Submit Review',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
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

