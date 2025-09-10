import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import './models/routine.models.dart';
import './models/exercise_selection_model.dart';
import './models/exercise_model.dart';
import './services/routine_service.dart';
import './services/exercise_selection_service.dart';
import 'coach_selection_muscle_group_page.dart';

class CoachCreateRoutinePage extends StatefulWidget {
  final MemberModel selectedClient;
  final Color selectedColor;

  const CoachCreateRoutinePage({
    Key? key,
    required this.selectedClient,
    this.selectedColor = const Color(0xFF4ECDC4),
  }) : super(key: key);

  @override
  _CoachCreateRoutinePageState createState() => _CoachCreateRoutinePageState();
}

class _CoachCreateRoutinePageState extends State<CoachCreateRoutinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
    
  String selectedGoal = "General Fitness";
  String selectedDifficulty = "Beginner";
  List<String> selectedTags = [];
  Color selectedColor = Color(0xFF96CEB4);
  List<ExerciseModel> exercises = [];
  bool isLoading = false;

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

  @override
  void initState() {
    super.initState();
    selectedColor = widget.selectedColor;
    // Pre-fill routine name with client's name
    nameController.text = "${widget.selectedClient.fname}'s Routine";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Routine',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'For ${widget.selectedClient.fullName}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: selectedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            _buildClientInfoCard(),
            SizedBox(height: 24),
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            _buildExercisesSection(),
            SizedBox(height: 24),
            _buildCustomizationSection(),
            SizedBox(height: 32),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selectedColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Client Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: selectedColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: widget.selectedClient.profileImage != null && widget.selectedClient.profileImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.network(
                      widget.selectedClient.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            widget.selectedClient.initials,
                            style: GoogleFonts.poppins(
                              color: selectedColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      widget.selectedClient.initials,
                      style: GoogleFonts.poppins(
                        color: selectedColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedClient.fullName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.selectedClient.email,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.selectedClient.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.selectedClient.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: widget.selectedClient.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.person,
            color: selectedColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
                    
          _buildInputField(
            'Routine Name *',
            nameController,
            'Enter routine name',
          ),
          SizedBox(height: 16),
                    
          _buildInputField(
            'Duration *',
            durationController,
            'e.g., 45 minutes',
          ),
          SizedBox(height: 16),
                    
          _buildDropdownField(
            'Goal *',
            selectedGoal,
            availableGoals,
            (value) => setState(() => selectedGoal = value!),
          ),
          SizedBox(height: 16),
                    
          _buildDropdownField(
            'Difficulty',
            selectedDifficulty,
            availableDifficulties,
            (value) => setState(() => selectedDifficulty = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exercises',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _startExerciseSelectionFlow,
                icon: Icon(Icons.add, color: selectedColor),
                label: Text(
                  exercises.isEmpty ? 'Add Exercises' : 'Modify Exercises',
                  style: GoogleFonts.poppins(
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
                    
          if (exercises.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center, color: Colors.grey[600], size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No exercises added yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select muscle groups and exercises for ${widget.selectedClient.fname}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...exercises.asMap().entries.map((entry) {
              int index = entry.key;
              ExerciseModel exercise = entry.value;
              return _buildExerciseCard(exercise, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseModel exercise, int index) {
    final exerciseColor = Color(int.parse(exercise.color));
        
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exerciseColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: exerciseColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${exercise.targetSets} sets × ${exercise.targetReps} reps',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    if (exercise.targetMuscle.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: exerciseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise.targetMuscle,
                          style: GoogleFonts.poppins(
                            color: exerciseColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: Icon(Icons.delete, color: Colors.red[400]),
              ),
            ],
          ),
          if (exercise.targetWeight.isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: exerciseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Target: ${exercise.targetWeight}',
                style: GoogleFonts.poppins(
                  color: exerciseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
                    
          // Tags Selection
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
                  setState(() {
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
                    color: isSelected
                        ? selectedColor.withOpacity(0.2)
                        : Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? selectedColor : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? selectedColor : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
                    
          _buildInputField(
            'Notes for ${widget.selectedClient.fname} (Optional)',
            notesController,
            'Add any specific instructions or notes for your client',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
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
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF2A2A2A),
              style: GoogleFonts.poppins(color: Colors.white),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createRoutine,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Routine for ${widget.selectedClient.fname}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Start the multi-step exercise selection flow
  Future<void> _startExerciseSelectionFlow() async {
    try {
      // Convert current ExerciseModel list to SelectedExerciseWithConfig
      final currentSelections = ExerciseSelectionService.convertFromExerciseModels(exercises);

      final result = await Navigator.push<List<SelectedExerciseWithConfig>>(context,
        MaterialPageRoute(
          builder: (context) => CoachMuscleGroupSelectionPage(
            selectedClient: widget.selectedClient,
            selectedColor: selectedColor,
            currentSelections: currentSelections,
          ),
        ),
      );

      if (result != null) {
        // Validate the configuration
        final errors = ExerciseSelectionService.validateExerciseConfiguration(result);
        
        if (errors.isNotEmpty) {
          _showError(errors.first);
          return;
        }

        // Convert back to ExerciseModel list
        final exerciseModels = ExerciseSelectionService.convertToExerciseModels(
          result,
          selectedColor,
        );

        setState(() {
          exercises = exerciseModels;
        });

        // Show success message with summary
        final duration = ExerciseSelectionService.calculateEstimatedDuration(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.length} exercises configured for ${widget.selectedClient.fname} • Est. ${duration}min workout',
            ),
            backgroundColor: selectedColor,
          ),
        );
      }
    } catch (e) {
      _showError('Error starting exercise selection: ${e.toString()}');
    }
  }

  void _removeExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
  }

  Future<void> _createRoutine() async {
    // Validation
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter a routine name');
      return;
    }
    if (durationController.text.trim().isEmpty) {
      _showError('Please enter a duration');
      return;
    }
    if (exercises.isEmpty) {
      _showError('Please add at least one exercise');
      return;
    }

    setState(() => isLoading = true);
    try {
      final success = await RoutineService.createRoutineForClient(
        routineName: nameController.text.trim(),
        clientId: widget.selectedClient.id.toString(),
        coachId: 'current_coach_id', // You'll need to pass the actual coach ID
        exercises: exercises,
        description: notesController.text.trim(),
        duration: durationController.text.trim(),
        goal: selectedGoal,
        difficulty: selectedDifficulty,
        color: selectedColor.value.toString(),
        tags: selectedTags,
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine created successfully for ${widget.selectedClient.fname}!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        throw Exception('Failed to create routine');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error creating routine: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
