import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import './models/progress_model.dart';
import './services/enhanced_progress_service.dart';

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
  final TextEditingController chestController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipsController = TextEditingController();
    
  String selectedMood = 'Good';
  List<String> moods = ['Excellent', 'Good', 'Average', 'Poor'];

  @override
  void initState() {
    super.initState();
    _loadCurrentMeasurements();
  }

  void _loadCurrentMeasurements() {
    weightController.text = widget.currentMeasurements['weight']?.toString() ?? '';
    chestController.text = widget.currentMeasurements['chest']?.toString() ?? '';
    waistController.text = widget.currentMeasurements['waist']?.toString() ?? '';
    hipsController.text = widget.currentMeasurements['hips']?.toString() ?? '';
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
          'Body Measurements',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressChart(),
            SizedBox(height: 24),
            _buildUpdateMeasurements(),
            SizedBox(height: 24),
            _buildMoodTracker(),
            SizedBox(height: 24),
            _buildCurrentStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
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
            'Weight Progress',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: widget.progressData.isEmpty
                ? Center(
                    child: Text(
                      'No progress data available',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _generateWeightDataFromProgress(),
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

  List<FlSpot> _generateWeightDataFromProgress() {
    if (widget.progressData.isEmpty) return [];
    
    // Sort by date and take last 10 entries
    final sortedData = widget.progressData
        .where((p) => p.weight != null && p.weight! > 0)
        .toList()
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    
    final recentData = sortedData.length > 10 
        ? sortedData.sublist(sortedData.length - 10)
        : sortedData;
    
    return recentData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight!);
    }).toList();
  }

  Widget _buildUpdateMeasurements() {
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
            'Update Measurements',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildMeasurementInput('Weight (kg)', weightController, Icons.scale_rounded),
          SizedBox(height: 16),
          _buildMeasurementInput('Chest (cm)', chestController, Icons.straighten_rounded),
          SizedBox(height: 16),
          _buildMeasurementInput('Waist (cm)', waistController, Icons.straighten_rounded),
          SizedBox(height: 16),
          _buildMeasurementInput('Hips (cm)', hipsController, Icons.straighten_rounded),
          SizedBox(height: 24),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveMeasurements,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Measurements',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementInput(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF4ECDC4)),
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTracker() {
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
            'How are you feeling today?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: moods.map((mood) {
              final isSelected = selectedMood == mood;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMood = mood;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF4ECDC4) : Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(0xFF4ECDC4) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMoodIcon(mood),
                        color: isSelected ? Colors.white : Colors.grey[400],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        mood,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Excellent': return Icons.sentiment_very_satisfied_rounded;
      case 'Good': return Icons.sentiment_satisfied_rounded;
      case 'Average': return Icons.sentiment_neutral_rounded;
      case 'Poor': return Icons.sentiment_dissatisfied_rounded;
      default: return Icons.sentiment_neutral_rounded;
    }
  }

  Widget _buildCurrentStats() {
    final latestProgress = widget.progressData.isNotEmpty 
        ? widget.progressData.latest 
        : null;
    
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
            'Current Statistics',
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
                child: _buildStatItem(
                  'BMI', 
                  latestProgress?.bmi?.toStringAsFixed(1) ?? '--', 
                  Color(0xFF45B7D1)
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Weight Change', 
                  _calculateWeightChange(), 
                  Color(0xFF96CEB4)
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Chest', 
                  latestProgress?.chestCm?.toStringAsFixed(1) ?? '--', 
                  Color(0xFFFF6B35)
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Waist', 
                  latestProgress?.waistCm?.toStringAsFixed(1) ?? '--', 
                  Color(0xFFE74C3C)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateWeightChange() {
    if (widget.progressData.length < 2) return '--';
    
    final sortedData = widget.progressData
        .where((p) => p.weight != null && p.weight! > 0)
        .toList()
      ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
    
    if (sortedData.length < 2) return '--';
    
    final change = sortedData.last.weight! - sortedData.first.weight!;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)} kg';
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMeasurements() async {
    try {
      final userId = await EnhancedProgressService.getCurrentUserId();
      
      final progressModel = ProgressModel(
        userId: userId,
        weight: double.tryParse(weightController.text),
        chestCm: double.tryParse(chestController.text),
        waistCm: double.tryParse(waistController.text),
        hipsCm: double.tryParse(hipsController.text),
        dateRecorded: DateTime.now(),
      );
      
      final success = await EnhancedProgressService.addProgress(progressModel);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurements saved successfully!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurements'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
