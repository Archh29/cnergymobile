import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_model.dart';

class WorkoutLogsDetailPage extends StatefulWidget {
  final MemberModel member;
  final Map<String, dynamic> workoutData;

  const WorkoutLogsDetailPage({
    Key? key,
    required this.member,
    required this.workoutData,
  }) : super(key: key);

  @override
  State<WorkoutLogsDetailPage> createState() => _WorkoutLogsDetailPageState();
}

class _WorkoutLogsDetailPageState extends State<WorkoutLogsDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(),
                        SizedBox(height: 24),
                        _buildRecentWorkouts(),
                        SizedBox(height: 24),
                        _buildPerformanceMetrics(),
                        SizedBox(height: 24),
                        _buildExerciseBreakdown(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3)),
              ),
              child: Icon(Icons.arrow_back, color: Color(0xFFFF6B35), size: 20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Analytics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.member.fullName,
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFF6B35).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.fitness_center, color: Color(0xFFFF6B35), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalWorkouts = _parseInt(widget.workoutData['total_workouts']) ?? 0;
    final thisWeekWorkouts = _parseInt(widget.workoutData['this_week_workouts']) ?? 0;
    final totalSets = _parseInt(widget.workoutData['total_sets']) ?? 0;
    final totalReps = _parseInt(widget.workoutData['total_reps']) ?? 0;
    final totalWeight = _parseDouble(widget.workoutData['total_weight']) ?? 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Workouts',
                totalWorkouts.toString(),
                Icons.fitness_center,
                Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'This Week',
                thisWeekWorkouts.toString(),
                Icons.calendar_view_week,
                Color(0xFF96CEB4),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total Sets',
                totalSets.toString(),
                Icons.repeat,
                Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Total Reps',
                totalReps.toString(),
                Icons.timeline,
                Color(0xFF10B981),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        _buildOverviewCard(
          'Total Weight Lifted',
          '${totalWeight.toStringAsFixed(1)} kg',
          Icons.scale,
          Color(0xFFFFD93D),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkouts() {
    final recentWorkouts = List<Map<String, dynamic>>.from(
      widget.workoutData['recent_workouts'] ?? []
    );

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: Color(0xFFFF6B35), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Recent Workouts',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (recentWorkouts.isNotEmpty) ...[
            ...recentWorkouts.map((workout) => _buildWorkoutItem(workout)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No recent workouts',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(Map<String, dynamic> workout) {
    final date = workout['log_date'] ?? '';
    final sets = _parseInt(workout['actual_sets']) ?? 0;
    final reps = _parseInt(workout['actual_reps']) ?? 0;
    final weight = _parseDouble(workout['total_kg']) ?? 0.0;
    final exerciseName = workout['exercise_name'] ?? 'Unknown Exercise';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF8C42),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(date),
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
                '${weight.toStringAsFixed(1)} kg',
                style: GoogleFonts.poppins(
                  color: Color(0xFFFF6B35),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$sets sets × $reps reps',
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

  Widget _buildPerformanceMetrics() {
    final complianceMetrics = widget.workoutData['compliance_metrics'] ?? {};
    final avgSetsCompliance = _parseDouble(complianceMetrics['avg_sets_compliance']) ?? 0.0;
    final avgRepsCompliance = _parseDouble(complianceMetrics['avg_reps_compliance']) ?? 0.0;
    final avgVolumeCompliance = _parseDouble(complianceMetrics['avg_volume_compliance']) ?? 0.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics, color: Color(0xFF10B981), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Performance Metrics',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMetricItem(
            'Sets Compliance',
            '${avgSetsCompliance.toStringAsFixed(1)}%',
            avgSetsCompliance,
            Color(0xFF4ECDC4),
          ),
          SizedBox(height: 12),
          _buildMetricItem(
            'Reps Compliance',
            '${avgRepsCompliance.toStringAsFixed(1)}%',
            avgRepsCompliance,
            Color(0xFF96CEB4),
          ),
          SizedBox(height: 12),
          _buildMetricItem(
            'Volume Compliance',
            '${avgVolumeCompliance.toStringAsFixed(1)}%',
            avgVolumeCompliance,
            Color(0xFFFF6B35),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseBreakdown() {
    final recentWorkouts = List<Map<String, dynamic>>.from(
      widget.workoutData['recent_workouts'] ?? []
    );

    // Group workouts by exercise
    Map<String, List<Map<String, dynamic>>> exerciseGroups = {};
    for (var workout in recentWorkouts) {
      final exerciseName = workout['exercise_name'] ?? 'Unknown';
      if (!exerciseGroups.containsKey(exerciseName)) {
        exerciseGroups[exerciseName] = [];
      }
      exerciseGroups[exerciseName]!.add(workout);
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Exercise Breakdown',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (exerciseGroups.isNotEmpty) ...[
            ...exerciseGroups.entries.map((entry) => _buildExerciseGroup(entry.key, entry.value)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No exercise data available',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseGroup(String exerciseName, List<Map<String, dynamic>> workouts) {
    final totalSets = workouts.fold<int>(0, (sum, workout) => sum + (_parseInt(workout['actual_sets']) ?? 0));
    final totalReps = workouts.fold<int>(0, (sum, workout) => sum + (_parseInt(workout['actual_reps']) ?? 0));
    final totalWeight = workouts.fold<double>(0, (sum, workout) => sum + (_parseDouble(workout['total_kg']) ?? 0.0));

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseName,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildExerciseStat('Sets', totalSets.toString(), Color(0xFF4ECDC4)),
              ),
              Expanded(
                child: _buildExerciseStat('Reps', totalReps.toString(), Color(0xFF96CEB4)),
              ),
              Expanded(
                child: _buildExerciseStat('Weight', '${totalWeight.toStringAsFixed(1)} kg', Color(0xFFFF6B35)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference < 7) return '$difference days ago';
      
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
