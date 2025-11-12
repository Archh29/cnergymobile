import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/exercise_selection_model.dart';

class ExerciseConfigurationPage extends StatefulWidget {
  final List<SelectedExerciseWithConfig> exercises;
  final Color selectedColor;
  final String? difficulty; // Optional difficulty level (Beginner, Intermediate, Advanced)

  const ExerciseConfigurationPage({
    Key? key,
    required this.exercises,
    required this.selectedColor,
    this.difficulty,
  }) : super(key: key);

  @override
  _ExerciseConfigurationPageState createState() => _ExerciseConfigurationPageState();
}

class _ExerciseConfigurationPageState extends State<ExerciseConfigurationPage> {
  List<SelectedExerciseWithConfig> configuredExercises = [];
  Map<int, TextEditingController> setsControllers = {};
  Map<int, TextEditingController> repsControllers = {};
  Map<int, TextEditingController> weightControllers = {};
  Map<int, TextEditingController> restControllers = {};
  Map<String, TextEditingController> setRepsControllers = {}; // For individual set reps
  Map<String, TextEditingController> setWeightControllers = {}; // For individual set weights
  Map<int, bool> expandedExercises = {}; // Track which exercises are expanded

  @override
  void initState() {
    super.initState();
    configuredExercises = List.from(widget.exercises);
    
    // Initialize controllers
    for (var exercise in configuredExercises) {
      final id = exercise.exercise.id;
      setsControllers[id] = TextEditingController(text: exercise.sets.toString());
      repsControllers[id] = TextEditingController(text: exercise.reps);
      weightControllers[id] = TextEditingController(text: exercise.weight);
      restControllers[id] = TextEditingController(text: exercise.restTime.toString());
      
      // Initialize individual set controllers
      for (int i = 0; i < exercise.setConfigs.length; i++) {
        final setKey = '${id}_${i}';
        setRepsControllers[setKey] = TextEditingController(text: exercise.setConfigs[i].reps);
        setWeightControllers[setKey] = TextEditingController(text: exercise.setConfigs[i].weight);
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    setsControllers.values.forEach((controller) => controller.dispose());
    repsControllers.values.forEach((controller) => controller.dispose());
    weightControllers.values.forEach((controller) => controller.dispose());
    restControllers.values.forEach((controller) => controller.dispose());
    setRepsControllers.values.forEach((controller) => controller.dispose());
    setWeightControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _onSetCountChanged(int exerciseId, String newValue) {
    final newSetCount = int.tryParse(newValue) ?? 1;
    if (newSetCount < 1) return;
    
    setState(() {
      // Find the exercise and update its set count
      final exerciseIndex = configuredExercises.indexWhere((e) => e.exercise.id == exerciseId);
      if (exerciseIndex != -1) {
        final exercise = configuredExercises[exerciseIndex];
        final updatedExercise = exercise.updateSetCount(newSetCount);
        configuredExercises[exerciseIndex] = updatedExercise;
        
        // Update controllers for new sets
        for (int i = 0; i < newSetCount; i++) {
          final setKey = '${exerciseId}_${i}';
          if (!setRepsControllers.containsKey(setKey)) {
            setRepsControllers[setKey] = TextEditingController(text: updatedExercise.setConfigs[i].reps);
            setWeightControllers[setKey] = TextEditingController(text: updatedExercise.setConfigs[i].weight);
          }
        }
        
        // Clean up excess controllers
        for (int i = newSetCount; i < 10; i++) {
          final setKey = '${exerciseId}_${i}';
          setRepsControllers[setKey]?.dispose();
          setWeightControllers[setKey]?.dispose();
          setRepsControllers.remove(setKey);
          setWeightControllers.remove(setKey);
        }
      }
      
      // Update sets guidance by triggering rebuild
      // This will be handled automatically by setState
    });
  }

  void _removeExercise(int index) {
    final exerciseId = configuredExercises[index].exercise.id;
    
    setState(() {
      configuredExercises.removeAt(index);
      
      // Dispose and remove controllers
      setsControllers[exerciseId]?.dispose();
      repsControllers[exerciseId]?.dispose();
      weightControllers[exerciseId]?.dispose();
      restControllers[exerciseId]?.dispose();
      
      // Dispose and remove set controllers
      for (int i = 0; i < 10; i++) { // Clean up potential set controllers
        final setKey = '${exerciseId}_${i}';
        setRepsControllers[setKey]?.dispose();
        setWeightControllers[setKey]?.dispose();
        setRepsControllers.remove(setKey);
        setWeightControllers.remove(setKey);
      }
      
      setsControllers.remove(exerciseId);
      repsControllers.remove(exerciseId);
      weightControllers.remove(exerciseId);
      restControllers.remove(exerciseId);
      expandedExercises.remove(exerciseId);
    });
  }

  void _saveConfiguration() {
    // Update configurations from controllers
    final updatedExercises = configuredExercises.map((exercise) {
      final id = exercise.exercise.id;
      final newSetCount = int.tryParse(setsControllers[id]?.text ?? '3') ?? 3;
      
      // Update set configurations
      List<SetConfig> updatedSetConfigs = [];
      for (int i = 0; i < newSetCount; i++) {
        final setKey = '${id}_${i}';
        final reps = setRepsControllers[setKey]?.text ?? '10';
        final weight = setWeightControllers[setKey]?.text ?? '';
        
        updatedSetConfigs.add(SetConfig(
          setNumber: i + 1,
          reps: reps,
          weight: weight,
        ));
      }
      
      return exercise.copyWith(
        sets: newSetCount,
        reps: repsControllers[id]?.text ?? '10', // Keep for backward compatibility
        weight: weightControllers[id]?.text ?? '', // Keep for backward compatibility
        restTime: int.tryParse(restControllers[id]?.text ?? '60') ?? 60,
        setConfigs: updatedSetConfigs,
      );
    }).toList();

    Navigator.pop(context, updatedExercises);
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
              'Configure Exercises',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${configuredExercises.length} exercises',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.selectedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: configuredExercises.isNotEmpty ? _saveConfiguration : null,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: configuredExercises.isNotEmpty 
                    ? widget.selectedColor 
                    : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: configuredExercises.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Colors.grey[600],
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No exercises to configure',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Set the number of sets, reps, and weights for each exercise:',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: configuredExercises.length,
                    itemBuilder: (context, index) {
                      final exerciseConfig = configuredExercises[index];
                      return _buildExerciseConfigCard(exerciseConfig, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseConfigCard(SelectedExerciseWithConfig exerciseConfig, int index) {
    final exercise = exerciseConfig.exercise;
    final exerciseId = exercise.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.selectedColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: exercise.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          exercise.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.fitness_center,
                              color: widget.selectedColor,
                              size: 20,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.fitness_center,
                        color: widget.selectedColor,
                        size: 20,
                      ),
              ),
              SizedBox(width: 16),
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
                      exercise.targetMuscle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
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
          
          SizedBox(height: 20),
          
          // Compact configuration view
          _buildCompactConfiguration(exerciseId),
        ],
      ),
    );
  }

  Widget _buildCompactConfiguration(int exerciseId) {
    final isExpanded = expandedExercises[exerciseId] ?? false;
    
    return Column(
      children: [
        // Sets guidance
        _buildSetsGuidance(exerciseId),
        SizedBox(height: 8),
        
        // Compact view - always visible
        Row(
          children: [
            Expanded(
              child: _buildConfigField(
                'Sets',
                setsControllers[exerciseId]!,
                TextInputType.number,
                onChanged: (value) => _onSetCountChanged(exerciseId, value),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildConfigField(
                'Default Reps',
                repsControllers[exerciseId]!,
                TextInputType.text,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildConfigField(
                'Default Weight (kg)',
                weightControllers[exerciseId]!,
                TextInputType.text,
                isOptional: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildConfigField(
                'Rest (sec)',
                restControllers[exerciseId]!,
                TextInputType.number,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Expandable section
        Container(
          width: double.infinity,
          child: InkWell(
            onTap: () {
              setState(() {
                expandedExercises[exerciseId] = !isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF3A3A3A), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize Individual Sets',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Expandable content
        if (isExpanded) ...[
          SizedBox(height: 12),
          _buildSetConfigurations(exerciseId),
        ],
      ],
    );
  }

  Widget _buildSetConfigurations(int exerciseId) {
    final exercise = configuredExercises.firstWhere((e) => e.exercise.id == exerciseId);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Individual Set Configurations',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        ...exercise.setConfigs.asMap().entries.map((entry) {
          final setIndex = entry.key;
          final setKey = '${exerciseId}_${setIndex}';
          
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFF3A3A3A), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set ${setIndex + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSetInputField(
                        'Reps',
                        setRepsControllers[setKey]!,
                        TextInputType.text,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSetInputField(
                        'Weight (kg)',
                        setWeightControllers[setKey]!,
                        TextInputType.text,
                        isOptional: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSetInputField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isOptional ? ' (optional)' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[400],
          ),
        ),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFF3A3A3A), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    bool isOptional = false,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${isOptional ? ' (optional)' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildSetsGuidance(int exerciseId) {
    final currentSets = int.tryParse(setsControllers[exerciseId]?.text ?? '3') ?? 3;
    final difficulty = widget.difficulty ?? 'Intermediate'; // Default to Intermediate if not provided
    final isBeginner = difficulty.toLowerCase() == 'beginner';
    final isIntermediate = difficulty.toLowerCase() == 'intermediate';
    final isAdvanced = difficulty.toLowerCase() == 'advanced';
    
    String guidanceText = '';
    Color guidanceColor = Color(0xFF4ECDC4); // Default teal
    IconData guidanceIcon = Icons.info_outline;
    bool showGuidance = false;
    
    if (isBeginner) {
      // Beginners: 2-4 sets recommended
      if (currentSets < 2) {
        guidanceText = 'Recommended: 2-4 sets for beginners. Consider adding more sets.';
        guidanceColor = Color(0xFFFFB74D); // Orange
        guidanceIcon = Icons.info;
        showGuidance = true;
      } else if (currentSets >= 2 && currentSets <= 4) {
        guidanceText = 'Recommended: 2-4 sets for beginners.';
        guidanceColor = Color(0xFF4ECDC4); // Teal
        guidanceIcon = Icons.check_circle_outline;
        showGuidance = true;
      } else if (currentSets > 4) {
        guidanceText = 'This is higher than the recommended 2-4 sets for beginners. Ensure proper form and recovery.';
        guidanceColor = Color(0xFFFFB74D); // Orange
        guidanceIcon = Icons.warning_amber_rounded;
        showGuidance = true;
      }
    } else if (isIntermediate || isAdvanced) {
      // Intermediate/Advanced: 3-5 sets recommended
      if (currentSets < 3) {
        guidanceText = 'Recommended: 3-5 sets for ${difficulty.toLowerCase()} users. Consider adding more sets.';
        guidanceColor = Color(0xFFFFB74D); // Orange
        guidanceIcon = Icons.info;
        showGuidance = true;
      } else if (currentSets >= 3 && currentSets <= 5) {
        guidanceText = 'Recommended: 3-5 sets for ${difficulty.toLowerCase()} users.';
        guidanceColor = Color(0xFF4ECDC4); // Teal
        guidanceIcon = Icons.check_circle_outline;
        showGuidance = true;
      } else if (currentSets > 5) {
        guidanceText = 'This is higher than the recommended 3-5 sets for ${difficulty.toLowerCase()} users. Ensure proper recovery.';
        guidanceColor = Color(0xFFFFB74D); // Orange
        guidanceIcon = Icons.warning_amber_rounded;
        showGuidance = true;
      }
    }
    
    if (!showGuidance) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(10),
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
            size: 18,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              guidanceText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
