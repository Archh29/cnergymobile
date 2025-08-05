import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/workout_session_model.dart';

class WorkoutHeatmapPage extends StatefulWidget {
  final Map<DateTime, int> heatmapData;
  final List<WorkoutSessionModel> workoutSessions;

  const WorkoutHeatmapPage({
    Key? key, 
    required this.heatmapData,
    required this.workoutSessions,
  }) : super(key: key);

  @override
  _WorkoutHeatmapPageState createState() => _WorkoutHeatmapPageState();
}

class _WorkoutHeatmapPageState extends State<WorkoutHeatmapPage> {
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workout Heatmap',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.calendar_today_rounded, color: Colors.white),
            color: Color(0xFF2A2A2A),
            onSelected: (year) {
              setState(() {
                selectedYear = year;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 2024, child: Text('2024', style: GoogleFonts.poppins(color: Colors.white))),
              PopupMenuItem(value: 2023, child: Text('2023', style: GoogleFonts.poppins(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearlyHeatmap(),
            SizedBox(height: 24),
            _buildStats(),
            SizedBox(height: 24),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyHeatmap() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedYear Workout Activity',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
                .map((month) => Text(
                      month,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 12),
          Container(
            height: 200,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 53,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 365,
              itemBuilder: (context, index) {
                final date = DateTime(selectedYear, 1, 1).add(Duration(days: index));
                final intensity = widget.heatmapData[DateTime(date.year, date.month, date.day)] ?? 0;
                                
                return Container(
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(intensity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalWorkouts = widget.heatmapData.values.where((v) => v > 0).length;
    final maxStreak = _calculateMaxStreak();
    final currentStreak = _calculateCurrentStreak();
        
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Total Workouts', totalWorkouts.toString(), Icons.fitness_center_rounded, Color(0xFF4ECDC4)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Max Streak', '$maxStreak days', Icons.local_fire_department_rounded, Color(0xFFFF6B35)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Current Streak', '$currentStreak days', Icons.trending_up_rounded, Color(0xFF96CEB4)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Legend',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Less',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Row(
                children: List.generate(5, (index) => Container(
                  margin: EdgeInsets.only(left: 4),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(index),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              Text(
                'More',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0: return Color(0xFF2A2A2A);
      case 1: return Color(0xFF4ECDC4).withOpacity(0.3);
      case 2: return Color(0xFF4ECDC4).withOpacity(0.6);
      case 3: return Color(0xFF4ECDC4).withOpacity(0.8);
      case 4: return Color(0xFF4ECDC4);
      default: return Color(0xFF2A2A2A);
    }
  }

  int _calculateMaxStreak() {
    if (widget.workoutSessions.isEmpty) return 0;
    
    final completedSessions = widget.workoutSessions
        .where((session) => session.completed)
        .toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
    
    if (completedSessions.isEmpty) return 0;
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < completedSessions.length; i++) {
      final daysDiff = completedSessions[i].sessionDate
          .difference(completedSessions[i - 1].sessionDate)
          .inDays;
      
      if (daysDiff <= 2) {
        currentStreak++;
        maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  int _calculateCurrentStreak() {
    if (widget.workoutSessions.isEmpty) return 0;
    
    final now = DateTime.now();
    final recentSessions = widget.workoutSessions
        .where((session) => session.completed && 
               session.sessionDate.isAfter(now.subtract(Duration(days: 30))))
        .toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    
    if (recentSessions.isEmpty) return 0;
    
    int streak = 0;
    DateTime? lastWorkoutDate;
    
    for (final session in recentSessions) {
      if (lastWorkoutDate == null) {
        streak = 1;
        lastWorkoutDate = session.sessionDate;
      } else {
        final daysDiff = lastWorkoutDate.difference(session.sessionDate).inDays;
        if (daysDiff <= 2) {
          streak++;
          lastWorkoutDate = session.sessionDate;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }
}
