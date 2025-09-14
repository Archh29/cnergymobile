import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/exercise_model.dart' as exercise_model;
import './models/exercise_selection_model.dart';
import './models/member_model.dart'; 
import './services/routine_service.dart';
import './services/exercise_selection_service.dart';
import 'coach_exercise_selection_page.dart';

class CoachMuscleGroupSelectionPage extends StatefulWidget {
  final MemberModel selectedClient;
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections;

  const CoachMuscleGroupSelectionPage({
    Key? key,
    required this.selectedClient,
    required this.selectedColor,
    this.currentSelections = const [],
  }) : super(key: key);

  @override
  _CoachMuscleGroupSelectionPageState createState() => _CoachMuscleGroupSelectionPageState();
}

class _CoachMuscleGroupSelectionPageState extends State<CoachMuscleGroupSelectionPage> {
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

      print('🔍 Loading muscle groups for coach routine creation');
      final List<exercise_model.TargetMuscleModel> muscles = await RoutineService.fetchMuscleGroups();
      print('📋 Loaded ${muscles.length} muscle groups');

      setState(() {
        muscleGroups = muscles.map((muscle) {
          print('💪 Muscle Group: ${muscle.name} - ID: ${muscle.id}');
          return MuscleGroupModel.fromTargetMuscle(TargetMuscleModel(
            id: muscle.id,
            name: muscle.name,
            description: muscle.name,
            imageUrl: muscle.imageUrl,
          ));
        }).toList();
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

  // Helper to get the count of exercises for a specific muscle group from the GLOBAL list
  int _getExerciseCountForMuscle(String muscleName) {
    return selectedExercises
        .where((exercise) => exercise.exercise.targetMuscle.toLowerCase() == muscleName.toLowerCase())
        .length;
  }

  // Helper to get the percentage for a specific muscle group from the GLOBAL list
  String _getMuscleGroupPercentage(String muscleName) {
    if (selectedExercises.isEmpty) {
      return '0%';
    }
    final int count = _getExerciseCountForMuscle(muscleName);
    final int totalSelected = selectedExercises.length;
    final double percentage = (count / totalSelected) * 100;
    return '${percentage.toStringAsFixed(0)}%';
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
              'Muscle Groups',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Creating routine for ${widget.selectedClient.fullName}',
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
          // Client Info Header
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.selectedColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                // Client Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.selectedColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.selectedClient.initials,
                      style: GoogleFonts.poppins(
                        color: widget.selectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedClient.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${selectedExercises.length} exercises selected',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.fitness_center,
                  color: widget.selectedColor,
                  size: 20,
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select muscle groups to train:',
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 16),

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
                final percentage = _getMuscleGroupPercentage(muscle.name);
                return _buildMuscleGroupCard(muscle, exerciseCount, percentage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroupModel muscle, int exerciseCount, String percentage) {
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

            // Exercise count and percentage
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasExercises
                    ? widget.selectedColor.withOpacity(0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasExercises ? '$exerciseCount exercises' : 'Add exercises',
                style: GoogleFonts.poppins(
                  color: hasExercises ? widget.selectedColor : Colors.grey[400],
                  fontSize: 10,
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
        builder: (context) => CoachExerciseSelectionPage(
          selectedClient: widget.selectedClient,
          muscleGroup: muscle,
          selectedColor: widget.selectedColor,
          currentSelections: selectedExercises,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedExercises = result;
      });
    }
  }
}
