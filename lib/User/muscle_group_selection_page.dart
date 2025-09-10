import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/exercise_selection_model.dart';
import 'services/routine_services.dart';
import 'services/exercises_selection_service.dart'; // Corrected import
import 'package:gym/User/exercise_selection_page.dart'; // Assuming this is the correct path to your ExerciseSelectionPage

class MuscleGroupSelectionPage extends StatefulWidget {
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections; // This is the GLOBAL list of selected exercises

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
  List<SelectedExerciseWithConfig> selectedExercises = []; // This holds the GLOBAL list of selected exercises

  @override
  void initState() {
    super.initState();
    selectedExercises = List.from(widget.currentSelections); // Initialize with the global list from parent
    print('Initialized with ${selectedExercises.length} exercises');
    for (var exercise in selectedExercises) {
      print('Exercise: ${exercise.exercise.name} - Target Muscle: "${exercise.exercise.targetMuscle}"');
    }
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

  // Helper to calculate muscle activation percentage for a specific muscle group
  double _getMuscleActivationPercentage(String muscleName) {
    if (selectedExercises.isEmpty) return 0.0;
    
    double totalActivation = 0.0;
    double muscleActivation = 0.0;
    
    for (var exercise in selectedExercises) {
      final exerciseMuscle = exercise.exercise.targetMuscle.toLowerCase().trim();
      
      // Parse muscle roles and calculate activation points
      final muscleParts = exerciseMuscle.split(',');
      
      for (var part in muscleParts) {
        final cleanPart = part.trim();
        if (cleanPart.isEmpty) continue;
        
        // Extract muscle name and role
        final muscleMatch = RegExp(r'^([^(]+)\s*\(([^)]+)\)').firstMatch(cleanPart);
        if (muscleMatch != null) {
          final muscle = muscleMatch.group(1)!.trim().toLowerCase();
          final role = muscleMatch.group(2)!.trim().toLowerCase();
          
          // Calculate activation points based on role
          double activationPoints = 0.0;
          switch (role) {
            case 'primary':
              activationPoints = 3.0;
              break;
            case 'secondary':
              activationPoints = 2.0;
              break;
            case 'stabilizer':
              activationPoints = 1.0;
              break;
            default:
              activationPoints = 1.0;
          }
          
          totalActivation += activationPoints;
          
          // Check if this muscle matches our target muscle
          if (muscle == muscleName.toLowerCase().trim()) {
            muscleActivation += activationPoints;
          }
        }
      }
    }
    
    if (totalActivation == 0) return 0.0;
    
    final percentage = (muscleActivation / totalActivation) * 100;
    print('Muscle "$muscleName": $muscleActivation/$totalActivation = ${percentage.toStringAsFixed(1)}%');
    return percentage;
  }

  // Helper to get the percentage for a specific muscle group from the GLOBAL list
  String _getMuscleGroupPercentage(String muscleName) {
    final double percentage = _getMuscleActivationPercentage(muscleName);
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Show info dialog explaining how percentages work
  void _showPercentageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'How Percentages Work',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Muscle activation is calculated based on exercise roles:',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                _buildInfoRow('Primary', '3 points', Colors.red),
                _buildInfoRow('Secondary', '2 points', Colors.orange),
                _buildInfoRow('Stabilizer', '1 point', Colors.yellow),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example: Barbell Curl',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Back (primary) = 3 points\n• Forearm (primary) = 3 points\n• Brachialis (secondary) = 2 points\n• Brachioradialis (stabilizer) = 1 point',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Total: 9 points\nBack: 3/9 = 33.3%',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'The percentage shows how much each muscle group is being worked relative to your total workout.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: GoogleFonts.poppins(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String role, String points, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Text(
            role,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            points,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
          onPressed: () => Navigator.pop(context, selectedExercises), // Return the updated GLOBAL list
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
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white70),
            onPressed: () => _showPercentageInfo(context),
            tooltip: 'How percentages work',
          ),
          if (selectedExercises.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, selectedExercises), // Return the updated GLOBAL list
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
              key: ValueKey(selectedExercises.length), // Force rebuild when exercises change
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
                print('Building card for muscle: ${muscle.name}');
                final activationPercentage = _getMuscleActivationPercentage(muscle.name);
                final percentage = _getMuscleGroupPercentage(muscle.name);
                return _buildMuscleGroupCard(muscle, activationPercentage, percentage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroupModel muscle, double activationPercentage, String percentage) {
    final hasExercises = activationPercentage > 0;
    print('Building card for ${muscle.name}: activation=${activationPercentage.toStringAsFixed(1)}%, percentage=$percentage, hasExercises=$hasExercises');

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

            // Percentage display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: hasExercises
                    ? widget.selectedColor.withOpacity(0.2)
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                percentage, // Display the calculated percentage
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
          currentSelections: selectedExercises, // IMPORTANT: Pass the GLOBAL list
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // Replace the entire global list with the updated list from ExerciseSelectionPage
        selectedExercises = result;
        print('Updated exercises list: ${selectedExercises.length} exercises');
        for (var exercise in selectedExercises) {
          print('Exercise: ${exercise.exercise.name} - Target Muscle: "${exercise.exercise.targetMuscle}"');
        }
      });
    }
  }
}
