import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './services/enhanced_progress_service.dart';
import './models/goal_model.dart';
import './models/workout_session_model.dart';
import './models/attendance_model.dart';
import './models/progress_model.dart';
import './workout_heatmap_page.dart';
import './measurements_page.dart';
import './schedule_page.dart';
import './personal_records_page.dart';
import './goals_page.dart';
import './models/personal_record_model.dart';

class ComprehensiveDashboard extends StatefulWidget {
  @override
  _ComprehensiveDashboardState createState() => _ComprehensiveDashboardState();
}

class _ComprehensiveDashboardState extends State<ComprehensiveDashboard>
    with TickerProviderStateMixin {
    
  Map<String, dynamic> stats = {};
  List<GoalModel> goals = [];
  List<WorkoutSessionModel> recentSessions = [];
  List<AttendanceModel> recentAttendance = [];
  List<ProgressModel> progressData = [];
  Map<DateTime, int> workoutHeatmapData = {};
  String? nextScheduledWorkout;
  DateTime? nextWorkoutDate;
  Map<String, double> latestMeasurements = {};
  bool isLoading = true;
  List<PersonalRecordModel> personalRecords = [];
    
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
        
    try {
      final futures = await Future.wait([
        EnhancedProgressService.getComprehensiveStats(),
        EnhancedProgressService.fetchUserGoals(),
        EnhancedProgressService.fetchWorkoutSessions(),
        EnhancedProgressService.fetchAttendanceHistory(),
        EnhancedProgressService.fetchUserProgress(),
        EnhancedProgressService.fetchPersonalRecords(),
      ]);

      if (mounted) {
        setState(() {
          stats = futures[0] as Map<String, dynamic>;
          goals = (futures[1] as List<GoalModel>).take(3).toList();
          recentSessions = (futures[2] as List<WorkoutSessionModel>).take(5).toList();
          recentAttendance = (futures[3] as List<AttendanceModel>).take(7).toList();
          progressData = futures[4] as List<ProgressModel>;
          
          // Generate heatmap from actual workout sessions
          workoutHeatmapData = _generateWorkoutHeatmapFromSessions(recentSessions);
          
          // Get next scheduled workout from sessions
          nextScheduledWorkout = _getNextScheduledWorkoutFromSessions();
          
          // Get latest measurements from progress data
          latestMeasurements = _getLatestMeasurementsFromProgress();
          
          personalRecords = (futures[5] as List<PersonalRecordModel>).take(3).toList();
          
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<DateTime, int> _generateWorkoutHeatmapFromSessions(List<WorkoutSessionModel> sessions) {
    final Map<DateTime, int> heatmapData = {};
    final now = DateTime.now();
    
    // Initialize last 90 days with 0
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      heatmapData[dateKey] = 0;
    }
    
    // Mark days with workouts
    for (final session in sessions) {
      final dateKey = DateTime(
        session.sessionDate.year,
        session.sessionDate.month,
        session.sessionDate.day,
      );
      
      if (heatmapData.containsKey(dateKey)) {
        // Intensity based on completion status
        heatmapData[dateKey] = session.completed ? 3 : 1;
      }
    }
    
    return heatmapData;
  }

  String? _getNextScheduledWorkoutFromSessions() {
    final now = DateTime.now();
    final upcomingSessions = recentSessions
        .where((session) => session.sessionDate.isAfter(now) && !session.completed)
        .toList();
    
    if (upcomingSessions.isNotEmpty) {
      upcomingSessions.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
      final nextSession = upcomingSessions.first;
      nextWorkoutDate = nextSession.sessionDate;
      return nextSession.programName ?? 'Workout Session';
    }
    
    return null;
  }

  Map<String, double> _getLatestMeasurementsFromProgress() {
    if (progressData.isEmpty) {
      return {
        'weight': 0.0,
        'body_fat': 0.0,
        'muscle_mass': 0.0,
        'height': 0.0,
      };
    }
    
    // Sort by date and get latest
    progressData.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    final latest = progressData.first;
    
    return {
      'weight': latest.weight ?? 0.0,
      'body_fat': 0.0, // Not available in your DB
      'muscle_mass': 0.0, // Calculate from other measurements if needed
      'height': 175.0, // Default or get from user profile
      'bmi': latest.bmi ?? 0.0,
      'chest': latest.chestCm ?? 0.0,
      'waist': latest.waistCm ?? 0.0,
      'hips': latest.hipsCm ?? 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: Color(0xFF4ECDC4),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernHeader(),
                        SizedBox(height: 24),
                        _buildWorkoutHeatmapSection(),
                        SizedBox(height: 24),
                        _buildNextWorkoutSection(),
                        SizedBox(height: 24),
                        _buildMeasurementsSection(),
                        SizedBox(height: 24),
                        _buildPersonalRecordsSection(),
                        SizedBox(height: 24),
                        _buildQuickStats(),
                        SizedBox(height: 24),
                        _buildGoalsSection(),
                        SizedBox(height: 24),
                        _buildRecentActivity(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.dashboard_rounded, color: Colors.white, size: 32),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track your progress and stay motivated',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHeatmapSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutHeatmapPage(
              heatmapData: workoutHeatmapData,
              workoutSessions: recentSessions,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.calendar_view_month_rounded, color: Color(0xFFFF6B35), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Heatmap',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last 90 days activity',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 20),
            _buildMiniHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHeatmap() {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: 20));
        
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Text(
                    day,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 12),
        Container(
          height: 80,
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: 21,
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              final dateKey = DateTime(date.year, date.month, date.day);
              final intensity = workoutHeatmapData[dateKey] ?? 0;
                            
              return Container(
                decoration: BoxDecoration(
                  color: _getHeatmapColor(intensity),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Less',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            Row(
              children: List.generate(5, (index) => Container(
                margin: EdgeInsets.only(left: 2),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getHeatmapColor(index),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
            Text(
              'More',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return Color(0xFF2A2A2A);
      case 1:
        return Color(0xFF4ECDC4).withOpacity(0.3);
      case 2:
        return Color(0xFF4ECDC4).withOpacity(0.6);
      case 3:
        return Color(0xFF4ECDC4).withOpacity(0.8);
      case 4:
        return Color(0xFF4ECDC4);
      default:
        return Color(0xFF2A2A2A);
    }
  }

  Widget _buildNextWorkoutSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchedulePage(workoutSessions: recentSessions),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF96CEB4), Color(0xFF7FB069)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF96CEB4).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.schedule_rounded, color: Colors.white, size: 28),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Workout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    nextScheduledWorkout ?? 'No workout scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (nextWorkoutDate != null)
                    Text(
                      _formatNextWorkoutDate(nextWorkoutDate!),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatNextWorkoutDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
        
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return 'In $difference days';
  }

  Widget _buildMeasurementsSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeasurementsPage(
              currentMeasurements: latestMeasurements,
              progressData: progressData,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF45B7D1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.monitor_weight_rounded, color: Color(0xFF45B7D1), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Measurements',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your progress',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementCard(
                    'Weight',
                    latestMeasurements['weight'] != null && latestMeasurements['weight']! > 0
                        ? '${latestMeasurements['weight']!.toStringAsFixed(1)} kg'
                        : '--',
                    Icons.scale_rounded,
                    Color(0xFF45B7D1),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementCard(
                    'BMI',
                    latestMeasurements['bmi'] != null && latestMeasurements['bmi']! > 0
                        ? latestMeasurements['bmi']!.toStringAsFixed(1)
                        : '--',
                    Icons.pie_chart_rounded,
                    Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordsSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalRecordsPage(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFF6B35), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Records',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your PRs',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 20),
            if (personalRecords.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 12),
                    Text(
                      'No personal records yet',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              ...personalRecords.map((record) => _buildPRItem(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPRItem(PersonalRecordModel record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B35), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName ?? 'Unknown Exercise',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.formattedWeight,
            style: GoogleFonts.poppins(
              color: Color(0xFFFF6B35),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final goalStats = stats['goals'] ?? {};
    final workoutStats = stats['workouts'] ?? {};
    final attendanceStats = stats['attendance'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Goals',
            '${goalStats['achieved'] ?? 0}/${goalStats['total'] ?? 0}',
            'Achieved',
            Color(0xFF96CEB4),
            Icons.flag_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Workouts',
            '${workoutStats['thisWeek'] ?? 0}',
            'This Week',
            Color(0xFF45B7D1),
            Icons.fitness_center_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Gym Visits',
            '${attendanceStats['thisMonth'] ?? 0}',
            'This Month',
            Color(0xFFE74C3C),
            Icons.location_on_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF96CEB4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.flag_rounded, color: Color(0xFF96CEB4), size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Active Goals',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalsPage(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF96CEB4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (goals.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No active goals',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...goals.map((goal) => _buildGoalItem(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalItem(GoalModel goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goal.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: goal.statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goal,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  goal.formattedTargetDate,
                  style: GoogleFonts.poppins(
                    color: goal.statusColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (goal.status == GoalStatus.active)
            IconButton(
              onPressed: () => _markGoalAchieved(goal),
              icon: Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF45B7D1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.history_rounded, color: Color(0xFF45B7D1), size: 24),
              ),
              SizedBox(width: 16),
              Text(
                'Recent Activity',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (recentSessions.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...recentSessions.take(3).map((session) => _buildActivityItem(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(WorkoutSessionModel session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session.completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: session.statusColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.programName ?? 'Workout Session',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  session.formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.completed ? 'Completed' : 'Pending',
              style: GoogleFonts.poppins(
                color: session.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markGoalAchieved(GoalModel goal) async {
    final success = await EnhancedProgressService.updateGoalStatus(
      goal.id!,
      GoalStatus.achieved,
    );
        
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal marked as achieved! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDashboardData();
    }
  }
}
