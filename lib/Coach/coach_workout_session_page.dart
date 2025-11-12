import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import '../User/models/routine.models.dart' as UserModels;
import '../User/models/workoutpreview_model.dart';
import '../User/exercise_instructions_page.dart';
import '../User/services/session_tracking_service.dart';
import 'models/member_model.dart';
import 'services/coach_service.dart';
import 'package:http/http.dart' as http;
import 'coach_workout_summary_page.dart';

class CoachWorkoutSessionPage extends StatefulWidget {
  final UserModels.RoutineModel routine;
  final List<UserModels.ExerciseModel> exercises;
  final MemberModel selectedMember;

  const CoachWorkoutSessionPage({
    Key? key,
    required this.routine,
    required this.exercises,
    required this.selectedMember,
  }) : super(key: key);

  @override
  _CoachWorkoutSessionPageState createState() => _CoachWorkoutSessionPageState();
}

class _CoachWorkoutSessionPageState extends State<CoachWorkoutSessionPage> {
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
  
  // Rest timer picker state
  Map<String, int> exerciseRestTimes = {}; // Store rest time for each exercise
  
  List<WorkoutExerciseModel> workoutExercises = [];
  DateTime workoutStartTime = DateTime.now();
  Timer? durationTimer;
  
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

  @override
  void initState() {
    super.initState();
    print('🚀 CoachWorkoutSessionPage: initState() called - mounted: $mounted');
    try {
      _initializeWorkout();
      _startDurationTimer();
      // Load workout data after a short delay to ensure workoutExercises is set
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _loadLatestWorkoutData();
        }
      });
      
    } catch (e) {
      print('❌ CoachWorkoutSessionPage: Initialization error: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh latest workout data when page becomes visible (only if workout is initialized)
    if (workoutExercises.isNotEmpty) {
      _loadLatestWorkoutData();
    }
  }

  @override
  void dispose() {
    restTimer?.cancel();
    durationTimer?.cancel();
    _weightControllers.values.forEach((controller) => controller.dispose());
    _repsControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeWorkout() {
    print('🔄 CoachWorkoutSessionPage: Initializing workout...');
    workoutExercises = widget.exercises.map((exercise) {
      try {
        print('🔄 Processing exercise: ${exercise.name}');
        
        // Create logged sets with 0 values to allow coach input (same as user version)
        List<WorkoutSetModel> loggedSets = exercise.sets.map((set) {
          return WorkoutSetModel(
            reps: 0, // Start with 0 so coach can input their own values
            weight: 0.0, // Start with 0 so coach can input their own values
            timestamp: set.timestamp ?? DateTime.now(),
            isCompleted: false,
          );
        }).toList();
        
        // Calculate target sets
        int targetSets = exercise.targetSets ?? exercise.sets.length;
        
        return WorkoutExerciseModel(
          exerciseId: exercise.id,
          name: exercise.name,
          sets: targetSets,
          reps: exercise.targetReps,
          weight: double.tryParse(exercise.targetWeight) ?? 0.0,
          category: exercise.category,
          difficulty: exercise.difficulty,
          restTime: exercise.restTime,
          targetMuscle: exercise.targetMuscle,
          description: exercise.description,
          imageUrl: exercise.imageUrl,
          completedSets: exercise.completedSets,
          isCompleted: exercise.completed,
          loggedSets: loggedSets,
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
      print('🎯 Exercise key: $exerciseKey, Rest time: ${exerciseRestTimes[exerciseKey]}');
    }
        
    if (workoutExercises.isNotEmpty) {
      currentSetIndex = workoutExercises[currentExerciseIndex].completedSets;
    }
    print('✅ CoachWorkoutSessionPage: Workout initialized with ${workoutExercises.length} exercises');
  }

  void _logSet(int setIndex, String reps, String weight) {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
    if (setIndex >= currentExercise.sets) return;

    int repsInt = int.tryParse(reps) ?? 0;
    double weightDouble = double.tryParse(weight) ?? 0.0;

    print('🔍 COACH INPUT - Set ${setIndex + 1}: ${weightDouble}kg x ${repsInt} reps');
    print('🔍 COACH INPUT - Raw input: reps="$reps", weight="$weight"');

    if (!mounted) return;
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

    // Log the individual set to the API in real-time
    _logIndividualSetToAPI(currentExercise, setIndex, repsInt, weightDouble);

    if (currentExercise.completedSets >= currentExercise.sets) {
      currentExercise.isCompleted = true;
      _showExerciseCompletedModal();
    } else {
      if (!mounted) return;
      
      // Get the exercise-specific rest time
      final exerciseKey = '${currentExercise.exerciseId}_${currentExercise.name}';
      final exerciseRestTime = exerciseRestTimes[exerciseKey] ?? 0;
      
      print('🔍 REST TIMER DEBUG:');
      print('🔍 Exercise: ${currentExercise.name}');
      print('🔍 Exercise key: $exerciseKey');
      print('🔍 Exercise rest time from model: ${currentExercise.restTime}');
      print('🔍 Exercise rest time from map: $exerciseRestTime');
      print('🔍 All exercise rest times: $exerciseRestTimes');
      
      if (exerciseRestTime > 0) {
        // Start the rest timer with exercise-specific time
        print('🎯 Setting showRestTimer = true, exerciseRestTime: $exerciseRestTime');
        setState(() {
          showRestTimer = true;
          restTimeRemaining = exerciseRestTime;
          print('🎯 Inside setState - showRestTimer set to: $showRestTimer, restTimeRemaining: $restTimeRemaining');
        });
        _startRestTimer();
      } else {
        print('🎯 Exercise rest time is 0, not showing timer');
      }
    }
  }

  void _navigateToInstructions() {
    if (workoutExercises.isEmpty || currentExerciseIndex >= workoutExercises.length) return;
    final currentExercise = workoutExercises[currentExerciseIndex];
        
    final exerciseModel = UserModels.ExerciseModel(
      id: currentExercise.exerciseId,
      name: currentExercise.name,
      targetSets: currentExercise.sets,
      targetReps: currentExercise.reps,
      targetWeight: currentExercise.weight.toString(),
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

  void _startRestTimer() {
    if (!mounted) return;
    
    // Don't start timer if rest time is OFF (0)
    if (restTimeRemaining == 0) {
      print('Rest timer is OFF');
      return;
    }
    
    setState(() {
      isTimerRunning = true;
      print('Starting timer: ${restTimeRemaining}s');
    });
    print('⏰ Starting rest timer');
    restTimer?.cancel(); // Cancel any existing timer
    restTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      print('⏰ Rest timer tick - mounted: $mounted, restTimeRemaining: $restTimeRemaining');
      if (!mounted) {
        print('⏰ Rest timer: Widget not mounted, canceling');
        timer.cancel();
        return;
      }
      if (restTimeRemaining > 0) {
        try {
          print('⏰ Rest timer: Calling setState to decrement');
          setState(() {
            restTimeRemaining--;
          });
          print('⏰ Rest timer: setState completed');
        } catch (e) {
          print('❌ Error in rest timer setState: $e');
          print('❌ Stack trace: ${StackTrace.current}');
          timer.cancel();
        }
      } else {
        print('⏰ Rest timer: Time up, canceling');
        timer.cancel();
        if (!mounted) {
          print('⏰ Rest timer: Widget not mounted after completion');
          return;
        }
        try {
          print('⏰ Rest timer: Calling setState for completion');
          setState(() {
            isTimerRunning = false;
            showRestTimer = false;
          });
          print('⏰ Rest timer: Completion setState done');
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
    
    setState(() {
      isTimerRunning = false;
      showRestTimer = false;
    });
  }

  void _adjustTimer(int seconds) {
    if (!mounted) return;
    setState(() {
      restTimeRemaining = (restTimeRemaining + seconds).clamp(0, 600); // Max 10 minutes
    });
  }

  void _startDurationTimer() {
    durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        // Timer updates every second for duration display
      });
    });
  }

  void _loadLatestWorkoutData() async {
    try {
      print('🔄 Loading latest workout data for client: ${widget.selectedMember.id}');
      
      // Get all progress data for the client
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/progress_tracker.php?action=get_all_progress&user_id=${widget.selectedMember.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Progress API response status: ${response.statusCode}');
      print('📄 Progress API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed progress data: $data');
        
        // API returns data in 'data' field, not 'progress'
        if (data['success'] == true && data['data'] != null) {
          final allProgress = data['data'];
          print('📊 All progress data: $allProgress');
          print('📊 Progress keys: ${allProgress.keys.toList()}');
          
          // Process each exercise
          for (String exerciseName in allProgress.keys) {
            final exerciseData = allProgress[exerciseName] ?? [];
            
            if (exerciseData.isNotEmpty) {
              // Sort by date (newest first) and take the latest workout
              exerciseData.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
              
              // Group by workout session (same date)
              Map<String, List<Map<String, dynamic>>> sessionData = {};
              
              for (final record in exerciseData) {
                try {
                  final dateKey = DateTime.parse(record['date']).toIso8601String().split('T')[0];
                  if (!sessionData.containsKey(dateKey)) {
                    sessionData[dateKey] = [];
                  }
                  // Parse weight and reps as numbers (they come as strings from API)
                  final weight = double.tryParse(record['weight']?.toString() ?? '0') ?? 0.0;
                  final reps = int.tryParse(record['reps']?.toString() ?? '0') ?? 0;
                  
                  sessionData[dateKey]!.add({
                    'weight': weight,
                    'reps': reps,
                    'sets': record['sets'],
                    'date': DateTime.parse(record['date']),
                  });
                } catch (e) {
                  print('⚠️ Error parsing record: $e');
                }
              }
              
              // Get the most recent session
              if (sessionData.isNotEmpty) {
                final sortedDates = sessionData.keys.toList()..sort((a, b) => b.compareTo(a));
                final latestDate = sortedDates.first;
                var latestSessionData = sessionData[latestDate]!;
                
                // Sort by date/time within the session to maintain set order
                latestSessionData.sort((a, b) {
                  final dateA = a['date'] as DateTime;
                  final dateB = b['date'] as DateTime;
                  return dateA.compareTo(dateB);
                });
                
                // Store the latest workout data for this exercise
                latestWorkoutData[exerciseName] = latestSessionData;
                print('📊 Loaded latest data for $exerciseName: ${latestSessionData.length} sets');
                print('📊 Latest session data: $latestSessionData');
              }
            }
          }
          
          print('✅ Loaded workout data for ${latestWorkoutData.length} exercises');
          print('📊 Latest workout data keys: ${latestWorkoutData.keys.toList()}');
          
          // Trigger UI update to show previous data in controllers
          if (mounted && workoutExercises.isNotEmpty) {
            print('🔄 Initializing controllers with previous data for ${workoutExercises.length} exercises');
            print('📊 Available exercise names in latestWorkoutData: ${latestWorkoutData.keys.toList()}');
            setState(() {
              // Re-initialize controllers with previous data for all exercises
              for (var exercise in workoutExercises) {
                print('🔄 Processing exercise: "${exercise.name}"');
                print('   - Looking for matching data in latestWorkoutData...');
                print('   - Has data: ${latestWorkoutData.containsKey(exercise.name)}');
                
                for (int i = 0; i < exercise.loggedSets.length; i++) {
                  final previousData = _getPreviousWorkoutData(exercise.name, i);
                  print('🔍 Set $i previous data: $previousData');
                  if (previousData != null) {
                    final weightKey = '${exercise.name}_${i}_weight';
                    final repsKey = '${exercise.name}_${i}_reps';
                    
                    final previousWeight = previousData['weight']?.toStringAsFixed(0) ?? '0';
                    final previousReps = previousData['reps']?.toString() ?? '0';
                    
                    // Initialize or update weight controller
                    if (!_weightControllers.containsKey(weightKey)) {
                      _weightControllers[weightKey] = TextEditingController(text: previousWeight);
                      print('✅ Created weight controller for set $i: $previousWeight');
                      if (previousWeight != '0' && exercise.loggedSets[i].weight == 0) {
                        _showingPreviousData[weightKey] = true;
                      }
                    } else {
                      // Always update if current weight is 0 (not user-entered) and we have previous data
                      final currentText = _weightControllers[weightKey]!.text;
                      if (exercise.loggedSets[i].weight == 0) {
                        // Update if: text is empty/0 OR we have new previous data that's different
                        if (currentText.isEmpty || currentText == '0' || (previousWeight != '0' && currentText != previousWeight)) {
                          _weightControllers[weightKey]!.text = previousWeight;
                          print('✅ Updated weight controller for set $i: $previousWeight (was: $currentText)');
                          if (previousWeight != '0') {
                            _showingPreviousData[weightKey] = true;
                          }
                        }
                      }
                    }
                    
                    // Initialize or update reps controller
                    if (!_repsControllers.containsKey(repsKey)) {
                      _repsControllers[repsKey] = TextEditingController(text: previousReps);
                      print('✅ Created reps controller for set $i: $previousReps');
                      if (previousReps != '0' && exercise.loggedSets[i].reps == 0) {
                        _showingPreviousData[repsKey] = true;
                      }
                    } else {
                      // Always update if current reps is 0 (not user-entered) and we have previous data
                      final currentText = _repsControllers[repsKey]!.text;
                      if (exercise.loggedSets[i].reps == 0) {
                        // Update if: text is empty/0 OR we have new previous data that's different
                        if (currentText.isEmpty || currentText == '0' || (previousReps != '0' && currentText != previousReps)) {
                          _repsControllers[repsKey]!.text = previousReps;
                          print('✅ Updated reps controller for set $i: $previousReps (was: $currentText)');
                          if (previousReps != '0') {
                            _showingPreviousData[repsKey] = true;
                          }
                        }
                      }
                    }
                  }
                }
              }
            });
          }
        } else {
          print('⚠️ API response success is false or data is null');
          print('   - success: ${data['success']}');
          print('   - data: ${data['data']}');
        }
      } else {
        print('⚠️ API response status is not 200: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading latest workout data: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  void _showExerciseCompletedModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exercise Completed!',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Great job! Ready for the next exercise?',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextExercise();
            },
            child: Text(
              'Next Exercise',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextExercise() {
    if (currentExerciseIndex < workoutExercises.length - 1) {
      setState(() {
        currentExerciseIndex++;
        currentSetIndex = 0;
        showRestTimer = false;
        isTimerRunning = false;
        restTimer?.cancel();
      });
    } else {
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Workout Complete!',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Excellent work! The workout has been completed for ${widget.selectedMember.fullName}.',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveWorkout();
            },
            child: Text(
              'Save Workout',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (isSavingWorkout) return;
    
    // Check if there's at least one completed set
    final totalCompletedSets = workoutExercises.fold(0, (sum, exercise) => 
        sum + exercise.loggedSets.where((set) => set.isCompleted).length);
    
    if (totalCompletedSets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete at least one set before saving the workout.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    
    setState(() {
      isSavingWorkout = true;
    });

    try {
      final duration = DateTime.now().difference(workoutStartTime).inMinutes;
      final success = await _completeWorkoutForClient(
        widget.routine.id,
        workoutExercises,
        duration,
        widget.selectedMember.id,
      );

      if (success) {
        if (mounted) {
          // Calculate workout metrics for summary
          final workoutDuration = DateTime.now().difference(workoutStartTime);
          final totalVolume = workoutExercises.fold(0.0, (sum, exercise) => 
              sum + exercise.loggedSets.where((set) => set.isCompleted)
                  .fold(0.0, (setSum, set) => setSum + (set.weight * set.reps)));
          final totalSets = workoutExercises.fold(0, (sum, exercise) => sum + exercise.completedSets);
          
          // Navigate to workout summary page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CoachWorkoutSummaryPage(
                routine: widget.routine,
                exercises: workoutExercises,
                workoutDuration: workoutDuration,
                totalVolume: totalVolume,
                totalSets: totalSets,
                selectedMember: widget.selectedMember,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save workout. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSavingWorkout = false;
        });
      }
    }
  }

  // Custom method to complete workout for a specific client
  Future<bool> _completeWorkoutForClient(String routineId, List<WorkoutExerciseModel> exercises, int duration, int clientId) async {
    try {
      print('✅ Coach completing workout session for routine: $routineId, client: $clientId');
      
      // Calculate workout stats
      final totalVolume = exercises.fold(0.0, (sum, exercise) => sum + exercise.totalVolume);
      final completedExercises = exercises.where((e) => e.isCompleted).length;
      final totalSets = exercises.fold(0, (sum, exercise) => sum + exercise.completedSets);
      
      final requestData = {
        "action": "completeWorkout",
        "routine_id": routineId,
        "user_id": clientId, // Use client's ID instead of coach's ID
        "duration": duration,
        "total_volume": totalVolume,
        "completed_exercises": completedExercises,
        "total_exercises": exercises.length,
        "total_sets": totalSets,
        "exercises": exercises.map((exercise) => {
          "exercise_id": exercise.exerciseId,
          "member_workout_exercise_id": exercise.memberWorkoutExerciseId ?? 0,
          "completed_sets": exercise.completedSets,
          "is_completed": exercise.isCompleted,
          "logged_sets": exercise.loggedSets.map((set) => set.toJson()).toList(),
        }).toList(),
      };
      
      print('📤 Complete workout request: ${json.encode(requestData)}');
      
      // Debug: Check what's in loggedSets for each exercise
      for (final exercise in exercises) {
        print('🔍 DEBUG - Exercise: ${exercise.name}');
        print('🔍 DEBUG - loggedSets count: ${exercise.loggedSets.length}');
        for (int i = 0; i < exercise.loggedSets.length; i++) {
          final set = exercise.loggedSets[i];
          print('🔍 DEBUG - Set ${i + 1}: ${set.weight}kg x ${set.reps} reps');
        }
      }
      
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );
      
      print('📊 Complete workout response status: ${response.statusCode}');
      print('📋 Complete workout response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['success'] == true;
        
        if (success) {
          print('✅ Workout completed successfully for client $clientId');
          
          // Update program weights with latest logged weights
          await _updateProgramWeightsSimple(routineId, exercises);
          
          // Also save all completed exercises to progress tracker for progressive overload
          await _saveAllExercisesToProgressTracker(routineId, exercises, clientId);
          
          // Show modal to ask coach if they want to deduct session
          if (mounted) {
            await _showSessionDeductionModal(clientId);
          }
        }
        
        return success;
      }
      
      return false;
    } catch (e) {
      print('💥 Error completing workout session for client: $e');
      return false;
    }
  }

  // Show modal to ask coach if they want to deduct session
  Future<void> _showSessionDeductionModal(int memberId) async {
    try {
      // Get coach ID
      final coachId = await CoachService.getCoachId();
      if (coachId == 0) {
        print('❌ SESSION DEDUCTION: Coach ID is 0, cannot check sessions');
        return;
      }

      // Get current session status
      final sessionStatus = await SessionTrackingService.checkSessionAvailability(
        userId: memberId,
        coachId: coachId,
      );

      // Get remaining sessions from session status
      final remainingSessions = sessionStatus.remainingSessions;

      if (!mounted) return;

      // Show modal
      final shouldDeduct = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _SessionDeductionModal(
          remainingSessions: remainingSessions,
          memberName: widget.selectedMember.fullName,
          canDeduct: sessionStatus.canStartWorkout,
        ),
      );

      // Deduct session if coach chose to do so
      if (shouldDeduct == true) {
        await _deductSession(memberId, coachId);
      }
    } catch (e) {
      print('❌ SESSION DEDUCTION: Error showing modal: $e');
    }
  }

  // Deduct session
  Future<void> _deductSession(int memberId, int coachId) async {
    try {
      print('🔄 SESSION DEDUCTION: Deducting session for member $memberId');
      
      // Deduct session
      final deductionResult = await SessionTrackingService.deductSession(
        userId: memberId,
        coachId: coachId,
      );

      if (deductionResult.success && mounted) {
        print('✅ SESSION DEDUCTION: Session deducted successfully. ${deductionResult.remainingSessions} sessions remaining.');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session deducted. ${deductionResult.remainingSessions} sessions remaining.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        print('❌ SESSION DEDUCTION: Failed to deduct session: ${deductionResult.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deduct session: ${deductionResult.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ SESSION DEDUCTION: Error deducting session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deducting session: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Update program weights with latest logged weights
  static Future<void> _updateProgramWeightsSimple(String routineId, List<WorkoutExerciseModel> exercises) async {
    try {
      print('🔄 Updating program weights for routine: $routineId');
      
      for (final exercise in exercises) {
        if (exercise.exerciseId != null && exercise.loggedSets.isNotEmpty) {
          // Get the latest weight for this exercise
          final completedSets = exercise.loggedSets.where((set) => set.isCompleted && set.weight > 0).toList();
          
          if (completedSets.isNotEmpty) {
            // Sort by timestamp to get the most recent set
            completedSets.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            final latestWeight = completedSets.first.weight;
            
            // Update the program weight in the database
            await _updateProgramWeightsInDatabase(routineId, exercise.exerciseId!, latestWeight);
            print('📊 Updated program weight for ${exercise.name}: ${latestWeight}kg');
          }
        }
      }
    } catch (e) {
      print('❌ Error updating program weights: $e');
    }
  }

  static Future<void> _updateProgramWeightsInDatabase(String routineId, int exerciseId, double weight) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "action": "update_program_weight",
          "routine_id": routineId,
          "exercise_id": exerciseId,
          "weight": weight,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Program weight updated successfully');
        } else {
          print('❌ Failed to update program weight: ${data['message']}');
        }
      }
    } catch (e) {
      print('❌ Error updating program weight in database: $e');
    }
  }

  // Save all completed exercises to progress tracker for progressive overload
  static Future<void> _saveAllExercisesToProgressTracker(String routineId, List<WorkoutExerciseModel> exercises, int clientId) async {
    try {
      print('🔄 Saving exercises to progress tracker for client: $clientId');
      
      for (final exercise in exercises) {
        if (exercise.isCompleted && exercise.loggedSets.isNotEmpty) {
          final completedSets = exercise.loggedSets.where((set) => set.isCompleted).toList();
          
          if (completedSets.isNotEmpty) {
            // Calculate total volume for this exercise
            final totalVolume = completedSets.fold(0.0, (sum, set) => sum + (set.weight * set.reps));
            final totalWeight = completedSets.fold(0.0, (sum, set) => sum + set.weight);
            final avgWeight = totalWeight / completedSets.length;
            final totalReps = completedSets.fold(0, (sum, set) => sum + set.reps);
            
            // Save to progress tracker
            await _saveToProgressTracker(
              clientId: clientId,
              exerciseName: exercise.name,
              muscleGroup: exercise.targetMuscle.isNotEmpty ? exercise.targetMuscle : 'Unknown',
              weight: avgWeight,
              reps: totalReps,
              sets: completedSets.length,
              programName: routineId,
              programId: int.tryParse(routineId),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error saving to progress tracker: $e');
    }
  }

  static Future<void> _saveToProgressTracker({
    required int clientId,
    required String exerciseName,
    required String muscleGroup,
    required double weight,
    required int reps,
    required int sets,
    String? programName,
    int? programId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/progress_tracker.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'action': 'save_lift',
          'data': {
            'user_id': clientId,
            'exercise_name': exerciseName,
            'muscle_group': muscleGroup,
            'weight': weight,
            'reps': reps,
            'sets': sets,
            'date': DateTime.now().toIso8601String(),
            'program_name': programName,
            'program_id': programId,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Progress tracker updated for $exerciseName');
        } else {
          print('❌ Failed to update progress tracker: ${data['message']}');
        }
      }
    } catch (e) {
      print('❌ Error saving to progress tracker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width <= 375;
    
    if (workoutExercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F0F0F),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4ECDC4), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Coach Workout Session',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'No exercises found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isSmallScreen),
            if (showRestTimer) _buildRestTimer(isSmallScreen),
            Expanded(
              child: _buildExercisesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    final duration = DateTime.now().difference(workoutStartTime);
    final totalVolume = _calculateTotalVolume();
    final totalSets = _calculateTotalSets();
    
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Header with title and finish button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4ECDC4), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Log Workout',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _completeWorkout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Finish',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Summary card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Duration', _formatDuration(duration)),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[700],
                ),
                _buildSummaryItem('Volume', '${totalVolume.toInt()} lbs'),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[700],
                ),
                _buildSummaryItem('Sets', totalSets.toString()),
              ],
            ),
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
            color: const Color(0xFF4ECDC4),
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

  Widget _buildRestTimer(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4ECDC4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rest Time',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${restTimeRemaining}s remaining',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4ECDC4),
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: Colors.white),
                onPressed: () => _adjustTimer(-15),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: () => _adjustTimer(15),
              ),
              IconButton(
                icon: Icon(Icons.stop, color: Colors.red),
                onPressed: _stopRestTimer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (workoutExercises.isEmpty) {
      return Center(
        child: Text(
          'No exercises found',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: workoutExercises.length,
      itemBuilder: (context, index) {
        return _buildExerciseCard(workoutExercises[index], index);
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
            onTap: () => _navigateToInstructions(),
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
            
            return AnimatedContainer(
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
                        child: Icon(
                          Icons.check,
                          color: Colors.white.withOpacity(1.0),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
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
      print('🔧 _buildEditableWeightField: Created controller for $fieldKey with value: $previousWeight');
      // Mark as showing previous data if we have previous data and current weight is 0
      if (previousWeight != '0' && set.weight == 0) {
        _showingPreviousData[fieldKey] = true;
        // Don't update the actual set data - keep it as 0 so it's clearly a guide
      } else {
        _showingPreviousData[fieldKey] = false;
      }
    } else {
      // If controller exists, check if we need to update it with previous data
      final currentText = _weightControllers[fieldKey]!.text;
      // Update if: current weight is 0 AND (text is empty/0 OR we have new previous data)
      if (set.weight == 0 && (currentText.isEmpty || currentText == '0' || (previousWeight != '0' && currentText != previousWeight))) {
        _weightControllers[fieldKey]!.text = previousWeight;
        print('🔧 _buildEditableWeightField: Updated controller for $fieldKey from "$currentText" to "$previousWeight"');
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
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
      print('🔧 _buildEditableRepsField: Created controller for $fieldKey with value: $previousReps');
      // Mark as showing previous data if we have previous data and current reps is 0
      if (previousReps != '0' && set.reps == 0) {
        _showingPreviousData[fieldKey] = true;
        // Don't update the actual set data - keep it as 0 so it's clearly a guide
      } else {
        _showingPreviousData[fieldKey] = false;
      }
    } else {
      // If controller exists, check if we need to update it with previous data
      final currentText = _repsControllers[fieldKey]!.text;
      // Update if: current reps is 0 AND (text is empty/0 OR we have new previous data)
      if (set.reps == 0 && (currentText.isEmpty || currentText == '0' || (previousReps != '0' && currentText != previousReps))) {
        _repsControllers[fieldKey]!.text = previousReps;
        print('🔧 _buildEditableRepsField: Updated controller for $fieldKey from "$currentText" to "$previousReps"');
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
      onSubmitted: (value) {
        final reps = int.tryParse(value) ?? 0;
        _updateSetReps(exercise, setIndex, reps);
        // Mark as no longer showing previous data
        _showingPreviousData[fieldKey] = false;
      },
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

  // Helper methods
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

  String _getPreviousWorkoutText(String exerciseName, int setIndex) {
    // Get previous workout data for this exercise
    // Try exact match first
    var previousData = latestWorkoutData[exerciseName];
    
    // If no exact match, try case-insensitive match
    if (previousData == null) {
      for (String key in latestWorkoutData.keys) {
        if (key.toLowerCase() == exerciseName.toLowerCase()) {
          previousData = latestWorkoutData[key];
          break;
        }
      }
    }
    
    if (previousData != null && previousData.isNotEmpty && setIndex < previousData.length) {
      final data = previousData[setIndex];
      final weight = data['weight']?.toStringAsFixed(0) ?? '0';
      final reps = data['reps']?.toString() ?? '0';
      return '$weight kg x $reps';
    }
    
    return '-';
  }

  Map<String, dynamic>? _getPreviousWorkoutData(String exerciseName, int setIndex) {
    // Get previous workout data for this exercise
    // Try exact match first
    var previousData = latestWorkoutData[exerciseName];
    
    // If no exact match, try case-insensitive match
    if (previousData == null) {
      for (String key in latestWorkoutData.keys) {
        if (key.toLowerCase() == exerciseName.toLowerCase()) {
          previousData = latestWorkoutData[key];
          print('🔍 Found case-insensitive match: "$key" for "$exerciseName"');
          break;
        }
      }
    }
    
    if (previousData != null && previousData.isNotEmpty && setIndex < previousData.length) {
      print('✅ Returning previous data for set $setIndex: weight=${previousData[setIndex]['weight']}, reps=${previousData[setIndex]['reps']}');
      return previousData[setIndex];
    }
    
    if (previousData != null) {
      print('⚠️ Previous data exists but setIndex $setIndex is out of range (length: ${previousData.length})');
    } else {
      print('⚠️ No previous data found for exercise: "$exerciseName"');
    }
    
    return null;
  }

  void _updateSetWeight(WorkoutExerciseModel exercise, int setIndex, double weight) {
    if (setIndex < exercise.loggedSets.length) {
      setState(() {
        final set = exercise.loggedSets[setIndex];
        exercise.loggedSets[setIndex] = WorkoutSetModel(
          reps: set.reps,
          weight: weight,
          timestamp: set.timestamp,
          isCompleted: set.isCompleted,
        );
      });
      
      // If both weight and reps are set, log the set
      if (exercise.loggedSets[setIndex].reps > 0 && weight > 0) {
        _logSet(setIndex, exercise.loggedSets[setIndex].reps.toString(), weight.toString());
      }
    }
  }

  void _updateSetReps(WorkoutExerciseModel exercise, int setIndex, int reps) {
    if (setIndex < exercise.loggedSets.length) {
      setState(() {
        final set = exercise.loggedSets[setIndex];
        exercise.loggedSets[setIndex] = WorkoutSetModel(
          reps: reps,
          weight: set.weight,
          timestamp: set.timestamp,
          isCompleted: set.isCompleted,
        );
      });
      
      // If both weight and reps are set, log the set
      if (reps > 0 && exercise.loggedSets[setIndex].weight > 0) {
        _logSet(setIndex, reps.toString(), exercise.loggedSets[setIndex].weight.toString());
      }
    }
  }

  void _toggleSetCompletion(WorkoutExerciseModel exercise, int setIndex) {
    if (setIndex < exercise.loggedSets.length) {
      setState(() {
        final currentSet = exercise.loggedSets[setIndex];
        final newCompletedState = !currentSet.isCompleted;
        
        print('🏋️ COACH TOGGLE SET COMPLETION: ${exercise.name} - Set ${setIndex + 1} - Current: ${currentSet.isCompleted} -> New: $newCompletedState');
        
        // If we're completing the set (not unchecking), handle coach input logic
        if (newCompletedState) {
          // Get previous workout data for this set
          final previousData = _getPreviousWorkoutData(exercise.name, setIndex);
          final isShowingPreviousData = currentSet.weight == 0 && previousData != null;
          
          // Check if coach has manually entered any data by looking at the text controllers
          final weightFieldKey = '${exercise.name}_${setIndex}_weight';
          final repsFieldKey = '${exercise.name}_${setIndex}_reps';
          final hasCoachEnteredData = (_weightControllers[weightFieldKey]?.text.isNotEmpty == true && 
                                     _weightControllers[weightFieldKey]?.text != '0') ||
                                    (_repsControllers[repsFieldKey]?.text.isNotEmpty == true && 
                                     _repsControllers[repsFieldKey]?.text != '0');
          
          print('🔍 COACH SET COMPLETION DEBUG: isShowingPreviousData = $isShowingPreviousData, hasCoachEnteredData = $hasCoachEnteredData');
          
          if (isShowingPreviousData && !hasCoachEnteredData && previousData != null) {
            // Use previous workout data
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
            print('🏋️ COACH Using previous workout data: ${previousWeight}kg x ${previousReps} reps');
            
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
          } else if (hasCoachEnteredData) {
            // Use coach-entered data from text controllers
            final weightText = _weightControllers[weightFieldKey]?.text ?? '';
            final repsText = _repsControllers[repsFieldKey]?.text ?? '';
            
            final finalWeight = weightText.isNotEmpty ? double.tryParse(weightText) ?? currentSet.weight : currentSet.weight;
            final finalReps = repsText.isNotEmpty ? int.tryParse(repsText) ?? currentSet.reps : currentSet.reps;
            
            final updatedSetWithCoachData = WorkoutSetModel(
              reps: finalReps,
              weight: finalWeight,
              rpe: currentSet.rpe,
              notes: currentSet.notes,
              timestamp: currentSet.timestamp,
              isCompleted: true,
            );
            
            exercise.loggedSets[setIndex] = updatedSetWithCoachData;
            print('🏋️ COACH Using coach-entered values: ${finalWeight}kg x ${finalReps} reps');
          } else {
            // Use current data if no coach input and no previous data
            final updatedSet = WorkoutSetModel(
              reps: currentSet.reps,
              weight: currentSet.weight,
              rpe: currentSet.rpe,
              notes: currentSet.notes,
              timestamp: currentSet.timestamp,
              isCompleted: true,
            );
            
            exercise.loggedSets[setIndex] = updatedSet;
            print('🏋️ COACH Using current data: ${currentSet.weight}kg x ${currentSet.reps} reps');
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
          print('🏋️ COACH Unchecked set: ${currentSet.weight}kg x ${currentSet.reps} reps');
        }
        
        // Update completed sets count for this exercise
        exercise.completedSets = exercise.loggedSets.where((set) => set.isCompleted).length;
        
        // Update total completed sets across all exercises
        totalCompletedSets = workoutExercises.fold(0, (sum, ex) => sum + ex.completedSets);
        
        // If we just completed a set, start the rest timer if it's enabled for this exercise
        if (!currentSet.isCompleted && exercise.loggedSets[setIndex].isCompleted) {
          final exerciseKey = '${exercise.exerciseId}_${exercise.name}';
          final exerciseRestTime = exerciseRestTimes[exerciseKey] ?? 0;
          
          print('🔍 TOGGLE SET COMPLETION REST TIMER DEBUG:');
          print('🔍 Exercise: ${exercise.name}');
          print('🔍 Exercise key: $exerciseKey');
          print('🔍 Exercise rest time from model: ${exercise.restTime}');
          print('🔍 Exercise rest time from map: $exerciseRestTime');
          print('🔍 Previous set completed: ${currentSet.isCompleted}');
          print('🔍 New set completed: ${exercise.loggedSets[setIndex].isCompleted}');
          
          if (exerciseRestTime > 0) {
            // Start the rest timer
            print('🎯 Setting showRestTimer = true, exerciseRestTime: $exerciseRestTime');
            setState(() {
              showRestTimer = true;
              restTimeRemaining = exerciseRestTime;
              print('🎯 Inside setState - showRestTimer set to: $showRestTimer, restTimeRemaining: $restTimeRemaining');
            });
            _startRestTimer();
          } else {
            print('🎯 Exercise rest time is 0, not showing timer');
          }
        }
      });
    }
  }

  void _addSetToExercise(WorkoutExerciseModel exercise) {
    setState(() {
      exercise.loggedSets.add(WorkoutSetModel(
        reps: 0,
        weight: 0.0,
        timestamp: DateTime.now(),
        isCompleted: false,
      ));
    });
  }

  // Log individual set to API in real-time
  Future<void> _logIndividualSetToAPI(WorkoutExerciseModel exercise, int setIndex, int reps, double weight) async {
    try {
      print('📤 Logging individual set: ${exercise.name} - Set ${setIndex + 1}: ${weight}kg x $reps');
      
      final requestData = {
        "action": "logExerciseSet",
        "user_id": widget.selectedMember.id,
        "member_workout_exercise_id": exercise.memberWorkoutExerciseId ?? 0,
        "set_number": setIndex + 1,
        "reps": reps,
        "weight": weight,
      };
      
      print('📤 Log set request: ${json.encode(requestData)}');
      
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );
      
      print('📊 Log set response status: ${response.statusCode}');
      print('📋 Log set response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Individual set logged successfully');
        } else {
          print('❌ Failed to log individual set: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        print('❌ Failed to log individual set: ${response.body}');
      }
    } catch (e) {
      print('❌ Error logging individual set: $e');
    }
  }

  void _showExerciseMenu(WorkoutExerciseModel exercise, int index) {
    // Show exercise menu options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white),
              title: Text(
                'Exercise Info',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToInstructions();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Remove Exercise',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                // Remove exercise logic
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimerPicker(WorkoutExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Rest Timer',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...List.generate(6, (index) {
              final time = [0, 30, 60, 90, 120, 180][index];
              final isSelected = exerciseRestTimes['${exercise.exerciseId}_${exercise.name}'] == time;
              return ListTile(
                title: Text(
                  time == 0 ? 'OFF' : _formatRestTime(time),
                  style: GoogleFonts.poppins(
                    color: isSelected ? const Color(0xFF4ECDC4) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    exerciseRestTimes['${exercise.exerciseId}_${exercise.name}'] = time;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// Session Deduction Modal Widget
class _SessionDeductionModal extends StatelessWidget {
  final int remainingSessions;
  final String memberName;
  final bool canDeduct;

  const _SessionDeductionModal({
    Key? key,
    required this.remainingSessions,
    required this.memberName,
    required this.canDeduct,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                color: Color(0xFF4ECDC4),
                size: 32,
              ),
            ),
            SizedBox(height: 20),
            
            // Title
            Text(
              'Deduct Session?',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            
            // Member name
            Text(
              'Workout completed for',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 4),
            Text(
              memberName,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            
            // Current Sessions Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF4ECDC4).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Sessions',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      Text(
                        '$remainingSessions ${remainingSessions == 1 ? 'session' : 'sessions'} remaining',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: remainingSessions > 0 
                              ? Color(0xFF4ECDC4) 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Warning if no sessions available
            if (!canDeduct || remainingSessions <= 0)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        remainingSessions <= 0
                            ? 'No sessions remaining. Cannot deduct session.'
                            : 'Session cannot be deducted at this time.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[700]!, width: 1),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (canDeduct && remainingSessions > 0)
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[700],
                      disabledForegroundColor: Colors.grey[400],
                    ),
                    child: Text(
                      'Deduct Session',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
  }
}