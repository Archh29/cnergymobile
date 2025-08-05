import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/routine.models.dart';
import '../models/exercise_selection_model.dart';
import '../muscle_group_selection_page.dart';
import '../services/exercises_selection_service.dart';

class ExerciseSelectionFlowButton extends StatelessWidget {
  final Color selectedColor;
  final List<ExerciseModel> currentExercises;
  final Function(List<ExerciseModel>) onExercisesSelected;

  const ExerciseSelectionFlowButton({
    Key? key,
    required this.selectedColor,
    required this.currentExercises,
    required this.onExercisesSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _startExerciseSelectionFlow(context),
      icon: Icon(Icons.add, color: selectedColor),
      label: Text(
        currentExercises.isEmpty ? 'Add Exercises' : 'Modify Exercises',
        style: GoogleFonts.poppins(
          color: selectedColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _startExerciseSelectionFlow(BuildContext context) async {
    try {
      // Convert current ExerciseModel list to SelectedExerciseWithConfig
      final currentSelections = currentExercises.map((exercise) {
        return SelectedExerciseWithConfig(
          exercise: ExerciseSelectionModel(
            id: exercise.id ?? 0,
            name: exercise.name,
            description: exercise.description ?? '', // Handle null with default
            imageUrl: exercise.imageUrl ?? '', // Handle null with default
            targetMuscle: exercise.targetMuscle ?? '', // Handle null with default
            category: exercise.category ?? 'General', // Handle null with default
            difficulty: exercise.difficulty ?? 'Intermediate', // Handle null with default
          ),
          sets: exercise.targetSets,
          reps: exercise.targetReps,
          weight: exercise.targetWeight,
          restTime: exercise.restTime,
          notes: exercise.notes ?? '', // Handle null with default
        );
      }).toList();

      final result = await Navigator.push<List<SelectedExerciseWithConfig>>(
        context,
        MaterialPageRoute(
          builder: (context) => MuscleGroupSelectionPage(
            selectedColor: selectedColor,
            currentSelections: currentSelections,
          ),
        ),
      );

      if (result != null) {
        // Validate the configuration
        final errors = ExerciseSelectionService.validateExerciseConfiguration(result);
        
        if (errors.isNotEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errors.first),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Convert back to ExerciseModel list
        final exerciseModels = ExerciseSelectionService.convertToExerciseModels(
          result,
          selectedColor,
        );

        onExercisesSelected(exerciseModels);

        // Show success message with summary
        final duration = ExerciseSelectionService.calculateEstimatedDuration(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${result.length} exercises added • Est. ${duration}min workout',
              ),
              backgroundColor: selectedColor,
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors that might occur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
