import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/exercise_selection_model.dart';

class ExerciseConfigurationPage extends StatefulWidget {
  final List<SelectedExerciseWithConfig> exercises;
  final Color selectedColor;

  const ExerciseConfigurationPage({
    Key? key,
    required this.exercises,
    required this.selectedColor,
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
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    setsControllers.values.forEach((controller) => controller.dispose());
    repsControllers.values.forEach((controller) => controller.dispose());
    weightControllers.values.forEach((controller) => controller.dispose());
    restControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
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
      
      setsControllers.remove(exerciseId);
      repsControllers.remove(exerciseId);
      weightControllers.remove(exerciseId);
      restControllers.remove(exerciseId);
    });
  }

  void _saveConfiguration() {
    // Update configurations from controllers
    final updatedExercises = configuredExercises.map((exercise) {
      final id = exercise.exercise.id;
      return exercise.copyWith(
        sets: int.tryParse(setsControllers[id]?.text ?? '3') ?? 3,
        reps: repsControllers[id]?.text ?? '10',
        weight: weightControllers[id]?.text ?? '',
        restTime: int.tryParse(restControllers[id]?.text ?? '60') ?? 60,
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
          
          // Configuration inputs
          Row(
            children: [
              Expanded(
                child: _buildConfigField(
                  'Sets',
                  setsControllers[exerciseId]!,
                  TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildConfigField(
                  'Reps',
                  repsControllers[exerciseId]!,
                  TextInputType.text,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildConfigField(
                  'Weight (kg)',
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
        ],
      ),
    );
  }

  Widget _buildConfigField(
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
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
}
