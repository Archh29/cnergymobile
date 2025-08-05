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
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final futures = await Future.wait([
        EnhancedProgressService.fetchPersonalRecords(),
        EnhancedProgressService.fetchExercises(),
      ]);
      
      if (mounted) {
        setState(() {
          personalRecords = futures[0] as List<PersonalRecordModel>;
          exercises = futures[1] as List<Map<String, dynamic>>;
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
                Expanded(child: _buildRecordsList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(20),
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
    return Container(
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
                Text(
                  'Achieved ${record.formattedDate}',
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
    );
  }

  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddRecordDialog(
        exercises: exercises,
        onRecordAdded: () {
          _loadData();
        },
      ),
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  final List<Map<String, dynamic>> exercises;
  final VoidCallback onRecordAdded;

  const _AddRecordDialog({
    Key? key,
    required this.exercises,
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
            items: widget.exercises.map((exercise) {
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
