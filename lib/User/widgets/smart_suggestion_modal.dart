import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartSuggestionModal extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final String exerciseName;
  final int reps;
  final double weight;
  final VoidCallback onGotIt;

  const SmartSuggestionModal({
    Key? key,
    required this.message,
    required this.icon,
    required this.color,
    required this.exerciseName,
    required this.reps,
    required this.weight,
    required this.onGotIt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A), // Match system dark background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with better spacing
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(height: 20),
            
            // Title with system styling
            Text(
              'Smart Suggestion',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            
            // Exercise info with system styling
            Text(
              exerciseName,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '${weight.toStringAsFixed(0)}kg × $reps reps',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            
            // Message with system styling
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            
            // Single "Got it" button with system styling
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGotIt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Got it',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
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

}
