import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/workout_preview_service.dart';
import './services/progress_analytics_service.dart';
import './services/smart_suggestion_service.dart';
import './widgets/set_experience_modal.dart';
import './widgets/smart_suggestion_modal.dart';
import './exercise_instructions_page.dart';
import './exercise_selection_modal.dart';
import '../utils/error_handler.dart';
import './add_exercise_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../user_dashboard.dart';
import './save_workout_page.dart';
import './reorder_exercises_page.dart';

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

class _WorkoutSessionPageState extends State<WorkoutSessionPage> with WidgetsBindingObserver {
  int currentExerciseIndex = 0;
  int currentSetIndex = 0;
  bool isWorkoutStarted = true;
  bool isWorkoutPaused = false;
  bool isWorkoutCompleted = false;
  bool showRestTimer = false;
  bool isSavingWorkout = false;
  int totalCompletedSets = 0;
  Set<String> _animatingCheckboxes = {};
  
  bool isTimerRunning = false;
  Timer? restTimer;
  int restTimeRemaining = 120;
  int customRestTime = 120;
  bool useCustomTimer = false;
  
  // Track rest timer start time to handle background properly
  DateTime? _restTimerStartTime;
  int _initialRestTime = 120;
  
  // Rest timer picker state
  Map<String, int> exerciseRestTimes = {}; // Store rest time for each exercise
  
  List<WorkoutExerciseModel> workoutExercises = [];
  DateTime workoutStartTime = DateTime.now();
  Timer? durationTimer;
  
  // Clock modal variables
  bool showClockModal = false;
  bool isTimerMode = true; // true for timer, false for stopwatch
  Duration timerDuration = Duration(minutes: 1); // Default 1 minute timer
  Duration stopwatchDuration = Duration.zero;
  Timer? clockTimer;
  Timer? animationTimer;
  bool isStopwatchRunning = false;
  double circleRotation = 0.0; // For the racing circle animation
  Duration originalTimerDuration = Duration(minutes: 1); // Store original timer duration
  
  // Store latest workout data for PREVIOUS column
  Map<String, List<Map<String, dynamic>>> latestWorkoutData = {};
  
  // Persistent controllers to prevent recreation on rebuild
  Map<String, TextEditingController> _weightControllers = {};
  Map<String, TextEditingController> _repsControllers = {};
  Set<String> _clearingFields = {};
  
  // Map to track if onChanged should be disabled for each field
  Map<String, bool> _onChangedDisabled = {};
  
  // Map to track if a field is showing previous data as a guide
  Map<String, bool> _showingPreviousData = {};
  
