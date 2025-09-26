import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_model.dart';

class ProgressOverTimeDetailPage extends StatefulWidget {
  final MemberModel member;
  final Map<String, dynamic> progressData;

  const ProgressOverTimeDetailPage({
    Key? key,
    required this.member,
    required this.progressData,
  }) : super(key: key);

  @override
  State<ProgressOverTimeDetailPage> createState() => _ProgressOverTimeDetailPageState();
}

class _ProgressOverTimeDetailPageState extends State<ProgressOverTimeDetailPage>
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
                        _buildProgressCharts(),
                        SizedBox(height: 24),
                        _buildComplianceMetrics(),
                        SizedBox(height: 24),
                        _buildProgressiveOverload(),
                        SizedBox(height: 24),
                        _buildProgressInsights(),
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
                border: Border.all(color: Color(0xFF06B6D4).withOpacity(0.3)),
              ),
              child: Icon(Icons.arrow_back, color: Color(0xFF06B6D4), size: 20),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Analytics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.member.fullName,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF06B6D4),
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
              color: Color(0xFF06B6D4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.trending_up, color: Color(0xFF06B6D4), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final weightProgress = List<Map<String, dynamic>>.from(widget.progressData['weight_progress'] ?? []);
    final strengthProgress = List<Map<String, dynamic>>.from(widget.progressData['strength_progress'] ?? []);
    final attendanceProgress = List<Map<String, dynamic>>.from(widget.progressData['attendance_progress'] ?? []);
    final volumeProgress = List<Map<String, dynamic>>.from(widget.progressData['volume_progress'] ?? []);

    // Calculate trends
    final weightTrend = _calculateTrend(weightProgress);
    final strengthTrend = _calculateTrend(strengthProgress);
    final attendanceTrend = _calculateTrend(attendanceProgress);
    final volumeTrend = _calculateTrend(volumeProgress);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Weight Progress',
                weightTrend,
                Icons.monitor_weight,
                Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Strength Progress',
                strengthTrend,
                Icons.fitness_center,
                Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Attendance Trend',
                attendanceTrend,
                Icons.calendar_today,
                Color(0xFF96CEB4),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Volume Progress',
                volumeTrend,
                Icons.scale,
                Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String trend, IconData icon, Color color) {
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
            trend,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
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

  Widget _buildProgressCharts() {
    final weightProgress = List<Map<String, dynamic>>.from(widget.progressData['weight_progress'] ?? []);
    final strengthProgress = List<Map<String, dynamic>>.from(widget.progressData['strength_progress'] ?? []);
    final attendanceProgress = List<Map<String, dynamic>>.from(widget.progressData['attendance_progress'] ?? []);

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
                  color: Color(0xFF06B6D4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.show_chart, color: Color(0xFF06B6D4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Progress Charts',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (weightProgress.isNotEmpty) ...[
            _buildProgressChart('Weight Progress', weightProgress, Color(0xFF4ECDC4), 'kg'),
            SizedBox(height: 16),
          ],
          if (strengthProgress.isNotEmpty) ...[
            _buildProgressChart('Strength Progress', strengthProgress, Color(0xFFFF6B35), 'kg'),
            SizedBox(height: 16),
          ],
          if (attendanceProgress.isNotEmpty) ...[
            _buildProgressChart('Attendance Trend', attendanceProgress, Color(0xFF96CEB4), 'visits'),
          ],
          if (weightProgress.isEmpty && strengthProgress.isEmpty && attendanceProgress.isEmpty) ...[
            Container(
              height: 120,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No progress data available yet',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                    Text(
                      'Progress tracking will appear as member logs more data',
                      style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
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

  Widget _buildProgressChart(String title, List<Map<String, dynamic>> data, Color color, String unit) {
    if (data.isEmpty) return SizedBox.shrink();

    // Get the last 7 data points for the chart
    final chartData = data.length > 7 ? data.sublist(data.length - 7) : data;
    final maxValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((point) {
                final value = _parseDouble(point['value']) ?? 0.0;
                final date = point['date'] ?? '';
                // For single data points, use a reasonable height. For multiple points, use proportional height
                final height = valueRange > 0 
                    ? ((value - minValue) / valueRange * 60) + 10
                    : (value > 0 ? 50.0 : 10.0); // Show 50px height for non-zero values, 10px for zero
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatChartDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(0)}$unit',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceMetrics() {
    final complianceProgress = List<Map<String, dynamic>>.from(widget.progressData['compliance_progress'] ?? []);

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
                child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Compliance Metrics',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (complianceProgress.isNotEmpty) ...[
            ...complianceProgress.map((data) => _buildComplianceItem(data)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No compliance data available',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComplianceItem(Map<String, dynamic> data) {
    final date = data['date'] ?? '';
    final setsCompliance = _parseDouble(data['sets_compliance']) ?? 0.0;
    final repsCompliance = _parseDouble(data['reps_compliance']) ?? 0.0;
    final volumeCompliance = _parseDouble(data['volume_compliance']) ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatChartDate(date),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildComplianceBar('Sets', setsCompliance, Color(0xFF4ECDC4)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildComplianceBar('Reps', repsCompliance, Color(0xFF96CEB4)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildComplianceBar('Volume', volumeCompliance, Color(0xFFFF6B35)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceBar(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
        SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressiveOverload() {
    final progressiveOverload = List<Map<String, dynamic>>.from(widget.progressData['progressive_overload'] ?? []);

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
                child: Icon(Icons.trending_up, color: Color(0xFFFF6B35), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Progressive Overload',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (progressiveOverload.isNotEmpty) ...[
            ...progressiveOverload.map((data) => _buildOverloadItem(data)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No progressive overload data available',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverloadItem(Map<String, dynamic> data) {
    final date = data['date'] ?? '';
    final avgWeight = _parseDouble(data['avg_weight']) ?? 0.0;
    final totalVolume = _parseDouble(data['total_volume']) ?? 0.0;
    final workoutDays = _parseInt(data['workout_days']) ?? 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatChartDate(date),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverloadStat('Avg Weight', '${avgWeight.toStringAsFixed(1)} kg', Color(0xFFFF6B35)),
              ),
              Expanded(
                child: _buildOverloadStat('Total Volume', '${totalVolume.toStringAsFixed(0)} kg', Color(0xFF4ECDC4)),
              ),
              Expanded(
                child: _buildOverloadStat('Workout Days', workoutDays.toString(), Color(0xFF96CEB4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadStat(String label, String value, Color color) {
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

  Widget _buildProgressInsights() {
    final weightProgress = List<Map<String, dynamic>>.from(widget.progressData['weight_progress'] ?? []);
    final strengthProgress = List<Map<String, dynamic>>.from(widget.progressData['strength_progress'] ?? []);
    final attendanceProgress = List<Map<String, dynamic>>.from(widget.progressData['attendance_progress'] ?? []);

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
                child: Icon(Icons.lightbulb, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Progress Insights',
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
            'Data Points',
            '${weightProgress.length + strengthProgress.length + attendanceProgress.length}',
            Icons.analytics,
            Color(0xFF4ECDC4),
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Tracking Period',
            _calculateTrackingPeriod(weightProgress, strengthProgress, attendanceProgress),
            Icons.calendar_today,
            Color(0xFF96CEB4),
          ),
          SizedBox(height: 12),
          _buildInsightItem(
            'Progress Status',
            _getProgressStatus(weightProgress, strengthProgress, attendanceProgress),
            Icons.trending_up,
            Color(0xFF10B981),
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

  String _calculateTrend(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 'Insufficient Data';
    
    final firstValue = _parseDouble(data.first['value']) ?? 0.0;
    final lastValue = _parseDouble(data.last['value']) ?? 0.0;
    final change = lastValue - firstValue;
    final percentage = firstValue > 0 ? (change / firstValue * 100) : 0;
    
    if (percentage > 5) return '↗️ Improving';
    if (percentage < -5) return '↘️ Declining';
    return '➡️ Stable';
  }

  String _calculateTrackingPeriod(List<Map<String, dynamic>> weight, List<Map<String, dynamic>> strength, List<Map<String, dynamic>> attendance) {
    final allData = [...weight, ...strength, ...attendance];
    if (allData.isEmpty) return 'No data';
    
    final dates = allData.map((d) => DateTime.tryParse(d['date'] ?? '')).where((d) => d != null).cast<DateTime>().toList();
    if (dates.isEmpty) return 'No data';
    
    dates.sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    final days = lastDate.difference(firstDate).inDays;
    
    if (days < 7) return '${days} days';
    if (days < 30) return '${(days / 7).floor()} weeks';
    return '${(days / 30).floor()} months';
  }

  String _getProgressStatus(List<Map<String, dynamic>> weight, List<Map<String, dynamic>> strength, List<Map<String, dynamic>> attendance) {
    final totalDataPoints = weight.length + strength.length + attendance.length;
    
    if (totalDataPoints == 0) return 'No Progress Data';
    if (totalDataPoints < 3) return 'Early Stage';
    if (totalDataPoints < 10) return 'Building Momentum';
    return 'Strong Progress';
  }

  String _formatChartDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}';
    } catch (e) {
      return dateString;
    }
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
