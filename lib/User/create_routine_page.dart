import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';
import './models/exercise_selection_model.dart';
import './services/routine_services.dart';
import './services/exercises_selection_service.dart';
import './muscle_group_selection_page.dart';

class CreateRoutinePage extends StatefulWidget {
  final bool isProMember;
  final int currentRoutineCount;
  final bool isEditing;
  final dynamic existingRoutine;

  const CreateRoutinePage({
    Key? key,
    required this.isProMember,
    required this.currentRoutineCount,
    this.isEditing = false,
    this.existingRoutine,
  }) : super(key: key);

  @override
  _CreateRoutinePageState createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
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
    
    // Populate form with existing routine data when editing
    if (widget.isEditing && widget.existingRoutine != null) {
      nameController.text = widget.existingRoutine.name ?? '';
      notesController.text = widget.existingRoutine.notes ?? '';
      selectedDifficulty = widget.existingRoutine.difficulty ?? 'Beginner';
      
      // Handle color conversion - it might be stored as int or string
      // RoutineModel.color is always a String, so we need to parse it properly
      if (widget.existingRoutine.color != null && widget.existingRoutine.color.toString().isNotEmpty) {
        try {
          String colorStr = widget.existingRoutine.color.toString().trim();
          
          if (colorStr.startsWith('0x') || colorStr.startsWith('0X')) {
            // Format: 0xFF96CEB4
            selectedColor = Color(int.parse(colorStr));
          } else if (colorStr.startsWith('#')) {
            // Format: #3B82F6 or #FF3B82F6
            String hexStr = colorStr.substring(1);
            if (hexStr.length == 6) {
              // 6-digit hex (RGB) - add alpha channel FF
              selectedColor = Color(int.parse(hexStr, radix: 16) + 0xFF000000);
            } else if (hexStr.length == 8) {
              // 8-digit hex (ARGB)
              selectedColor = Color(int.parse(hexStr, radix: 16));
            } else {
              throw FormatException('Invalid hex color length: $colorStr (expected 6 or 8 digits after #)');
            }
          } else {
            // Try parsing as integer string (format: "4280392702")
            try {
              selectedColor = Color(int.parse(colorStr));
            } catch (e) {
              // If integer parse fails, try as hex without prefix (6 or 8 digits)
              if (colorStr.length == 6 || colorStr.length == 8) {
                selectedColor = Color(int.parse(colorStr, radix: 16) + (colorStr.length == 6 ? 0xFF000000 : 0));
              } else {
                throw FormatException('Unable to parse color: $colorStr');
              }
            }
          }
        } catch (e) {
          print('❌ Error parsing routine color "${widget.existingRoutine.color}": $e');
          print('   Color string: "${widget.existingRoutine.color}"');
          selectedColor = Color(0xFF96CEB4); // Default color on error
        }
      } else {
        selectedColor = Color(0xFF96CEB4); // Default color
      }
      
      exercises = widget.existingRoutine.detailedExercises ?? [];
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
              widget.isEditing ? 'Edit Program' : 'Create New Program',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.isProMember
                  ? '✅ Premium: Unlimited programs'
                  : '⚠️ Basic: ${widget.currentRoutineCount}/1 programs used',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.isProMember ? Color(0xFF4ECDC4) : Color(0xFFFFD700),
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
          
          // Exercise count guidance
          _buildExerciseCountGuidance(),
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
                    'Use the multi-step flow to select exercises by muscle group',
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
    // Parse exercise color safely - handle hex strings with #, 0x format, or integer strings
    Color exerciseColor;
    try {
      String colorStr = exercise.color.toString().trim();
      
      if (colorStr.startsWith('0x') || colorStr.startsWith('0X')) {
        // Format: 0xFF96CEB4
        exerciseColor = Color(int.parse(colorStr));
      } else if (colorStr.startsWith('#')) {
        // Format: #3B82F6 or #FF3B82F6
        String hexStr = colorStr.substring(1);
        if (hexStr.length == 6) {
          // 6-digit hex (RGB) - add alpha channel FF
          exerciseColor = Color(int.parse(hexStr, radix: 16) + 0xFF000000);
        } else if (hexStr.length == 8) {
          // 8-digit hex (ARGB)
          exerciseColor = Color(int.parse(hexStr, radix: 16));
        } else {
          throw FormatException('Invalid hex color length: $colorStr (expected 6 or 8 digits after #)');
        }
      } else {
        // Try parsing as integer string (format: "4280392702" or "0xFF96CEB4" without 0x prefix)
        try {
          exerciseColor = Color(int.parse(colorStr));
        } catch (e) {
          // If integer parse fails, try as hex without prefix (6 or 8 digits)
          if (colorStr.length == 6 || colorStr.length == 8) {
            exerciseColor = Color(int.parse(colorStr, radix: 16) + (colorStr.length == 6 ? 0xFF000000 : 0));
          } else {
            throw FormatException('Unable to parse color: $colorStr');
          }
        }
      }
    } catch (e) {
      print('❌ Error parsing exercise color "${exercise.color}": $e');
      print('   Color string: "${exercise.color}"');
      exerciseColor = Color(0xFF96CEB4); // Default color on error
    }
        
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
            'Notes (Optional)',
            notesController,
            'Add any additional notes or instructions',
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
    ValueChanged<String?> onChanged, {
    IconData? icon,
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
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.grey[400], size: 18),
                        SizedBox(width: 8),
                      ],
                      Text(item),
                    ],
                  ),
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
                'Create Program',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // NEW METHOD: Start the multi-step exercise selection flow
  Future<void> _startExerciseSelectionFlow() async {
    try {
      // Convert current ExerciseModel list to SelectedExerciseWithConfig
      final currentSelections = ExerciseSelectionService.convertFromExerciseModels(exercises);

      final result = await Navigator.push<List<SelectedExerciseWithConfig>>(
        context,
        MaterialPageRoute(
          builder: (context) => MuscleGroupSelectionPage(
            selectedColor: selectedColor,
            currentSelections: currentSelections,
            difficulty: selectedDifficulty,
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
              '${result.length} exercises configured • Est. ${duration}min workout',
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
      _showError('Please enter a program name');
      return;
    }
    if (exercises.isEmpty) {
      _showError('Please add at least one exercise');
      return;
    }

    setState(() => isLoading = true);
    try {
      final newRoutine = RoutineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        exercises: exercises.length,
        duration: '', // Duration removed
        difficulty: selectedDifficulty,
        createdBy: 'user',
        exerciseList: exercises.map((e) => e.name).join(', '),
        color: selectedColor.value.toString(),
        lastPerformed: 'Never',
        tags: [], // Tags removed
        goal: '', // Goal removed
        completionRate: 0,
        totalSessions: 0,
        notes: notesController.text.trim(),
        scheduledDays: [], // No longer using scheduled days - will be handled by schedule page
        version: 1.0,
        detailedExercises: exercises,
      );

      final result = await RoutineService.createRoutine(newRoutine);
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Program created successfully!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'Failed to create program');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error creating program: ${e.toString()}');
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

  Widget _buildExerciseCountGuidance() {
    final exerciseCount = exercises.length;
    String guidanceText = '';
    Color guidanceColor = Colors.grey;
    IconData guidanceIcon = Icons.info_outline;
    
    if (exerciseCount == 0) {
      return SizedBox.shrink(); // Don't show guidance when no exercises
    } else if (exerciseCount < 2) {
      guidanceText = 'Consider adding more exercises to cover major muscle groups. Recommended: 3-6 exercises per session.';
      guidanceColor = Color(0xFFFFB74D); // Orange for warning
      guidanceIcon = Icons.info;
    } else if (exerciseCount >= 3 && exerciseCount <= 6) {
      guidanceText = 'Recommended: 3-6 exercises per session for most users.';
      guidanceColor = Color(0xFF4ECDC4); // Teal for good
      guidanceIcon = Icons.check_circle_outline;
    } else if (exerciseCount >= 8) {
      guidanceText = 'This is a high volume workout. Make sure to allow sufficient recovery and focus on form.';
      guidanceColor = Color(0xFFFFB74D); // Orange for warning
      guidanceIcon = Icons.warning_amber_rounded;
    } else {
      return SizedBox.shrink(); // Don't show guidance for 2 or 7 exercises (border cases)
    }
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: guidanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: guidanceColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            guidanceIcon,
            color: guidanceColor,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              guidanceText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
