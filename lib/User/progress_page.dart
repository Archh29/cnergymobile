import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './services/enhanced_progress_service.dart';
import './models/goal_model.dart';
import './models/workout_session_model.dart';
import './models/attendance_model.dart';
import './models/progress_model.dart';
import './workout_heatmap_page.dart';
import './measurements_page.dart';
import './personal_records_page.dart';
import './goals_page.dart';
import './models/personal_record_model.dart';
import './models/muscle_analytics_model.dart';
import './services/muscle_analytics_service.dart';
import './services/profile_service.dart';
import './services/gym_utils_service.dart';
import './muscle_analytics_page.dart';

class ComprehensiveDashboard extends StatefulWidget {
  @override
  _ComprehensiveDashboardState createState() => _ComprehensiveDashboardState();
}

class _ComprehensiveDashboardState extends State<ComprehensiveDashboard>
    with TickerProviderStateMixin {
    
  Map<String, dynamic> stats = {};
  List<GoalModel> goals = [];
  List<WorkoutSessionModel> recentSessions = [];
  List<WorkoutSessionModel> allSessions = [];
  List<AttendanceModel> recentAttendance = [];
  List<ProgressModel> progressData = [];
  Map<DateTime, int> workoutHeatmapData = {};
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, double> latestMeasurements = {};
  bool isLoading = true;
  List<PersonalRecordModel> personalRecords = [];
  MuscleAnalyticsData? muscleAnalytics;
  double? userHeight;
  double? userWeight;
    
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
        MuscleAnalyticsService.getWeeklyStats(),
        _loadUserHeight(),
      ]);

      if (mounted) {
        setState(() {
          stats = futures[0] as Map<String, dynamic>;
          goals = (futures[1] as List<GoalModel>).take(3).toList();
          allSessions = (futures[2] as List<WorkoutSessionModel>);
          recentSessions = allSessions.take(5).toList();
          recentAttendance = (futures[3] as List<AttendanceModel>).take(7).toList();
          progressData = futures[4] as List<ProgressModel>;
          
          // Generate heatmap from all workout sessions
          workoutHeatmapData = _generateWorkoutHeatmapFromSessions(allSessions);
          
          
          // Get latest measurements from progress data
          latestMeasurements = _getLatestMeasurementsFromProgress();
          
          personalRecords = (futures[5] as List<PersonalRecordModel>).take(3).toList();
          muscleAnalytics = futures[6] as MuscleAnalyticsData;
          
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
    
    // Mark days with workouts
    for (final session in sessions) {
      final dateKey = DateTime(
        session.sessionDate.year,
        session.sessionDate.month,
        session.sessionDate.day,
      );
      
      // Intensity based on completion status
      heatmapData[dateKey] = session.completed ? 3 : 1;
    }
    
    return heatmapData;
  }


  Future<void> _loadUserHeight() async {
    try {
      final profileData = await ProfileService.getProfile();
      if (profileData != null) {
        if (profileData['height_cm'] != null) {
          userHeight = double.tryParse(profileData['height_cm'].toString());
        }
        if (profileData['weight_kg'] != null) {
          userWeight = double.tryParse(profileData['weight_kg'].toString());
        }
      }
    } catch (e) {
      print('Error loading user profile data: $e');
    }
  }

  Map<String, double> _getLatestMeasurementsFromProgress() {
    if (progressData.isEmpty) {
      // If no progress data, try to get BMI from profile data
      double? profileBMI;
      if (userHeight != null && userHeight! > 0 && userWeight != null && userWeight! > 0) {
        profileBMI = GymUtilsService.calculateBMI(userWeight!, userHeight!);
      }
      
      return {
        'weight': userWeight ?? 0.0,
        'bmi': profileBMI ?? 0.0,
        'chest': 0.0,
        'waist': 0.0,
        'hips': 0.0,
        'arms': 0.0,
        'thighs': 0.0,
      };
    }
    
    // Sort by date and get latest
    progressData.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    final latest = progressData.first;
    
    // Calculate BMI if not available in progress data
    double? calculatedBMI = latest.bmi;
    if ((calculatedBMI == null || calculatedBMI == 0.0) && 
        latest.weight != null && latest.weight! > 0 && 
        userHeight != null && userHeight! > 0) {
      calculatedBMI = GymUtilsService.calculateBMI(latest.weight!, userHeight!);
    }
    
    return {
      'weight': latest.weight ?? 0.0,
      'bmi': calculatedBMI ?? 0.0,
      'chest': latest.chestCm ?? 0.0,
      'waist': latest.waistCm ?? 0.0,
      'hips': latest.hipsCm ?? 0.0,
      'arms': latest.armsCm ?? 0.0,
      'thighs': latest.thighsCm ?? 0.0,
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
                        _buildMeasurementsSection(),
                        SizedBox(height: 24),
                        _buildMuscleAnalyticsSection(),
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
              workoutSessions: allSessions,
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
                        '${_monthName(selectedMonth)} $selectedYear',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Month selector
                PopupMenuButton<int>(
                  icon: Icon(Icons.calendar_view_month_rounded, color: Colors.white),
                  color: Color(0xFF2A2A2A),
                  onSelected: (m) {
                    setState(() {
                      selectedMonth = m;
                    });
                  },
                  itemBuilder: (context) => List.generate(12, (i) => i + 1)
                      .map((m) => PopupMenuItem(
                            value: m,
                            child: Text(_monthName(m), style: GoogleFonts.poppins(color: Colors.white)),
                          ))
                      .toList(),
                ),
                SizedBox(width: 8),
                // Year selector
                PopupMenuButton<int>(
                  icon: Icon(Icons.calendar_today_rounded, color: Colors.white),
                  color: Color(0xFF2A2A2A),
                  onSelected: (y) {
                    setState(() {
                      selectedYear = y;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}', style: GoogleFonts.poppins(color: Colors.white))),
                    PopupMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}', style: GoogleFonts.poppins(color: Colors.white))),
                    PopupMenuItem(value: DateTime.now().year - 2, child: Text('${DateTime.now().year - 2}', style: GoogleFonts.poppins(color: Colors.white))),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildMonthGrid(selectedYear, selectedMonth),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(int year, int month) {
    final int days = _daysInMonth(year, month);
    final DateTime firstDay = DateTime(year, month, 1);
    final int startWeekday = firstDay.weekday; // 1=Mon..7=Sun
    final int leadingBlanks = (startWeekday - 1);
    final totalCells = leadingBlanks + days;
    final int rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 12),
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            final int dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > days) {
              return Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
            final date = DateTime(year, month, dayNumber);
            final dateKey = DateTime(date.year, date.month, date.day);
            final int intensity = workoutHeatmapData[dateKey] ?? 0;
            return Container(
              height: 20,
              decoration: BoxDecoration(
                color: _getHeatmapColor(intensity),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
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
                margin: EdgeInsets.only(left: 4),
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

  int _daysInMonth(int year, int month) {
    final beginningNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDayOfMonth = beginningNextMonth.subtract(Duration(days: 1));
    return lastDayOfMonth.day;
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
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

  Widget _buildMuscleAnalyticsSection() {
    return GestureDetector(
      onTap: () {
        if (muscleAnalytics != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MuscleAnalyticsPage(
                initialData: muscleAnalytics!,
              ),
            ),
          );
        }
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
                  child: Icon(Icons.fitness_center, color: Color(0xFFFF6B35), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Muscle Group Analytics',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'This Week',
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
            if (muscleAnalytics != null && muscleAnalytics!.muscleGroups.isNotEmpty) ...[
              Text(
                'Top ${muscleAnalytics!.muscleGroups.length > 3 ? 3 : muscleAnalytics!.muscleGroups.length} Muscle Groups',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              ...muscleAnalytics!.muscleGroups.take(3).map((muscle) => 
                _buildMuscleGroupPreview(muscle)
              ).toList(),
              if (muscleAnalytics!.muscleGroups.length > 3) ...[
                SizedBox(height: 12),
                Text(
                  '+${muscleAnalytics!.muscleGroups.length - 3} more muscle groups',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No workout data available for this week',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupPreview(MuscleGroupStats muscle) {
    final color = Color(MuscleAnalyticsService.getMuscleGroupColor(muscle.muscleGroup));
    final icon = MuscleAnalyticsService.getMuscleGroupIcon(muscle.muscleGroup);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                icon,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle.muscleGroup,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${muscle.exerciseCount} exercises • ${muscle.workoutSessions} sessions',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${muscle.totalReps}',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'reps',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeasurementsPage(
              currentMeasurements: latestMeasurements,
              progressData: progressData,
            ),
          ),
        );
        
        // If measurements were updated, refresh the data
        if (result == true) {
          await _loadDashboardData();
        }
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
