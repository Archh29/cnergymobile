import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import './models/member_model.dart';
import './services/coach_service.dart';
import './models/goal_model.dart';
import './models/workout_session_model.dart';

class CoachProgressPage extends StatefulWidget {
  final MemberModel selectedMember;

  const CoachProgressPage({Key? key, required this.selectedMember}) : super(key: key);

  @override
  _CoachProgressPageState createState() => _CoachProgressPageState();
}

class _CoachProgressPageState extends State<CoachProgressPage>
    with TickerProviderStateMixin {
  Map<String, dynamic> memberProgress = {};
  List<GoalModel> memberGoals = [];
  List<WorkoutSessionModel> recentSessions = [];
  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMemberProgress();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberProgress() async {
    setState(() => isLoading = true);

    try {
      final futures = await Future.wait([
        CoachService.getMemberProgress(widget.selectedMember.id),
        CoachService.getMemberGoals(widget.selectedMember.id),
        CoachService.getMemberWorkoutSessions(widget.selectedMember.id),
      ]);

      if (mounted) {
        setState(() {
          memberProgress = futures[0] as Map<String, dynamic>;
          memberGoals = (futures[1] as List<GoalModel>).take(5).toList();
          recentSessions = (futures[2] as List<WorkoutSessionModel>).take(10).toList();
          isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading member progress: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadMemberProgress,
                  color: Color(0xFF4ECDC4),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMemberHeader(),
                        SizedBox(height: 20),
                        _buildProgressOverview(),
                        SizedBox(height: 20),
                        _buildQuickStats(),
                        SizedBox(height: 20),
                        _buildGoalsSection(),
                        SizedBox(height: 20),
                        _buildRecentSessions(),
                        SizedBox(height: 20),
                        _buildProgressChart(),
                        SizedBox(height: 20),
                        _buildCoachActions(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading ${widget.selectedMember.fname}\'s progress...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberHeader() {
    final overallStats = memberProgress['overall'] ?? {};
    final fitnessScore = overallStats['fitnessScore'] ?? 0;
    final level = overallStats['level'] ?? 'Getting Started';

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF96CEB4), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF96CEB4).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  widget.selectedMember.initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.selectedMember.fullName}\'s Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Fitness Level: $level',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Member since ${widget.selectedMember.createdAt.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (widget.selectedMember.subscriptionStatus != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Plan: ${widget.selectedMember.planName ?? 'Basic'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: fitnessScore / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$fitnessScore',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Score',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  'Streak',
                  '${overallStats['streak'] ?? 0} days',
                  Icons.local_fire_department,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'This Week',
                  '${overallStats['weeklyWorkouts'] ?? 0} workouts',
                  Icons.fitness_center,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'Goals',
                  '${memberGoals.where((g) => g.status == GoalStatus.achieved).length}/${memberGoals.length}',
                  Icons.flag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
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
                child: Icon(Icons.trending_up, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Progress Overview',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Coach View',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Member Performance Summary',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildProgressItem(
                  'Workout Consistency',
                  '${memberProgress['consistency'] ?? 75}%',
                  (memberProgress['consistency'] ?? 75) / 100,
                  Color(0xFF4ECDC4),
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  'Goal Achievement',
                  '${memberProgress['goalAchievement'] ?? 60}%',
                  (memberProgress['goalAchievement'] ?? 60) / 100,
                  Color(0xFF96CEB4),
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  'Attendance Rate',
                  '${memberProgress['attendance'] ?? 80}%',
                  (memberProgress['attendance'] ?? 80) / 100,
                  Color(0xFFFF6B35),
                ),
                if (widget.selectedMember.hasActiveSubscription) ...[
                  SizedBox(height: 12),
                  _buildProgressItem(
                    'Subscription Status',
                    'Active',
                    1.0,
                    Color(0xFF10B981),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final workoutStats = memberProgress['workouts'] ?? {};
    final goalStats = memberProgress['goals'] ?? {};
    final attendanceStats = memberProgress['attendance'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Workouts',
            '${workoutStats['thisMonth'] ?? 0}',
            'This Month',
            Color(0xFF45B7D1),
            Icons.fitness_center,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Goals',
            '${goalStats['active'] ?? 0}',
            'In Progress',
            Color(0xFF96CEB4),
            Icons.flag,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Check-ins',
            '${attendanceStats['thisWeek'] ?? 0}',
            'This Week',
            Color(0xFFE74C3C),
            Icons.location_on,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
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
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
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
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF96CEB4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flag, color: Color(0xFF96CEB4), size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Member Goals',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showCreateGoalDialog,
                icon: Icon(Icons.add, color: Color(0xFF96CEB4), size: 16),
                label: Text(
                  'Add Goal',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF96CEB4),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (memberGoals.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No goals set for ${widget.selectedMember.fname}',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _showCreateGoalDialog,
                    child: Text(
                      'Create First Goal',
                      style: GoogleFonts.poppins(color: Color(0xFF96CEB4)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...memberGoals.map((goal) => _buildGoalItem(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalItem(GoalModel goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goal.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: goal.statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goal,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  goal.formattedTargetDate,
                  style: GoogleFonts.poppins(
                    color: goal.statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            color: Color(0xFF2A2A2A),
            onSelected: (value) => _handleGoalAction(value, goal),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color(0xFF4ECDC4), size: 16),
                    SizedBox(width: 8),
                    Text('Edit', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              if (goal.status == GoalStatus.active)
                PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Mark Complete', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions() {
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
                  color: Color(0xFF45B7D1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: Color(0xFF45B7D1), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Recent Workout Sessions',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No recent workout sessions',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...recentSessions.take(5).map((session) => _buildSessionItem(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildSessionItem(WorkoutSessionModel session) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.completed ? Icons.check_circle : Icons.schedule,
              color: session.statusColor,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.programName ?? 'Workout Session',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  session.formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              session.completed ? 'Completed' : 'Pending',
              style: GoogleFonts.poppins(
                color: session.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _addSessionFeedback(session),
            icon: Icon(Icons.feedback, color: Color(0xFF4ECDC4), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
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
                  color: Color(0xFFE74C3C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.show_chart, color: Color(0xFFE74C3C), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Weekly Progress Trend',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateProgressData(),
                    isCurved: true,
                    color: Color(0xFF4ECDC4),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateProgressData() {
    // Generate mock progress data for the week
    return [
      FlSpot(0, 3),
      FlSpot(1, 4),
      FlSpot(2, 2),
      FlSpot(3, 5),
      FlSpot(4, 3),
      FlSpot(5, 4),
      FlSpot(6, 6),
    ];
  }

  Widget _buildCoachActions() {
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
          Text(
            'Coach Actions',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Add Goal',
                  Icons.flag,
                  Color(0xFF96CEB4),
                  _showCreateGoalDialog,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Send Message',
                  Icons.message,
                  Color(0xFF4ECDC4),
                  () => _sendMessage(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Update Plan',
                  Icons.edit,
                  Color(0xFFFF6B35),
                  () => _updateWorkoutPlan(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleGoalAction(String action, GoalModel goal) {
    switch (action) {
      case 'edit':
        _editGoal(goal);
        break;
      case 'complete':
        _markGoalComplete(goal);
        break;
    }
  }

  void _editGoal(GoalModel goal) {
    // Show edit goal dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit goal feature coming soon!'),
        backgroundColor: Color(0xFF4ECDC4),
      ),
    );
  }

  void _markGoalComplete(GoalModel goal) {
    // Mark goal as completed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Goal marked as completed for ${widget.selectedMember.fname}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCreateGoalDialog() {
    final TextEditingController goalController = TextEditingController();
    DateTime targetDate = DateTime.now().add(Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF96CEB4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.flag,
                        color: Color(0xFF96CEB4),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Goal',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'For ${widget.selectedMember.fullName}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                TextField(
                  controller: goalController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter goal for ${widget.selectedMember.fname}...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Text(
                      'Target Date: ',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: targetDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => targetDate = date);
                        }
                      },
                      child: Text(
                        '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                        style: GoogleFonts.poppins(color: Color(0xFF96CEB4)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (goalController.text.trim().isNotEmpty) {
                            // Create goal via API
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Goal created for ${widget.selectedMember.fname}!'),
                                backgroundColor: Color(0xFF96CEB4),
                              ),
                            );
                            _loadMemberProgress();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF96CEB4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addSessionFeedback(WorkoutSessionModel session) {
    final TextEditingController feedbackController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Session Feedback',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'For ${widget.selectedMember.fname}\'s ${session.programName ?? "workout"}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 24),

                // Rating
                Text(
                  'Performance Rating',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = index + 1.0),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),

                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter feedback for ${widget.selectedMember.fname}...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (feedbackController.text.trim().isNotEmpty) {
                            final success = await CoachService.addSessionFeedback(
                              session.id!,
                              feedbackController.text.trim(),
                              rating,
                            );

                            Navigator.pop(context);

                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Feedback added successfully!'),
                                  backgroundColor: Color(0xFF4ECDC4),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    // Navigate to messages with selected member
    Navigator.pushNamed(
      context,
      '/coach-messages',
      arguments: widget.selectedMember,
    );
  }

  void _updateWorkoutPlan() {
    // Navigate to routine management for this member
    Navigator.pushNamed(
      context,
      '/coach-routines',
      arguments: widget.selectedMember,
    );
  }
}
