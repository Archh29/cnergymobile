import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/exercise_selection_model.dart';
import './services/routine_services.dart';
import 'exercise_selection_page.dart';

class MuscleGroupSelectionPage extends StatefulWidget {
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections;

  const MuscleGroupSelectionPage({
    Key? key,
    required this.selectedColor,
    this.currentSelections = const [],
  }) : super(key: key);

  @override
  _MuscleGroupSelectionPageState createState() => _MuscleGroupSelectionPageState();
}

class _MuscleGroupSelectionPageState extends State<MuscleGroupSelectionPage> {
  List<MuscleGroupModel> muscleGroups = [];
  bool isLoading = true;
  List<SelectedExerciseWithConfig> selectedExercises = [];

  @override
  void initState() {
    super.initState();
    selectedExercises = List.from(widget.currentSelections);
    _loadMuscleGroups();
  }

  Future<void> _loadMuscleGroups() async {
    try {
      setState(() => isLoading = true);
      
      final muscles = await RoutineService.fetchTargetMuscles();
      
      setState(() {
        muscleGroups = muscles.map((muscle) => 
            MuscleGroupModel.fromTargetMuscle(muscle)
        ).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load muscle groups: ${e.toString()}');
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

  int _getExerciseCountForMuscle(String muscleName) {
    return selectedExercises
        .where((exercise) => exercise.exercise.targetMuscle.toLowerCase()
            .contains(muscleName.toLowerCase()))
        .length;
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
          onPressed: () => Navigator.pop(context, selectedExercises),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Muscles',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${selectedExercises.length} exercises selected',
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
              onPressed: () => Navigator.pop(context, selectedExercises),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  color: widget.selectedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Pick the muscle groups you want to train:',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: muscleGroups.length,
                    itemBuilder: (context, index) {
                      final muscle = muscleGroups[index];
                      final exerciseCount = _getExerciseCountForMuscle(muscle.name);
                      
                      return _buildMuscleGroupCard(muscle, exerciseCount);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroupModel muscle, int exerciseCount) {
    final hasExercises = exerciseCount > 0;
    
    return GestureDetector(
      onTap: () => _navigateToExerciseSelection(muscle),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: hasExercises 
              ? Border.all(color: widget.selectedColor, width: 2)
              : Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Muscle illustration
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: muscle.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        muscle.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fitness_center,
                            color: widget.selectedColor,
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.fitness_center,
                      color: widget.selectedColor,
                      size: 30,
                    ),
            ),
            SizedBox(height: 12),
            
            // Muscle name
            Text(
              muscle.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            
            // Selection indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hasExercises 
                    ? widget.selectedColor.withOpacity(0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasExercises ? '100%' : '0%',
                style: GoogleFonts.poppins(
                  color: hasExercises ? widget.selectedColor : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToExerciseSelection(MuscleGroupModel muscle) async {
    final result = await Navigator.push<List<SelectedExerciseWithConfig>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseSelectionPage(
          muscleGroup: muscle,
          selectedColor: widget.selectedColor,
          currentSelections: selectedExercises
              .where((exercise) => exercise.exercise.targetMuscle.toLowerCase()
                  .contains(muscle.name.toLowerCase()))
              .toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // Remove existing exercises for this muscle group
        selectedExercises.removeWhere((exercise) => 
            exercise.exercise.targetMuscle.toLowerCase()
                .contains(muscle.name.toLowerCase()));
        
        // Add new selections
        selectedExercises.addAll(result);
      });
    }
  }
}
