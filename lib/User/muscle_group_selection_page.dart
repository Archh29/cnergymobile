import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/exercise_selection_model.dart';
import 'services/routine_services.dart';
import 'services/exercises_selection_service.dart'; // Corrected import
import 'services/enhanced_muscle_group_service.dart'; // New service for primary parts logic
import 'package:gym/User/exercise_selection_page.dart'; // Assuming this is the correct path to your ExerciseSelectionPage

class MuscleGroupSelectionPage extends StatefulWidget {
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections; // This is the GLOBAL list of selected exercises
  final bool isEditing;
  final dynamic existingRoutine; // RoutineModel for editing
  final bool isProMember;
  final int currentRoutineCount;

  const MuscleGroupSelectionPage({
    Key? key,
    required this.selectedColor,
    this.currentSelections = const [],
    this.isEditing = false,
    this.existingRoutine,
    this.isProMember = false,
    this.currentRoutineCount = 0,
  }) : super(key: key);

  @override
  _MuscleGroupSelectionPageState createState() => _MuscleGroupSelectionPageState();
}

class _MuscleGroupSelectionPageState extends State<MuscleGroupSelectionPage> {
  List<MuscleGroupModel> muscleGroups = [];
  List<MuscleGroupWithParts> muscleGroupsWithParts = []; // New list for primary parts logic
  bool isLoading = true;
  List<SelectedExerciseWithConfig> selectedExercises = []; // This holds the GLOBAL list of selected exercises

  @override
  void initState() {
    super.initState();
    
    if (widget.isEditing && widget.existingRoutine != null) {
      // Convert existing routine exercises to SelectedExerciseWithConfig format
      selectedExercises = _convertRoutineToSelectedExercises(widget.existingRoutine);
      print('Editing mode: Initialized with ${selectedExercises.length} exercises from existing routine');
    } else {
      selectedExercises = List.from(widget.currentSelections); // Initialize with the global list from parent
      print('Create mode: Initialized with ${selectedExercises.length} exercises');
    }
    
    for (var exercise in selectedExercises) {
      print('Exercise: ${exercise.exercise.name} - Target Muscle: "${exercise.exercise.targetMuscle}"');
    }
    _loadMuscleGroups();
  }

  List<SelectedExerciseWithConfig> _convertRoutineToSelectedExercises(dynamic routine) {
    List<SelectedExerciseWithConfig> exercises = [];
    
    // Use detailedExercises field which contains the full exercise data
    if (routine.detailedExercises != null && routine.detailedExercises is List) {
      for (var exerciseData in routine.detailedExercises) {
        try {
          // Create ExerciseSelectionModel from routine exercise data
          final exercise = ExerciseSelectionModel(
            id: int.tryParse(exerciseData['id']?.toString() ?? '0') ?? 0,
            name: exerciseData['name'] ?? 'Unknown Exercise',
            description: exerciseData['description'] ?? '',
            imageUrl: exerciseData['image_url'] ?? '',
            videoUrl: exerciseData['video_url'] ?? '',
            targetMuscle: exerciseData['target_muscle'] ?? '',
            category: exerciseData['category'] ?? 'General',
            difficulty: exerciseData['difficulty'] ?? 'Intermediate',
          );
          
          // Create set configurations from the exercise data
          List<SetConfig> setConfigs = [];
          if (exerciseData['sets'] is List) {
            // If sets is already a list of set objects
            for (int i = 0; i < exerciseData['sets'].length; i++) {
              final setData = exerciseData['sets'][i];
              setConfigs.add(SetConfig(
                setNumber: i + 1,
                reps: setData['reps']?.toString() ?? '10',
                weight: setData['weight']?.toString() ?? '0',
              ));
            }
          } else {
            // If sets is just a count, create default set configs
            final setCount = exerciseData['target_sets'] ?? exerciseData['sets'] ?? 3;
            final defaultReps = exerciseData['target_reps']?.toString() ?? exerciseData['reps']?.toString() ?? '10';
            final defaultWeight = exerciseData['target_weight']?.toString() ?? exerciseData['weight']?.toString() ?? '0';
            
            for (int i = 0; i < setCount; i++) {
              setConfigs.add(SetConfig(
                setNumber: i + 1,
                reps: defaultReps,
                weight: defaultWeight,
              ));
            }
          }
          
          // Create SelectedExerciseWithConfig
          final selectedExercise = SelectedExerciseWithConfig(
            exercise: exercise,
            sets: setConfigs.length,
            reps: exerciseData['target_reps']?.toString() ?? exerciseData['reps']?.toString() ?? '10',
            weight: exerciseData['target_weight']?.toString() ?? exerciseData['weight']?.toString() ?? '0',
            setConfigs: setConfigs,
          );
          
          exercises.add(selectedExercise);
        } catch (e) {
          print('Error converting exercise: $e');
        }
      }
    }
    
    return exercises;
  }

