import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/member_model.dart';
import 'models/routine.models.dart';
import 'services/coach_service.dart';

class CoachRoutinePage extends StatefulWidget {
  final MemberModel selectedMember;
  const CoachRoutinePage({Key? key, required this.selectedMember}) : super(key: key);

  @override
  _CoachRoutinePageState createState() => _CoachRoutinePageState();
}

class _CoachRoutinePageState extends State<CoachRoutinePage>
    with SingleTickerProviderStateMixin {
  List<RoutineModel> memberRoutines = [];
  bool isLoading = true;
  late TabController _tabController;
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemberRoutines();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberRoutines() async {
    setState(() => isLoading = true);
    
    try {
      final routines = await CoachService.getMemberRoutines(widget.selectedMember.id);
      setState(() {
        memberRoutines = routines;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading member routines: $e');
      setState(() => isLoading = false);
    }
  }

  // Helper method to convert string to RoutineDifficulty enum
  RoutineDifficulty _getDifficultyFromString(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return RoutineDifficulty.beginner;
      case 'intermediate':
        return RoutineDifficulty.intermediate;
      case 'advanced':
        return RoutineDifficulty.advanced;
      default:
        return RoutineDifficulty.beginner;
    }
  }

  void _showCreateRoutineModal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    final TextEditingController exerciseListController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedGoal = "General Fitness";
    String selectedDifficulty = "Beginner";
    List<String> selectedTags = [];
    Color selectedColor = Color(0xFF96CEB4);
    bool isCreating = false;

    final List<String> availableGoals = [
      "General Fitness", "Muscle Building", "Strength", "Fat Loss", "Endurance"
    ];

    final List<String> availableDifficulties = [
      "Beginner", "Intermediate", "Advanced"
    ];

    final List<String> availableTags = [
      "Strength", "Cardio", "HIIT", "Upper Body", "Lower Body", "Full Body", "Core"
    ];

    final List<Color> availableColors = [
      Color(0xFF96CEB4), Color(0xFF4ECDC4), Color(0xFFFF6B35),
      Color(0xFF45B7D1), Color(0xFFE74C3C), Color(0xFF9B59B6),
      Color(0xFFF39C12), Color(0xFF2ECC71)
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF4ECDC4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_circle_outline,
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
                                  'Create Routine for ${widget.selectedMember.fullName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Design a personalized workout routine',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Routine Name
                      Text(
                        'Routine Name *',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter routine name for ${widget.selectedMember.fname}',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Duration
                      Text(
                        'Duration',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: durationController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'e.g., 45 minutes',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Goal
                      Text(
                        'Goal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedGoal,
                            isExpanded: true,
                            dropdownColor: Color(0xFF2A2A2A),
                            style: GoogleFonts.poppins(color: Colors.white),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setModalState(() => selectedGoal = newValue);
                              }
                            },
                            items: availableGoals.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Difficulty
                      Text(
                        'Difficulty',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDifficulty,
                            isExpanded: true,
                            dropdownColor: Color(0xFF2A2A2A),
                            style: GoogleFonts.poppins(color: Colors.white),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setModalState(() => selectedDifficulty = newValue);
                              }
                            },
                            items: availableDifficulties.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Exercise List
                      Text(
                        'Exercise List',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: exerciseListController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter exercises separated by commas',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Tags
                      Text(
                        'Tags',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTags.map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedTags.remove(tag);
                                } else {
                                  selectedTags.add(tag);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF4ECDC4) : Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      // Color Selection
                      Text(
                        'Color Theme',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableColors.map((color) {
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),

                      // Notes
                      Text(
                        'Notes',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Additional notes or instructions...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isCreating ? null : () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isCreating ? null : () async {
                                if (nameController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter a routine name'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                setModalState(() => isCreating = true);
                                
                                try {
                                  final newRoutine = RoutineModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    name: nameController.text.trim(),
                                    exercises: exerciseListController.text.trim().split(',').where((e) => e.trim().isNotEmpty).length,
                                    duration: durationController.text.trim(),
                                    difficulty: _getDifficultyFromString(selectedDifficulty), // Fixed: Convert string to enum
                                    createdBy: 'Coach',
                                    createdDate: DateTime.now(), // Fixed: Added missing createdDate parameter
                                    exerciseList: exerciseListController.text.trim(),
                                    color: selectedColor.value.toString(),
                                    lastPerformed: 'Never',
                                    tags: selectedTags,
                                    goal: selectedGoal,
                                    completionRate: 0,
                                    totalSessions: 0,
                                    notes: notesController.text.trim(),
                                    scheduledDays: [],
                                    version: 1.0,
                                  );
                                  
                                  final success = await CoachService.createRoutineForMember(
                                    widget.selectedMember.id,
                                    newRoutine,
                                  );
                                  
                                  if (!context.mounted) return;
                                  
                                  if (success) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Routine created for ${widget.selectedMember.fname}!'),
                                        backgroundColor: Color(0xFF4ECDC4),
                                      ),
                                    );
                                    _loadMemberRoutines();
                                  } else {
                                    throw Exception('Failed to create routine');
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error creating routine: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (context.mounted) {
                                    setModalState(() => isCreating = false);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4ECDC4),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isCreating
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Create for Member',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Member Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4).withOpacity(0.1), Color(0xFF44A08D).withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
                    child: Text(
                      widget.selectedMember.initials,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4ECDC4),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.selectedMember.fullName}\'s Routines',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Manage workout routines and programs',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${memberRoutines.length} Routines',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                tabs: [
                  Tab(text: "Member's Routines"),
                  Tab(text: "Coach Templates"),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMemberRoutinesTab(),
                  _buildCoachTemplatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoutineModal,
        backgroundColor: Color(0xFF4ECDC4),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(
          "Create Routine",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMemberRoutinesTab() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading ${widget.selectedMember.fname}\'s routines...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (memberRoutines.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                color: Colors.grey[600],
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No Routines Yet',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Create the first workout routine for ${widget.selectedMember.fname}.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showCreateRoutineModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.add),
                label: Text(
                  'Create First Routine',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: memberRoutines.length,
      itemBuilder: (context, index) {
        final routine = memberRoutines[index];
        final routineColor = _getColorFromString(routine.color);
        
        return Container(
          margin: EdgeInsets.only(bottom: 20),
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
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Routine Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: routineColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: routineColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routine.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "Created by ${routine.createdBy}",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'COACH ASSIGNED',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF4ECDC4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      color: Color(0xFF2A2A2A),
                      onSelected: (value) => _handleRoutineAction(value, routine),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF4ECDC4), size: 20),
                              SizedBox(width: 8),
                              Text('Edit Routine', style: GoogleFonts.poppins(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'feedback',
                          child: Row(
                            children: [
                              Icon(Icons.feedback, color: Color(0xFF96CEB4), size: 20),
                              SizedBox(width: 8),
                              Text('Add Feedback', style: GoogleFonts.poppins(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'progress',
                          child: Row(
                            children: [
                              Icon(Icons.analytics, color: Color(0xFFFF6B35), size: 20),
                              SizedBox(width: 8),
                              Text('View Progress', style: GoogleFonts.poppins(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: Color(0xFF45B7D1), size: 20),
                              SizedBox(width: 8),
                              Text('Duplicate', style: GoogleFonts.poppins(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Tags
                if (routine.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: routine.tags.map<Widget>((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: routineColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: routineColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                SizedBox(height: 12),
                
                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(Icons.timer, routine.duration, routineColor),
                    _buildInfoChip(Icons.format_list_numbered, "${routine.exercises} exercises", routineColor),
                    _buildInfoChip(Icons.trending_up, routine.difficulty.toString().split('.').last, routineColor),
                    _buildInfoChip(Icons.flag, routine.goal, routineColor),
                  ],
                ),
                SizedBox(height: 16),
                
                // Member Progress Summary
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: routineColor, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Member Progress',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Completion Rate',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${routine.completionRate}%',
                                  style: GoogleFonts.poppins(
                                    color: routineColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sessions',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${routine.totalSessions}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Performed',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  routine.lastPerformed,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Exercise List
                Text(
                  routine.exerciseList.isEmpty ? "No exercises listed" : routine.exerciseList,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [routineColor, routineColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _viewMemberProgress(routine),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.analytics, size: 18),
                          label: Text(
                            "View Progress",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _addFeedback(routine),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.feedback, size: 18),
                          label: Text(
                            "Add Feedback",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoachTemplatesTab() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              color: Colors.grey[600],
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Coach Templates',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Browse and use pre-made routine templates to quickly assign workouts to your members.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to templates library
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.library_books),
              label: Text(
                'Browse Templates',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Color(0xFF96CEB4);
    }
  }

  void _handleRoutineAction(String action, RoutineModel routine) {
    switch (action) {
      case 'edit':
        _editRoutine(routine);
        break;
      case 'feedback':
        _addFeedback(routine);
        break;
      case 'progress':
        _viewMemberProgress(routine);
        break;
      case 'duplicate':
        _duplicateRoutine(routine);
        break;
    }
  }

  void _editRoutine(RoutineModel routine) {
    // Show edit routine dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit routine feature coming soon!'),
        backgroundColor: Color(0xFF4ECDC4),
      ),
    );
  }

  void _addFeedback(RoutineModel routine) {
    final TextEditingController feedbackController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.feedback,
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
                            'Add Feedback',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'For ${widget.selectedMember.fname}\'s ${routine.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Rating
                Text(
                  'Performance Rating',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setDialogState(() => rating = index + 1.0),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 16),
                
                // Feedback text
                TextField(
                  controller: feedbackController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your feedback for ${widget.selectedMember.fname}...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (feedbackController.text.trim().isNotEmpty) {
                            // Here you would call the API to save feedback
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Feedback added for ${widget.selectedMember.fname}!'),
                                backgroundColor: Color(0xFF4ECDC4),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewMemberProgress(RoutineModel routine) {
    // Navigate to detailed progress view for this routine
    Navigator.pushNamed(
      context,
      '/coach-routine-progress',
      arguments: {
        'member': widget.selectedMember,
        'routine': routine,
      },
    );
  }

  void _duplicateRoutine(RoutineModel routine) {
    // Create a copy of the routine
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Routine duplicated successfully!'),
        backgroundColor: Color(0xFF4ECDC4),
      ),
    );
  }
}