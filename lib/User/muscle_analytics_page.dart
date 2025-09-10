import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/muscle_analytics_model.dart';
import './services/muscle_analytics_service.dart';

class MuscleAnalyticsPage extends StatefulWidget {
  final MuscleAnalyticsData initialData;

  const MuscleAnalyticsPage({
    Key? key,
    required this.initialData,
  }) : super(key: key);

  @override
  _MuscleAnalyticsPageState createState() => _MuscleAnalyticsPageState();
}

class _MuscleAnalyticsPageState extends State<MuscleAnalyticsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  MuscleAnalyticsData? weeklyData;
  MuscleAnalyticsData? monthlyData;
  bool isLoading = false;
  String selectedPeriod = 'week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    weeklyData = widget.initialData;
    _loadMonthlyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyData() async {
    setState(() => isLoading = true);
    try {
      monthlyData = await MuscleAnalyticsService.getMonthlyStats();
    } catch (e) {
      print('Error loading monthly data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

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
          'Muscle Group Analytics',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFFFF6B35),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[400],
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAnalyticsContent(weeklyData, 'week'),
          _buildAnalyticsContent(monthlyData, 'month'),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(MuscleAnalyticsData? data, String period) {
    if (data == null && isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
        ),
      );
    }

    if (data == null || data.muscleGroups.isEmpty) {
      return _buildEmptyState(period);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSummary(data),
          SizedBox(height: 24),
          _buildMuscleGroupsList(data, period),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String period) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          SizedBox(height: 20),
          Text(
            'No Data Available',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'No workout data found for this $period',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSummary(MuscleAnalyticsData data) {
    final totalExercises = data.muscleGroups.fold(0, (sum, muscle) => sum + muscle.exerciseCount);
    final totalReps = data.muscleGroups.fold(0, (sum, muscle) => sum + muscle.totalReps);
    final avgIntensity = data.muscleGroups.isNotEmpty
        ? data.muscleGroups.fold(0.0, (sum, muscle) => sum + muscle.intensityScore) / data.muscleGroups.length
        : 0.0;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE55A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.periodType == 'week' ? 'Weekly' : 'Monthly'} Summary',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Workouts',
                  '${data.totalWorkouts}',
                  Icons.fitness_center,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Exercises',
                  '$totalExercises',
                  Icons.sports_gymnastics,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Reps',
                  '$totalReps',
                  Icons.repeat,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Intensity',
                  '${avgIntensity.toStringAsFixed(1)}',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
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
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupsList(MuscleAnalyticsData data, String period) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muscle Groups (${data.muscleGroups.length})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...data.muscleGroups.map((muscle) => 
          _buildMuscleGroupCard(muscle, period)
        ).toList(),
      ],
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroupStats muscle, String period) {
    final color = Color(MuscleAnalyticsService.getMuscleGroupColor(muscle.muscleGroup));
    final icon = MuscleAnalyticsService.getMuscleGroupIcon(muscle.muscleGroup);
    
    return GestureDetector(
      onTap: () => _showDetailedAnalytics(muscle, period),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: TextStyle(fontSize: 24),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Last worked: ${_formatDate(muscle.lastWorked)}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Exercises',
                    '${muscle.exerciseCount}',
                    Icons.sports_gymnastics,
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    '${muscle.workoutSessions}',
                    Icons.fitness_center,
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Reps',
                    '${muscle.totalReps}',
                    Icons.repeat,
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Weight',
                    '${muscle.avgWeight.toStringAsFixed(1)}kg',
                    Icons.monitor_weight,
                    color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Intensity: ${muscle.intensityScore.toStringAsFixed(1)}',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 10,
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
      if (difference < 30) return '${(difference / 7).floor()} weeks ago';
      return '${(difference / 30).floor()} months ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showDetailedAnalytics(MuscleGroupStats muscle, String period) async {
    try {
      // First try to get sub-muscles
      final subMusclesData = await MuscleAnalyticsService.getSubMuscles(muscle.muscleGroupId, period);
      
      if (subMusclesData.subMuscles.isNotEmpty) {
        // Show sub-muscles modal
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildSubMusclesModal(subMusclesData),
        );
      } else {
        // If no sub-muscles, show detailed exercise analytics
        final detailedData = await MuscleAnalyticsService.getDetailedAnalytics(muscle.muscleGroup, period);
        
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildDetailedModal(detailedData),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading detailed analytics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSubMusclesModal(SubMusclesData data) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '${data.parentMuscle} - Sub Muscles',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data.period == 'week' ? 'This Week' : 'This Month'}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.subMuscles.isEmpty
                ? Center(
                    child: Text(
                      'No sub-muscle data available',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.subMuscles.length,
                    itemBuilder: (context, index) {
                      final subMuscle = data.subMuscles[index];
                      return _buildSubMuscleCard(subMuscle);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMuscleCard(SubMuscleStats subMuscle) {
    final color = Color(MuscleAnalyticsService.getMuscleGroupColor(subMuscle.muscleName));
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subMuscle.muscleName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${subMuscle.totalReps}',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildSubMuscleStat('${subMuscle.exerciseCount} exercises', Icons.sports_gymnastics),
              SizedBox(width: 16),
              _buildSubMuscleStat('${subMuscle.workoutSessions} sessions', Icons.fitness_center),
              SizedBox(width: 16),
              _buildSubMuscleStat('${subMuscle.avgWeight.toStringAsFixed(1)}kg avg', Icons.monitor_weight),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Last worked: ${_formatDate(subMuscle.lastWorked)}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Intensity: ${subMuscle.intensityScore.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubMuscleStat(String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedModal(DetailedMuscleAnalytics data) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '${data.muscleGroup} - Detailed Analytics',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${data.period == 'week' ? 'This Week' : 'This Month'}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: data.exercises.isEmpty
                ? Center(
                    child: Text(
                      'No exercise data available',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: data.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = data.exercises[index];
                      return _buildExerciseDetailCard(exercise);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailCard(ExerciseDetail exercise) {
    final color = Color(MuscleAnalyticsService.getMuscleGroupColor(exercise.exerciseName));
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${exercise.totalVolume.toStringAsFixed(0)}kg',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildExerciseStat('${exercise.sets} sets', Icons.repeat),
              SizedBox(width: 16),
              _buildExerciseStat('${exercise.reps} reps', Icons.sports_gymnastics),
              SizedBox(width: 16),
              _buildExerciseStat('${exercise.weight}kg', Icons.monitor_weight),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _formatDate(exercise.workoutDate),
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseStat(String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
