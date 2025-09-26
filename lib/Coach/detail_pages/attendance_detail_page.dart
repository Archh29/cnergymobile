import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_model.dart';

class AttendanceDetailPage extends StatefulWidget {
  final MemberModel member;
  final Map<String, dynamic> attendanceData;

  const AttendanceDetailPage({
    Key? key,
    required this.member,
    required this.attendanceData,
  }) : super(key: key);

  @override
  State<AttendanceDetailPage> createState() => _AttendanceDetailPageState();
}

class _AttendanceDetailPageState extends State<AttendanceDetailPage>
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
                        _buildAttendanceChart(),
                        SizedBox(height: 24),
                        _buildWeeklyBreakdown(),
                        SizedBox(height: 24),
                        _buildAttendanceInsights(),
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
                border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
              ),
              child: Icon(Icons.arrow_back, color: Color(0xFF4ECDC4), size: 20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Analytics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.member.fullName,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
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
              color: Color(0xFF4ECDC4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.calendar_today, color: Color(0xFF4ECDC4), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalCheckins = _parseInt(widget.attendanceData['total_checkins']) ?? 0;
    final thisWeekCheckins = _parseInt(widget.attendanceData['this_week_checkins']) ?? 0;
    final thisMonthCheckins = _parseInt(widget.attendanceData['this_month_checkins']) ?? 0;
    final currentStreak = _parseInt(widget.attendanceData['current_streak']) ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Total Check-ins',
            totalCheckins.toString(),
            Icons.login,
            Color(0xFF4ECDC4),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'This Week',
            thisWeekCheckins.toString(),
            Icons.calendar_view_week,
            Color(0xFF96CEB4),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'This Month',
            thisMonthCheckins.toString(),
            Icons.calendar_month,
            Color(0xFFFF6B35),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Current Streak',
            currentStreak.toString(),
            Icons.local_fire_department,
            Color(0xFFFFD93D),
          ),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildAttendanceChart() {
    final weeklyData = List<Map<String, dynamic>>.from(
      widget.attendanceData['weekly_data'] ?? []
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
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Weekly Attendance Trend',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (weeklyData.isNotEmpty) ...[
            Container(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeklyData.map((day) {
                  final dayName = day['day'] ?? '';
                  final checkIns = _parseInt(day['checkins']) ?? 0;
                  final maxCheckIns = weeklyData.map((d) => _parseInt(d['checkins']) ?? 0).reduce((a, b) => a > b ? a : b);
                  final height = maxCheckIns > 0 ? (checkIns / maxCheckIns) * 80.0 : 0.0;
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF4ECDC4),
                              Color(0xFF96CEB4),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        dayName,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        checkIns.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            Container(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No attendance data available',
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

  Widget _buildWeeklyBreakdown() {
    final weeklyData = List<Map<String, dynamic>>.from(
      widget.attendanceData['weekly_data'] ?? []
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
                  color: Color(0xFF96CEB4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt, color: Color(0xFF96CEB4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Weekly Breakdown',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (weeklyData.isNotEmpty) ...[
            ...weeklyData.map((day) => _buildDayItem(day)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No weekly data available',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day) {
    final dayName = day['day'] ?? '';
    final checkIns = _parseInt(day['checkins']) ?? 0;
    final isToday = dayName.toLowerCase() == _getTodayName().toLowerCase();

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Color(0xFF4ECDC4).withOpacity(0.1) : Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? Color(0xFF4ECDC4).withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? Color(0xFF4ECDC4) : Color(0xFF96CEB4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                dayName.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isToday ? 'Today' : 'This week',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: checkIns > 0 ? Color(0xFF10B981).withOpacity(0.2) : Color(0xFF6B7280).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${checkIns} check-ins',
              style: GoogleFonts.poppins(
                color: checkIns > 0 ? Color(0xFF10B981) : Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceInsights() {
    final totalCheckins = _parseInt(widget.attendanceData['total_checkins']) ?? 0;
    final thisWeekCheckins = _parseInt(widget.attendanceData['this_week_checkins']) ?? 0;
    final currentStreak = _parseInt(widget.attendanceData['current_streak']) ?? 0;

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
                child: Icon(Icons.insights, color: Color(0xFFFF6B35), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Attendance Insights',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInsightItem(
            'Consistency Score',
            _calculateConsistencyScore(thisWeekCheckins, currentStreak),
            Icons.trending_up,
            Color(0xFF10B981),
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Total Sessions',
            totalCheckins.toString(),
            Icons.fitness_center,
            Color(0xFF4ECDC4),
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Best Streak',
            currentStreak.toString(),
            Icons.local_fire_department,
            Color(0xFFFFD93D),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
    );
  }

  String _calculateConsistencyScore(int weeklyCheckins, int streak) {
    if (weeklyCheckins >= 5) return 'Excellent';
    if (weeklyCheckins >= 3) return 'Good';
    if (weeklyCheckins >= 1) return 'Fair';
    return 'Needs Improvement';
  }

  String _getTodayName() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[now.weekday - 1];
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
}
