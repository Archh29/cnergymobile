import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/routine.models.dart';
import '../services/routine_services.dart';

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
    final stats = RoutineService.calculateRoutineStats(workoutHistory, routine.name);
    final routineColor = _getColorFromString(routine.color);

    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            routineColor.withOpacity(0.1),
            routineColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: routineColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: routineColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: routineColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress Overview',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your performance with this routine',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),

          // Progress Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions',
                  stats['totalSessions'].toString(),
                  Icons.fitness_center,
                  routineColor,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completion',
                  '${routine.completionRate}%',
                  Icons.check_circle,
                  routineColor,
                ),
              ),
            ],
          ),

          if (isProMember) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Duration',
                    _formatDuration(stats['averageDuration']),
                    Icons.timer,
                    routineColor,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Volume',
                    '${stats['totalVolume'].toStringAsFixed(0)} kg',
                    Icons.monitor_weight,
                    routineColor,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${routine.completionRate}%',
                    style: GoogleFonts.poppins(
                      color: routineColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: routine.completionRate / 100,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(routineColor),
                minHeight: 6,
              ),
            ],
          ),

          SizedBox(height: 16),

          // Last Performance
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey[500], size: 16),
                SizedBox(width: 8),
                Text(
                  'Last performed: ${stats['lastPerformed']}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
                if (isProMember && stats['averageRating'] > 0) ...[
                  Spacer(),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 12,
                        color: index < stats['averageRating']
                            ? Colors.amber
                            : Colors.grey[600],
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),

          // Recent Sessions (Pro only)
          if (isProMember) ...[
            SizedBox(height: 16),
            _buildRecentSessions(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
    final recentSessions = workoutHistory
        .where((session) => session.routineName == routine.name)
        .take(3)
        .toList();

    if (recentSessions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
            SizedBox(width: 8),
            Text(
              'No recent sessions found',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
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
          'Recent Sessions',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...recentSessions.map((session) => Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      RoutineService.formatDate(session.date),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_formatDuration(session.duration)} • ${session.exercises} exercises',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.rating > 0)
                Row(
                  children: List.generate(session.rating, (index) {
                    return Icon(
                      Icons.star,
                      size: 10,
                      color: Colors.amber,
                    );
                  }),
                ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Color(0xFF96CEB4);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0m';
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