  Future<void> _loadMuscleGroups() async {
    try {
      setState(() => isLoading = true);

      // Load both the old format and new format
      final muscles = await RoutineService.fetchTargetMuscles();
      final musclesWithParts = await EnhancedMuscleGroupService.fetchMuscleGroupsWithParts();

      setState(() {
        muscleGroups = muscles.map((muscle) =>
            MuscleGroupModel.fromTargetMuscle(muscle)
        ).toList();
        muscleGroupsWithParts = musclesWithParts;
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

  // Helper to calculate muscle group completion percentage based on primary parts
  double _getMuscleGroupCompletionPercentage(String muscleName) {
    if (selectedExercises.isEmpty || muscleGroupsWithParts.isEmpty) return 0.0;
    
    return EnhancedMuscleGroupService.calculateMuscleGroupCompletion(
      muscleName, 
      selectedExercises, 
      muscleGroupsWithParts
    );
  }

  // Helper to get muscle parts status (hit/missed) for a muscle group
  String _getMusclePartsStatus(String muscleName) {
    if (selectedExercises.isEmpty || muscleGroupsWithParts.isEmpty) return '';
    
    final muscleGroup = muscleGroupsWithParts.firstWhere(
      (group) => group.name.toLowerCase() == muscleName.toLowerCase(),
      orElse: () => MuscleGroupWithParts(id: 0, name: '', imageUrl: '', primaryParts: []),
    );
    
    if (muscleGroup.primaryParts.isEmpty) return '';
    
    // Get all primary muscle part IDs that are being targeted
    final targetedPartIds = <int>{};
    for (var exercise in selectedExercises) {
      // Parse target muscle string to find primary parts
      final targetMuscle = exercise.exercise.targetMuscle.toLowerCase();
      for (var part in muscleGroup.primaryParts) {
        if (targetMuscle.contains(part.name.toLowerCase()) && 
            targetMuscle.contains('(primary)')) {
          targetedPartIds.add(part.id);
        }
      }
    }
    
    final hitParts = muscleGroup.primaryParts.where((part) => targetedPartIds.contains(part.id)).toList();
    final missedParts = muscleGroup.primaryParts.where((part) => !targetedPartIds.contains(part.id)).toList();
    
    String status = '';
    if (hitParts.isNotEmpty) {
      status += 'Hit: ${hitParts.map((p) => p.name).join(', ')}';
    }
    if (missedParts.isNotEmpty) {
      if (status.isNotEmpty) status += '\n';
      status += 'Missed: ${missedParts.map((p) => p.name).join(', ')}';
    }
    
    return status;
  }

  // Helper to get the percentage for a specific muscle group from the GLOBAL list
  String _getMuscleGroupPercentage(String muscleName) {
    final double percentage = _getMuscleGroupCompletionPercentage(muscleName);
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
                  'How Muscle Group Completion Works',
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
                  'Each muscle group is made up of several primary muscle parts. The percentage shows how many of these primary parts are being targeted by your selected exercises.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Only exercises that target muscles as "primary" are counted. Secondary and stabilizer muscles are ignored.',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
                        'Example: Arms Muscle Group',
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Primary Parts: Biceps, Triceps, Forearms (3 total)\n\nSelected Exercises:\n• Barbell Curl (hits Biceps)\n• Tricep Extension (hits Triceps)',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Result: 2/3 = 66.7% completion',
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
                  'The percentage shows how many primary muscle parts are being targeted within each muscle group.',
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
              widget.isEditing ? 'Edit Routine' : 'Muscles',
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
            child: Column(
              children: [
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
                      final completionPercentage = _getMuscleGroupCompletionPercentage(muscle.name);
                      final percentage = _getMuscleGroupPercentage(muscle.name);
                      return _buildMuscleGroupCard(muscle, completionPercentage, percentage);
                    },
                  ),
                ),
                // Muscle Parts Status Section
                if (selectedExercises.isNotEmpty) _buildMusclePartsStatusCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupCard(MuscleGroupModel muscle, double completionPercentage, String percentage) {
    final hasExercises = completionPercentage > 0;
    print('Building card for ${muscle.name}: completion=${completionPercentage.toStringAsFixed(1)}%, percentage=$percentage, hasExercises=$hasExercises');

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
            SizedBox(height: 8),

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
            SizedBox(height: 6),

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

  Widget _buildMusclePartsStatusCard() {
    // Get all muscle groups that have exercises
    final muscleGroupsWithExercises = muscleGroups.where((muscle) {
      final completionPercentage = _getMuscleGroupCompletionPercentage(muscle.name);
      return completionPercentage > 0;
    }).toList();

    if (muscleGroupsWithExercises.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.selectedColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: widget.selectedColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Muscle Parts Status',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...muscleGroupsWithExercises.map((muscle) {
            final musclePartsStatus = _getMusclePartsStatus(muscle.name);
            if (musclePartsStatus.isEmpty) return SizedBox.shrink();
            
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    muscle.name,
                    style: GoogleFonts.poppins(
                      color: widget.selectedColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    musclePartsStatus,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
