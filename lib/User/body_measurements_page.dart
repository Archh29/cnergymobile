import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'services/body_measurements_service.dart';
import 'models/progress_model.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';
import 'services/gym_utils_service.dart';

class BodyMeasurementsPage extends StatefulWidget {
  const BodyMeasurementsPage({Key? key}) : super(key: key);

  @override
  _BodyMeasurementsPageState createState() => _BodyMeasurementsPageState();
}

class _BodyMeasurementsPageState extends State<BodyMeasurementsPage> {
  List<ProgressModel> _measurements = [];
  bool _isLoading = true;
  String _selectedMeasurement = 'all'; // Default to all

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final measurements = await BodyMeasurementsService.getBodyMeasurements();
      
      // Sort by date (newest first)
      measurements.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      
      if (mounted) {
        setState(() {
          _measurements = measurements;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading measurements: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
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
                          'Body Measurements',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Track your progress',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddMeasurementDialog,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4ECDC4).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Measurement Type Filter
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF181818),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMeasurementTypeChip('all', 'All', Icons.list),
                    _buildMeasurementTypeChip('chest', 'Chest', Icons.fitness_center),
                    _buildMeasurementTypeChip('waist', 'Waist', Icons.straighten),
                    _buildMeasurementTypeChip('arms', 'Arms', Icons.accessibility_new),
                    _buildMeasurementTypeChip('thighs', 'Thighs', Icons.directions_run),
                    _buildMeasurementTypeChip('hips', 'Hips', Icons.accessibility),
                  ],
                ),
              ),
            ),
            
            // Content - Single Measurement View
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF4ECDC4)))
                  : _buildSingleMeasurementView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTypeChip(String key, String label, IconData icon) {
    final isSelected = _selectedMeasurement == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMeasurement = key);
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)])
              : LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Color(0xFF4ECDC4).withOpacity(0.5)
                : Colors.grey[700]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMeasurementView() {
    if (_measurements.isEmpty) {
      return _buildEmptyState();
    }

    // If "All" is selected, show cards for each measurement type
    if (_selectedMeasurement == 'all') {
      return RefreshIndicator(
        color: Color(0xFF4ECDC4),
        onRefresh: _loadMeasurements,
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: 5, // Chest, Waist, Arms, Thighs, Hips
          itemBuilder: (context, index) {
            final measurementTypes = [
              {'key': 'chest', 'name': 'Chest', 'icon': Icons.fitness_center, 'unit': 'cm'},
              {'key': 'waist', 'name': 'Waist', 'icon': Icons.straighten, 'unit': 'cm'},
              {'key': 'arms', 'name': 'Arms', 'icon': Icons.accessibility_new, 'unit': 'cm'},
              {'key': 'thighs', 'name': 'Thighs', 'icon': Icons.directions_run, 'unit': 'cm'},
              {'key': 'hips', 'name': 'Hips', 'icon': Icons.accessibility, 'unit': 'cm'},
            ];
            
            final type = measurementTypes[index];
            return _buildMeasurementTypeCard(type);
          },
        ),
      );
    }

    // Find the latest measurement for the selected type
    double? latestValue;
    String unit = 'cm';
    IconData icon;
    String label;

    switch (_selectedMeasurement) {
      case 'chest':
        label = 'Chest';
        icon = Icons.fitness_center;
        latestValue = _measurements.firstWhere((m) => m.chestCm != null && m.chestCm != 0.0, orElse: () => _measurements[0]).chestCm;
        break;
      case 'waist':
        label = 'Waist';
        icon = Icons.straighten;
        latestValue = _measurements.firstWhere((m) => m.waistCm != null && m.waistCm != 0.0, orElse: () => _measurements[0]).waistCm;
        break;
      case 'arms':
        label = 'Arms';
        icon = Icons.accessibility_new;
        latestValue = _measurements.firstWhere((m) => m.armsCm != null && m.armsCm != 0.0, orElse: () => _measurements[0]).armsCm;
        break;
      case 'thighs':
        label = 'Thighs';
        icon = Icons.directions_run;
        latestValue = _measurements.firstWhere((m) => m.thighsCm != null && m.thighsCm != 0.0, orElse: () => _measurements[0]).thighsCm;
        break;
      case 'hips':
        label = 'Hips';
        icon = Icons.accessibility;
        latestValue = _measurements.firstWhere((m) => m.hipsCm != null && m.hipsCm != 0.0, orElse: () => _measurements[0]).hipsCm;
        break;
      default:
        label = 'Chest';
        icon = Icons.fitness_center;
        latestValue = _measurements[0].chestCm;
    }

    if (latestValue == null || latestValue == 0.0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.grey[400], size: 48),
            SizedBox(height: 16),
            Text(
              'No $label measurements yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first $label measurement to start tracking',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Get latest entry date
    final latestDate = _measurements.firstWhere(
      (m) {
        switch (_selectedMeasurement) {
          case 'chest':
            return m.chestCm != null && m.chestCm != 0.0;
          case 'waist':
            return m.waistCm != null && m.waistCm != 0.0;
          case 'arms':
            return m.armsCm != null && m.armsCm != 0.0;
          case 'thighs':
            return m.thighsCm != null && m.thighsCm != 0.0;
          case 'hips':
            return m.hipsCm != null && m.hipsCm != 0.0;
        }
        return false;
      },
      orElse: () => _measurements[0],
    ).dateRecorded;

    // Show direct data without card - just the measurement info
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 48),
            ),
            SizedBox(height: 24),
            Text(
              '${latestValue.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -3,
              ),
            ),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF4ECDC4), size: 18),
                  SizedBox(width: 8),
                  Text(
                    _formatDate(latestDate),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            GestureDetector(
              onTap: () => _showMeasurementHistory(_selectedMeasurement, label),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4ECDC4).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timeline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'View History',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTypeCard(Map<String, dynamic> type) {
    // Find the latest value for this measurement type
    double? value;
    DateTime? date;
    
    for (var measurement in _measurements) {
      double? currentValue;
      switch (type['key']) {
        case 'chest':
          currentValue = measurement.chestCm;
          break;
        case 'waist':
          currentValue = measurement.waistCm;
          break;
        case 'arms':
          currentValue = measurement.armsCm;
          break;
        case 'thighs':
          currentValue = measurement.thighsCm;
          break;
        case 'hips':
          currentValue = measurement.hipsCm;
          break;
      }
      
      if (currentValue != null && currentValue > 0) {
        value = currentValue;
        date = measurement.dateRecorded;
        break; // Found latest
      }
    }
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMeasurement = type['key']);
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: value != null 
            ? LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  type['icon'] as IconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (value != null) ...[
                Text(
                  '${value.toStringAsFixed(1)}',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Text(
                  type['unit'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.0,
                  ),
                ),
              ] else ...[
                Icon(Icons.add_circle_outline, color: Colors.white70, size: 20),
                SizedBox(height: 2),
                Text(
                  'No data',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white70,
                    height: 1.0,
                  ),
                ),
              ],
              Text(
                type['name'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (value != null && date != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4).withOpacity(0.1), Color(0xFF44A08D).withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.straighten_rounded,
              color: Color(0xFF4ECDC4),
              size: 64,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No measurements yet',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start tracking your body composition and see your progress over time',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showAddMeasurementDialog,
            icon: Icon(Icons.add_circle_outline),
            label: Text('Add First Measurement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(ProgressModel measurement, int index) {
    final isLatest = index == 0;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLatest ? Color(0xFF4ECDC4).withOpacity(0.4) : Colors.grey[800]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLatest 
                            ? [Color(0xFF4ECDC4), Color(0xFF44A08D)]
                            : [Color(0xFF3A3A3A), Color(0xFF2A2A2A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLatest)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF4ECDC4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LATEST',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4ECDC4),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        if (isLatest) SizedBox(height: 4),
                        Text(
                          _formatDate(measurement.dateRecorded),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7), size: 22),
                  onPressed: () => _showDeleteDialog(measurement),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.grey[800], height: 1, indent: 20, endIndent: 20),
          
          // Measurements Grid
          Padding(
            padding: EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    if (measurement.chestCm != null && measurement.chestCm != 0.0)
                      _buildMeasurementItem('chest', 'Chest', '${measurement.chestCm!.toStringAsFixed(1)} cm', Icons.fitness_center),
                    if (measurement.waistCm != null && measurement.waistCm != 0.0)
                      _buildMeasurementItem('waist', 'Waist', '${measurement.waistCm!.toStringAsFixed(1)} cm', Icons.straighten),
                    if (measurement.armsCm != null && measurement.armsCm != 0.0)
                      _buildMeasurementItem('arms', 'Arms', '${measurement.armsCm!.toStringAsFixed(1)} cm', Icons.accessibility_new),
                    if (measurement.thighsCm != null && measurement.thighsCm != 0.0)
                      _buildMeasurementItem('thighs', 'Thighs', '${measurement.thighsCm!.toStringAsFixed(1)} cm', Icons.directions_run),
                    if (measurement.hipsCm != null && measurement.hipsCm != 0.0)
                      _buildMeasurementItem('hips', 'Hips', '${measurement.hipsCm!.toStringAsFixed(1)} cm', Icons.accessibility),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String key, String label, String value, IconData icon) {
    return GestureDetector(
      onTap: () => _showMeasurementHistory(key, label),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Color(0xFF4ECDC4), size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showMeasurementHistory(String measurementKey, String measurementName) async {
    // Get ALL measurements from database (not just filtered)
    final allMeasurements = await BodyMeasurementsService.getBodyMeasurements();
    
    // Filter measurements that have this specific measurement
    final filteredData = allMeasurements.map((m) {
      double? value;
      switch (measurementKey) {
        case 'chest':
          value = m.chestCm;
          break;
        case 'waist':
          value = m.waistCm;
          break;
        case 'arms':
          value = m.armsCm;
          break;
        case 'thighs':
          value = m.thighsCm;
          break;
        case 'hips':
          value = m.hipsCm;
          break;
      }
      return {'date': m.dateRecorded, 'value': value};
    }).where((data) => data['value'] != null && data['value'] != 0.0).toList();
    
    if (filteredData.isEmpty) return;
    
    // Sort by date (newest first)
    filteredData.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    await showDialog(
      context: context,
      builder: (context) => _MeasurementHistoryDialog(
        measurementName: measurementName,
        history: filteredData,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} week${(difference / 7).floor() == 1 ? '' : 's'} ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showAddMeasurementDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddMeasurementDialog(
        onSave: () => _loadMeasurements(),
      ),
    );
  }

  Future<void> _showDeleteDialog(ProgressModel measurement) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Measurement?',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (result == true && measurement.id != null) {
      await BodyMeasurementsService.deleteBodyMeasurement(measurement.id!);
      if (mounted) {
        _loadMeasurements();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Measurement deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _AddMeasurementDialog extends StatefulWidget {
  final VoidCallback onSave;
  
  const _AddMeasurementDialog({required this.onSave});
  
  @override
  _AddMeasurementDialogState createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<_AddMeasurementDialog> {
  String? _selectedMeasurement;
  final TextEditingController _valueController = TextEditingController();

  final List<Map<String, dynamic>> _measurementTypes = [
    {'name': 'Chest', 'key': 'chest', 'icon': Icons.fitness_center, 'unit': 'cm'},
    {'name': 'Waist', 'key': 'waist', 'icon': Icons.straighten, 'unit': 'cm'},
    {'name': 'Arms', 'key': 'arms', 'icon': Icons.accessibility_new, 'unit': 'cm'},
    {'name': 'Thighs', 'key': 'thighs', 'icon': Icons.directions_run, 'unit': 'cm'},
    {'name': 'Hips', 'key': 'hips', 'icon': Icons.accessibility, 'unit': 'cm'},
  ];

  @override
  void initState() {
    super.initState();
    _valueController.addListener(() {
      setState(() {}); // Rebuild to update button state
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.straighten, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Measurement',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Selection Chips
                  Text(
                    'Select measurement type:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Grid of selection chips
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = _measurementTypes.length > 3 ? 2 : _measurementTypes.length;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _measurementTypes.length,
                        itemBuilder: (context, index) {
                          final measurement = _measurementTypes[index];
                          final isSelected = _selectedMeasurement == measurement['key'];
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMeasurement = measurement['key'];
                                _valueController.clear();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isSelected 
                                  ? LinearGradient(
                                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                                    )
                                  : LinearGradient(
                                      colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                                    ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                    ? Color(0xFF4ECDC4).withOpacity(0.5)
                                    : Colors.grey[700]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ] : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    measurement['icon'] as IconData,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    measurement['name'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  
                  // Input field (only shown when measurement is selected)
                  if (_selectedMeasurement != null) ...[
                    SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 2),
                      ),
                      child: TextField(
                        controller: _valueController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        autofocus: true,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter value',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 18,
                          ),
                          suffixText: 'cm',
                          suffixStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ),
            ),
            
            // Buttons - fixed at bottom
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[800]!, width: 1)),
                color: Color(0xFF1A1A1A),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[700]!, width: 1),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedMeasurement != null && _valueController.text.isNotEmpty
                          ? _saveMeasurement
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        disabledBackgroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeasurement() async {
    if (_selectedMeasurement == null || _valueController.text.isEmpty) return;
    
    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid measurement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Map<String, dynamic> data = {'notes': 'Body measurements entry'};
      
      switch (_selectedMeasurement) {
        case 'chest':
          data['chestCm'] = value;
          break;
        case 'waist':
          data['waistCm'] = value;
          break;
        case 'arms':
          data['armsCm'] = value;
          break;
        case 'thighs':
          data['thighsCm'] = value;
          break;
        case 'hips':
          data['hipsCm'] = value;
          break;
      }

      await BodyMeasurementsService.addBodyMeasurement(
        weight: 0.0,
        chestCm: data['chestCm'],
        waistCm: data['waistCm'],
        armsCm: data['armsCm'],
        thighsCm: data['thighsCm'],
        hipsCm: data['hipsCm'],
        bmi: null,
        notes: data['notes'],
      );

      Navigator.pop(context);
      widget.onSave();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Measurement saved successfully'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MeasurementHistoryDialog extends StatelessWidget {
  final String measurementName;
  final List<Map<String, dynamic>> history;
  
  const _MeasurementHistoryDialog({
    required this.measurementName,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    final values = history.map((h) => h['value'] as double).toList();
    final latest = values.first;
    final oldest = values.last;
    final change = latest - oldest;
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    return Dialog(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.timeline, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          measurementName,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Progress History',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Stats
            Container(
              padding: EdgeInsets.all(20),
              color: Color(0xFF2A2A2A),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Latest', '${latest.toStringAsFixed(1)} cm', Icons.arrow_upward, Colors.green),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[700]),
                  Expanded(
                    child: _buildStatItem('Change', '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} cm', Icons.trending_up, change > 0 ? Colors.green : change < 0 ? Colors.red : Colors.grey),
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[700]),
                  Expanded(
                    child: _buildStatItem('Average', '${avg.toStringAsFixed(1)} cm', Icons.calculate, Color(0xFF4ECDC4)),
                  ),
                ],
              ),
            ),
            
            // History List
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final date = entry['date'] as DateTime;
                    final value = entry['value'] as double;
                    
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calendar_today, color: Colors.white, size: 18),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatHistoryDate(date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${value.toStringAsFixed(1)} cm',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (index < history.length - 1) ...[
                            Icon(Icons.arrow_downward, color: Color(0xFF4ECDC4), size: 16),
                            SizedBox(width: 8),
                            Text(
                              '${(value - (history[index + 1]['value'] as double)).toStringAsFixed(1)} cm',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: (value - (history[index + 1]['value'] as double)) > 0 
                                  ? Colors.green 
                                  : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Close button
            Padding(
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
        SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
  
  String _formatHistoryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} week${(difference / 7).floor() == 1 ? '' : 's'} ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}