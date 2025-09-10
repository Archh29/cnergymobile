import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import './models/progress_model.dart';
import './services/enhanced_progress_service.dart';
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
  final TextEditingController chestController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipsController = TextEditingController();
  final TextEditingController armsController = TextEditingController();
  final TextEditingController thighsController = TextEditingController();
    
  String selectedMeasurement = 'Weight';
  List<String> measurements = ['Weight', 'BMI', 'Chest', 'Waist', 'Hips', 'Arms', 'Thighs'];
  double? userHeight;

  @override
  void initState() {
    super.initState();
    _loadCurrentMeasurements();
    _loadUserHeight();
  }

  void _loadCurrentMeasurements() {
    weightController.text = widget.currentMeasurements['weight']?.toString() ?? '';
    chestController.text = widget.currentMeasurements['chest']?.toString() ?? '';
    waistController.text = widget.currentMeasurements['waist']?.toString() ?? '';
    hipsController.text = widget.currentMeasurements['hips']?.toString() ?? '';
    armsController.text = widget.currentMeasurements['arms']?.toString() ?? '';
    thighsController.text = widget.currentMeasurements['thighs']?.toString() ?? '';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedMeasurement} Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
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
                  value: selectedMeasurement,
                  dropdownColor: Color(0xFF2A2A2A),
                  underline: SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF4ECDC4)),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  items: measurements.map((String measurement) {
                    return DropdownMenuItem<String>(
                      value: measurement,
                      child: Text(measurement),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedMeasurement = newValue;
                      });
                    }
                  },
                ),
              ),
            ],
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
                          spots: _generateDataFromProgress(selectedMeasurement),
                          isCurved: true,
                          color: _getMeasurementColor(selectedMeasurement),
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _getMeasurementColor(selectedMeasurement).withOpacity(0.1),
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

  List<FlSpot> _generateDataFromProgress(String measurement) {
    if (widget.progressData.isEmpty) return [];
    
    List<ProgressModel> sortedData;
    
    // Filter and sort data based on selected measurement
    switch (measurement) {
      case 'Weight':
        sortedData = widget.progressData
            .where((p) => p.weight != null && p.weight! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'BMI':
        sortedData = widget.progressData
            .where((p) => p.bmi != null && p.bmi! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'Chest':
        sortedData = widget.progressData
            .where((p) => p.chestCm != null && p.chestCm! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'Waist':
        sortedData = widget.progressData
            .where((p) => p.waistCm != null && p.waistCm! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'Hips':
        sortedData = widget.progressData
            .where((p) => p.hipsCm != null && p.hipsCm! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'Arms':
        sortedData = widget.progressData
            .where((p) => p.armsCm != null && p.armsCm! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      case 'Thighs':
        sortedData = widget.progressData
            .where((p) => p.thighsCm != null && p.thighsCm! > 0)
            .toList()
          ..sort((a, b) => a.dateRecorded.compareTo(b.dateRecorded));
        break;
      default:
        sortedData = [];
    }
    
    final recentData = sortedData.length > 10 
        ? sortedData.sublist(sortedData.length - 10)
        : sortedData;
    
    return recentData.asMap().entries.map((entry) {
      double value;
      switch (measurement) {
        case 'Weight':
          value = entry.value.weight!;
          break;
        case 'BMI':
          value = entry.value.bmi!;
          break;
        case 'Chest':
          value = entry.value.chestCm!;
          break;
        case 'Waist':
          value = entry.value.waistCm!;
          break;
        case 'Hips':
          value = entry.value.hipsCm!;
          break;
        case 'Arms':
          value = entry.value.armsCm!;
          break;
        case 'Thighs':
          value = entry.value.thighsCm!;
          break;
        default:
          value = 0.0;
      }
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  Color _getMeasurementColor(String measurement) {
    switch (measurement) {
      case 'Weight':
        return Color(0xFF4ECDC4);
      case 'BMI':
        return Color(0xFFFF6B35);
      case 'Chest':
        return Color(0xFFE67E22);
      case 'Waist':
        return Color(0xFFE74C3C);
      case 'Hips':
        return Color(0xFF96CEB4);
      case 'Arms':
        return Color(0xFF45B7D1);
      case 'Thighs':
        return Color(0xFF9B59B6);
      default:
        return Color(0xFF4ECDC4);
    }
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
          SizedBox(height: 16),
          _buildMeasurementInput('Arms (cm)', armsController, Icons.straighten_rounded),
          SizedBox(height: 16),
          _buildMeasurementInput('Thighs (cm)', thighsController, Icons.straighten_rounded),
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
                  _getCurrentBMI(), 
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
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Hips', 
                  latestProgress?.hipsCm?.toStringAsFixed(1) ?? '--', 
                  Color(0xFF96CEB4)
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Arms', 
                  latestProgress?.armsCm?.toStringAsFixed(1) ?? '--', 
                  Color(0xFF45B7D1)
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Thighs', 
                  latestProgress?.thighsCm?.toStringAsFixed(1) ?? '--', 
                  Color(0xFF9B59B6)
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Container(), // Empty space for alignment
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

  String _getCurrentBMI() {
    // First try to get BMI from latest progress data
    if (widget.progressData.isNotEmpty) {
      final sortedData = List<ProgressModel>.from(widget.progressData)
        ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      final latestProgress = sortedData.first;
      
      if (latestProgress.bmi != null && latestProgress.bmi! > 0) {
        return latestProgress.bmi!.toStringAsFixed(1);
      }
    }
    
    // If no BMI in progress data, calculate from current measurements and user height
    final currentWeight = widget.currentMeasurements['weight'];
    if (currentWeight != null && currentWeight > 0 && userHeight != null && userHeight! > 0) {
      final bmi = GymUtilsService.calculateBMI(currentWeight, userHeight!);
      return bmi.toStringAsFixed(1);
    }
    
    return '--';
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
      
      // Calculate BMI if weight and height are available
      double? calculatedBMI;
      final weight = double.tryParse(weightController.text);
      if (weight != null && userHeight != null && userHeight! > 0) {
        calculatedBMI = GymUtilsService.calculateBMI(weight, userHeight!);
      }
      
      final progressModel = ProgressModel(
        userId: userId,
        weight: weight,
        bmi: calculatedBMI,
        chestCm: double.tryParse(chestController.text),
        waistCm: double.tryParse(waistController.text),
        hipsCm: double.tryParse(hipsController.text),
        armsCm: double.tryParse(armsController.text),
        thighsCm: double.tryParse(thighsController.text),
        dateRecorded: DateTime.now(),
      );
      
      final success = await EnhancedProgressService.addProgress(progressModel);
      
      if (success) {
        // Update the current measurements immediately for real-time updates
        setState(() {
          if (progressModel.weight != null) {
            widget.currentMeasurements['weight'] = progressModel.weight!;
          }
          if (progressModel.bmi != null) {
            widget.currentMeasurements['bmi'] = progressModel.bmi!;
          }
          if (progressModel.chestCm != null) {
            widget.currentMeasurements['chest'] = progressModel.chestCm!;
          }
          if (progressModel.waistCm != null) {
            widget.currentMeasurements['waist'] = progressModel.waistCm!;
          }
          if (progressModel.hipsCm != null) {
            widget.currentMeasurements['hips'] = progressModel.hipsCm!;
          }
          if (progressModel.armsCm != null) {
            widget.currentMeasurements['arms'] = progressModel.armsCm!;
          }
          if (progressModel.thighsCm != null) {
            widget.currentMeasurements['thighs'] = progressModel.thighsCm!;
          }
        });
        
        // Add the new progress data to the list for immediate chart update
        widget.progressData.add(progressModel);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurements saved successfully!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
        
        // Return true to indicate measurements were updated
        Navigator.pop(context, true);
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
