import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SetExperienceModal extends StatelessWidget {
  final String exerciseName;
  final int setNumber;
  final int totalSets;
  final int reps;
  final double weight;
  final int restTimeRemaining;
  final Function(String experience) onExperienceSelected;
  final VoidCallback onSkip;

  const SetExperienceModal({
    Key? key,
    required this.exerciseName,
    required this.setNumber,
    required this.totalSets,
    required this.reps,
    required this.weight,
    required this.restTimeRemaining,
    required this.onExperienceSelected,
    required this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'How did this set feel?',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Exercise info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set $setNumber/$totalSets - $exerciseName',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Weight: ${weight}kg | Reps: $reps',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Experience buttons
              _buildExperienceButton(
                context,
                'easy',
                '😌 Easy',
                'This set felt easy',
                Color(0xFF4ECDC4),
              ),
              
              SizedBox(height: 12),
              
              _buildExperienceButton(
                context,
                'moderate',
                '😐 Moderate',
                'This set felt challenging but manageable',
                Color(0xFF2ECC71),
              ),
              
              SizedBox(height: 12),
              
              _buildExperienceButton(
                context,
                'hard',
                '😤 Hard',
                'This set felt very difficult',
                Color(0xFFE74C3C),
              ),
              
              SizedBox(height: 24),
              
              // Rest timer info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Color(0xFF4ECDC4),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Rest: ${_formatTime(restTimeRemaining)} remaining',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Skip button
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceButton(
    BuildContext context,
    String experience,
    String label,
    String description,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onExperienceSelected(experience);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}



