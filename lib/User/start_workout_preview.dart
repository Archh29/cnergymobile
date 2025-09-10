import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/workout_preview_service.dart';
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
            child: Text(
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
              onTap: () => _navigateToWorkoutSession(),
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
                  const SizedBox(height: 4),
                  if (exercise.isCompleted)
                    Text(
                      '${exercise.completedSets}/${exercise.sets} logged',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4ECDC4),
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (exercise.completedSets > 0)
                    Text(
                      '${exercise.completedSets}/${exercise.sets} logged',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4ECDC4),
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      exercise.exerciseDetails,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
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
      final exercises = workoutPreview!.exercises.map((exercise) => ExerciseModel(
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
      )).toList();
            
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

  void _startWorkout() {
    _navigateToWorkoutSession();
  }
}
