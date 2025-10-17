import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import './models/exercise_selection_model.dart';
import './models/exercise_model.dart';
import './models/routine.models.dart';
import './services/routine_service.dart';
import './services/exercise_selection_service.dart';
import 'coach_selection_muscle_group_page.dart';

class CoachCreateRoutinePage extends StatefulWidget {
  final MemberModel? selectedClient;
  final Color selectedColor;
  final bool isTemplate;
  final RoutineModel? editingRoutine;

  const CoachCreateRoutinePage({
    Key? key,
    this.selectedClient,
    this.selectedColor = const Color(0xFF4ECDC4),
    this.isTemplate = false,
    this.editingRoutine,
  }) : super(key: key);

  @override
  _CoachCreateRoutinePageState createState() => _CoachCreateRoutinePageState();
}

class _CoachCreateRoutinePageState extends State<CoachCreateRoutinePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
    
  String selectedDifficulty = "Beginner";
  Color selectedColor = Color(0xFF96CEB4);
  List<ExerciseModel> exercises = [];
  bool isLoading = false;

  final List<String> availableDifficulties = [
    "Beginner", "Intermediate", "Advanced"
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
    
    // If editing an existing routine, populate the form with existing data
    if (widget.editingRoutine != null) {
      nameController.text = widget.editingRoutine!.name;
      notesController.text = widget.editingRoutine!.notes;
      selectedDifficulty = widget.editingRoutine!.difficultyText;
      
      // Parse the color from the routine
      try {
        if (widget.editingRoutine!.color.isNotEmpty) {
          selectedColor = Color(int.parse(widget.editingRoutine!.color));
        }
      } catch (e) {
        print('Error parsing routine color: ${widget.editingRoutine!.color}');
      }
      
      // Parse exercises from the routine
      print('🔍 DEBUG: Editing routine - Name: ${widget.editingRoutine!.name}');
      print('🔍 DEBUG: Detailed exercises: ${widget.editingRoutine!.detailedExercises?.length ?? 0}');
      print('🔍 DEBUG: Exercise list string: "${widget.editingRoutine!.exerciseList}"');
      
      if (widget.editingRoutine!.detailedExercises != null && widget.editingRoutine!.detailedExercises!.isNotEmpty) {
        // The detailedExercises are already ExerciseModel objects
        exercises = List<ExerciseModel>.from(widget.editingRoutine!.detailedExercises!);
        print('✅ DEBUG: Loaded ${exercises.length} exercises from detailedExercises');
        print('✅ DEBUG: First exercise: ${exercises.isNotEmpty ? exercises.first.name : 'None'}');
      } else if (widget.editingRoutine!.exerciseList.isNotEmpty) {
        // Fallback: parse from exercise list string
        exercises = _parseExercisesFromString(widget.editingRoutine!.exerciseList);
        print('✅ DEBUG: Loaded ${exercises.length} exercises from exerciseList string');
      } else {
        print('⚠️ DEBUG: No exercises found in routine data');
        print('⚠️ DEBUG: detailedExercises: ${widget.editingRoutine!.detailedExercises}');
        print('⚠️ DEBUG: exerciseList: "${widget.editingRoutine!.exerciseList}"');
        // Create a default exercise if none exist
        exercises = [
          ExerciseModel(
            id: 1,
            name: 'Sample Exercise',
            targetMuscle: 'General',
            color: selectedColor.value.toString(),
            restTime: 60,
            targetReps: '10',
            targetSets: 3,
            targetWeight: '0',
            category: 'Strength',
            difficulty: 'Beginner',
          )
        ];
        print('✅ DEBUG: Created default exercise');
      }
    } else {
      // Pre-fill routine name based on whether it's a template or for a specific client
      if (widget.isTemplate) {
        nameController.text = "My Workout Template";
      } else if (widget.selectedClient != null) {
        nameController.text = "${widget.selectedClient!.fname}'s Program";
      } else {
        nameController.text = "New Program";
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editingRoutine != null 
                  ? 'Edit Program' 
                  : widget.isTemplate ? 'Create Template' : 'Create Program',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.editingRoutine != null
                  ? 'Update ${widget.editingRoutine!.name}'
                  : widget.isTemplate 
                      ? 'Create a reusable workout template'
                      : 'For ${widget.selectedClient?.fullName ?? 'Client'}',
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
            child: widget.selectedClient?.profileImage != null && widget.selectedClient!.profileImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Image.network(
                      widget.selectedClient!.profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            widget.selectedClient?.initials ?? 'T',
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
                      widget.selectedClient?.initials ?? 'T',
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
                  widget.selectedClient?.fullName ?? 'Template',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.selectedClient?.email ?? 'template@example.com',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (widget.selectedClient?.statusColor ?? Colors.green).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (widget.selectedClient?.status ?? 'TEMPLATE').toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: widget.selectedClient?.statusColor ?? Colors.green,
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
            'Program Name *',
            nameController,
            'Enter program name',
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
              ElevatedButton.icon(
                onPressed: _startExerciseSelectionFlow,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  exercises.isEmpty ? 'Add Exercises' : 'Modify Exercises',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    'Select muscle groups and exercises for ${widget.selectedClient?.fname ?? 'this template'}',
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
    print('🏋️ DEBUG: Building exercise card $index: ${exercise.name}');
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
          
          // Training day selection removed - now handled by schedule page
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
            'Notes for ${widget.selectedClient?.fname ?? 'this template'} (Optional)',
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
                widget.editingRoutine != null 
                    ? 'Update Program'
                    : widget.isTemplate ? 'Create Template' : 'Create Program for ${widget.selectedClient?.fname ?? 'Client'}',
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
            selectedClient: widget.selectedClient ?? MemberModel(
              id: 0,
              firstName: 'Template',
              lastName: 'User',
              email: 'template@example.com',
              phone: '',
              profileImage: null,
              status: 'active',
            ),
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
              '${result.length} exercises configured for ${widget.selectedClient?.fname ?? 'this template'} • Est. ${duration}min workout',
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
      _showError('Please enter a ${widget.isTemplate ? 'template' : 'program'} name');
      return;
    }
    if (exercises.isEmpty) {
      _showError('Please add at least one exercise');
      return;
    }

    setState(() => isLoading = true);
    try {
      bool success;
      
      if (widget.editingRoutine != null) {
        // Update existing routine
        print('🔄 DEBUG: Updating routine ${widget.editingRoutine!.id}');
        print('📝 DEBUG: Routine name: ${nameController.text.trim()}');
        print('📝 DEBUG: Number of exercises: ${exercises.length}');
        for (int i = 0; i < exercises.length; i++) {
          print('🏋️ DEBUG: Exercise $i: ${exercises[i].name} (${exercises[i].targetSets} sets, ${exercises[i].targetReps} reps)');
        }
        
        final updates = {
          'name': nameController.text.trim(),
          'notes': notesController.text.trim(),
          'difficulty': selectedDifficulty,
          'color': selectedColor.value.toString(),
          'exercises': exercises.map((exercise) => {
            'id': exercise.id,
            'name': exercise.name,
            'reps': exercise.targetReps,
            'sets': exercise.targetSets,
            'weight': exercise.targetWeight,
          }).toList(),
        };
        
        print('📤 DEBUG: Sending updates: $updates');
        success = await RoutineService.updateRoutine(
          widget.editingRoutine!.id,
          updates,
        );
        print('✅ DEBUG: Update result: $success');
      } else if (widget.isTemplate) {
        // Create template
        success = await RoutineService.createCoachTemplate(
          templateName: nameController.text.trim(),
          coachId: 'current_coach_id',
          exercises: exercises,
          description: notesController.text.trim(),
          duration: '30',
          goal: 'General Fitness',
          difficulty: selectedDifficulty,
          color: selectedColor.value.toString(),
          tags: [],
          notes: notesController.text.trim(),
        );
      } else {
        // Create routine for client
        if (widget.selectedClient == null) {
          _showError('No client selected');
          return;
        }
        
        success = await RoutineService.createRoutineForClient(
          routineName: nameController.text.trim(),
          clientId: widget.selectedClient!.id.toString(),
          coachId: 'current_coach_id',
          exercises: exercises,
          description: notesController.text.trim(),
          duration: '30',
          goal: 'General Fitness',
          difficulty: selectedDifficulty,
          color: selectedColor.value.toString(),
          tags: [],
          notes: notesController.text.trim(),
          scheduledDays: [], // No longer using scheduled days - will be handled by schedule page
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingRoutine != null
                ? 'Routine updated successfully!'
                : widget.isTemplate 
                    ? 'Template created successfully!' 
                    : 'Routine created successfully for ${widget.selectedClient!.fname}!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        throw Exception('Failed to ${widget.editingRoutine != null ? 'update' : 'create'} ${widget.isTemplate ? 'template' : 'routine'}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error ${widget.editingRoutine != null ? 'updating' : 'creating'} ${widget.isTemplate ? 'template' : 'routine'}: ${e.toString()}');
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

  // Helper method to parse exercises from string
  List<ExerciseModel> _parseExercisesFromString(String exerciseList) {
    if (exerciseList.isEmpty) return [];
    
    final exerciseNames = exerciseList.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final exercises = <ExerciseModel>[];
    
    for (int i = 0; i < exerciseNames.length; i++) {
      exercises.add(ExerciseModel(
        id: i + 1,
        name: exerciseNames[i],
        targetMuscle: 'General',
        color: selectedColor.value.toString(),
        restTime: 60,
        targetReps: '10',
        targetSets: 3,
        targetWeight: '0',
        category: 'Strength',
        difficulty: 'Beginner',
      ));
    }
    
    return exercises;
  }
}
