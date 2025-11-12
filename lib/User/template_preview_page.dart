import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/workout_preview_service.dart';
import './services/routine_services.dart';
import './services/subscription_service.dart';
import './models/subscription_model.dart';
import './manage_subscriptions_page.dart';
import './exercise_instructions_page.dart';

class TemplatePreviewPage extends StatefulWidget {
  final RoutineModel routine;
  final Color templateColor;
  final bool isProMember;
  final bool hasExistingProgram;
  final String? existingProgramName;
    
  const TemplatePreviewPage({
    Key? key,
    required this.routine,
    required this.templateColor,
    this.isProMember = false,
    this.hasExistingProgram = false,
    this.existingProgramName,
  }) : super(key: key);

  @override
  _TemplatePreviewPageState createState() => _TemplatePreviewPageState();
}

class _TemplatePreviewPageState extends State<TemplatePreviewPage> {
  WorkoutPreviewModel? workoutPreview;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTemplatePreview();
  }

  Future<void> _loadTemplatePreview() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
            
      // Fetch routine details to get exercises
      final routineDetails = await RoutineService.fetchRoutineDetails(widget.routine.id);
            
      if (routineDetails != null && routineDetails.detailedExercises != null) {
        // Convert ExerciseModel to WorkoutExerciseModel for preview
        final exercises = routineDetails.detailedExercises!.map((exercise) {
          // Get sets and reps from exercise
          String repsStr = exercise.targetReps;
          int setsCount = exercise.targetSets;
          
          // Create target sets with reps (no weight)
          List<WorkoutSetModel> targetSets = [];
          for (int i = 0; i < setsCount; i++) {
            targetSets.add(WorkoutSetModel(
              reps: int.tryParse(repsStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10,
              weight: 0.0, // No weight for templates
              timestamp: DateTime.now(),
              isCompleted: false,
            ));
          }
          
          return WorkoutExerciseModel(
            exerciseId: exercise.id,
            name: exercise.name,
            targetMuscle: exercise.targetMuscle,
            description: exercise.description,
            imageUrl: exercise.imageUrl,
            sets: setsCount,
            reps: repsStr,
            weight: 0.0, // No weight for templates
            restTime: exercise.restTime,
            category: exercise.category,
            difficulty: exercise.difficulty,
            targetSets: targetSets,
          );
        }).toList();
        
        // Create workout preview model
        workoutPreview = WorkoutPreviewModel(
          routineId: widget.routine.id,
          routineName: widget.routine.name,
          exercises: exercises,
          stats: WorkoutStatsModel(
            totalExercises: exercises.length,
            totalSets: exercises.fold(0, (sum, e) => sum + e.sets),
            estimatedDuration: exercises.length * 5, // Estimate 5 min per exercise
            estimatedCalories: exercises.length * 50, // Estimate 50 cal per exercise
            estimatedVolume: 0.0, // No volume for templates (no weight)
          ),
        );
        
        setState(() {
          isLoading = false;
        });
      } else {
        // Try using workout preview service as fallback
        final preview = await WorkoutPreviewService.getWorkoutPreview(widget.routine.id);
        
        // Remove weight from exercises for template preview
        final exercisesWithoutWeight = preview.exercises.map((exercise) {
          return WorkoutExerciseModel(
            exerciseId: exercise.exerciseId,
            memberWorkoutExerciseId: exercise.memberWorkoutExerciseId,
            name: exercise.name,
            targetMuscle: exercise.targetMuscle,
            description: exercise.description,
            imageUrl: exercise.imageUrl,
            sets: exercise.sets,
            reps: exercise.reps,
            weight: 0.0, // No weight for templates
            restTime: exercise.restTime,
            category: exercise.category,
            difficulty: exercise.difficulty,
            targetSets: exercise.targetSets?.map((set) => WorkoutSetModel(
              reps: set.reps,
              weight: 0.0, // No weight for templates - always 0
              rpe: set.rpe,
              notes: set.notes,
              timestamp: set.timestamp,
              isCompleted: false,
            )).toList(),
          );
        }).toList();
        
        workoutPreview = WorkoutPreviewModel(
          routineId: preview.routineId,
          routineName: preview.routineName,
          exercises: exercisesWithoutWeight,
          stats: WorkoutStatsModel(
            totalExercises: exercisesWithoutWeight.length,
            totalSets: exercisesWithoutWeight.fold(0, (sum, e) => sum + e.sets),
            estimatedDuration: preview.stats.estimatedDuration,
            estimatedCalories: preview.stats.estimatedCalories,
            estimatedVolume: 0.0, // No volume for templates
          ),
        );
        
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('Error loading template preview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 300;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Template Preview',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isVerySmall ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.routine.name.isNotEmpty)
                  Text(
                    widget.routine.name,
                    style: GoogleFonts.poppins(
                      fontSize: isVerySmall ? 10 : 12,
                      color: widget.templateColor.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          },
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(widget.templateColor),
              ),
            )
          : errorMessage != null
              ? _buildErrorState(isSmallScreen)
              : workoutPreview == null
                  ? _buildEmptyState(isSmallScreen)
                  : _buildPreviewContent(isSmallScreen),
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
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
              'Error Loading Preview',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              errorMessage ?? 'Failed to load template preview',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTemplatePreview,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.templateColor,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.grey[600],
              size: 64,
            ),
            SizedBox(height: 20),
            Text(
              'No Exercises Found',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This template does not have any exercises yet.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(bool isSmallScreen) {
    return Column(
      children: [
        // Exercises Header (like workout preview)
        _buildExercisesHeader(isSmallScreen),
        // Exercises List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            itemCount: workoutPreview!.exercises.length,
            itemBuilder: (context, index) {
              final exercise = workoutPreview!.exercises[index];
              return _buildExerciseCard(exercise, index, isSmallScreen);
            },
          ),
        ),
        // Action Buttons
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
              top: BorderSide(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add to My Programs button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAddToPrograms(),
                    icon: Icon(Icons.add_circle_outline, size: 22),
                    label: Text(
                      'Add to My Programs',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.templateColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                      shadowColor: widget.templateColor.withOpacity(0.4),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExercisesHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: 12),
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

  Widget _buildExerciseCard(WorkoutExerciseModel exercise, int index, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise image - clickable to go to instructions
          GestureDetector(
            onTap: () => _navigateToInstructions(exercise),
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(0xFF2A2A2A),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(widget.templateColor),
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
                                  color: widget.templateColor,
                                  size: 24,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: Icon(
                              Icons.fitness_center,
                              color: widget.templateColor,
                              size: 24,
                            ),
                          ),
                  ),
                ),
                // Play icon overlay to indicate video
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          // Exercise details
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToInstructions(exercise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name
                  Text(
                    exercise.name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  // Sets and reps info
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        '${exercise.sets} sets',
                        style: GoogleFonts.poppins(
                          color: widget.templateColor,
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '•',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${exercise.reps} reps',
                        style: GoogleFonts.poppins(
                          color: widget.templateColor,
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (exercise.restTime > 0) ...[
                        Text(
                          '•',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${exercise.restTime}s rest',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Show individual set breakdown if multiple sets with different reps
                  // Note: No weight displayed for templates - only sets and reps
                  if (exercise.targetSets != null && exercise.targetSets!.length > 1) ...[
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: exercise.targetSets!.asMap().entries.map((entry) {
                        final setIndex = entry.key;
                        final set = entry.value;
                        // Only show reps, no weight for templates
                        return Text(
                          'Set ${setIndex + 1}: ${set.reps} reps',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 11 : 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToInstructions(WorkoutExerciseModel exercise) {
    // Find the full exercise details from the loaded routine details
    // The videoUrl will be fetched by ExerciseInstructionsPage from the API if not available
    final exerciseModel = ExerciseModel(
      id: exercise.exerciseId,
      name: exercise.name,
      targetSets: exercise.sets,
      targetReps: exercise.reps,
      targetWeight: '0 kg', // No weight for templates
      category: exercise.category,
      difficulty: exercise.difficulty,
      color: widget.templateColor.value.toString(),
      restTime: exercise.restTime,
      targetMuscle: exercise.targetMuscle,
      description: exercise.description,
      imageUrl: exercise.imageUrl,
      videoUrl: '', // Will be fetched by ExerciseInstructionsPage from API
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

  Future<void> _handleAddToPrograms() async {
    // Check if free user has reached their limit
    if (!widget.isProMember && widget.hasExistingProgram) {
      // Show limit dialog
      final shouldProceed = await _showFreeUserProgramLimitDialog();
      if (shouldProceed != true) {
        return; // User cancelled or needs to delete/upgrade
      }
    }
    
    // Check if program already exists
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.templateColor),
          ),
        ),
      );

      final result = await RoutineService.cloneProgramToUser(int.parse(widget.routine.id));
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Program added to your library successfully!'),
            backgroundColor: widget.templateColor,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Return true to indicate successful addition
        Navigator.pop(context, true);
      } else if (result['already_exists'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'You already have this program in your library'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Still return true since program exists in library
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to add program to your library'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showFreeUserProgramLimitDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Program Limit Reached',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Basic users can only have 1 program at a time.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            height: 1.4,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.existingProgramName != null) ...[
                          SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Current Program:',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        widget.existingProgramName!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 16),
                        Text(
                          'To add "${widget.routine.name}", you need to:',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Delete your existing program first, or\n• Upgrade to Premium for unlimited programs',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Actions - Upgrade button on top, Cancel/Delete at bottom
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upgrade button on top
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showUpgradeDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Upgrade to Premium',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      // Cancel button at bottom
                      SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
      },
    );
  }

  void _showUpgradeDialog() async {
    // Fetch gym membership plan details
    int? userId;
    try {
      userId = await RoutineService.getCurrentUserId();
    } catch (e) {
      print('Error getting user ID: $e');
    }
    
    List<SubscriptionPlan>? plans;
    SubscriptionPlan? gymMembershipPlan;
    double startingPrice = 500.0;
    List<String> features = [
      'Unlimited Programs',
      'Advanced Analytics',
      'Priority Support',
      'Export Workout Data',
    ];
    
    if (userId != null) {
      try {
        plans = await SubscriptionService.getAvailablePlansForUser(userId);
        if (plans.isNotEmpty) {
          try {
            gymMembershipPlan = plans.firstWhere(
              (plan) => plan.id == 1,
            );
            startingPrice = gymMembershipPlan.price;
            features = gymMembershipPlan.features.map((f) => f.featureName).toList();
          } catch (e) {
            // Plan ID 1 not found, use first plan or default
            if (plans.isNotEmpty) {
              gymMembershipPlan = plans.first;
              startingPrice = gymMembershipPlan.price;
              features = gymMembershipPlan.features.map((f) => f.featureName).toList();
            }
          }
        }
      } catch (e) {
        print('Error fetching plans: $e');
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upgrade to Premium',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content - scrollable
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock Premium Features:',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        ...features.map((feature) => Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: widget.templateColor,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFFFD700).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Starting at ',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '₱${startingPrice.toStringAsFixed(0)}/month',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFFFFD700),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upgrade Now button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageSubscriptionsPage(highlightPlanId: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Upgrade Now',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      // Maybe Later button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Maybe Later',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
      },
    );
  }
}

