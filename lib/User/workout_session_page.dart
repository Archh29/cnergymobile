import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/workout_preview_service.dart';
import './exercise_instructions_page.dart';
import './exercise_selection_modal.dart';
import '../utils/error_handler.dart';

class WorkoutSessionPage extends StatefulWidget {
  final RoutineModel routine;
  final List<ExerciseModel> exercises;

  const WorkoutSessionPage({
    Key? key,
    required this.routine,
    required this.exercises,
  }) : super(key: key);

  @override
  _WorkoutSessionPageState createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  int currentExerciseIndex = 0;
  int currentSetIndex = 0;
  bool isWorkoutStarted = true;
  bool isWorkoutPaused = false;
  bool isWorkoutCompleted = false;
  bool showRestTimer = false;
  
  bool isTimerRunning = false;
  Timer? restTimer;
  int restTimeRemaining = 120;
  int customRestTime = 120;
  bool useCustomTimer = false;
  
  List<WorkoutExerciseModel> workoutExercises = [];
  DateTime workoutStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    try {
      _initializeWorkout();
    } catch (e) {
      print('❌ WorkoutSessionPage: Initialization error: $e');
    }
  }

  void _initializeWorkout() {
    print('🔍 WorkoutSessionPage: Initializing workout...');
    workoutStartTime = DateTime.now();
    
    if (widget.exercises.isEmpty) {
      workoutExercises = [];
      currentSetIndex = 0;
      return;
    }
    
    workoutExercises = widget.exercises.where((exercise) => exercise != null).map((exercise) {
      try {
        print('🔍 Processing exercise: ${exercise.name}');
        print('  - exercise.sets: ${exercise.sets}');
        print('  - exercise.sets length: ${exercise.sets?.length}');
        print('  - exercise.targetReps: ${exercise.targetReps}');
        print('  - exercise.targetWeight: ${exercise.targetWeight}');
        
        // Get the first set's reps as default, or use targetReps as fallback
        String defaultReps = '10';
        double defaultWeight = 0.0;
        List<WorkoutSetModel>? targetSets;
        
        if (exercise.sets != null && exercise.sets!.isNotEmpty) {
          print('  - Using exercise.sets for targetSets');
          // Convert ExerciseSet to WorkoutSetModel for target sets
          targetSets = exercise.sets!.map((set) => WorkoutSetModel(
            reps: int.tryParse(set.reps) ?? 0,
            weight: double.tryParse(set.weight) ?? 0.0,
            timestamp: set.timestamp,
            isCompleted: false,
          )).toList();
          
          // Use the first set's configuration as default
          defaultReps = exercise.sets![0].reps;
          defaultWeight = double.tryParse(exercise.sets![0].weight) ?? 0.0;
          print('  - targetSets created: ${targetSets.length} sets');
          print('  - First set: ${targetSets[0].reps} reps, ${targetSets[0].weight} weight');
        } else {
          print('  - Using fallback values');
          // Fallback to target values
          defaultReps = exercise.targetReps ?? '10';
          defaultWeight = double.tryParse(exercise.targetWeight?.toString() ?? '0') ?? 0.0;
        }
        
        return WorkoutExerciseModel(
          exerciseId: exercise.id ?? 0,
          name: exercise.name ?? 'Unknown Exercise',
          sets: exercise.targetSets ?? 1,
          reps: defaultReps,
          weight: defaultWeight,
          category: exercise.category ?? 'General',
          difficulty: exercise.difficulty ?? 'Beginner',
          restTime: exercise.restTime ?? 60,
          targetMuscle: exercise.targetMuscle ?? 'General',
          description: exercise.description ?? '',
          imageUrl: exercise.imageUrl ?? '',
          completedSets: 0,
          isCompleted: false,
          targetSets: targetSets,
        );
      } catch (e) {
        print('❌ Error processing exercise: $e');
        return WorkoutExerciseModel(
          exerciseId: 0,
          name: 'Unknown Exercise',
          sets: 1,
          reps: '10',
          weight: 0.0,
          category: 'General',
          difficulty: 'Beginner',
          restTime: 60,
          targetMuscle: 'General',
          description: '',
          imageUrl: '',
          completedSets: 0,
          isCompleted: false,
        );
      }
    }).toList();
        
    if (workoutExercises.isNotEmpty) {
      currentSetIndex = workoutExercises[currentExerciseIndex].completedSets;
    }
    print('✅ WorkoutSessionPage: Workout initialized with ${workoutExercises.length} exercises');
  }

  void _logSet(int setIndex, String reps, String weight) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    if (setIndex >= currentExercise.sets) return;

    if (!mounted) return;
    setState(() {
      int repsInt = int.tryParse(reps) ?? 0;
      double weightDouble = double.tryParse(weight) ?? 0.0;
            
      final newSet = WorkoutSetModel(
        reps: repsInt,
        weight: weightDouble,
        timestamp: DateTime.now(),
        isCompleted: true,
      );

      if (setIndex >= currentExercise.loggedSets.length) {
        currentExercise.loggedSets.add(newSet);
        currentExercise.completedSets++;
      } else {
        currentExercise.loggedSets[setIndex] = newSet;
      }
            
      currentSetIndex = currentExercise.completedSets;
    });

    if (currentExercise.completedSets >= currentExercise.sets) {
      currentExercise.isCompleted = true;
      _showExerciseCompletedModal();
    } else {
      if (!mounted) return;
      setState(() {
        showRestTimer = true;
      });
      _startRestTimer();
    }
  }

  void _navigateToInstructions() {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
        
    final exerciseModel = ExerciseModel(
      id: currentExercise.exerciseId,
      name: currentExercise.name,
      targetSets: currentExercise.sets,
      targetReps: currentExercise.reps,
      targetWeight: currentExercise.formattedWeight,
      category: currentExercise.category,
      difficulty: currentExercise.difficulty,
      color: '0xFF4ECDC4',
      restTime: currentExercise.restTime,
      targetMuscle: currentExercise.targetMuscle,
      description: currentExercise.description,
      imageUrl: currentExercise.imageUrl,
    );
        
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseInstructionsPage(
          exercise: exerciseModel,
        ),
      ),
    );
  }

  void _showTimerSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TimerSettingsModal(
        currentRestTime: restTimeRemaining,
        useCustomTimer: useCustomTimer,
        onSave: (newRestTime, useCustom) {
          if (!mounted) return;
          setState(() {
            restTimeRemaining = newRestTime;
            useCustomTimer = true; // Always set to true when user adjusts timer
            customRestTime = newRestTime; // Always update custom time
            print('Timer saved: ${newRestTime}s (useCustomTimer: true, customRestTime: $customRestTime)');
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _startRestTimer() {
    if (!mounted) return;
    setState(() {
      isTimerRunning = true;
      // Reset timer to the current custom value when starting
      restTimeRemaining = useCustomTimer ? customRestTime : 120;
      print('Starting timer: ${restTimeRemaining}s (useCustomTimer: $useCustomTimer, customRestTime: $customRestTime)');
    });
    restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (restTimeRemaining > 0) {
        setState(() {
          restTimeRemaining--;
        });
      } else {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          isTimerRunning = false;
          restTimeRemaining = useCustomTimer ? customRestTime : 120;
          showRestTimer = false;
        });
        // Show rest complete alert
        _showRestCompleteAlert();
      }
    });
  }

  void _stopRestTimer() {
    restTimer?.cancel();
    if (!mounted) return;
    setState(() {
      isTimerRunning = false;
      restTimeRemaining = useCustomTimer ? customRestTime : 120;
      showRestTimer = false;
    });
  }

  void _adjustTimer(int seconds) {
    if (!mounted) return;
    setState(() {
      restTimeRemaining = (restTimeRemaining + seconds).clamp(0, 600);
    });
  }

  void _showSetInputModal(int setIndex) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    final originalExercise = widget.exercises[currentExerciseIndex];
    final TextEditingController repsController = TextEditingController();
    final TextEditingController weightController = TextEditingController();

    if (setIndex < currentExercise.loggedSets.length) {
      // Use logged set data if available
      repsController.text = currentExercise.loggedSets[setIndex].reps.toString();
      weightController.text = currentExercise.loggedSets[setIndex].weight.toString();
    } else {
      // Use the configured reps/weight for this specific set
      String targetReps = currentExercise.reps;
      String targetWeight = currentExercise.weight.toString();
      
      // Get the specific set configuration from targetSets if available
      print('🔍 Set Input Modal for Set ${setIndex + 1}:');
      print('  - currentExercise.targetSets: ${currentExercise.targetSets}');
      print('  - currentExercise.targetSets length: ${currentExercise.targetSets?.length}');
      if (currentExercise.targetSets != null) {
        for (int i = 0; i < currentExercise.targetSets!.length; i++) {
          print('    - Set $i: ${currentExercise.targetSets![i].reps} reps, ${currentExercise.targetSets![i].weight} weight');
        }
      }
      print('  - originalExercise.sets: ${originalExercise.sets}');
      print('  - originalExercise.sets length: ${originalExercise.sets?.length}');
      if (originalExercise.sets != null) {
        for (int i = 0; i < originalExercise.sets!.length; i++) {
          print('    - Set $i: ${originalExercise.sets![i].reps} reps, ${originalExercise.sets![i].weight} weight');
        }
      }
      
      if (currentExercise.targetSets != null && setIndex < currentExercise.targetSets!.length) {
        targetReps = currentExercise.targetSets![setIndex].reps.toString();
        targetWeight = currentExercise.targetSets![setIndex].weight.toString();
        print('  - Using currentExercise.targetSets: $targetReps reps, $targetWeight weight');
      } else if (originalExercise.sets != null && setIndex < originalExercise.sets!.length) {
        // Fallback to original exercise sets
        targetReps = originalExercise.sets![setIndex].reps;
        targetWeight = originalExercise.sets![setIndex].weight;
        print('  - Using originalExercise.sets: $targetReps reps, $targetWeight weight');
      } else {
        print('  - Using default values: $targetReps reps, $targetWeight weight');
      }
      
      repsController.text = targetReps;
      weightController.text = targetWeight;
      print('  - Set text controllers: repsController="${repsController.text}", weightController="${weightController.text}"');
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set ${setIndex + 1}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField('REPS', repsController, currentExercise.reps),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField('WEIGHT', weightController, currentExercise.weight.toString()),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _logSet(setIndex, repsController.text, weightController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'LOG SET',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExerciseCompletedModal() {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseSelectionModal(
        exerciseName: currentExercise.name,
        exerciseColor: Color(0xFF4ECDC4),
        workoutExercises: workoutExercises,
        currentExerciseIndex: currentExerciseIndex,
        onExerciseSelected: (selectedIndex) {
          Navigator.of(context).pop();
          if (selectedIndex != -1) {
            _moveToSelectedExercise(selectedIndex);
          } else {
            _completeWorkout();
          }
        },
      ),
    );
  }

  void _moveToSelectedExercise(int selectedIndex) {
    if (workoutExercises.isEmpty || selectedIndex >= workoutExercises.length) return;
    if (!mounted) return;
    setState(() {
      currentExerciseIndex = selectedIndex;
      currentSetIndex = workoutExercises[currentExerciseIndex].completedSets;
    });
  }

  void _moveToNextExercise() {
    if (workoutExercises.isEmpty || currentExerciseIndex + 1 >= workoutExercises.length) return;
    if (!mounted) return;
    setState(() {
      currentExerciseIndex++;
      currentSetIndex = workoutExercises[currentExerciseIndex].completedSets;
    });
  }

  void _completeWorkout() {
    if (!mounted) return;
    setState(() {
      isWorkoutCompleted = true;
    });
    _saveWorkoutProgress();
  }

  Future<void> _saveWorkoutProgress() async {
    try {
      if (!mounted) return;
      final workoutDuration = DateTime.now().difference(workoutStartTime).inMinutes;
            
      final success = await WorkoutPreviewService.completeWorkoutSession(
        widget.routine.id ?? 'unknown',
        workoutExercises,
        workoutDuration,
      );
            
      if (success) {
        print('Workout progress saved successfully');
      } else {
        print('Failed to save workout progress');
      }
    } catch (e) {
      print('Error saving workout progress: $e');
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => _showExitConfirmation(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.routine.name?.toString() ?? 'Workout Routine',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Workout Session',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        body: _buildWorkoutContent(),
      );
    } catch (e) {
      print('❌ WorkoutSessionPage: Build error: $e');
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Workout Error',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Please try again later',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildWorkoutContent() {
    if (isWorkoutCompleted) {
      return _buildWorkoutCompletedScreen();
    }
    
    if (workoutExercises.isEmpty) {
      return _buildErrorContent();
    }
    
    // Ensure currentExerciseIndex is valid
    if (currentExerciseIndex >= workoutExercises.length) {
      currentExerciseIndex = 0;
    }
    
    final currentExercise = workoutExercises[currentExerciseIndex];
        
    return _buildWorkoutScreen();
  }

  Widget _buildLoadingContent() {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Loading Workout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
            SizedBox(height: 20),
            Text(
              'Preparing your workout...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 20),
          Text(
            'No exercises found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'This routine has no exercises to perform',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
            ),
            child: Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutScreen() {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) {
      return _buildErrorContent();
    }
    final currentExercise = workoutExercises[currentExerciseIndex];
        
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: showRestTimer ? 180 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  image: currentExercise.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(currentExercise.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              currentExercise.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(Icons.favorite_border, color: Colors.white, size: 24),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showTimerSettingsModal,
                      child: _buildControlItemContent(Icons.timer, _formatTime(restTimeRemaining), 'Timer'),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: _navigateToInstructions,
                      child: _buildControlItemContent(Icons.play_arrow, 'Instructions', 'Instructions'),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildControlItemContent(Icons.bar_chart, 'Analytics', 'Analytics'),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildControlItemContent(Icons.fitness_center, 'kg\nDumbbells', 'Equipment'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                'Show warmup sets',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Effective sets',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildClickableSetsTable(currentExercise),
              SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add Set',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF4ECDC4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showRestTimer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF0F0F0F),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: _buildStickyRestTimer(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStickyRestTimer() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF4ECDC4), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'REST TIME',
            style: GoogleFonts.poppins(
              color: Color(0xFF4ECDC4),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => _adjustTimer(-15),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-15s',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                _formatTime(restTimeRemaining),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => _adjustTimer(15),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+15s',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isTimerRunning ? _stopRestTimer : _startRestTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTimerRunning ? Colors.red : Color(0xFF4ECDC4),
                    foregroundColor: isTimerRunning ? Colors.white : Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isTimerRunning ? Icons.pause : Icons.play_arrow,
                        color: isTimerRunning ? Colors.white : Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isTimerRunning ? 'PAUSE' : 'START',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  _stopRestTimer();
                  if (!mounted) return;
                  setState(() {
                    showRestTimer = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2A2A2A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'DONE',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlItemContent(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildClickableSetsTable(WorkoutExerciseModel exercise) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  child: Text(
                    'SET',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPS\nPER ARM',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'KG\nPER DB',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(exercise.sets, (index) {
            bool isCompleted = index < exercise.completedSets;
            bool isCurrent = index == currentSetIndex && !isCompleted;
                        
            return GestureDetector(
              onTap: () => _showSetInputModal(index),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Color(0xFF4ECDC4)
                      : isCurrent
                          ? Colors.white
                          : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        child: isCompleted
                            ? Icon(Icons.check, color: Colors.black, size: 20)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color: isCurrent ? Colors.black : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Text(
                          isCompleted
                              ? (exercise.loggedSets.length > index ? exercise.loggedSets[index].reps.toString() : '0')
                              : (exercise.targetSets != null && index < exercise.targetSets!.length 
                                  ? exercise.targetSets![index].reps.toString() 
                                  : (exercise.reps ?? '0')),
                          style: GoogleFonts.poppins(
                            color: isCompleted || isCurrent ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isCompleted
                              ? (exercise.loggedSets.length > index ? exercise.loggedSets[index].weight.toString() : '0')
                              : (exercise.targetSets != null && index < exercise.targetSets!.length 
                                  ? exercise.targetSets![index].weight.toString() 
                                  : (exercise.weight?.toString() ?? '0')),
                          style: GoogleFonts.poppins(
                            color: isCompleted || isCurrent ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutCompletedScreen() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.celebration, color: Color(0xFF4ECDC4), size: 80),
                  SizedBox(height: 24),
                  Text(
                    'Workout Complete!',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Great job completing ${widget.routine.name}',
                    style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestCompleteAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF4ECDC4),
                  size: 48,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Rest Complete!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'You\'re ready for your next set. Time to get back to work!',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Optionally play a sound or vibration here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Continue Workout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Exit Workout?',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to exit? Your progress will be lost.',
            style: GoogleFonts.poppins(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[400], fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Exit',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

class TimerSettingsModal extends StatefulWidget {
  final int currentRestTime;
  final bool useCustomTimer;
  final Function(int, bool) onSave;

  const TimerSettingsModal({
    Key? key,
    required this.currentRestTime,
    required this.useCustomTimer,
    required this.onSave,
  }) : super(key: key);

  @override
  _TimerSettingsModalState createState() => _TimerSettingsModalState();
}

class _TimerSettingsModalState extends State<TimerSettingsModal> {
  late bool useCustomTimer;
  late int restTime;

  @override
  void initState() {
    super.initState();
    useCustomTimer = widget.useCustomTimer;
    restTime = widget.currentRestTime;
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rest Timer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            // Current timer display
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Timer',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTime(restTime),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Timer adjustment buttons
            Row(
              children: [
                Expanded(
                  child: _buildTimeAdjustmentButton('-15s', -15),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTimeAdjustmentButton('-30s', -30),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTimeAdjustmentButton('+15s', 15),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTimeAdjustmentButton('+30s', 30),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Quick preset buttons
            Row(
              children: [
                Expanded(
                  child: _buildPresetButton('1 min', 60),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildPresetButton('2 min', 120),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildPresetButton('3 min', 180),
                ),
              ],
            ),
            SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSave(restTime, useCustomTimer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'SAVE TIMER',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAdjustmentButton(String label, int seconds) {
    return GestureDetector(
      onTap: () {
        setState(() {
          restTime = (restTime + seconds).clamp(30, 600); // Min 30s, Max 10min
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Color(0xFF4ECDC4),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, int seconds) {
    final isSelected = restTime == seconds;
    return GestureDetector(
      onTap: () {
        setState(() {
          restTime = seconds;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4ECDC4) : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
