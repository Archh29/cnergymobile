import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import './models/progress_model.dart';
import './services/enhanced_progress_service.dart';
import './services/body_measurements_service.dart';
import './services/profile_service.dart';
import './services/gym_utils_service.dart';

class MeasurementsPage extends StatefulWidget {
  final Map<String, double> currentMeasurements;
  final List<ProgressModel> progressData;

  const MeasurementsPage({
    Key? key, 
    required this.currentMeasurements,
    required this.progressData,
  }) : super(key: key);

  @override
  _MeasurementsPageState createState() => _MeasurementsPageState();
}

class _MeasurementsPageState extends State<MeasurementsPage> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
    
  String selectedTimePeriod = '30d'; // 30d, 3m, 6m, 1y, all
  List<String> timePeriods = ['30d', '3m', '6m', '1y', 'all'];
  double? userHeight;
  bool isLoading = false;
  List<ProgressModel> _bodyMeasurements = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentMeasurements();
    _loadUserHeight();
    _loadBodyMeasurements();
  }

  void _loadCurrentMeasurements() {
    weightController.text = widget.currentMeasurements['weight']?.toString() ?? '';
  }

  Future<void> _loadUserHeight() async {
    try {
      final profileData = await ProfileService.getProfile();
      if (profileData != null && profileData['height_cm'] != null) {
        setState(() {
          userHeight = double.tryParse(profileData['height_cm'].toString());
        });
      }
    } catch (e) {
      print('Error loading user height: $e');
    }
  }

  Future<void> _loadBodyMeasurements() async {
    try {
      setState(() => isLoading = true);
      final measurements = await BodyMeasurementsService.getBodyMeasurements();
      setState(() {
        _bodyMeasurements = measurements;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading body measurements: $e');
      setState(() => isLoading = false);
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
          onPressed: () => Navigator.pop(context, true), // Return true to refresh parent
        ),
        title: Text(
          'Body Weight Tracking',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Color(0xFF4ECDC4)),
            onPressed: _showAddWeightDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeightProgressChart(),
            SizedBox(height: 24),
            _buildStatsSummary(),
            SizedBox(height: 24),
            _buildRecentEntries(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightProgressChart() {
    final weightData = _getFilteredWeightData();
    
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: selectedTimePeriod,
                  dropdownColor: Color(0xFF2A2A2A),
                  underline: SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF4ECDC4)),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  items: timePeriods.map((String period) {
                    return DropdownMenuItem<String>(
                      value: period,
                      child: Text(_getTimePeriodLabel(period)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedTimePeriod = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 250,
            child: weightData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.scale_rounded, color: Colors.grey[600], size: 48),
                        SizedBox(height: 16),
                        Text(
                          'No weight data available',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap + to add your first weight entry',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: _getHorizontalInterval(weightData),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[800]!,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.grey[800]!,
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      minX: 0,
                      maxX: weightData.length > 1 ? (weightData.length - 1).toDouble() : 1,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toInt()}kg',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1, // Show title for every data point
                            getTitlesWidget: (value, meta) {
                              if (weightData.isEmpty) return Text('');
                              final index = value.toInt();
                              // Only show dates at actual data points (where there are circles/lines)
                              if (index >= 0 && index < weightData.length) {
                                final date = weightData[index].dateRecorded;
                                return Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    '${_getMonthAbbreviation(date.month)} ${date.day}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                );
                              }
                              return Text(''); // No date for empty positions
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateWeightSpots(weightData),
                          isCurved: true,
                          color: Color(0xFF4ECDC4),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Color(0xFF4ECDC4),
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
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

  Widget _buildStatsSummary() {
    final weightData = _getFilteredWeightData();
    if (weightData.isEmpty) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
        child: Center(
              child: Text(
            'Add weight entries to see your progress stats',
                style: GoogleFonts.poppins(
              color: Colors.grey[400],
                  fontSize: 16,
              ),
            ),
      ),
    );
  }

    // Sort by date to get proper order
    weightData.sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    
    // Starting weight is ALWAYS the account creation weight (80kg)
    double startingWeight = 0.0;
    for (var entry in _bodyMeasurements) {
      if (entry.notes != null && 
          (entry.notes!.toLowerCase().contains('starting') || 
           entry.notes!.toLowerCase().contains('profile'))) {
        startingWeight = entry.weight ?? 0.0;
        break;
      }
    }
    
    // Current weight is the latest entry in the selected period (excluding starting weight)
    double currentWeight = 0.0;
    final periodData = weightData.where((p) => 
        p.notes == null || 
        (!p.notes!.toLowerCase().contains('starting') && !p.notes!.toLowerCase().contains('profile'))
    ).toList();
    
    
    if (periodData.isNotEmpty) {
      currentWeight = periodData.last.weight ?? 0.0; // Latest entry in period (excluding starting weight)
    } else {
      // If no data in period, use account creation weight as current weight too
      currentWeight = startingWeight;
    }
    
    final totalChange = currentWeight - startingWeight;
    
    // Calculate days between - always use starting weight date as reference
    int daysBetween = 0;
    DateTime? startingDate;
    
    // Find the starting weight date
    for (var entry in _bodyMeasurements) {
      if (entry.notes != null && 
          (entry.notes!.toLowerCase().contains('starting') || 
           entry.notes!.toLowerCase().contains('profile'))) {
        startingDate = entry.dateRecorded;
          break;
      }
    }
    
    if (startingDate != null && periodData.isNotEmpty) {
      // Calculate from starting weight to latest entry in period
      final latestDate = periodData.last.dateRecorded;
      final startDateOnly = DateTime(startingDate.year, startingDate.month, startingDate.day);
      final latestDateOnly = DateTime(latestDate.year, latestDate.month, latestDate.day);
      daysBetween = latestDateOnly.difference(startDateOnly).inDays;
    } else if (startingDate != null && weightData.isNotEmpty) {
      // If no period data but we have weight data, use the latest entry from all data
      final latestDate = weightData.first.dateRecorded;
      final startDateOnly = DateTime(startingDate.year, startingDate.month, startingDate.day);
      final latestDateOnly = DateTime(latestDate.year, latestDate.month, latestDate.day);
      daysBetween = latestDateOnly.difference(startDateOnly).inDays;
    } else if (startingDate != null) {
      // If no data at all, calculate from starting weight to now
      final now = DateTime.now();
      daysBetween = now.difference(startingDate).inDays;
    } else {
    }
    
    final averageWeeklyChange = daysBetween > 0 ? (totalChange / (daysBetween / 7)) : 0.0;
    
    
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Summary',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Weight',
                  '${currentWeight.toStringAsFixed(1)} kg',
                  Icons.scale_rounded,
                  Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Starting Weight',
                  '${startingWeight.toStringAsFixed(1)} kg',
                  Icons.trending_up_rounded,
                  Color(0xFF96CEB4),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Change',
                  '${totalChange >= 0 ? '+' : ''}${totalChange.toStringAsFixed(1)} kg',
                  Icons.trending_up_rounded,
                  totalChange >= 0 ? Color(0xFFE74C3C) : Color(0xFF00B894),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Weekly Average',
                  '${averageWeeklyChange >= 0 ? '+' : ''}${averageWeeklyChange.toStringAsFixed(1)} kg/week',
                  Icons.calendar_today_rounded,
                  averageWeeklyChange >= 0 ? Color(0xFFE74C3C) : Color(0xFF00B894),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
            child: Row(
            children: [
                Icon(Icons.schedule_rounded, color: Color(0xFF4ECDC4), size: 20),
                SizedBox(width: 12),
                Text(
                  'Time Period: ${_getTimePeriodLabel(selectedTimePeriod)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                ),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
      children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
        Text(
            value,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
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

  Widget _buildRecentEntries() {
    final weightData = _getFilteredWeightData();
    if (weightData.isEmpty) return SizedBox.shrink();
    
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
            'Recent Entries',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...weightData.reversed.take(5).map((entry) => _buildWeightEntry(entry)).toList(),
        ],
      ),
    );
  }

  Widget _buildWeightEntry(ProgressModel entry) {
    final isLatest = entry == _getFilteredWeightData().last;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isLatest 
          ? LinearGradient(
              colors: [
                Color(0xFF4ECDC4).withOpacity(0.15),
                Color(0xFF4ECDC4).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: [
                Color(0xFF2A2A2A),
                Color(0xFF1F1F1F),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? Color(0xFF4ECDC4).withOpacity(0.6) : Color(0xFF3A3A3A),
          width: isLatest ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
          if (isLatest)
            BoxShadow(
              color: Color(0xFF4ECDC4).withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4ECDC4).withOpacity(0.3),
                  Color(0xFF4ECDC4).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color(0xFF4ECDC4).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.scale_rounded,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.weight?.toStringAsFixed(1) ?? '0.0'} kg',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDate(entry.dateRecorded),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                // Show notes if they exist
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8, right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4ECDC4).withOpacity(0.15),
                          Color(0xFF4ECDC4).withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF4ECDC4).withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4ECDC4).withOpacity(0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        Container(
                          margin: EdgeInsets.only(right: 8, top: 2),
                          child: Icon(
                            Icons.note_alt_rounded,
                            color: Color(0xFF4ECDC4),
                            size: 14,
                          ),
                        ),
              Expanded(
                          child: Text(
                            entry.notes!,
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
                  ),
              ],
            ),
          ),
          // Edit and Delete buttons
          SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              GestureDetector(
                onTap: () => _showEditDialog(entry),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ECDC4).withOpacity(0.3),
                        Color(0xFF4ECDC4).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF4ECDC4).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4ECDC4).withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
              ),
            ],
          ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF4ECDC4),
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteDialog(entry),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.3),
                        Colors.red.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Latest badge
              if (isLatest)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ECDC4),
                        Color(0xFF3BB5B0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'LATEST',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddWeightDialog() {
    weightController.clear();
    notesController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Add Weight Entry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'One entry per day - will update if exists',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
            // Weight input with improved styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.scale_rounded,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Notes input with improved styling
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: notesController,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  labelStyle: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.note_alt_rounded,
                      color: Color(0xFF4ECDC4),
                      size: 20,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  hintText: 'Add notes about your weight (e.g., "after workout", "morning weight", "feeling bloated")',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: _saveWeightEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, TextInputType keyboardType, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Color(0xFF4ECDC4)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4ECDC4)),
        ),
      ),
    );
  }

  Future<void> _saveWeightEntry() async {
    if (weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final weight = double.tryParse(weightController.text);
      final notes = notesController.text.isNotEmpty ? notesController.text : null;

      if (weight == null) {
        throw Exception('Invalid weight value');
      }

      // Calculate BMI if height is available
      double? bmi;
      if (userHeight != null && userHeight! > 0) {
        bmi = GymUtilsService.calculateBMI(weight, userHeight!);
      }

      // Save to database using the new body measurements service
      final result = await BodyMeasurementsService.addBodyMeasurement(
        weight: weight,
        bmi: bmi,
        notes: notes,
      );

      if (result['success']) {
        Navigator.pop(context);
        
        // Show different message based on action
        String message;
        Color backgroundColor;
        
        if (result['action'] == 'updated') {
          message = 'Weight updated for today!';
          backgroundColor = Color(0xFF4ECDC4);
        } else {
          message = 'Weight saved for today!';
          backgroundColor = Colors.green;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Refresh the data
        await _loadBodyMeasurements();
      } else {
        throw Exception(result['message'] ?? 'Failed to save weight entry');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving weight entry: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<ProgressModel> _getFilteredWeightData() {
    if (_bodyMeasurements.isEmpty) return [];

    final now = DateTime.now();
    DateTime filterDate;

    switch (selectedTimePeriod) {
      case '30d':
        filterDate = now.subtract(Duration(days: 30));
        break;
      case '3m':
        filterDate = now.subtract(Duration(days: 90));
        break;
      case '6m':
        filterDate = now.subtract(Duration(days: 180));
        break;
      case '1y':
        filterDate = now.subtract(Duration(days: 365));
        break;
      default:
        filterDate = DateTime(2020); // All time
    }

    // Filter by time period, but always include starting weight for reference
    final filteredData = _bodyMeasurements
        .where((p) => p.weight != null && p.weight! > 0 && 
                     (p.dateRecorded.isAfter(filterDate) || 
                      (p.notes != null && (p.notes!.toLowerCase().contains('starting') || p.notes!.toLowerCase().contains('profile')))))
        .toList()
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    
    return filteredData;
  }

  List<FlSpot> _generateWeightSpots(List<ProgressModel> weightData) {
    return weightData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight!);
    }).toList();
  }

  double _getHorizontalInterval(List<ProgressModel> weightData) {
    if (weightData.isEmpty) return 5.0;
    
    final weights = weightData.map((d) => d.weight!).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final range = maxWeight - minWeight;
    
    if (range <= 5) return 1.0;
    if (range <= 10) return 2.0;
    if (range <= 20) return 5.0;
    return 10.0;
  }

  String _getTimePeriodLabel(String period) {
    switch (period) {
      case '30d': return '30 Days';
      case '3m': return '3 Months';
      case '6m': return '6 Months';
      case '1y': return '1 Year';
      case 'all': return 'All Time';
      default: return '30 Days';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(entryDate).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    
    return '${_getMonthAbbreviation(date.month)} ${date.day}, ${date.year}';
  }

  void _showEditDialog(ProgressModel entry) {
    final editWeightController = TextEditingController(text: entry.weight?.toString() ?? '');
    final editNotesController = TextEditingController(text: entry.notes ?? '');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon and title
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ECDC4).withOpacity(0.1),
                        Color(0xFF4ECDC4).withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                              'Edit Weight Entry',
            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
                              'Update your weight and notes',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
                                fontSize: 14,
            ),
          ),
        ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Weight input with better styling
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: editWeightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.scale_rounded,
                              color: Color(0xFF4ECDC4),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Notes input with better styling
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                        ),
                        child: TextField(
                          controller: editNotesController,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(
                                Icons.note_alt_rounded,
                                color: Color(0xFF4ECDC4),
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            hintText: 'Add any notes about this measurement...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Action buttons with better design
                Container(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Update button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF4ECDC4).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () async {
                              final weight = double.tryParse(editWeightController.text);
                              if (weight == null || weight <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Please enter a valid weight'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);
                              
                              // Calculate BMI if height is available
                              double? bmi;
                              if (userHeight != null && userHeight! > 0) {
                                bmi = GymUtilsService.calculateBMI(weight, userHeight!);
                              }

                              final success = await BodyMeasurementsService.updateBodyMeasurement(
                                id: entry.id!,
        weight: weight,
                                bmi: bmi,
                                notes: editNotesController.text.isNotEmpty ? editNotesController.text : null,
                              );

                              setState(() => isLoading = false);
      
      if (success) {
                                Navigator.of(context).pop();
                                await _loadBodyMeasurements();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Weight entry updated successfully'),
                                    backgroundColor: Color(0xFF4ECDC4),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update weight entry'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Update',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(ProgressModel entry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with warning icon
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.red.withOpacity(0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.warning_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Weight Entry',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'This action cannot be undone',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.scale_rounded,
                              color: Colors.red,
                              size: 24,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.weight?.toStringAsFixed(1)} kg',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(entry.dateRecorded),
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      Text(
                        'Are you sure you want to delete this weight entry? This will permanently remove it from your progress tracking.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[300],
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[300],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 16),
                      
                      // Delete button
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red, Colors.red[700]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () async {
                              setState(() => isLoading = true);
                              
                              final success = await BodyMeasurementsService.deleteBodyMeasurement(entry.id!);
                              
                              setState(() => isLoading = false);

                              if (success) {
                                Navigator.of(context).pop();
                                await _loadBodyMeasurements();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                                    content: Text('Weight entry deleted successfully'),
            backgroundColor: Color(0xFF4ECDC4),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                                    content: Text('Failed to delete weight entry'),
            backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}