  // Map to track adjusted weights per exercise and set
  Map<String, Map<int, double>> _adjustedWeights = {};
  Map<String, Map<int, Map<String, dynamic>>> _setSuggestions = {}; // Store suggestions for each set

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    print('🚀 WorkoutSessionPage: initState() called - mounted: $mounted');
    try {
      _initializeWorkout();
      _startDurationTimer();
      _loadLatestWorkoutData();
      _loadTimerState(); // Load saved timer state
      
    } catch (e) {
      print('❌ WorkoutSessionPage: Initialization error: $e');
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      if (isTimerRunning && showRestTimer) {
        print('🔄 App resumed - checking rest timer');
        _updateRestTimerOnResume();
      }
    } else if (state == AppLifecycleState.paused) {
      // App went to background
      print('📱 App went to background');
    }
  }
  
  void _updateRestTimerOnResume() {
    if (_restTimerStartTime == null || !isTimerRunning) return;
    
    // Calculate actual elapsed time
    final elapsed = DateTime.now().difference(_restTimerStartTime!).inSeconds;
    final remaining = (_initialRestTime - elapsed).clamp(0, _initialRestTime);
    
    print('🔄 Rest timer on resume - elapsed: ${elapsed}s, remaining: ${remaining}s');
    
    setState(() {
      restTimeRemaining = remaining;
    });
    
    // If time is up, stop the timer
    if (restTimeRemaining <= 0) {
      restTimer?.cancel();
      _restTimerStartTime = null;
      setState(() {
        isTimerRunning = false;
        showRestTimer = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh latest workout data when page becomes visible
    print('🔄 WorkoutSessionPage: didChangeDependencies - refreshing latest workout data');
    _loadLatestWorkoutData();
  }

  void _startDurationTimer() {
    durationTimer?.cancel(); // Cancel any existing timer
    durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        setState(() {
          // This will trigger a rebuild to update the duration display
        });
      } catch (e) {
        print('❌ Error in duration timer setState: $e');
        timer.cancel();
      }
    });
  }

  void _initializeWorkout() {
    print('🔍 WorkoutSessionPage: Initializing workout...');
    workoutStartTime = DateTime.now();
    
    // Store workout data for banner detection
    _storeWorkoutData();
    
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
        List<WorkoutSetModel>? loggedSets;
        
        if (exercise.sets != null && exercise.sets!.isNotEmpty) {
          print('  - Using exercise.sets for targetSets');
          // Convert ExerciseSet to WorkoutSetModel for target sets
          targetSets = exercise.sets!.map((set) => WorkoutSetModel(
            reps: int.tryParse(set.reps) ?? 0,
            weight: double.tryParse(set.weight) ?? 0.0,
            timestamp: set.timestamp,
            isCompleted: false,
          )).toList();
          
          // Create empty logged sets (0 reps, 0 weight) so previous data can be used as guide
          loggedSets = exercise.sets!.map((set) => WorkoutSetModel(
            reps: 0, // Start with 0 so previous data can be used as guide
            weight: 0.0, // Start with 0 so previous data can be used as guide
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
          
          // Create empty logged sets for fallback
          loggedSets = [WorkoutSetModel(
            reps: 0, // Start with 0 so previous data can be used as guide
            weight: 0.0, // Start with 0 so previous data can be used as guide
            timestamp: DateTime.now(),
            isCompleted: false,
          )];
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
          loggedSets: loggedSets ?? [],
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
          loggedSets: [],
        );
      }
    }).toList();
    
    // Initialize exerciseRestTimes with default rest times
    for (final exercise in workoutExercises) {
      final exerciseKey = '${exercise.exerciseId}_${exercise.name}';
      exerciseRestTimes[exerciseKey] = exercise.restTime;
      print('🎯 Initialized rest time for ${exercise.name}: ${exercise.restTime}s');
    }
        
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
    
    // Parse values outside setState to make them accessible
    int repsInt = int.tryParse(reps) ?? 0;
    double weightDouble = double.tryParse(weight) ?? 0.0;
    
    setState(() {
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
      // Start rest timer first
      if (!mounted) return;
      setState(() {
        showRestTimer = true;
      });
      _startRestTimer();
      
        // Generate suggestion for this completed set
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            _generateSetSuggestion(currentExercise, setIndex, repsInt, weightDouble);
          }
        });
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
          // Save timer state immediately when user changes settings
          _saveTimerState();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _startRestTimer() {
    if (!mounted) return;
    
    // Don't start timer if rest time is OFF (0)
    if (restTimeRemaining == 0) {
      print('Rest timer is OFF');
      return;
    }
    
    // Save initial values for background handling
    _restTimerStartTime = DateTime.now();
    _initialRestTime = restTimeRemaining;
    
    setState(() {
      isTimerRunning = true;
      print('Starting timer: ${restTimeRemaining}s');
    });
    print('⏰ Starting rest timer');
    restTimer?.cancel(); // Cancel any existing timer
    restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted || _restTimerStartTime == null) {
        print('⏰ Rest timer: Widget not mounted or start time missing, canceling');
        timer.cancel();
        return;
      }
      
      // Calculate remaining time based on actual elapsed time
      final elapsed = DateTime.now().difference(_restTimerStartTime!).inSeconds;
      final remaining = (_initialRestTime - elapsed).clamp(0, _initialRestTime);
      
      if (remaining > 0) {
        try {
          setState(() {
            restTimeRemaining = remaining;
          });
        } catch (e) {
          print('❌ Error in rest timer setState: $e');
          timer.cancel();
        }
      } else {
        print('⏰ Rest timer: Time up, canceling');
        timer.cancel();
        if (!mounted) {
          return;
        }
        try {
          print('⏰ Rest timer: Calling setState for completion');
          setState(() {
            isTimerRunning = false;
            showRestTimer = false;
          });
          // Clear start time when timer completes
          _restTimerStartTime = null;
          print('⏰ Rest timer: Completion setState done');
          // Timer finished - no popup needed
        } catch (e) {
          print('❌ Error in rest timer completion setState: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
      }
    });
  }

  void _stopRestTimer() {
    restTimer?.cancel();
    if (!mounted) return;
    
    // Clear the start time when stopping
    _restTimerStartTime = null;
    
    setState(() {
      isTimerRunning = false;
      showRestTimer = false;
    });
  }

  void _adjustTimer(int seconds) {
    if (!mounted) return;
    setState(() {
      restTimeRemaining = (restTimeRemaining + seconds).clamp(0, 600);
      // Update initial time when manually adjusting
      if (isTimerRunning && _restTimerStartTime != null) {
        _initialRestTime = restTimeRemaining;
        _restTimerStartTime = DateTime.now();
      }
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
      
      // Debug: Print workout data before saving
      print('💾 SAVING WORKOUT PROGRESS:');
      print('  Routine ID: ${widget.routine.id}');
      print('  Duration: $workoutDuration minutes');
      print('  Total exercises: ${workoutExercises.length}');
      
      for (int i = 0; i < workoutExercises.length; i++) {
        final exercise = workoutExercises[i];
        print('  Exercise $i: ${exercise.name}');
        print('    Completed: ${exercise.isCompleted}');
        print('    Completed sets: ${exercise.completedSets}');
        print('    Logged sets: ${exercise.loggedSets.length}');
        for (int j = 0; j < exercise.loggedSets.length; j++) {
          final set = exercise.loggedSets[j];
          print('      Set $j: ${set.reps} reps x ${set.weight}kg');
        }
      }
            
      final success = await WorkoutPreviewService.completeWorkoutSession(
        widget.routine.id ?? 'unknown',
        workoutExercises,
        workoutDuration,
      );
            
      if (success) {
        print('✅ Workout progress saved successfully');
      } else {
        print('❌ Failed to save workout progress');
      }
    } catch (e) {
      print('❌ Error saving workout progress: $e');
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Generate suggestion for a completed set (without showing modal)
  void _generateSetSuggestion(WorkoutExerciseModel exercise, int setIndex, int reps, double weight) {
    // Generate a random experience for now (in real app, this would come from user input)
    final experiences = ['easy', 'moderate', 'hard'];
    final randomExperience = experiences[(DateTime.now().millisecondsSinceEpoch % 3)];
    
    final suggestion = SmartSuggestionService.generateSuggestion(
      experience: randomExperience,
      reps: reps,
      weight: weight,
      exerciseName: exercise.name,
    );
    
    // Store the suggestion for this set
    final exerciseKey = exercise.name;
    if (!_setSuggestions.containsKey(exerciseKey)) {
      _setSuggestions[exerciseKey] = {};
    }
    _setSuggestions[exerciseKey]![setIndex] = suggestion;
    
    print('💡 Generated suggestion for ${exercise.name} Set ${setIndex + 1}: ${suggestion['message']}');
  }

  // Show suggestion when light bulb is clicked
  void _showSuggestionModal(WorkoutExerciseModel exercise, int setIndex) {
    final exerciseKey = exercise.name;
    final suggestion = _setSuggestions[exerciseKey]?[setIndex];
    
    if (suggestion == null) {
      print('❌ No suggestion found for ${exercise.name} Set ${setIndex + 1}');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => SmartSuggestionModal(
        message: suggestion['message'],
        icon: suggestion['icon'],
        color: suggestion['color'],
        exerciseName: exercise.name,
        reps: exercise.loggedSets[setIndex].reps,
        weight: exercise.loggedSets[setIndex].weight,
        onGotIt: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSmartSuggestionModal(String experience, int reps, double weight) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    
    final suggestion = SmartSuggestionService.generateSuggestion(
      experience: experience,
      reps: reps,
      weight: weight,
      exerciseName: currentExercise.name,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SmartSuggestionModal(
        message: suggestion['message'],
        icon: suggestion['icon'],
        color: suggestion['color'],
        exerciseName: currentExercise.name,
        reps: reps,
        weight: weight,
        onGotIt: () {
          Navigator.of(context).pop();
          // User acknowledged suggestion, continue with rest timer
        },
      ),
    );
  }

  void _showWeightAdjustmentModal(String suggestionType) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    
    String title = '';
    String message = '';
    double weightAdjustment = 0.0;
    
    switch (suggestionType) {
      case 'weight_increase':
        title = 'Increase Weight';
        message = 'How much would you like to increase the weight?';
        weightAdjustment = 2.5; // Default increase
        break;
      case 'weight_decrease':
        title = 'Decrease Weight';
        message = 'How much would you like to decrease the weight?';
        weightAdjustment = -2.5; // Default decrease
        break;
      case 'maintain_weight':
        title = 'Keep Current Weight';
        message = 'Keep the current weight for the next set?';
        weightAdjustment = 0.0;
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            if (suggestionType != 'maintain_weight') ...[
              SizedBox(height: 16),
              Text(
                'Current weight: ${currentExercise.weight}kg',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Suggested adjustment: ${weightAdjustment > 0 ? '+' : ''}${weightAdjustment}kg',
                style: GoogleFonts.poppins(
                  color: weightAdjustment > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          if (suggestionType != 'maintain_weight')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _adjustWeightForNextSet(weightAdjustment);
              },
              child: Text('Apply'),
            ),
          if (suggestionType == 'maintain_weight')
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Keep Weight'),
            ),
        ],
      ),
    );
  }

  void _adjustWeightForNextSet(double adjustment) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    if (!mounted) return;
    
    setState(() {
      final currentExercise = workoutExercises[currentExerciseIndex];
      final newWeight = (currentExercise.weight + adjustment).clamp(0.0, 999.9);
      
      // Since weight is final, we need to update the weight controllers for the next set
      // The weight will be applied when the user logs the next set
      final nextSetIndex = currentExercise.completedSets;
      final weightFieldKey = '${currentExercise.name}_${nextSetIndex}_weight';
      if (_weightControllers.containsKey(weightFieldKey)) {
        _weightControllers[weightFieldKey]!.text = newWeight.toString();
      }
      
      // Store the adjusted weight for this exercise
      // We'll use a map to track adjusted weights per exercise
      if (!_adjustedWeights.containsKey(currentExercise.name)) {
        _adjustedWeights[currentExercise.name] = {};
      }
      _adjustedWeights[currentExercise.name]![nextSetIndex] = newWeight;
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Weight adjusted to ${workoutExercises[currentExerciseIndex].weight + adjustment}kg for next set',
        ),
        backgroundColor: Color(0xFF4ECDC4),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _storeWorkoutData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_workout_routine_id', widget.routine.id.toString());
      await prefs.setString('active_workout_routine_name', widget.routine.name);
      print('💾 Stored workout data for banner detection');
    } catch (e) {
      print('❌ Error storing workout data: $e');
    }
  }

  // Save timer state to SharedPreferences
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_rest_time', restTimeRemaining);
      await prefs.setInt('saved_custom_rest_time', customRestTime);
      await prefs.setBool('saved_use_custom_timer', useCustomTimer);
      await prefs.setInt('saved_timer_duration_seconds', timerDuration.inSeconds);
      print('⏰ Saved timer state: restTime=$restTimeRemaining, customTime=$customRestTime, useCustom=$useCustomTimer, timerDuration=${timerDuration.inSeconds}s');
    } catch (e) {
      print('❌ Error saving timer state: $e');
    }
  }

  // Load saved timer state from SharedPreferences
  Future<void> _loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRestTime = prefs.getInt('saved_rest_time');
      final savedCustomRestTime = prefs.getInt('saved_custom_rest_time');
      final savedUseCustomTimer = prefs.getBool('saved_use_custom_timer');
      final savedTimerDurationSeconds = prefs.getInt('saved_timer_duration_seconds');
      
      if (savedRestTime != null) {
        restTimeRemaining = savedRestTime;
        print('⏰ Loaded saved rest time: $restTimeRemaining seconds');
      }
      
      if (savedCustomRestTime != null) {
        customRestTime = savedCustomRestTime;
        print('⏰ Loaded saved custom rest time: $customRestTime seconds');
      }
      
      if (savedUseCustomTimer != null) {
        useCustomTimer = savedUseCustomTimer;
        print('⏰ Loaded saved use custom timer: $useCustomTimer');
      }
      
      if (savedTimerDurationSeconds != null) {
        timerDuration = Duration(seconds: savedTimerDurationSeconds);
        originalTimerDuration = timerDuration;
        print('⏰ Loaded saved timer duration: ${timerDuration.inSeconds} seconds');
      }
    } catch (e) {
      print('❌ Error loading timer state: $e');
    }
  }

  void _clearWorkoutData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_workout_routine_id');
      await prefs.remove('active_workout_routine_name');
      print('🗑️ Cleared workout data');
    } catch (e) {
      print('❌ Error clearing workout data: $e');
    }
  }

  void _showDiscardWorkoutConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Get screen dimensions for responsive design
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 360 || screenHeight < 600;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 20 : 40,
            ),
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 400,
              maxHeight: isSmallScreen ? screenHeight * 0.7 : 500,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              border: Border.all(
                color: Color(0xFF333333),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: isSmallScreen ? 25 : 30,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Title
                Text(
                  'Discard Workout?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                
                // Message
                Text(
                  'Are you sure you want to discard this workout? All your progress will be lost and cannot be recovered.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: isSmallScreen ? 13 : 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 20 : 24),
                
                // Action Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 14,
                            horizontal: isSmallScreen ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            border: Border.all(
                              color: Color(0xFF444444),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    
                    // Discard Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          // Clear workout data and navigate back
                          _clearWorkoutData();
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/userDashboard', 
                            (route) => false
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 12 : 14,
                            horizontal: isSmallScreen ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Discard',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    print('💀 WorkoutSessionPage: dispose() called');
    print('💀 WorkoutSessionPage: Canceling timers');
    restTimer?.cancel();
    durationTimer?.cancel();
    clockTimer?.cancel();
    animationTimer?.cancel();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    print('💀 WorkoutSessionPage: Disposing text controllers');
    // Dispose all text controllers
    _weightControllers.values.forEach((controller) => controller.dispose());
    _repsControllers.values.forEach((controller) => controller.dispose());
    
    print('💀 WorkoutSessionPage: Calling super.dispose()');
    super.dispose();
    print('💀 WorkoutSessionPage: dispose() completed');
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Custom Header with Time and Finish Button
                  _buildCustomHeader(),
                  // Blue Progress Bar (below header, full width)
                  _buildProgressBar(),
                  // Workout Summary Section
                  _buildWorkoutSummary(),
                  // Exercises List
                  Expanded(
                    child: _buildExercisesList(),
                  ),
                ],
              ),
            ),
             // Clock Modal
             if (showClockModal) _buildClockModal(),
             // Rest Timer
             if (showRestTimer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A), // Dark gray background
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
            // Blue loading overlay when saving workout
            if (isSavingWorkout)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Saving Workout...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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

  Widget _buildCustomHeader() {
    return Container(
      color: Color(0xFF1A1A1A), // Dark gray header background to match image
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
           // Log Workout Title with Chevron (aligned to left)
           GestureDetector(
             onTap: () {
               // Just navigate to Programs page without disposing the workout
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => UserDashboard(),
                 ),
               );
             },
             child: Row(
               children: [
                 Icon(
                   Icons.keyboard_arrow_down,
                   color: Colors.white,
                   size: 20,
                 ),
                 SizedBox(width: 8),
                 Text(
                   'Log Workout',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 18,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ],
             ),
           ),
          // Spacer to push timer and finish button to the right
          Spacer(),
          // Clock Button and Finish Button
          Row(
            children: [
              // Clock Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    showClockModal = true;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isTimerRunning || isStopwatchRunning) ? Color(0xFF007AFF) : Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!, width: 1),
                  ),
                  child: Icon(
                    Icons.schedule,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Finish Button
              GestureDetector(
                onTap: isSavingWorkout ? null : _finishWorkout,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSavingWorkout ? Colors.grey[600] : Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSavingWorkout
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Saving...',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Finish',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    // Calculate total possible sets
    final totalSets = workoutExercises.fold(0, (sum, exercise) => sum + exercise.sets);
    final progress = totalSets > 0 ? totalCompletedSets / totalSets : 0.0;
    
    return Container(
      height: 3, // Thinner bar to match image
      color: Color(0xFF0F0F0F), // Dark background
      child: Row(
        children: [
          // Blue progress bar aligned to left
          Container(
            width: MediaQuery.of(context).size.width * progress,
            height: 3,
            color: Color(0xFF007AFF), // Blue color matching Finish button
          ),
          // Remaining space (transparent)
          Expanded(
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWorkoutSummary() {
    final duration = DateTime.now().difference(workoutStartTime);
    final totalVolume = _calculateTotalVolume();
    final totalSets = _calculateTotalSets();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Duration', _formatDuration(duration)),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[700],
          ),
          Expanded(
            child: _buildSummaryItem('Volume', '${totalVolume.toStringAsFixed(0)} lbs'),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey[700],
          ),
          Expanded(
            child: _buildSummaryItem('Sets', totalSets.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Color(0xFF007AFF),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  double _calculateTotalVolume() {
    double total = 0.0;
    for (var exercise in workoutExercises) {
      for (var set in exercise.loggedSets) {
        if (set.isCompleted) {
          total += (set.weight ?? 0.0) * (set.reps ?? 0);
        }
      }
    }
    return total;
  }

  int _calculateTotalSets() {
    int total = 0;
    for (var exercise in workoutExercises) {
      total += exercise.completedSets;
    }
    return total;
  }

  Widget _buildExercisesList() {
    if (workoutExercises.isEmpty) {
      return _buildErrorContent();
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: workoutExercises.length + 1, // +1 for the bottom buttons
      itemBuilder: (context, index) {
        if (index < workoutExercises.length) {
          return _buildExerciseCard(workoutExercises[index], index);
        } else {
          // Bottom buttons as the last item in the list
          return _buildBottomButtons();
        }
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseModel exercise, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Header
          _buildExerciseHeader(exercise, index),
          // Notes Field
          _buildNotesField(exercise),
          // Rest Timer
          _buildRestTimerSection(exercise),
          // Sets Table
          _buildSetsTable(exercise),
          // Add Set Button
          _buildAddSetButton(exercise),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExerciseHeader(WorkoutExerciseModel exercise, int index) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Exercise Icon - Clickable
          GestureDetector(
            onTap: () => _showExerciseInstructions(exercise),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getExerciseIcon(exercise.name),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 12),
          // Exercise Name
          Expanded(
            child: Text(
              exercise.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Three Dots Menu
          GestureDetector(
            onTap: () => _showExerciseMenu(exercise, index),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.more_vert,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getExerciseIcon(String exerciseName) {
    if (exerciseName.toLowerCase().contains('bench')) {
      return Icons.fitness_center;
    } else if (exerciseName.toLowerCase().contains('incline')) {
      return Icons.trending_up;
    } else if (exerciseName.toLowerCase().contains('lateral')) {
      return Icons.open_in_full;
    } else {
      return Icons.fitness_center;
    }
  }

  Widget _buildNotesField(WorkoutExerciseModel exercise) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A), // Gray background to blend with the page
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF333333), // Subtle border
            width: 1,
          ),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Add notes here...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[400], // Clear, visible placeholder text
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            filled: true,
            fillColor: Colors.transparent,
          ),
          style: GoogleFonts.poppins(
            color: Colors.white, // White text for user input
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildRestTimerSection(WorkoutExerciseModel exercise) {
    final exerciseKey = '${exercise.exerciseId}_${exercise.name}';
    final currentRestTime = exerciseRestTimes[exerciseKey] ?? 0; // Default to OFF
    
    return GestureDetector(
      onTap: () => _showRestTimerPicker(exercise),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              currentRestTime == 0 ? Icons.timer_off : Icons.timer,
              color: currentRestTime == 0 ? Colors.grey[500] : Color(0xFF007AFF),
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              currentRestTime == 0 ? 'Rest Timer: OFF' : 'Rest Timer: ${_formatRestTime(currentRestTime)}',
              style: GoogleFonts.poppins(
                color: currentRestTime == 0 ? Colors.grey[500] : Color(0xFF007AFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: currentRestTime == 0 ? Colors.grey[500] : Color(0xFF007AFF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsTable(WorkoutExerciseModel exercise) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
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
                    'PREVIOUS',
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
                    'KG',
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
                    'REPS',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 30,
                  child: Text(
                    '',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...List.generate(exercise.loggedSets.length, (index) {
            final set = exercise.loggedSets[index];
            final isCompleted = set.isCompleted;
            final previousSet = index > 0 ? exercise.loggedSets[index - 1] : null;
            
              return Dismissible(
                key: Key('${exercise.name}_${index}_${set.timestamp}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  final shouldDelete = await _showDeleteConfirmation(exercise, index);
                  if (shouldDelete) {
                    // Delete the set immediately when confirmed
                    _deleteSet(exercise, index);
                    // Add a small delay to ensure smooth UI update
                    await Future.delayed(Duration(milliseconds: 100));
                  }
                  return false; // Always return false to prevent automatic dismissal
                },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 100),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green[900] // Darker green row background
                      : (index % 2 == 0 ? Color(0xFF1A1A1A) : Color(0xFF2A2A2A)),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[800]!,
                      width: 0.5,
                    ),
                  ),
                ),
                transform: _animatingCheckboxes.contains('${exercise.name}_${index}')
                    ? (Matrix4.identity()..scale(1.01)..translate(0.0, -1.5))
                    : Matrix4.identity(),
                child: Row(
                children: [
                  Container(
                    width: 40,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: isCompleted ? Colors.white : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _getPreviousWorkoutText(exercise.name, index),
                      style: GoogleFonts.poppins(
                        color: isCompleted ? Colors.white : Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: _buildEditableWeightField(exercise, index, isCompleted: isCompleted),
                  ),
                  Expanded(
                    child: _buildEditableRepsField(exercise, index, isCompleted: isCompleted),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 30,
                        child: GestureDetector(
                          onTap: () => _toggleSetCompletion(exercise, index),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompleted ? Colors.green[300] : Colors.grey[600],
                              borderRadius: BorderRadius.circular(6), // More rounded like the image
                            ),
                            transform: Matrix4.identity(),
                            child: Icon(
                              Icons.check,
                              color: Colors.white.withOpacity(1.0),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // Light bulb icon for suggestions (only show if set is completed and has suggestion)
                      if (isCompleted && _setSuggestions[exercise.name]?[index] != null)
                        GestureDetector(
                          onTap: () => _showSuggestionModal(exercise, index),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Color(0xFF4ECDC4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFF4ECDC4),
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddSetButton(WorkoutExerciseModel exercise) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: GestureDetector(
          onTap: () => _addSetToExercise(exercise),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Add Set',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // Add Exercise Button (Blue)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => AddExercisePage(
                    onExerciseAdded: (exercise) {
                      _addExerciseToWorkout(exercise);
                    },
                    existingExerciseNames: workoutExercises.map((e) => e.name).toList(),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Add Exercise',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          
          // Bottom row: Settings and Discard Workout
          Row(
            children: [
              // Settings Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Settings functionality
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              
              // Discard Workout Button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _showDiscardWorkoutConfirmation();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Discard Workout',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _finishWorkout() {
    print('🏁 FINISH WORKOUT CALLED');
    print('🏁 Total exercises: ${workoutExercises.length}');
    
    // Check if any sets have been completed
    int totalCompletedSets = 0;
    for (var exercise in workoutExercises) {
      totalCompletedSets += exercise.completedSets;
      print('🏁 Exercise: ${exercise.name} - Completed sets: ${exercise.completedSets}');
    }
    
    print('🏁 TOTAL COMPLETED SETS: $totalCompletedSets');
    
    if (totalCompletedSets == 0) {
      // Show dialog if no sets completed
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'No Sets Completed',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Message
                  Text(
                    'Your workout has no set values.\nPlease complete at least one set before finishing.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // OK Button
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'OK',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }
    
    // Calculate workout metrics
    final workoutDuration = DateTime.now().difference(workoutStartTime);
    double totalVolume = 0;
    int totalSets = 0;
    
    print('📊 CALCULATING WORKOUT METRICS:');
    print('📊 Workout duration: ${workoutDuration.inMinutes} minutes');
    
    for (var exercise in workoutExercises) {
      totalSets += exercise.completedSets;
      print('📊 Exercise: ${exercise.name} - Completed sets: ${exercise.completedSets}');
      
      for (var set in exercise.loggedSets) {
        if (set.isCompleted) {
          final setVolume = set.weight * set.reps;
          totalVolume += setVolume;
          print('📊   Set: ${set.weight}kg x ${set.reps} reps = ${setVolume}kg volume');
        }
      }
    }
    
    print('📊 TOTAL VOLUME: ${totalVolume}kg');
    print('📊 TOTAL SETS: $totalSets');
    
    // Save timer state before finishing workout
    _saveTimerState();
    
    // Navigate directly to save workout page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveWorkoutPage(
          routine: widget.routine,
          exercises: workoutExercises,
          workoutDuration: workoutDuration,
          totalVolume: totalVolume,
          totalSets: totalSets,
        ),
      ),
    );
  }

  void _addSetToExercise(WorkoutExerciseModel exercise) {
    setState(() {
      exercise.loggedSets.add(WorkoutSetModel(
        reps: exercise.loggedSets.isNotEmpty ? exercise.loggedSets.last.reps : 10,
        weight: exercise.loggedSets.isNotEmpty ? exercise.loggedSets.last.weight : 0.0,
        timestamp: DateTime.now(),
        isCompleted: false,
      ));
    });
  }

  void _showExerciseMenu(WorkoutExerciseModel exercise, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF3A3A3A),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getExerciseIcon(exercise.name),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Options
            _buildMenuOption(
              icon: Icons.swap_vert,
              title: 'Reorder Exercise',
              subtitle: 'Drag and drop to change exercise order',
              onTap: () {
                Navigator.pop(context);
                _showReorderDialog(exercise, index);
              },
            ),
            
            _buildMenuOption(
              icon: Icons.delete_outline,
              title: 'Remove Exercise',
              subtitle: 'Remove this exercise from workout',
              onTap: () {
                Navigator.pop(context);
                _showRemoveExerciseDialog(exercise, index);
              },
              isDestructive: true,
            ),
            
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showReorderDialog(WorkoutExerciseModel exercise, int currentIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ReorderExercisesPage(
          exercises: List.from(workoutExercises),
          onReorder: (reorderedExercises) {
            setState(() {
              workoutExercises = reorderedExercises;
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildReorderButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF3A3A3A),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFF007AFF),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
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

  void _moveExercise(WorkoutExerciseModel exercise, int fromIndex, int toIndex) {
    setState(() {
      // Remove the exercise from its current position
      workoutExercises.removeAt(fromIndex);
      // Insert it at the new position
      workoutExercises.insert(toIndex, exercise);
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name} moved successfully'),
        backgroundColor: Color(0xFF4ECDC4),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRemoveExerciseDialog(WorkoutExerciseModel exercise, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              SizedBox(height: 20),
              
              // Title
              Text(
                'Remove Exercise',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              
              // Message
              Text(
                'Are you sure you want to remove "${exercise.name}" from this workout?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _removeExercise(exercise, index);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Remove',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeExercise(WorkoutExerciseModel exercise, int index) {
    setState(() {
      workoutExercises.removeAt(index);
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name} removed from workout'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleSetCompletion(WorkoutExerciseModel exercise, int setIndex) {
    // Add haptic feedback for the pop animation
    HapticFeedback.lightImpact();
    
    final checkboxKey = '${exercise.name}_${setIndex}';
    
    // Add to animating set for pop effect
    if (mounted) {
      try {
        setState(() {
          _animatingCheckboxes.add(checkboxKey);
        });
      } catch (e) {
        print('❌ Error in animation setState: $e');
      }
    }
    
    // Remove from animating set after animation
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        try {
          setState(() {
            _animatingCheckboxes.remove(checkboxKey);
          });
        } catch (e) {
          print('❌ Error in animation removal setState: $e');
        }
      }
    });
    
    if (mounted) {
      try {
        setState(() {
          if (setIndex < exercise.loggedSets.length) {
            final currentSet = exercise.loggedSets[setIndex];
            final newCompletedState = !currentSet.isCompleted;
            
            print('🏋️ TOGGLE SET COMPLETION: ${exercise.name} - Set ${setIndex + 1} - Current: ${currentSet.isCompleted} -> New: $newCompletedState');
            
            // If we're completing the set (not unchecking), handle previous data logic
            if (newCompletedState) {
              // Check if we're showing previous data as a guide (weight is 0 but we have previous data)
              final previousData = _getPreviousWorkoutData(exercise.name, setIndex);
              final isShowingPreviousData = currentSet.weight == 0 && previousData != null;
              
              // Check if user has manually entered any data by looking at the text controllers
              final weightFieldKey = '${exercise.name}_${setIndex}_weight';
              final repsFieldKey = '${exercise.name}_${setIndex}_reps';
              final hasUserEnteredData = (_weightControllers[weightFieldKey]?.text.isNotEmpty == true && 
                                         _weightControllers[weightFieldKey]?.text != '0') ||
                                        (_repsControllers[repsFieldKey]?.text.isNotEmpty == true && 
                                         _repsControllers[repsFieldKey]?.text != '0');
              
              print('🔍 SET COMPLETION DEBUG: isShowingPreviousData = $isShowingPreviousData, hasUserEnteredData = $hasUserEnteredData');
              
              if (isShowingPreviousData && !hasUserEnteredData) {
                // Use previous workout data
                if (previousData != null) {
                  final previousWeight = previousData['weight']?.toDouble() ?? 0.0;
                  final previousReps = previousData['reps']?.toInt() ?? 0;
                  
                  final updatedSetWithPreviousData = WorkoutSetModel(
                    reps: previousReps,
                    weight: previousWeight,
                    rpe: currentSet.rpe,
                    notes: currentSet.notes,
                    timestamp: currentSet.timestamp,
                    isCompleted: true,
                  );
                  
                  exercise.loggedSets[setIndex] = updatedSetWithPreviousData;
                  print('🏋️ Using previous workout data: ${previousWeight}kg x ${previousReps} reps');
                  
                  // Update the text controllers to show the actual data (no longer guide)
                  if (_weightControllers.containsKey(weightFieldKey)) {
                    _weightControllers[weightFieldKey]!.text = previousWeight.toStringAsFixed(0);
                  }
                  if (_repsControllers.containsKey(repsFieldKey)) {
                    _repsControllers[repsFieldKey]!.text = previousReps.toString();
                  }
                  
                  // Mark as no longer showing previous data (now it's actual data)
                  _showingPreviousData[weightFieldKey] = false;
                  _showingPreviousData[repsFieldKey] = false;
                }
              } else {
                // Use user-entered data or current data
                final weightText = _weightControllers[weightFieldKey]?.text ?? '';
                final repsText = _repsControllers[repsFieldKey]?.text ?? '';
                
                final finalWeight = weightText.isNotEmpty ? double.tryParse(weightText) ?? currentSet.weight : currentSet.weight;
                final finalReps = repsText.isNotEmpty ? int.tryParse(repsText) ?? currentSet.reps : currentSet.reps;
                
                final updatedSetWithUserData = WorkoutSetModel(
                  reps: finalReps,
                  weight: finalWeight,
                  rpe: currentSet.rpe,
                  notes: currentSet.notes,
                  timestamp: currentSet.timestamp,
                  isCompleted: true,
                );
                
                exercise.loggedSets[setIndex] = updatedSetWithUserData;
                print('🏋️ Using user-entered values: ${finalWeight}kg x ${finalReps} reps');
              }
            } else {
              // Simply uncheck the set - keep all other data the same
              final updatedSet = WorkoutSetModel(
                reps: currentSet.reps,
                weight: currentSet.weight,
                rpe: currentSet.rpe,
                notes: currentSet.notes,
                timestamp: currentSet.timestamp,
                isCompleted: false,
              );
              
              exercise.loggedSets[setIndex] = updatedSet;
              print('🏋️ Unchecked set: ${currentSet.weight}kg x ${currentSet.reps} reps');
            }
            
            // Update completed sets count for this exercise
            exercise.completedSets = exercise.loggedSets.where((set) => set.isCompleted).length;
            
            // Update total completed sets across all exercises
            totalCompletedSets = workoutExercises.fold(0, (sum, ex) => sum + ex.completedSets);
            
            // If we just completed a set, start the rest timer if it's enabled for this exercise
            if (!currentSet.isCompleted && exercise.loggedSets[setIndex].isCompleted) {
              final exerciseKey = '${exercise.exerciseId}_${exercise.name}';
              final exerciseRestTime = exerciseRestTimes[exerciseKey] ?? 0;
              
              if (exerciseRestTime > 0) {
                // Start the rest timer
                print('🎯 Setting showRestTimer = true, exerciseRestTime: $exerciseRestTime');
                setState(() {
                  showRestTimer = true;
                  restTimeRemaining = exerciseRestTime;
                  print('🎯 Inside setState - showRestTimer set to: $showRestTimer, restTimeRemaining: $restTimeRemaining');
                });
                _startRestTimer();
                
                // Generate suggestion for this completed set
                Future.delayed(Duration(milliseconds: 500), () {
                  if (mounted) {
                    final completedSet = exercise.loggedSets[setIndex];
                    _generateSetSuggestion(exercise, setIndex, completedSet.reps, completedSet.weight);
                  }
                });
              } else {
                print('🎯 Exercise rest time is 0, not showing timer');
                
                // Even if rest timer is disabled, generate suggestion
                Future.delayed(Duration(milliseconds: 300), () {
                  if (mounted) {
                    final completedSet = exercise.loggedSets[setIndex];
                    _generateSetSuggestion(exercise, setIndex, completedSet.reps, completedSet.weight);
                  }
                });
              }
            }
          }
        });
      } catch (e) {
        print('❌ Error in toggle set completion setState: $e');
        print('❌ Stack trace: ${StackTrace.current}');
      }
    }
  }


  Widget _buildEditableWeightField(WorkoutExerciseModel exercise, int setIndex, {bool isCompleted = false}) {
    final set = exercise.loggedSets[setIndex];
    
    // Get previous workout data for this set
    final previousData = _getPreviousWorkoutData(exercise.name, setIndex);
    final previousWeight = previousData?['weight']?.toStringAsFixed(0) ?? '0';
    
    // Create unique key for this field
    final fieldKey = '${exercise.name}_${setIndex}_weight';
    
    // Get or create persistent controller
    if (!_weightControllers.containsKey(fieldKey)) {
      // Always show previous data as guide text initially
      _weightControllers[fieldKey] = TextEditingController(text: previousWeight);
      // Mark as showing previous data if we have previous data and current weight is 0
      if (previousWeight != '0' && set.weight == 0) {
        _showingPreviousData[fieldKey] = true;
        // Don't update the actual set data - keep it as 0 so it's clearly a guide
      } else {
        _showingPreviousData[fieldKey] = false;
      }
    } else {
      // If controller exists but text is empty or "0", update it with previous data
      if (_weightControllers[fieldKey]!.text.isEmpty || _weightControllers[fieldKey]!.text == '0') {
        _weightControllers[fieldKey]!.text = previousWeight;
        // Mark as showing previous data if we have previous data and current weight is 0
        if (previousWeight != '0' && set.weight == 0) {
          _showingPreviousData[fieldKey] = true;
          // Don't update the actual set data - keep it as 0 so it's clearly a guide
        } else {
          _showingPreviousData[fieldKey] = false;
        }
      }
    }
    
    final weightController = _weightControllers[fieldKey]!;
    bool isShowingPreviousData = _showingPreviousData[fieldKey] ?? false;
    
    
    
    return TextField(
        controller: weightController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        onTap: () {
          if (isShowingPreviousData) {
            // Clear and set cursor at beginning without showing "0"
            weightController.text = '';
            weightController.selection = TextSelection.collapsed(offset: 0);
            // Mark as no longer showing previous data
            _showingPreviousData[fieldKey] = false;
          }
        },
        onChanged: (value) {
          if (isShowingPreviousData && value.isNotEmpty) {
            // If user is typing over previous data, just use their input
            _updateSetWeight(exercise, setIndex, double.tryParse(value) ?? 0);
            // Mark as no longer showing previous data
            _showingPreviousData[fieldKey] = false;
          } else if (value.isNotEmpty) {
            // Normal input
            _updateSetWeight(exercise, setIndex, double.tryParse(value) ?? 0);
            // Mark as no longer showing previous data
            _showingPreviousData[fieldKey] = false;
          }
        },
      style: GoogleFonts.poppins(
        color: isCompleted ? Colors.white : (isShowingPreviousData ? Colors.grey[400] : Colors.white),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        hintText: isShowingPreviousData ? '' : '0',
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: false,
      ),
      onSubmitted: (value) {
        final weight = double.tryParse(value) ?? 0.0;
        _updateSetWeight(exercise, setIndex, weight);
        // Mark as no longer showing previous data
        _showingPreviousData[fieldKey] = false;
      },
    );
  }

  Widget _buildEditableRepsField(WorkoutExerciseModel exercise, int setIndex, {bool isCompleted = false}) {
    final set = exercise.loggedSets[setIndex];
    
    // Get previous workout data for this set
    final previousData = _getPreviousWorkoutData(exercise.name, setIndex);
    final previousReps = previousData?['reps']?.toString() ?? '0';
    
    // Create unique key for this field
    final fieldKey = '${exercise.name}_${setIndex}_reps';
    
    // Get or create persistent controller
    if (!_repsControllers.containsKey(fieldKey)) {
      // Always show previous data as guide text initially
      _repsControllers[fieldKey] = TextEditingController(text: previousReps);
      // Mark as showing previous data if we have previous data and current reps is 0
      if (previousReps != '0' && set.reps == 0) {
        _showingPreviousData[fieldKey] = true;
        // Don't update the actual set data - keep it as 0 so it's clearly a guide
      } else {
        _showingPreviousData[fieldKey] = false;
      }
    } else {
      // If controller exists but text is empty or "0", update it with previous data
      if (_repsControllers[fieldKey]!.text.isEmpty || _repsControllers[fieldKey]!.text == '0') {
        _repsControllers[fieldKey]!.text = previousReps;
        // Mark as showing previous data if we have previous data and current reps is 0
        if (previousReps != '0' && set.reps == 0) {
          _showingPreviousData[fieldKey] = true;
          // Don't update the actual set data - keep it as 0 so it's clearly a guide
        } else {
          _showingPreviousData[fieldKey] = false;
        }
      }
    }
    
    final repsController = _repsControllers[fieldKey]!;
    bool isShowingPreviousData = _showingPreviousData[fieldKey] ?? false;
    
    return TextField(
      controller: repsController,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
      ],
      onTap: () {
        if (isShowingPreviousData) {
          // Clear and set cursor at beginning without showing "0"
          repsController.text = '';
          repsController.selection = TextSelection.collapsed(offset: 0);
          // Mark as no longer showing previous data
          _showingPreviousData[fieldKey] = false;
        }
      },
      style: GoogleFonts.poppins(
        color: isCompleted ? Colors.white : (isShowingPreviousData ? Colors.grey[400] : Colors.white),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        hintText: isShowingPreviousData ? '' : '0',
        hintStyle: GoogleFonts.poppins(
          color: Colors.grey[500],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: false,
      ),
      onChanged: (value) {
        if (isShowingPreviousData && value.isNotEmpty) {
          // If user is typing over previous data, just use their input
          _updateSetReps(exercise, setIndex, int.tryParse(value) ?? 0);
          // Mark as no longer showing previous data
          _showingPreviousData[fieldKey] = false;
        } else if (value.isNotEmpty) {
          // Normal input
          _updateSetReps(exercise, setIndex, int.tryParse(value) ?? 0);
          // Mark as no longer showing previous data
          _showingPreviousData[fieldKey] = false;
        }
      },
      onSubmitted: (value) {
        final reps = int.tryParse(value) ?? 0;
        _updateSetReps(exercise, setIndex, reps);
        // Mark as no longer showing previous data
        _showingPreviousData[fieldKey] = false;
      },
    );
  }

  void _updateSetWeight(WorkoutExerciseModel exercise, int setIndex, double weight) {
    if (mounted) {
      try {
        // Use WidgetsBinding to schedule the setState after the current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (setIndex < exercise.loggedSets.length) {
                final currentSet = exercise.loggedSets[setIndex];
                final updatedSet = WorkoutSetModel(
                  reps: currentSet.reps,
                  weight: weight,
                  rpe: currentSet.rpe,
                  notes: currentSet.notes,
                  timestamp: currentSet.timestamp,
                  isCompleted: currentSet.isCompleted,
                );
                
                exercise.loggedSets[setIndex] = updatedSet;
                
                // Trigger rebuild to update volume calculation
                if (mounted) {
                  setState(() {});
                }
              }
            });
          }
        });
      } catch (e) {
        print('❌ Error in _updateSetWeight setState: $e');
      }
    }
  }

  void _updateSetReps(WorkoutExerciseModel exercise, int setIndex, int reps) {
    if (mounted) {
      try {
        // Use WidgetsBinding to schedule the setState after the current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              if (setIndex < exercise.loggedSets.length) {
                final currentSet = exercise.loggedSets[setIndex];
                final updatedSet = WorkoutSetModel(
                  reps: reps,
                  weight: currentSet.weight,
                  rpe: currentSet.rpe,
                  notes: currentSet.notes,
                  timestamp: currentSet.timestamp,
                  isCompleted: currentSet.isCompleted,
                );
                
                exercise.loggedSets[setIndex] = updatedSet;
                
                // Trigger rebuild to update volume calculation
                if (mounted) {
                  setState(() {});
                }
              }
            });
          }
        });
      } catch (e) {
        print('❌ Error in _updateSetReps setState: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(WorkoutExerciseModel exercise, int setIndex) async {
    final setNumber = setIndex + 1;
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red[400]!, Colors.red[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red[400]!.withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Delete Set $setNumber?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'This action cannot be undone',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 50,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  void _deleteSet(WorkoutExerciseModel exercise, int setIndex) {
    if (mounted && setIndex < exercise.loggedSets.length) {
      try {
        // Remove the set
        exercise.loggedSets.removeAt(setIndex);
        
        // Update completed sets count for this exercise
        exercise.completedSets = exercise.loggedSets.where((set) => set.isCompleted).length;
        
        // Update total completed sets across all exercises
        totalCompletedSets = workoutExercises.fold(0, (sum, ex) => sum + ex.completedSets);
        
        // Clean up and renumber all controllers for this exercise
        _cleanupAndRenumberControllers(exercise);
        
        // Trigger a rebuild to update the UI
        setState(() {});
      } catch (e) {
        print('❌ Error deleting set: $e');
      }
    }
  }

  Widget _buildClockModal() {
    return GestureDetector(
      onTap: () {
        setState(() {
          showClockModal = false;
          // Don't stop clock when closing modal
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap from bubbling up
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Clock',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              
              // Timer/Stopwatch Toggle
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isTimerMode = true;
                            // Keep clock running when switching modes - don't restart timer
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isTimerMode ? Color(0xFF007AFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Timer',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isTimerMode = false;
                            // Keep clock running when switching modes - don't restart timer
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isTimerMode ? Color(0xFF007AFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Stopwatch',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Mode Name with Animation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: Text(
                  isTimerMode ? 'Timer' : 'Stopwatch',
                  key: ValueKey(isTimerMode ? 'timer' : 'stopwatch'),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Time Display with Fixed Container
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF333333), width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Time display with animation
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: Text(
                        _formatClockTime(isTimerMode ? timerDuration : stopwatchDuration),
                        key: ValueKey(_formatClockTime(isTimerMode ? timerDuration : stopwatchDuration)),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Progress circles with consistent sizing
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      child: isTimerMode
                        ? CustomPaint(
                            key: ValueKey('timer_circle'),
                            size: Size(220, 220),
                            painter: ProgressCirclePainter(
                              progress: originalTimerDuration.inSeconds > 0 
                                  ? timerDuration.inSeconds / originalTimerDuration.inSeconds 
                                  : 1.0,
                              isTimer: true,
                              isRunning: isTimerRunning,
                            ),
                          )
                        : AnimatedBuilder(
                            key: ValueKey('stopwatch_circle'),
                            animation: AlwaysStoppedAnimation(circleRotation),
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: circleRotation,
                                child: CustomPaint(
                                  size: Size(220, 220),
                                  painter: ProgressCirclePainter(
                                    progress: 0.95, // 95% of circle (5% gap)
                                    isTimer: false,
                                    isRunning: isStopwatchRunning,
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Timer Controls with Animation
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: isTimerMode ? 40 : 0,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isTimerMode ? 1.0 : 0.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            timerDuration = Duration(
                              seconds: (timerDuration.inSeconds - 15).clamp(0, 3600),
                            );
                            originalTimerDuration = timerDuration;
                          });
                          // Save timer state when user adjusts clock timer
                          _saveTimerState();
                        },
                        child: Text(
                          '-15s',
                          style: GoogleFonts.poppins(
                            color: Color(0xFF007AFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            timerDuration = Duration(
                              seconds: (timerDuration.inSeconds + 15).clamp(0, 3600),
                            );
                            originalTimerDuration = timerDuration;
                          });
                          // Save timer state when user adjusts clock timer
                          _saveTimerState();
                        },
                        child: Text(
                          '+15s',
                          style: GoogleFonts.poppins(
                            color: Color(0xFF007AFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              
              // Action Buttons
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Row(
                  children: [
                    if (!isTimerMode && !isStopwatchRunning) ...[
                      Expanded(
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 50,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                stopwatchDuration = Duration.zero;
                                _stopClock();
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: (isTimerMode ? isTimerRunning : isStopwatchRunning) ? 0 : 16,
                        child: SizedBox(width: 16),
                      ),
                    ],
                    Expanded(
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            if ((isTimerMode ? isTimerRunning : isStopwatchRunning)) {
                              _stopClock();
                            } else {
                              _startClock();
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: (isTimerMode ? isTimerRunning : isStopwatchRunning) ? Colors.red[600] : Color(0xFF007AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 200),
                            child: Text(
                              (isTimerMode ? isTimerRunning : isStopwatchRunning) ? 'Stop' : 'Start',
                              key: ValueKey((isTimerMode ? isTimerRunning : isStopwatchRunning) ? 'stop' : 'start'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatClockTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _startClock() {
    // Don't start if already running
    if ((isTimerMode && isTimerRunning) || (!isTimerMode && isStopwatchRunning)) {
      return;
    }
    
    // Cancel any existing timer first to prevent multiple timers
    clockTimer?.cancel();
    
    setState(() {
      if (isTimerMode) {
        isTimerRunning = true;
        originalTimerDuration = timerDuration;
      } else {
        isStopwatchRunning = true;
      }
    });
    
    // Start the racing circle animation
    _startCircleAnimation();
    
    // Create a single, stable timer that runs every second
    clockTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        // Update timer if it's running (regardless of current mode)
        if (isTimerRunning) {
          if (timerDuration.inSeconds > 0) {
            timerDuration = Duration(seconds: timerDuration.inSeconds - 1);
          } else {
            // Timer finished - stop only the timer
            isTimerRunning = false;
            // Could add notification here
          }
        }
        
        // Update stopwatch if it's running (regardless of current mode)
        if (isStopwatchRunning) {
          stopwatchDuration = Duration(seconds: stopwatchDuration.inSeconds + 1);
        }
      });
    });
  }

  void _stopClock() {
    setState(() {
      if (isTimerMode) {
        isTimerRunning = false;
      } else {
        isStopwatchRunning = false;
      }
    });
    
    // Only cancel timer if both are stopped
    if (!isTimerRunning && !isStopwatchRunning) {
      clockTimer?.cancel();
      _stopCircleAnimation();
    }
  }

  void _startCircleAnimation() {
    // Cancel any existing animation timer first
    _stopCircleAnimation();
    
    // Create a super fast and smooth rotation animation
    animationTimer = Timer.periodic(Duration(milliseconds: 16), (timer) { // 60 FPS for ultra smooth animation
      if (!mounted || (!isTimerRunning && !isStopwatchRunning)) {
        timer.cancel();
        return;
      }
      
      setState(() {
        circleRotation += 0.3; // Much faster rotation speed
        if (circleRotation >= 2 * 3.14159) {
          circleRotation = 0.0; // Reset to prevent overflow
        }
      });
    });
  }

  void _stopCircleAnimation() {
    animationTimer?.cancel();
    animationTimer = null;
  }

  void _cleanupAndRenumberControllers(WorkoutExerciseModel exercise) {
    // Get all controllers for this exercise
    final exerciseWeightKeys = _weightControllers.keys
        .where((key) => key.startsWith('${exercise.name}_'))
        .toList();
    final exerciseRepsKeys = _repsControllers.keys
        .where((key) => key.startsWith('${exercise.name}_'))
        .toList();
    
    // Dispose all existing controllers for this exercise
    for (String key in exerciseWeightKeys) {
      _weightControllers[key]?.dispose();
      _weightControllers.remove(key);
    }
    for (String key in exerciseRepsKeys) {
      _repsControllers[key]?.dispose();
      _repsControllers.remove(key);
    }
    
    // Create new controllers with correct numbering (0, 1, 2, 3...)
    for (int i = 0; i < exercise.loggedSets.length; i++) {
      final weightKey = '${exercise.name}_${i}_weight';
      final repsKey = '${exercise.name}_${i}_reps';
      
      // Get previous workout data for this set
      final previousData = _getPreviousWorkoutData(exercise.name, i);
      final previousWeight = previousData?['weight']?.toStringAsFixed(0) ?? '0';
      final previousReps = previousData?['reps']?.toString() ?? '0';
      
      // Create controllers with previous data if current set is empty
      final currentSet = exercise.loggedSets[i];
      String weightText = '';
      String repsText = '';
      
      if (currentSet.weight > 0) {
        weightText = currentSet.weight.toString();
      } else if (previousData != null) {
        weightText = previousWeight;
      }
      
      if (currentSet.reps > 0) {
        repsText = currentSet.reps.toString();
      } else if (previousData != null) {
        repsText = previousReps;
      }
      
      _weightControllers[weightKey] = TextEditingController(text: weightText);
      _repsControllers[repsKey] = TextEditingController(text: repsText);
    }
  }

  void _showExerciseInstructions(WorkoutExerciseModel exercise) {
    final exerciseModel = ExerciseModel(
      id: exercise.exerciseId,
      name: exercise.name,
      targetSets: exercise.sets,
      targetReps: exercise.reps,
      targetWeight: exercise.formattedWeight,
      category: exercise.category,
      difficulty: exercise.difficulty,
      color: '0xFF4ECDC4',
      restTime: exercise.restTime,
      targetMuscle: exercise.targetMuscle,
      description: exercise.description,
      imageUrl: exercise.imageUrl,
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

  String _formatRestTime(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}min';
      } else {
        return '${minutes}min ${remainingSeconds}s';
      }
    }
  }

  void _showRestTimerPicker(WorkoutExerciseModel exercise) {
    final exerciseKey = '${exercise.exerciseId}_${exercise.name}';
    final currentRestTime = exerciseRestTimes[exerciseKey] ?? 0; // 0 means OFF
    
    // Rest time options with OFF option
    final restTimeOptions = [
      {'label': 'OFF', 'value': 0, 'icon': Icons.timer_off},
      {'label': '30s', 'value': 30, 'icon': Icons.timer},
      {'label': '1min', 'value': 60, 'icon': Icons.timer},
      {'label': '1.5min', 'value': 90, 'icon': Icons.timer},
      {'label': '2min', 'value': 120, 'icon': Icons.timer},
      {'label': '3min', 'value': 180, 'icon': Icons.timer},
      {'label': '5min', 'value': 300, 'icon': Icons.timer},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF007AFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer,
                      color: Color(0xFF007AFF),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Rest Timer',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable options
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: restTimeOptions.map((option) => 
                    Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              exerciseRestTimes[exerciseKey] = option['value'] as int;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: currentRestTime == option['value'] 
                                  ? Color(0xFF007AFF).withOpacity(0.2)
                                  : Color(0xFF2A2A2A).withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                              border: currentRestTime == option['value']
                                  ? Border.all(color: Color(0xFF007AFF), width: 2)
                                  : null,
                              boxShadow: currentRestTime == option['value']
                                  ? [
                                      BoxShadow(
                                        color: Color(0xFF007AFF).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: currentRestTime == option['value']
                                        ? Color(0xFF007AFF)
                                        : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    option['icon'] as IconData,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    option['label'] as String,
                                    style: GoogleFonts.poppins(
                                      color: currentRestTime == option['value']
                                          ? Colors.white
                                          : Colors.grey[300],
                                      fontSize: 16,
                                      fontWeight: currentRestTime == option['value']
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (currentRestTime == option['value'])
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF007AFF),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  void _addExerciseToWorkout(ExerciseModel exercise) {
    print('🔄 Adding exercise to workout: ${exercise.name} (ID: ${exercise.id})');
    
    // Create a new WorkoutExerciseModel from the ExerciseModel
    final newWorkoutExercise = WorkoutExerciseModel(
      exerciseId: exercise.id,
      name: exercise.name,
      sets: 3, // Default 3 sets
      reps: '10', // Default 10 reps (String type)
      weight: 0, // Default weight
      restTime: 120, // Default 2 minutes rest
      loggedSets: [
        WorkoutSetModel(
          weight: 0,
          reps: 0,
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
        WorkoutSetModel(
          weight: 0,
          reps: 0,
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
        WorkoutSetModel(
          weight: 0,
          reps: 0,
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
      ],
    );

    setState(() {
      workoutExercises.add(newWorkoutExercise);
      
      // Initialize rest time for this exercise
      final exerciseKey = '${exercise.id}_${exercise.name}';
      exerciseRestTimes[exerciseKey] = 120; // Default 2 minutes
    });

    print('✅ Exercise added to local workout list. Now saving to database...');

    // Add exercise to the routine in the database
    _addExerciseToRoutine(exercise.id, 3, 10, 0.0);
  }

  Future<void> _addExerciseToRoutine(int? exerciseId, int sets, int reps, double weight) async {
    if (exerciseId == null) return;
    
    try {
      // Get user ID from AuthService (the correct source)
      final prefs = await SharedPreferences.getInstance();
      
      // Get from 'current_user_id' key (not 'user_id')
      final userId = prefs.getInt('current_user_id');
      
      print('🔍 Getting user ID from SharedPreferences...');
      print('🔍 current_user_id: $userId');
      
      if (userId == null) {
        print('❌ User ID not found in SharedPreferences (key: current_user_id)');
        print('🔍 Available keys: ${prefs.getKeys()}');
        return;
      }
      
      print('📤 Sending API request to add exercise to routine:');
      print('   routine_id: ${widget.routine.id}');
      print('   user_id: $userId');
      print('   exercise_id: $exerciseId');
      print('   sets: $sets, reps: $reps, weight: $weight');
      
      final requestBody = {
        'action': 'add_exercise_to_routine',
        'routine_id': widget.routine.id,
        'user_id': userId,
        'exercise_id': exerciseId,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };
      
      print('📦 Request body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/routines.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 API Response: ${responseData}');
        if (responseData['success'] == true) {
          final exerciseName = responseData['exercise_name'] ?? 'Unknown';
          print('✅ EXERCISE SAVED TO ROUTINE PERMANENTLY!');
          print('   Exercise: $exerciseName');
          print('   Member Workout Exercise ID: ${responseData['member_workout_exercise_id']}');
          
          // Show success message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $exerciseName added to routine permanently!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Update the workout exercise with the database ID
          if (responseData['member_workout_exercise_id'] != null) {
            final exerciseToUpdate = workoutExercises.lastWhere(
              (e) => e.exerciseId == exerciseId,
              orElse: null,
            );
            if (exerciseToUpdate != null) {
              print('💾 Updated exercise with database ID: ${responseData['member_workout_exercise_id']}');
            }
          }
        } else {
          print('❌ Failed to add exercise to routine: ${responseData['error'] ?? responseData['message']}');
          print('📊 Debug Info: ${responseData['debug_info']}');
          
          // Show error message to user with debug info
          String errorMessage = responseData['error'] ?? responseData['message'] ?? 'Unknown error';
          if (responseData['debug_info'] != null) {
            errorMessage = '$errorMessage\n(${responseData['debug_info']['message'] ?? ''})';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to save to routine: $errorMessage'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error connecting to server'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error adding exercise to routine: $e');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
    print('🎯 _buildWorkoutScreen called - showRestTimer: $showRestTimer, restTimeRemaining: $restTimeRemaining');
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
      ],
    );
  }

  Widget _buildStickyRestTimer() {
    print('🎯 _buildStickyRestTimer called - restTimeRemaining: $restTimeRemaining');
    
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions
    final isSmallScreen = screenWidth < 400 || screenHeight < 700;
    final padding = isSmallScreen ? 12.0 : 16.0;
    final fontSize = isSmallScreen ? 24.0 : 32.0;
    final buttonFontSize = isSmallScreen ? 12.0 : 14.0;
    final spacing = isSmallScreen ? 8.0 : 12.0;
    final buttonPadding = isSmallScreen ? 12.0 : 16.0;
    
    // Calculate progress for the blue progress bar
    final currentExercise = workoutExercises.isNotEmpty ? workoutExercises[currentExerciseIndex] : null;
    final exerciseKey = currentExercise != null ? '${currentExercise.exerciseId}_${currentExercise.name}' : '';
    final totalRestTime = exerciseRestTimes[exerciseKey] ?? 0;
    final progress = totalRestTime > 0 ? (totalRestTime - restTimeRemaining) / totalRestTime : 0.0;
    
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue progress bar at the top - thicker
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Stack(
              children: [
                // Full background bar (always full)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Blue progress bar that shrinks from right
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (1.0 - progress).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          
          // Timer display - bigger text
          Text(
            _formatTime(restTimeRemaining),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 12),
          
          // Control buttons - wider buttons with less space
          Row(
            children: [
              Expanded(
                child: _buildTimerButton('-15', () => _adjustTimer(-15)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTimerButton('+15', () => _adjustTimer(15)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTimerButton('Skip', () {
                  _stopRestTimer();
                  if (!mounted) return;
                  setState(() {
                    showRestTimer = false;
                  });
                }, isPrimary: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimerButton(String text, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? Color(0xFF007AFF) : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
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

  // Load latest workout data for PREVIOUS column
  Future<void> _loadLatestWorkoutData() async {
    try {
      // Get all progress data
      final allProgress = await ProgressAnalyticsService.getAllProgress();
      
      if (allProgress.isNotEmpty) {
        // Process each exercise
        for (String exerciseName in allProgress.keys) {
          final exerciseData = allProgress[exerciseName] ?? [];
          
          if (exerciseData.isNotEmpty) {
            // Sort by date (newest first) and take the latest workout
            exerciseData.sort((a, b) => b.date.compareTo(a.date));
            
            // Group by workout session (same date)
            Map<String, List<Map<String, dynamic>>> sessionData = {};
            
            for (final record in exerciseData) {
              final dateKey = '${record.date.year}-${record.date.month}-${record.date.day}';
              if (!sessionData.containsKey(dateKey)) {
                sessionData[dateKey] = [];
              }
              sessionData[dateKey]!.add({
                'weight': record.weight,
                'reps': record.reps,
                'sets': record.sets,
                'date': record.date,
              });
            }
            
            // Get the most recent session
            if (sessionData.isNotEmpty) {
              // Sort date keys properly by converting to DateTime
              final sortedDateKeys = sessionData.keys.toList()..sort((a, b) {
                try {
                  // Parse date keys with proper formatting
                  final dateA = _parseDateKey(a);
                  final dateB = _parseDateKey(b);
                  return dateB.compareTo(dateA); // Newest first
                } catch (e) {
                  return b.compareTo(a); // Fallback to string comparison
                }
              });
              final latestSessionKey = sortedDateKeys.first;
              latestWorkoutData[exerciseName] = sessionData[latestSessionKey] ?? [];
            }
          }
        }
        
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ WORKOUT SESSION: Error loading latest workout data: $e');
    }
  }

  // Get previous workout data for a specific exercise and set
  Map<String, dynamic>? _getPreviousWorkoutData(String exerciseName, int setIndex) {
    final exerciseData = latestWorkoutData[exerciseName];
    if (exerciseData != null && setIndex < exerciseData.length) {
      final data = exerciseData[setIndex];
      return data;
    }
    return null;
  }


  // Helper method to parse date keys with proper formatting
  DateTime _parseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('❌ Error parsing date key "$dateKey": $e');
    }
    return DateTime.now();
  }

  // Get previous workout text for display
  String _getPreviousWorkoutText(String exerciseName, int setIndex) {
    final previousData = _getPreviousWorkoutData(exerciseName, setIndex);
    if (previousData != null) {
      final weight = previousData['weight']?.toStringAsFixed(0) ?? '0';
      final reps = previousData['reps']?.toString() ?? '0';
      return '${weight}kg x $reps';
    }
    return '-';
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

class ProgressCirclePainter extends CustomPainter {
  final double progress;
  final bool isTimer;
  final bool isRunning;

  ProgressCirclePainter({
    required this.progress,
    required this.isTimer,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2; // Account for stroke width
    
    final paint = Paint()
      ..color = Color(0xFF007AFF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isTimer) {
      // Timer: Always show circle, but adjust based on progress
      if (progress < 1.0) {
        // Show remaining time as blue arc
        double remainingAngle = 2 * 3.14159 * progress; // How much should be visible
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -3.14159 / 2, // Start from top (-π/2)
          remainingAngle,
          false,
          paint,
        );
      } else {
        // Show full circle when at 100% (not started or reset)
        canvas.drawCircle(center, radius, paint);
      }
    } else {
      // Stopwatch: Draw 95% circle with small gap that spins
      if (isRunning) {
        double circleAngle = 2 * 3.14159 * progress; // 95% of circle (5% gap)
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -3.14159 / 2, // Start from top (-π/2)
          circleAngle,
          false,
          paint,
        );
      } else {
        // Show full circle when stopped
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.isTimer != isTimer || 
           oldDelegate.isRunning != isRunning;
  }
}
