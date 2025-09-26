import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './services/enhanced_progress_service.dart';
import './models/personal_record_model.dart';

class PersonalRecordsPage extends StatefulWidget {
  @override
  _PersonalRecordsPageState createState() => _PersonalRecordsPageState();
}

class _PersonalRecordsPageState extends State<PersonalRecordsPage> {
  List<PersonalRecordModel> personalRecords = [];
  List<Map<String, dynamic>> exercises = [];
  List<Map<String, dynamic>> muscleGroups = [];
  bool isLoading = true;
  String searchQuery = '';
  int? selectedMuscleGroupId;
  String selectedMuscleGroupName = 'All Muscle Groups';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final futures = await Future.wait([
        EnhancedProgressService.fetchPersonalRecords(muscleGroupId: selectedMuscleGroupId),
        EnhancedProgressService.fetchExercises(),
        EnhancedProgressService.fetchMuscleGroups(),
      ]);
      
      if (mounted) {
        setState(() {
          personalRecords = futures[0] as List<PersonalRecordModel>;
          exercises = futures[1] as List<Map<String, dynamic>>;
          muscleGroups = futures[2] as List<Map<String, dynamic>>;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          'Personal Records',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _showAddRecordDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ))
          : Column(
              children: [
                _buildSearchBar(),
                _buildMuscleGroupFilter(),
                Expanded(child: _buildRecordsList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search exercises...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4ECDC4)),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildMuscleGroupFilter() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Muscle Groups', null, selectedMuscleGroupId == null),
            SizedBox(width: 8),
            ...muscleGroups.map((group) => _buildFilterChip(
              group['name'],
              group['id'],
              selectedMuscleGroupId == group['id'],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? muscleGroupId, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMuscleGroupId = muscleGroupId;
          selectedMuscleGroupName = label;
        });
        _loadData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4ECDC4) : Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    final filteredRecords = personalRecords.where((record) {
      return record.exerciseName?.toLowerCase().contains(searchQuery) ?? false;
    }).toList();

    if (filteredRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 64),
            SizedBox(height: 16),
            Text(
              personalRecords.isEmpty ? 'No personal records yet' : 'No records found',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start tracking your PRs!',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredRecords.length,
      itemBuilder: (context, index) {
        final record = filteredRecords[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(PersonalRecordModel record) {
    return GestureDetector(
      onTap: () => _showExerciseHistory(record),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
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
                  record.exerciseName ?? 'Unknown Exercise',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    if (record.primaryMuscleGroup != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.primaryMuscleGroup!,
                          style: GoogleFonts.poppins(
                            color: Color(0xFF4ECDC4),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                    ],
                    Text(
                      'Achieved ${record.formattedDate}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.formattedWeight,
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'PR',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  void _showExerciseHistory(PersonalRecordModel record) async {
    try {
      final history = await EnhancedProgressService.fetchExerciseHistory(record.exerciseId);
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Color(0xFF0F0F0F),
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF4ECDC4), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${record.exerciseName} - History',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[400]),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // History List
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 64),
                            SizedBox(height: 16),
                            Text(
                              'No history found',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final historyRecord = history[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4ECDC4).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.emoji_events_rounded,
                                    color: Color(0xFF4ECDC4),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        historyRecord.formattedWeight,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        historyRecord.formattedDate,
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading exercise history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddRecordDialog(
        exercises: exercises,
        muscleGroups: muscleGroups,
        onRecordAdded: () {
          _loadData();
        },
      ),
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> muscleGroups;
  final VoidCallback onRecordAdded;

  const _AddRecordDialog({
    Key? key,
    required this.exercises,
    required this.muscleGroups,
    required this.onRecordAdded,
  }) : super(key: key);

  @override
  _AddRecordDialogState createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  Map<String, dynamic>? selectedExercise;
  final TextEditingController weightController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  int? selectedMuscleGroupId;
  String selectedMuscleGroupName = 'All Muscle Groups';
  List<Map<String, dynamic>> filteredExercises = [];

  @override
  void initState() {
    super.initState();
    filteredExercises = widget.exercises;
  }

  Future<void> _filterExercisesByMuscleGroup(int? muscleGroupId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final exercises = await EnhancedProgressService.fetchExercises(muscleGroupId: muscleGroupId);
      setState(() {
        filteredExercises = exercises;
        selectedExercise = null; // Reset selected exercise when filter changes
        isLoading = false;
      });
    } catch (e) {
      print('Error filtering exercises: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add Personal Record',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Muscle Group Filter Dropdown
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Muscle Group',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: selectedMuscleGroupId,
                      isExpanded: true,
                      dropdownColor: Color(0xFF2A2A2A),
                      style: GoogleFonts.poppins(color: Colors.white),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'All Muscle Groups',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                        ...widget.muscleGroups.map((group) => DropdownMenuItem<int?>(
                          value: group['id'],
                          child: Text(
                            group['name'],
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedMuscleGroupId = value;
                          selectedMuscleGroupName = value == null 
                              ? 'All Muscle Groups' 
                              : widget.muscleGroups.firstWhere((g) => g['id'] == value)['name'];
                        });
                        _filterExercisesByMuscleGroup(value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Exercise Dropdown
          DropdownButtonFormField<Map<String, dynamic>>(
            value: selectedExercise,
            decoration: InputDecoration(
              labelText: 'Exercise',
              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: Color(0xFF2A2A2A),
            items: filteredExercises.map((exercise) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: exercise,
                child: Text(
                  exercise['name'].toString(),
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedExercise = value;
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Date Achieved',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            trailing: Icon(Icons.calendar_today_rounded, color: Color(0xFF4ECDC4)),
            onTap: _selectDate,
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
          onPressed: isLoading ? null : _saveRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4ECDC4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Save',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }


  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF4ECDC4),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (selectedExercise == null || weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = await EnhancedProgressService.getCurrentUserId();
      final record = PersonalRecordModel(
        userId: userId,
        exerciseId: int.parse(selectedExercise!['id'].toString()),
        maxWeight: double.parse(weightController.text),
        achievedOn: selectedDate,
      );

      final success = await EnhancedProgressService.createPersonalRecord(record);

      if (success) {
        Navigator.pop(context);
        widget.onRecordAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Personal record saved!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save record'),
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
    } finally {
      setState(() => isLoading = false);
    }
  }
}
