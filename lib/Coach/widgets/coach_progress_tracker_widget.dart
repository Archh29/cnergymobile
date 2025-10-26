import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/progress_tracker_model.dart';
import '../services/progress_analytics_service.dart';

class ProgressTrackerWidget extends StatefulWidget {
  const ProgressTrackerWidget({Key? key}) : super(key: key);

  @override
  _ProgressTrackerWidgetState createState() => _ProgressTrackerWidgetState();
}

class _ProgressTrackerWidgetState extends State<ProgressTrackerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<ProgressTrackerModel>> _allProgress = {};
  Map<String, ProgressAnalytics> _muscleGroupAnalytics = {};
  List<ProgressTrackerModel> _recentLifts = [];
  bool _isLoading = true;
  String _selectedExercise = '';
  String _selectedMuscleGroup = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allProgress = await ProgressAnalyticsService.getAllProgress();
      final muscleGroupAnalytics = await ProgressAnalyticsService.getMuscleGroupAnalytics();
      final recentLifts = await ProgressAnalyticsService.getRecentLifts();

      setState(() {
        _allProgress = allProgress;
        _muscleGroupAnalytics = muscleGroupAnalytics;
        _recentLifts = recentLifts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2D2D2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Track your strength progression and analyze your performance',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF4ECDC4),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Analytics'),
                Tab(text: 'Exercises'),
                Tab(text: 'Recent'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildExercisesTab(),
                _buildRecentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          
          // Progress Charts
          _buildProgressCharts(),
          const SizedBox(height: 20),
          
          // Statistics Cards
          _buildStatisticsCards(),
        ],
      ),
    );
  }


  Widget _buildProgressCharts() {
    if (_allProgress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              color: Colors.white.withOpacity(0.5),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No progress data yet',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your lifts to see your progression',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Progression',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildWeightChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_allProgress.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Get the first exercise for demonstration
    final firstExercise = _allProgress.keys.first;
    final exerciseData = _allProgress[firstExercise]!;
    
    if (exerciseData.length < 2) {
      return const Center(
        child: Text('Need at least 2 data points for chart'),
      );
    }

    final spots = exerciseData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < exerciseData.length) {
                  return Text(
                    '${value.toInt() + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (exerciseData.length - 1).toDouble(),
        minY: exerciseData.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 5,
        maxY: exerciseData.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF4ECDC4),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF4ECDC4),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_allProgress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Workouts',
            '${_recentLifts.length}',
            Icons.fitness_center,
            const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Exercises Tracked',
            '${_allProgress.length}',
            Icons.list,
            const Color(0xFF45B7D1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Muscle Groups',
            '${_muscleGroupAnalytics.length}',
            Icons.category,
            const Color(0xFF96CEB4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (_allProgress.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No exercises tracked yet',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts from your programs to see progress here',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How it works:',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4ECDC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Go to your workout programs\n2. Complete exercises with weights & reps\n3. Your progress will appear here automatically',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _allProgress.length,
      itemBuilder: (context, index) {
        final exerciseName = _allProgress.keys.elementAt(index);
        final exerciseData = _allProgress[exerciseName]!;
        final analytics = ProgressAnalyticsService.calculateAnalytics(
          exerciseName: exerciseName,
          muscleGroup: exerciseData.first.muscleGroup,
          data: exerciseData,
          programName: exerciseData.first.programName,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF2D2D2D),
                const Color(0xFF1E1E1E),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4ECDC4).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: const Color(0xFF4ECDC4),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exerciseName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (analytics.hasProgression)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PROGRESSING',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildExerciseStat(
                      'Best Weight',
                      analytics.bestWeight?.toStringAsFixed(1) ?? '0.0',
                      'kg',
                    ),
                  ),
                  Expanded(
                    child: _buildExerciseStat(
                      'Total Volume',
                      analytics.totalVolume?.toStringAsFixed(0) ?? '0',
                      'kg',
                    ),
                  ),
                  Expanded(
                    child: _buildExerciseStat(
                      'Workouts',
                      '${analytics.totalWorkouts}',
                      '',
                    ),
                  ),
                ],
              ),
              if (analytics.progressionStreak > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: const Color(0xFF4ECDC4),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${analytics.progressionStreak} workout streak!',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF4ECDC4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Add progression comparison
              _buildProgressionComparison(analytics),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseStat(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value$unit',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressionComparison(ProgressAnalytics analytics) {
    if (analytics.data.length < 2) {
      return const SizedBox.shrink();
    }

    final sortedData = analytics.data;
    final latest = sortedData.last;
    final previous = sortedData[sortedData.length - 2];
    
    final weightChange = latest.weight - previous.weight;
    final repsChange = latest.reps - previous.reps;
    final volumeChange = latest.calculatedVolume - previous.calculatedVolume;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression vs Last Workout',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildProgressionItem(
                  'Weight',
                  '${latest.weight.toStringAsFixed(1)} kg',
                  weightChange,
                  'kg',
                ),
              ),
              Expanded(
                child: _buildProgressionItem(
                  'Reps',
                  '${latest.reps}',
                  repsChange.toDouble(),
                  '',
                ),
              ),
              Expanded(
                child: _buildProgressionItem(
                  'Volume',
                  '${latest.calculatedVolume.toStringAsFixed(0)} kg',
                  volumeChange,
                  'kg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionItem(String label, String currentValue, double change, String unit) {
    final isPositive = change > 0;
    final isNeutral = change == 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          currentValue,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : isNeutral ? Icons.remove : Icons.trending_down,
              color: isPositive ? const Color(0xFF4CAF50) : isNeutral ? Colors.white.withOpacity(0.5) : const Color(0xFFF44336),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}$unit',
              style: GoogleFonts.poppins(
                color: isPositive ? const Color(0xFF4CAF50) : isNeutral ? Colors.white.withOpacity(0.5) : const Color(0xFFF44336),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (_recentLifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No recent lifts',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete workouts from your programs to see recent lifts here',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _recentLifts.length,
      itemBuilder: (context, index) {
        final lift = _recentLifts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: const Color(0xFF4ECDC4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lift.exerciseName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lift.weight.toStringAsFixed(1)} kg × ${lift.reps} reps × ${lift.sets} sets',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lift.relativeDate,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lift.formattedVolume,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF4ECDC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
