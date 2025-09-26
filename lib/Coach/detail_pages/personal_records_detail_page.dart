import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/member_model.dart';

class PersonalRecordsDetailPage extends StatefulWidget {
  final MemberModel member;
  final Map<String, dynamic> personalRecordsData;

  const PersonalRecordsDetailPage({
    Key? key,
    required this.member,
    required this.personalRecordsData,
  }) : super(key: key);

  @override
  State<PersonalRecordsDetailPage> createState() => _PersonalRecordsDetailPageState();
}

class _PersonalRecordsDetailPageState extends State<PersonalRecordsDetailPage>
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
                        _buildPersonalRecordsList(),
                        SizedBox(height: 24),
                        _buildAchievementStats(),
                        SizedBox(height: 24),
                        _buildRecentAchievements(),
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
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Icon(Icons.arrow_back, color: Color(0xFF10B981), size: 20),
            ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.member.fullName,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF10B981),
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
              color: Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final records = List<Map<String, dynamic>>.from(
      widget.personalRecordsData['records'] ?? []
    );
    final totalRecords = records.length;
    final recentRecords = records.where((record) {
      final date = record['achieved_date'];
      if (date == null) return false;
      try {
        final recordDate = DateTime.parse(date);
        final now = DateTime.now();
        return now.difference(recordDate).inDays <= 30;
      } catch (e) {
        return false;
      }
    }).length;

    // Calculate total weight lifted in PRs
    final totalWeight = records.fold<double>(0, (sum, record) {
      final weight = _parseDouble(record['max_weight']) ?? 0.0;
      final reps = _parseInt(record['max_reps']) ?? 0;
      return sum + (weight * reps);
    });

    // Find the heaviest single lift
    final heaviestLift = records.fold<double>(0, (max, record) {
      final weight = _parseDouble(record['max_weight']) ?? 0.0;
      return weight > max ? weight : max;
    });

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Total PRs',
                totalRecords.toString(),
                Icons.emoji_events,
                Color(0xFF10B981),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Recent PRs',
                recentRecords.toString(),
                Icons.trending_up,
                Color(0xFF4ECDC4),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Heaviest Lift',
                '${heaviestLift.toStringAsFixed(1)} kg',
                Icons.fitness_center,
                Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Total Volume',
                '${totalWeight.toStringAsFixed(0)} kg',
                Icons.scale,
                Color(0xFFFFD93D),
              ),
            ),
          ],
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

  Widget _buildPersonalRecordsList() {
    final records = List<Map<String, dynamic>>.from(
      widget.personalRecordsData['records'] ?? []
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
                  color: Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt, color: Color(0xFF10B981), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'All Personal Records',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (records.isNotEmpty) ...[
            ...records.map((record) => _buildRecordItem(record)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 8),
                    Text(
                      'No personal records yet',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                    Text(
                      'Start logging workouts to track PRs!',
                      style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
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

  Widget _buildRecordItem(Map<String, dynamic> record) {
    final exerciseName = record['exercise_name'] ?? 'Unknown Exercise';
    final weight = _parseDouble(record['max_weight']) ?? 0.0;
    final reps = _parseInt(record['max_reps']) ?? 0;
    final date = record['achieved_date'] ?? '';
    final recordType = record['record_type'] ?? 'PR';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981).withOpacity(0.1),
            Color(0xFF4ECDC4).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF4ECDC4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 20),
                Text(
                  recordType,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                    fontSize: 16,
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
                  color: Color(0xFF10B981),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (reps > 0)
                Text(
                  '× $reps reps',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStats() {
    final records = List<Map<String, dynamic>>.from(
      widget.personalRecordsData['records'] ?? []
    );

    // Group records by exercise
    Map<String, List<Map<String, dynamic>>> exerciseGroups = {};
    for (var record in records) {
      final exerciseName = record['exercise_name'] ?? 'Unknown';
      if (!exerciseGroups.containsKey(exerciseName)) {
        exerciseGroups[exerciseName] = [];
      }
      exerciseGroups[exerciseName]!.add(record);
    }

    // Find most improved exercise
    String mostImprovedExercise = 'None';
    double biggestImprovement = 0.0;
    
    for (var entry in exerciseGroups.entries) {
      final exerciseRecords = entry.value;
      if (exerciseRecords.length > 1) {
        // Sort by date to find first and latest
        exerciseRecords.sort((a, b) {
          final dateA = DateTime.tryParse(a['achieved_date'] ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['achieved_date'] ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
        
        final firstWeight = _parseDouble(exerciseRecords.first['max_weight']) ?? 0.0;
        final latestWeight = _parseDouble(exerciseRecords.last['max_weight']) ?? 0.0;
        final improvement = latestWeight - firstWeight;
        
        if (improvement > biggestImprovement) {
          biggestImprovement = improvement;
          mostImprovedExercise = entry.key;
        }
      }
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
                child: Icon(Icons.analytics, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Achievement Statistics',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatItem(
            'Most PRs',
            exerciseGroups.isNotEmpty 
                ? exerciseGroups.entries.reduce((a, b) => a.value.length > b.value.length ? a : b).key
                : 'None',
            Icons.trending_up,
            Color(0xFF10B981),
          ),
          SizedBox(height: 12),
          _buildStatItem(
            'Most Improved',
            mostImprovedExercise,
            Icons.trending_up,
            Color(0xFF4ECDC4),
          ),
          SizedBox(height: 12),
          _buildStatItem(
            'Improvement',
            biggestImprovement > 0 
                ? '+${biggestImprovement.toStringAsFixed(1)} kg'
                : 'No improvement',
            Icons.add_circle,
            Color(0xFFFF6B35),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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

  Widget _buildRecentAchievements() {
    final records = List<Map<String, dynamic>>.from(
      widget.personalRecordsData['records'] ?? []
    );

    // Sort by date and get recent ones
    records.sort((a, b) {
      final dateA = DateTime.tryParse(a['achieved_date'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['achieved_date'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    final recentRecords = records.take(3).toList();

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
                  color: Color(0xFFFFD93D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.star, color: Color(0xFFFFD93D), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Recent Achievements',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (recentRecords.isNotEmpty) ...[
            ...recentRecords.map((record) => _buildRecentAchievementItem(record)).toList(),
          ] else ...[
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No recent achievements',
                  style: GoogleFonts.poppins(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentAchievementItem(Map<String, dynamic> record) {
    final exerciseName = record['exercise_name'] ?? 'Unknown Exercise';
    final weight = _parseDouble(record['max_weight']) ?? 0.0;
    final reps = _parseInt(record['max_reps']) ?? 0;
    final date = record['achieved_date'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFFD93D).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFFD93D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emoji_events, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
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
          Text(
            '${weight.toStringAsFixed(1)} kg',
            style: GoogleFonts.poppins(
              color: Color(0xFFFFD93D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      if (difference < 30) return '${(difference / 7).floor()} weeks ago';
      
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
