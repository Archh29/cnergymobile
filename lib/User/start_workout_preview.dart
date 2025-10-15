import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/workout_preview_service.dart';
import './services/session_tracking_service.dart';
import './services/auth_service.dart';
import './widgets/exercise_detail_modal.dart';
import 'workout_session_page.dart';
import 'exercise_instructions_page.dart';

class StartWorkoutPreviewPage extends StatefulWidget {
  final RoutineModel routine;
    
  const StartWorkoutPreviewPage({
    Key? key,
    required this.routine,
  }) : super(key: key);

  @override
  _StartWorkoutPreviewPageState createState() => _StartWorkoutPreviewPageState();
}

class _StartWorkoutPreviewPageState extends State<StartWorkoutPreviewPage> {
  WorkoutPreviewModel? workoutPreview;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPreview();
  }

  Future<void> _loadWorkoutPreview() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
            
      final preview = await WorkoutPreviewService.getWorkoutPreview(widget.routine.id);
            
      setState(() {
        workoutPreview = preview;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width <= 375;
        
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, isSmallScreen),
            Expanded(
              child: isLoading
                  ? _buildLoadingState(isSmallScreen)
                  : errorMessage != null
                      ? _buildErrorState(isSmallScreen)
                      : _buildContent(context, isSmallScreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isSmallScreen) {
    // Get current day
    final currentDay = _getCurrentWorkoutDay();
    
    // Check if this program is for today's workout
    final isTodayWorkout = widget.routine.scheduledDays?.contains(currentDay) == true;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4ECDC4), size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.all(8),
          ),
          Expanded(
            child: Column(
              children: [
                // Current day at the top (only if this is today's workout)
                if (isTodayWorkout) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF4ECDC4), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4ECDC4),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          currentDay,
                          style: GoogleFonts.poppins(
                            color: Color(0xFF4ECDC4),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                // Routine name
                Text(
                  workoutPreview?.routineName ?? widget.routine.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Scheduled day info (if this is not today's workout)
                if (widget.routine.scheduledDays?.isNotEmpty == true && !isTodayWorkout) ...[
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey[400],
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Scheduled: ${widget.routine.scheduledDays!.first}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 24),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  // Get current workout day
  String _getCurrentWorkoutDay() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[now.weekday - 1];
  }

  Widget _buildContent(BuildContext context, bool isSmallScreen) {
    if (workoutPreview == null) return Container();
        
    return Column(
      children: [
        _buildExercisesHeader(isSmallScreen),
        Expanded(
          child: _buildExercisesList(isSmallScreen),
        ),
        _buildStartButton(isSmallScreen),
      ],
    );
  }

  Widget _buildWorkoutStats(bool isSmallScreen) {
    final stats = workoutPreview!.stats;
        
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Duration', stats.formattedDuration, const Color(0xFF4ECDC4), isSmallScreen),
          _buildStatColumn('Calories', stats.formattedCalories, Colors.white, isSmallScreen),
          _buildStatColumn('Volume', stats.formattedVolume, Colors.white, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == 'Duration')
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4),
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(right: 6),
              ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: valueColor,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExercisesHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${workoutPreview!.exercises.length} exercises',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Removed add exercise button
        ],
      ),
    );
  }

  Widget _buildExercisesList(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: workoutPreview!.exercises.length,
      itemBuilder: (context, index) {
        final exercise = workoutPreview!.exercises[index];
        return _buildExerciseCard(exercise, index, isSmallScreen);
      },
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseModel exercise, int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToInstructions(exercise),
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: exercise.imageUrl.isNotEmpty
                        ? Image.network(
                            exercise.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: const Color(0xFF2A2A2A),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF4ECDC4)),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2A2A2A),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: const Color(0xFF4ECDC4),
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: Icon(
                              Icons.fitness_center,
                              color: const Color(0xFF4ECDC4),
                              size: 24,
                            ),
                          ),
                  ),
                ),
                if (exercise.isCompleted)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0F0F0F), width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToInstructions(exercise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Removed the sets/reps text as requested
                ],
              ),
            ),
          ),
          // Removed per-exercise overflow menu
        ],
      ),
    );
  }

  Widget _buildStartButton(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _startWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'START WORKOUT',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            strokeWidth: 3,
          ),
          SizedBox(height: isSmallScreen ? 10 : 16),
          Text(
            'Loading workout details...',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 13 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 12 : 20),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: isSmallScreen ? 36 : 48,
            ),
            SizedBox(height: isSmallScreen ? 10 : 16),
            Text(
              'Error Loading Workout',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              errorMessage ?? 'Something went wrong. Please try again.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 14 : 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadWorkoutPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(WorkoutExerciseModel exercise) {
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
        
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExerciseDetailModal(exercise: exerciseModel),
    );
  }

  void _navigateToInstructions(WorkoutExerciseModel exercise) {
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

  void _navigateToWorkoutSession() {
    if (workoutPreview != null) {
      final exercises = workoutPreview!.exercises.map((exercise) {
        // Convert WorkoutSetModel to ExerciseSet for individual set configurations
        List<ExerciseSet> exerciseSets = [];
        if (exercise.targetSets != null && exercise.targetSets!.isNotEmpty) {
          exerciseSets = exercise.targetSets!.map((set) => ExerciseSet(
            reps: set.reps.toString(),
            weight: set.weight.toString(),
            rpe: set.rpe,
            duration: set.notes, // Using notes as duration
            timestamp: set.timestamp,
          )).toList();
          print('🔍 Converting WorkoutExerciseModel to ExerciseModel:');
          print('  - Exercise: ${exercise.name}');
          print('  - targetSets count: ${exercise.targetSets!.length}');
          print('  - Individual sets: ${exerciseSets.map((s) => '${s.reps} reps, ${s.weight} kg').join(', ')}');
        }
        
        return ExerciseModel(
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
          sets: exerciseSets, // Individual set configurations
        );
      }).toList();
            
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSessionPage(
            routine: widget.routine,
            exercises: exercises,
          ),
        ),
      );
    }
  }

  void _startWorkout() async {
    // Check if this routine was created by a coach
    if (widget.routine.createdBy.isNotEmpty && 
        widget.routine.createdBy != 'null' && 
        widget.routine.createdBy != '0') {
      await _checkSessionAndStartWorkout();
    } else {
      // User-created routine, no session check needed
      _navigateToWorkoutSession();
    }
  }

  Future<void> _checkSessionAndStartWorkout() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        _showErrorDialog('Please log in to start workout');
        return;
      }

      // Debug: Print the createdBy value
      print('🔍 DEBUG - Routine createdBy value: "${widget.routine.createdBy}"');
      print('🔍 DEBUG - Routine createdBy type: ${widget.routine.createdBy.runtimeType}');
      print('🔍 DEBUG - Routine createdBy isEmpty: ${widget.routine.createdBy.isEmpty}');
      print('🔍 DEBUG - Routine createdBy == "null": ${widget.routine.createdBy == "null"}');

      final coachId = int.tryParse(widget.routine.createdBy);
      print('🔍 DEBUG - Parsed coachId: $coachId');
      
      if (coachId == null) {
        _showErrorDialog('Invalid coach information. CreatedBy: "${widget.routine.createdBy}"');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Checking session availability...'),
            ],
          ),
        ),
      );

      // Check session availability
      final sessionStatus = await SessionTrackingService.checkSessionAvailability(
        userId: currentUserId,
        coachId: coachId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (!sessionStatus.canStartWorkout) {
        _showSessionErrorDialog(sessionStatus.reason);
        return;
      }

      // Deduct session if needed
      final deductionResult = await SessionTrackingService.deductSession(
        userId: currentUserId,
        coachId: coachId,
      );

      if (!deductionResult.success) {
        _showErrorDialog(deductionResult.message);
        return;
      }

      // Show success message if session was deducted
      if (!deductionResult.alreadyDeductedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session deducted. ${deductionResult.remainingSessions} sessions remaining.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Start the workout
      _navigateToWorkoutSession();

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Error checking session: $e');
    }
  }

  void _showSessionErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot Start Workout'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          if (message.contains('No sessions remaining') || message.contains('expired'))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription page
                Navigator.pushNamed(context, '/manage-subscriptions');
              },
              child: Text('Manage Subscription'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
