import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/routine.models.dart';

class ExerciseDetailModal extends StatelessWidget {
  final ExerciseModel exercise;

  const ExerciseDetailModal({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 375;
    final exerciseColor = Color(int.parse(exercise.color));
    
    return Container(
      height: size.height * (isSmallScreen ? 0.9 : 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(exerciseColor, isSmallScreen),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVideoSection(exerciseColor, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  _buildExerciseInfo(exerciseColor, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  _buildInstructions(exerciseColor, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  _buildTipsSection(exerciseColor, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color exerciseColor, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            exerciseColor.withOpacity(0.2),
            exerciseColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: exerciseColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: exerciseColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.category} • ${exercise.difficulty}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[300],
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(Color exerciseColor, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 180 : 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: exerciseColor.withOpacity(0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  exerciseColor.withOpacity(0.1),
                  exerciseColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.play_circle_outline,
              color: exerciseColor,
              size: isSmallScreen ? 56 : 64,
            ),
          ),
          
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Exercise Demonstration',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '1:30',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo(Color exerciseColor, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exercise Details',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Sets',
                  exercise.targetSets.toString(),
                  Icons.repeat,
                  exerciseColor,
                  isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildInfoCard(
                  'Reps',
                  exercise.targetReps,
                  Icons.format_list_numbered,
                  exerciseColor,
                  isSmallScreen,
                ),
              ),
            ],
          ),
          
          if (exercise.targetWeight.isNotEmpty || exercise.restTime > 0) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            Row(
              children: [
                if (exercise.targetWeight.isNotEmpty)
                  Expanded(
                    child: _buildInfoCard(
                      'Weight',
                      exercise.targetWeight,
                      Icons.fitness_center,
                      exerciseColor,
                      isSmallScreen,
                    ),
                  ),
                if (exercise.targetWeight.isNotEmpty && exercise.restTime > 0)
                  SizedBox(width: isSmallScreen ? 8 : 12),
                if (exercise.restTime > 0)
                  Expanded(
                    child: _buildInfoCard(
                      'Rest',
                      '${exercise.restTime}s',
                      Icons.timer,
                      exerciseColor,
                      isSmallScreen,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(Color exerciseColor, bool isSmallScreen) {
    final instructions = [
      'Start in the starting position with proper form and alignment.',
      'Perform the movement slowly and with control, focusing on the target muscles.',
      'Maintain proper breathing throughout the exercise - exhale on exertion.',
      'Complete all repetitions before resting for the specified time.',
    ];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, color: exerciseColor, size: isSmallScreen ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          ...List.generate(instructions.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isSmallScreen ? 20 : 24,
                    height: isSmallScreen ? 20 : 24,
                    decoration: BoxDecoration(
                      color: exerciseColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: exerciseColor,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Text(
                      instructions[index],
                      style: GoogleFonts.poppins(
                        color: Colors.grey[300],
                        fontSize: isSmallScreen ? 12 : 14,
                        height: 1.4,
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

  Widget _buildTipsSection(Color exerciseColor, bool isSmallScreen) {
    final tips = [
      {
        'title': 'Form Focus',
        'description': 'Prioritize proper form over heavy weight to prevent injury.',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': 'Breathing',
        'description': 'Maintain steady breathing - never hold your breath during the exercise.',
        'icon': Icons.air,
        'color': Colors.blue,
      },
      {
        'title': 'Progressive Overload',
        'description': 'Gradually increase weight or reps as you get stronger.',
        'icon': Icons.trending_up,
        'color': exerciseColor,
      },
    ];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: exerciseColor, size: isSmallScreen ? 18 : 20),
              const SizedBox(width: 8),
              Text(
                'Tips & Safety',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
            child: _buildTipItem(
              tip['title'] as String,
              tip['description'] as String,
              tip['icon'] as IconData,
              tip['color'] as Color,
              isSmallScreen,
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String description, IconData icon, Color color, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isSmallScreen ? 14 : 16),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: isSmallScreen ? 10 : 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
