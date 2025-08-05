import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/routine.models.dart';


class ProgressSectionWidget extends StatelessWidget {
  final RoutineModel routine;
  final List<WorkoutSession> workoutHistory;
  final bool isProMember;

  const ProgressSectionWidget({
    Key? key,
    required this.routine,
    required this.workoutHistory,
    required this.isProMember,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show progress section for premium users
    if (!isProMember) {
      return Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFFFD700).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, color: Color(0xFFFFD700), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Progress tracking available in Premium',
                style: GoogleFonts.poppins(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate progress stats for premium users
    final routineSessions = workoutHistory
        .where((session) => session.routineName.contains(routine.id))
        .toList();

    final completionRate = routine.completionRate;
    final totalSessions = routine.totalSessions;
    final lastPerformed = routine.lastPerformed;

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFF4ECDC4), size: 16),
              SizedBox(width: 8),
              Text(
                'Progress Tracking',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completion Rate',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$completionRate%',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Sessions',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$totalSessions',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Performed',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      lastPerformed,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: completionRate / 100,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ],
      ),
    );
  }
}
