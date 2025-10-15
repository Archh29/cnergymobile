import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './models/routine.models.dart';
import './models/workoutpreview_model.dart';
import './services/auth_service.dart';
import '../user_dashboard.dart';

class SaveWorkoutPage extends StatefulWidget {
  final RoutineModel routine;
  final List<WorkoutExerciseModel> exercises;
  final Duration workoutDuration;
  final double totalVolume;
  final int totalSets;

  const SaveWorkoutPage({
    Key? key,
    required this.routine,
    required this.exercises,
    required this.workoutDuration,
    required this.totalVolume,
    required this.totalSets,
  }) : super(key: key);

  @override
  State<SaveWorkoutPage> createState() => _SaveWorkoutPageState();
}

class _SaveWorkoutPageState extends State<SaveWorkoutPage> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  String _visibility = 'Everyone';
  DateTime _workoutDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _workoutDate = DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$day $month $year, $displayHour:$minute $period';
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      print('💾 Starting workout save process...');
      print('💾 Exercises to save: ${widget.exercises.length}');
      print('💾 Total volume: ${widget.totalVolume}');
      print('💾 Total sets: ${widget.totalSets}');
      
      // Get current user ID
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      print('💾 User ID: $userId');
      
      // Prepare exercises data for the API
      List<Map<String, dynamic>> exercisesData = [];
      int completedExercises = 0;
      
      for (var exercise in widget.exercises) {
        if (exercise.completedSets > 0) {
          completedExercises++;
          print('💾 Processing exercise: ${exercise.name} with ${exercise.completedSets} sets');
          
          // Prepare logged sets data
          List<Map<String, dynamic>> loggedSets = [];
          for (var set in exercise.loggedSets) {
            if (set.isCompleted) {
              loggedSets.add({
                'reps': set.reps,
                'weight': set.weight,
                'rpe': 0, // Default RPE
                'notes': _descriptionController.text,
              });
            }
          }
          
          exercisesData.add({
            'exercise_id': exercise.exerciseId,
            'member_workout_exercise_id': exercise.memberWorkoutExerciseId,
            'completed_sets': exercise.completedSets,
            'logged_sets': loggedSets,
          });
        }
      }
      
      // Save workout using the correct API that writes to member_exercise_log and member_exercise_set_log
      print('🌐 MAKING API CALL TO: https://api.cnergy.site/workout_preview.php?action=completeWorkout');
      print('🌐 REQUEST DATA:');
      print('🌐   routine_id: ${widget.routine.id}');
      print('🌐   user_id: $userId');
      print('🌐   duration: ${widget.workoutDuration.inMinutes} minutes');
      print('🌐   total_volume: ${widget.totalVolume}kg');
      print('🌐   completed_exercises: $completedExercises');
      print('🌐   total_exercises: ${widget.exercises.length}');
      print('🌐   total_sets: ${widget.totalSets}');
      print('🌐   exercises_data: ${json.encode(exercisesData)}');
      
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php?action=completeWorkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'routine_id': widget.routine.id,
          'user_id': userId,
          'duration': widget.workoutDuration.inMinutes,
          'total_volume': widget.totalVolume,
          'completed_exercises': completedExercises,
          'total_exercises': widget.exercises.length,
          'total_sets': widget.totalSets,
          'exercises': exercisesData,
        }),
      );
      
      if (response.statusCode == 200) {
        print('✅ Successfully saved workout');
        print('📊 Response: ${response.body}');
        
        // Clear any active workout data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_workout_routine_id');
        await prefs.remove('active_workout_routine_name');
        await prefs.remove('active_workout_exercises');
        
        print('✅ Workout save completed successfully!');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to user dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/userDashboard',
          (route) => false,
        );
      } else {
        print('❌ Failed to save workout: ${response.statusCode}');
        print('📊 Response: ${response.body}');
        throw Exception('Failed to save workout: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error saving workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                
                // Title
                Text(
                  'Discard Workout?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                
                // Message
                Text(
                  'Are you sure you want to discard this workout? All your progress will be lost and cannot be recovered.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                
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
                          padding: EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFF444444),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    
                    // Discard Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          // Clear workout data and navigate back
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('active_workout_routine_id');
                          await prefs.remove('active_workout_routine_name');
                          await prefs.remove('active_workout_exercises');
                          
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/userDashboard',
                            (route) => false,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
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
                              fontSize: 16,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Container(
              height: 56,
              color: Color(0xFF2A2A2A),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Title
                  Expanded(
                    child: Text(
                      'Save Workout',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Save Button
                  GestureDetector(
                    onTap: _isSaving ? null : _saveWorkout,
                    child: Container(
                      margin: EdgeInsets.only(right: 16),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isSaving ? Colors.grey : Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Save',
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
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Workout Title Section
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.routine.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Workout Metrics Section
                    Row(
                      children: [
                        // Duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _formatDuration(widget.workoutDuration),
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF007AFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Volume
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Volume',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${widget.totalVolume.toStringAsFixed(0)} lbs',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Sets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sets',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${widget.totalSets}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Color(0xFF333333),
                    ),
                    SizedBox(height: 24),
                    
                    // When Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'When',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatDate(_workoutDate),
                          style: GoogleFonts.poppins(
                            color: Color(0xFF007AFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Description Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'How did your workout go?',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(height: 4),
                        
                        // Gray line below "How did your workout go?"
                        Container(
                          height: 1,
                          color: Color(0xFF333333),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Discard Workout Button
                    Center(
                      child: GestureDetector(
                        onTap: _showDiscardConfirmation,
                        child: Text(
                          'Discard Workout',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
