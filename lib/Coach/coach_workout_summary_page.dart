import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../User/models/routine.models.dart' as UserModels;
import '../User/models/workoutpreview_model.dart';
import 'models/member_model.dart';
import '../coach_dashboard.dart';

class CoachWorkoutSummaryPage extends StatefulWidget {
  final UserModels.RoutineModel routine;
  final List<WorkoutExerciseModel> exercises;
  final Duration workoutDuration;
  final double totalVolume;
  final int totalSets;
  final MemberModel selectedMember;

  const CoachWorkoutSummaryPage({
    Key? key,
    required this.routine,
    required this.exercises,
    required this.workoutDuration,
    required this.totalVolume,
    required this.totalSets,
    required this.selectedMember,
  }) : super(key: key);

  @override
  State<CoachWorkoutSummaryPage> createState() => _CoachWorkoutSummaryPageState();
}

class _CoachWorkoutSummaryPageState extends State<CoachWorkoutSummaryPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workout Summary',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.selectedMember.initials,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.selectedMember.fullName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Workout Completed',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Workout Stats
            Text(
              'Workout Statistics',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Duration',
                    _formatDuration(widget.workoutDuration),
                    Icons.timer,
                    Color(0xFF007AFF),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Volume',
                    '${widget.totalVolume.toStringAsFixed(0)} kg',
                    Icons.fitness_center,
                    Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Sets',
                    widget.totalSets.toString(),
                    Icons.repeat,
                    Color(0xFF34C759),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Exercises',
                    widget.exercises.where((e) => 
                        e.loggedSets.any((set) => set.isCompleted)).length.toString(),
                    Icons.list_alt,
                    Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Exercise Breakdown
            Text(
              'Exercise Breakdown',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            ...widget.exercises.map((exercise) => _buildExerciseCard(exercise)).toList(),
            
            SizedBox(height: 24),
            
            // Notes Section
            Text(
              'Workout Notes',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Add notes about the workout...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Save Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Workout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExerciseModel exercise) {
    final completedSets = exercise.loggedSets.where((set) => set.isCompleted).length;
    final totalVolume = exercise.loggedSets
        .where((set) => set.isCompleted)
        .fold(0.0, (sum, set) => sum + (set.weight * set.reps));

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: exercise.isCompleted ? Color(0xFF34C759) : Color(0xFF8E8E93),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              exercise.isCompleted ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$completedSets/${exercise.sets} sets • ${totalVolume.toStringAsFixed(0)} kg',
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
    );
  }

  Future<void> _saveWorkout() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Calculate workout metrics
      final totalVolume = widget.exercises.fold(0.0, (sum, exercise) => 
          sum + exercise.loggedSets.where((set) => set.isCompleted)
              .fold(0.0, (setSum, set) => setSum + (set.weight * set.reps)));
      
      final completedExercises = widget.exercises.where((e) => 
          e.loggedSets.any((set) => set.isCompleted)).length;
      final totalSets = widget.exercises.fold(0, (sum, exercise) => sum + exercise.completedSets);
      
      final requestData = {
        "action": "completeWorkout",
        "routine_id": widget.routine.id,
        "user_id": widget.selectedMember.id,
        "duration": widget.workoutDuration.inMinutes,
        "total_volume": totalVolume,
        "completed_exercises": completedExercises,
        "total_exercises": widget.exercises.length,
        "total_sets": totalSets,
        "exercises": widget.exercises.map((exercise) => {
          "exercise_id": exercise.exerciseId,
          "member_workout_exercise_id": exercise.memberWorkoutExerciseId ?? 0,
          "completed_sets": exercise.completedSets,
          "is_completed": exercise.isCompleted,
          "logged_sets": exercise.loggedSets.map((set) => set.toJson()).toList(),
        }).toList(),
      };
      
      print('📤 Saving workout for client: ${widget.selectedMember.id}');
      
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/workout_preview.php'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestData),
      );
      
      print('📊 Save workout response status: ${response.statusCode}');
      print('📋 Save workout response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final success = responseData['success'] == true;
        
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout saved successfully!'),
              backgroundColor: Color(0xFF4ECDC4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          
          // Navigate back to coach dashboard
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CoachDashboard()),
            (route) => false,
          );
        } else {
          throw Exception('Failed to save workout');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error saving workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save workout. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
