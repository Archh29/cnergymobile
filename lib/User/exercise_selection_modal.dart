import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/workoutpreview_model.dart';

class ExerciseSelectionModal extends StatelessWidget {
  final String exerciseName;
  final Color exerciseColor;
  final List<WorkoutExerciseModel> workoutExercises;
  final int currentExerciseIndex;
  final Function(int) onExerciseSelected;

  const ExerciseSelectionModal({
    Key? key,
    required this.exerciseName,
    required this.exerciseColor,
    required this.workoutExercises,
    required this.currentExerciseIndex,
    required this.onExerciseSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    final isVerySmallScreen = screenHeight < 600 || screenWidth < 320;
    
    // Get remaining exercises (not completed)
    final remainingExercises = <int>[];
    for (int i = 0; i < workoutExercises.length; i++) {
      if (!workoutExercises[i].isCompleted) {
        remainingExercises.add(i);
      }
    }

    final bool hasRemainingExercises = remainingExercises.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24),
          Icon(Icons.check_circle, color: exerciseColor, size: isVerySmallScreen ? 40 : 48),
          SizedBox(height: isVerySmallScreen ? 12 : 16),
          Text(
            'Exercise Complete!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isVerySmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 6 : 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 0),
            child: Text(
              'Great job completing $exerciseName',
              style: GoogleFonts.poppins(
                color: Colors.grey[400], 
                fontSize: isVerySmallScreen ? 12 : 14
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 24),
          
          if (hasRemainingExercises) ...[
            Text(
              'Choose your next exercise:',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isVerySmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
            Container(
              constraints: BoxConstraints(
                maxHeight: isVerySmallScreen 
                  ? screenHeight * 0.25 
                  : isSmallScreen 
                    ? screenHeight * 0.3 
                    : screenHeight * 0.35
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: remainingExercises.map((index) {
                    final exercise = workoutExercises[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: isVerySmallScreen ? 6 : 8),
                      child: InkWell(
                        onTap: () => onExerciseSelected(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[700]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: isVerySmallScreen ? 32 : 40,
                                height: isVerySmallScreen ? 32 : 40,
                                decoration: BoxDecoration(
                                  color: exerciseColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: exerciseColor,
                                  size: isVerySmallScreen ? 16 : 20,
                                ),
                              ),
                              SizedBox(width: isVerySmallScreen ? 8 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: isVerySmallScreen ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${exercise.sets} sets • ${exercise.reps} reps • ${exercise.formattedWeight}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: isVerySmallScreen ? 10 : 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[600],
                                size: isVerySmallScreen ? 12 : 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: isVerySmallScreen ? 12 : 16),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onExerciseSelected(-1),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasRemainingExercises ? Colors.grey[700] : exerciseColor,
                foregroundColor: hasRemainingExercises ? Colors.white : Colors.black,
                padding: EdgeInsets.symmetric(vertical: isVerySmallScreen ? 10 : 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                hasRemainingExercises ? 'Finish Workout' : 'Complete Workout',
                style: GoogleFonts.poppins(
                  fontSize: isVerySmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
