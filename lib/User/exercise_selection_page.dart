import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/exercise_selection_model.dart'; // Corrected import
import 'services/routine_services.dart'; // Corrected import
import 'services/exercises_selection_service.dart'; // Corrected import: changed 'exercises_selection_service.dart' to 'exercise_selection_service.dart'
import 'exercise_configuration_page.dart'; // Corrected import

class ExerciseSelectionPage extends StatefulWidget {
  final MuscleGroupModel muscleGroup;
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections; // This should be the GLOBAL list of selected exercises

  const ExerciseSelectionPage({
    Key? key,
    required this.muscleGroup,
    required this.selectedColor,
    this.currentSelections = const [],
  }) : super(key: key);

  @override
  _ExerciseSelectionPageState createState() => _ExerciseSelectionPageState();
}

class _ExerciseSelectionPageState extends State<ExerciseSelectionPage> {
  List<ExerciseSelectionModel> exercises = []; // Exercises for the current muscle group being displayed
  List<ExerciseSelectionModel> selectedExercises = []; // This must hold ALL selected exercises for the entire routine
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize selectedExercises from the GLOBAL list passed via widget.currentSelections
    selectedExercises = widget.currentSelections
        .map((config) => config.exercise)
        .toList();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() => isLoading = true);

      final exerciseModels = await RoutineService.fetchExercisesByMuscle(widget.muscleGroup.id);

      setState(() {
        exercises = exerciseModels.map((exercise) => ExerciseSelectionModel(
          id: exercise.id ?? 0,
          name: exercise.name,
          description: exercise.description,
          imageUrl: exercise.imageUrl,
          targetMuscle: exercise.targetMuscle,
          category: exercise.category,
          difficulty: exercise.difficulty,
          // Check if this exercise is in the GLOBAL selectedExercises list
          isSelected: selectedExercises.any((selected) => selected.id == exercise.id),
        )).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load exercises: ${e.toString()}');
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

  List<ExerciseSelectionModel> get filteredExercises {
    if (searchQuery.isEmpty) return exercises;
    return exercises.where((exercise) =>
        exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        exercise.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  void _toggleExerciseSelection(ExerciseSelectionModel exercise) {
    setState(() {
      if (selectedExercises.any((selected) => selected.id == exercise.id)) {
        selectedExercises.removeWhere((selected) => selected.id == exercise.id);
      } else {
        selectedExercises.add(exercise);
      }
      // Update the 'exercises' list (which is the source for filteredExercises)
      // to reflect the selection state for the UI checkmark.
      exercises = exercises.map((ex) =>
          ex.id == exercise.id
              ? ex.copyWith(isSelected: !ex.isSelected)
              : ex
      ).toList();
    });
  }

  // This method correctly calculates percentages based on the content of 'selectedExercises'
  String _getMuscleGroupPercentages() {
    if (selectedExercises.isEmpty) {
      return '0 selected';
    }

    // Convert ExerciseSelectionModel list to SelectedExerciseWithConfig list for the service method
    // We only need the exercise property for targetMuscle, so default config values are fine.
    final List<SelectedExerciseWithConfig> allSelectedConfigs = selectedExercises.map((exerciseModel) {
      return SelectedExerciseWithConfig(exercise: exerciseModel);
    }).toList();

    final Map<String, int> counts = ExerciseSelectionService.getExerciseCountByMuscle(allSelectedConfigs);

    final int totalSelected = selectedExercises.length; // This is the total count of ALL selected exercises
    if (totalSelected == 0) return '0 selected';

    final List<String> percentageStrings = [];
    counts.forEach((muscle, count) {
      final double percentage = (count / totalSelected) * 100; // Percentage is calculated against totalSelected
      percentageStrings.add('${muscle}: ${percentage.toStringAsFixed(0)}%');
    });

    return '${percentageStrings.join(', ')} (${totalSelected} selected)';
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
          // IMPORTANT: Return the updated GLOBAL list when going back
          onPressed: () => Navigator.pop(context, selectedExercises.map((e) => SelectedExerciseWithConfig(exercise: e)).toList()),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.muscleGroup.name} Exercises',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _getMuscleGroupPercentages(), // This will now show global percentages
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.selectedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (selectedExercises.isNotEmpty)
            TextButton(
              onPressed: _proceedToConfiguration,
              child: Text(
                'Next',
                style: GoogleFonts.poppins(
                  color: widget.selectedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(20),
            child: TextField(
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),

          // Exercise list
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
              ),
            )
                : filteredExercises.isEmpty
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
                    'No exercises found',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseSelectionModel exercise) {
    final isSelected = selectedExercises.any((selected) => selected.id == exercise.id);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: widget.selectedColor, width: 2)
            : Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleExerciseSelection(exercise),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise image with improved handling
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildExerciseImage(exercise),
                ),
                SizedBox(width: 16),

                // Exercise details
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
                      if (exercise.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          exercise.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.selectedColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.difficulty,
                              style: GoogleFonts.poppins(
                                color: widget.selectedColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise.category,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? widget.selectedColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? widget.selectedColor : Colors.grey[600]!,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New method to handle image display logic
  Widget _buildExerciseImage(ExerciseSelectionModel exercise) {
    // Check if image URL exists and is not empty
    if (exercise.imageUrl == null ||
        exercise.imageUrl!.isEmpty ||
        exercise.imageUrl!.trim().isEmpty) {
      // No image URL - show stock icon
      return _buildStockIcon();
    }

    // Image URL exists - try to load it
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        exercise.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Image loaded successfully
            return child;
          }
          // Show loading indicator
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Image failed to load (CORS, 404, etc.) - show stock icon
          print('❌ Failed to load image for ${exercise.name}: $error');
          return _buildStockIcon();
        },
      ),
    );
  }

  // Stock icon widget
  Widget _buildStockIcon() {
    return Center(
      child: Icon(
        Icons.fitness_center,
        color: widget.selectedColor,
        size: 24,
      ),
    );
  }

  Future<void> _proceedToConfiguration() async {
    if (selectedExercises.isEmpty) return;
    // Convert to SelectedExerciseWithConfig with default values
    final exercisesWithConfig = selectedExercises.map((exercise) {
      // Check if we already have configuration for this exercise
      final existingConfig = widget.currentSelections
          .where((config) => config.exercise.id == exercise.id)
          .firstOrNull;

      return existingConfig ?? SelectedExerciseWithConfig(exercise: exercise);
    }).toList();

    final result = await Navigator.push<List<SelectedExerciseWithConfig>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseConfigurationPage(
          exercises: exercisesWithConfig,
          selectedColor: widget.selectedColor,
        ),
      ),
    );

    if (result != null) {
      // Merge the newly configured exercises with existing exercises from other muscle groups
      final existingExercisesFromOtherMuscles = widget.currentSelections
          .where((config) => config.exercise.targetMuscle.toLowerCase() != widget.muscleGroup.name.toLowerCase())
          .toList();
      
      final mergedExercises = [...existingExercisesFromOtherMuscles, ...result];
      
      print('Merging exercises: ${existingExercisesFromOtherMuscles.length} existing + ${result.length} new = ${mergedExercises.length} total');
      for (var exercise in mergedExercises) {
        print('Merged exercise: ${exercise.exercise.name} - Target Muscle: "${exercise.exercise.targetMuscle}"');
      }
      
      // When returning from configuration, update the global list and pop back
      Navigator.pop(context, mergedExercises);
    }
  }
}
