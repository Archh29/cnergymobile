import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../User/models/routine.models.dart' as UserModels;
import '../User/models/workoutpreview_model.dart';
import 'coach_workout_session_page.dart';
import '../User/exercise_instructions_page.dart';
import 'models/member_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../User/services/session_tracking_service.dart';
import 'services/coach_service.dart';

class CoachWorkoutPreviewPage extends StatefulWidget {
  final UserModels.RoutineModel routine;
  final MemberModel selectedMember;
    
  const CoachWorkoutPreviewPage({
    Key? key,
    required this.routine,
    required this.selectedMember,
  }) : super(key: key);

  @override
  _CoachWorkoutPreviewPageState createState() => _CoachWorkoutPreviewPageState();
}

class _CoachWorkoutPreviewPageState extends State<CoachWorkoutPreviewPage> {
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
            
      // For coach sessions, we need to fetch the workout preview for the client
      final preview = await _getWorkoutPreviewForClient(widget.routine.id, widget.selectedMember.id);
            
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

  // Custom method to fetch workout preview for a specific client
  Future<WorkoutPreviewModel> _getWorkoutPreviewForClient(String routineId, int clientId) async {
    try {
      print('🔍 Coach fetching workout preview for routine ID: "$routineId", client ID: $clientId');
      
      if (routineId.isEmpty) {
        throw Exception('Routine ID is empty - cannot fetch workout preview');
      }
      
      final url = 'https://api.cnergy.site/workout_preview.php?action=getWorkoutPreview&routine_id=$routineId&user_id=$clientId';
      print('📡 API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      
      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return WorkoutPreviewModel.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['error'] ?? 'Failed to load workout preview');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Error fetching workout preview for client: $e');
      throw Exception('Failed to load workout preview: $e');
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
    final isTodayWorkout = widget.routine.scheduledDays.contains(currentDay);
    
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
                // Client name
                SizedBox(height: 4),
                Text(
                  'Client: ${widget.selectedMember.fullName}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Scheduled day info (if this is not today's workout)
                if (widget.routine.scheduledDays.isNotEmpty && !isTodayWorkout) ...[
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
                        'Scheduled: ${widget.routine.scheduledDays.first}',
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
                ],
              ),
            ),
          ),
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
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout() async {
    if (workoutPreview == null) return;

    // Check if this routine was created by a coach (has createdBy)
    final routineCreatedBy = widget.routine.createdBy;
    print('🔍 SESSION CHECK: Routine createdBy value: "$routineCreatedBy"');
    print('🔍 SESSION CHECK: Routine createdBy type: ${routineCreatedBy.runtimeType}');
    
    final hasCoachCreator = routineCreatedBy.isNotEmpty && 
        routineCreatedBy != 'null' && 
        routineCreatedBy != '0';
    
    print('🔍 SESSION CHECK: hasCoachCreator = $hasCoachCreator');

    if (hasCoachCreator) {
      print('✅ SESSION CHECK: Coach-created routine detected. Checking and deducting session...');
      // Check and deduct session before starting workout
      await _checkAndDeductSession();
    } else {
      print('⚠️ SESSION CHECK: User-created routine or no coach creator. Skipping session check.');
      // User-created routine, no session check needed - start directly
      _navigateToWorkoutSession();
    }
  }

  Future<void> _checkAndDeductSession() async {
    try {
      print('🔄 SESSION DEDUCTION: Starting session check and deduction process...');
      
      // Get coach ID and member ID
      final coachId = await CoachService.getCoachId();
      print('🔄 SESSION DEDUCTION: Coach ID = $coachId');
      
      if (coachId == 0) {
        print('❌ SESSION DEDUCTION: Coach ID is 0, cannot proceed');
        _showErrorDialog('Unable to identify coach. Please try again.');
        return;
      }

      final memberId = widget.selectedMember.id;
      print('🔄 SESSION DEDUCTION: Member ID = $memberId');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
              SizedBox(width: 16),
              Text(
                'Checking session availability...',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // Check session availability (but don't deduct yet - will deduct on completion)
      final sessionStatus = await SessionTrackingService.checkSessionAvailability(
        userId: memberId,
        coachId: coachId,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (!sessionStatus.canStartWorkout) {
        _showSessionErrorDialog(sessionStatus.reason);
        return;
      }

      // Start the workout (session will be deducted when workout is completed)
      _navigateToWorkoutSession();

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Error checking session: $e');
    }
  }

  void _navigateToWorkoutSession() {
    if (workoutPreview == null) return;

    // Convert WorkoutExerciseModel to ExerciseModel for the session page
    final exercises = workoutPreview!.exercises.map((exercise) {
      return UserModels.ExerciseModel(
        id: exercise.exerciseId,
        name: exercise.name,
        targetSets: exercise.sets,
        targetReps: exercise.reps,
        targetWeight: exercise.weight.toString(),
        completedSets: exercise.completedSets,
        sets: exercise.targetSets?.map((set) => UserModels.ExerciseSet(
          reps: set.reps.toString(),
          weight: set.weight.toString(),
          rpe: set.rpe,
          duration: set.notes,
          timestamp: set.timestamp,
        )).toList() ?? [],
        completed: exercise.isCompleted,
        category: exercise.category,
        difficulty: exercise.difficulty,
        color: '0xFF4ECDC4',
        restTime: exercise.restTime,
        notes: '',
        targetMuscle: exercise.targetMuscle,
        description: exercise.description,
        imageUrl: exercise.imageUrl,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachWorkoutSessionPage(
          routine: widget.routine,
          exercises: exercises,
          selectedMember: widget.selectedMember,
        ),
      ),
    );
  }

  void _showSessionErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cannot Start Workout',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToInstructions(WorkoutExerciseModel exercise) {
    // Convert WorkoutExerciseModel to ExerciseModel for the instructions page
    final exerciseModel = UserModels.ExerciseModel(
      id: exercise.exerciseId,
      name: exercise.name,
      targetSets: exercise.sets,
      targetReps: exercise.reps,
      targetWeight: exercise.weight.toString(),
      completedSets: exercise.completedSets,
      sets: exercise.targetSets?.map((set) => UserModels.ExerciseSet(
        reps: set.reps.toString(),
        weight: set.weight.toString(),
        rpe: set.rpe,
        duration: set.notes,
        timestamp: set.timestamp,
      )).toList() ?? [],
      completed: exercise.isCompleted,
      category: exercise.category,
      difficulty: exercise.difficulty,
        color: '0xFF4ECDC4',
        restTime: exercise.restTime,
        notes: '',
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

}