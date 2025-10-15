import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/routine.models.dart';

class AddExercisePage extends StatefulWidget {
  final Function(ExerciseModel) onExerciseAdded;
  final List<String> existingExerciseNames;

  const AddExercisePage({
    Key? key,
    required this.onExerciseAdded,
    this.existingExerciseNames = const [],
  }) : super(key: key);

  @override
  _AddExercisePageState createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  List<ExerciseModel> exercises = [];
  List<ExerciseModel> filteredExercises = [];
  List<ExerciseModel> selectedExercises = [];
  List<TargetMuscleModel> muscleGroups = [];
  TargetMuscleModel? selectedMuscleGroup;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchExercises(),
      _fetchMuscleGroups(),
    ]);
  }

  Future<void> _fetchMuscleGroups() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/exercises.php?action=fetchMuscles'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> musclesData = responseData['muscles'] ?? [];
          setState(() {
            muscleGroups = musclesData.map((muscle) => TargetMuscleModel.fromJson(muscle)).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching muscle groups: $e');
    }
  }

  Future<void> _fetchExercises() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await http.get(
        Uri.parse('https://api.cnergy.site/exercises.php?action=fetchExercises'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> exercisesData = responseData['exercises'] ?? [];
          setState(() {
            exercises = exercisesData.map((exercise) => ExerciseModel.fromJson(exercise)).toList();
            // Filter out existing exercises
            exercises = exercises.where((exercise) => 
              !widget.existingExerciseNames.contains(exercise.name)
            ).toList();
            filteredExercises = exercises;
            isLoading = false;
          });
        } else {
          setState(() {
            error = responseData['error'] ?? 'Failed to fetch exercises';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to fetch exercises: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _filterExercisesByMuscle(TargetMuscleModel? muscleGroup) {
    setState(() {
      selectedMuscleGroup = muscleGroup;
      if (muscleGroup == null) {
        filteredExercises = exercises;
      } else {
        filteredExercises = exercises.where((exercise) {
          return exercise.targetMuscle.toLowerCase().contains(muscleGroup.name.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleExerciseSelection(ExerciseModel exercise) {
    setState(() {
      if (selectedExercises.contains(exercise)) {
        selectedExercises.remove(exercise);
      } else {
        selectedExercises.add(exercise);
      }
    });
  }

  void _addSelectedExercises() {
    for (final exercise in selectedExercises) {
      widget.onExerciseAdded(exercise);
    }
    Navigator.pop(context);
  }

  IconData _getExerciseIcon(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (name.contains('push') || name.contains('press') || name.contains('bench')) {
      return Icons.fitness_center;
    } else if (name.contains('curl') || name.contains('bicep')) {
      return Icons.accessibility_new;
    } else if (name.contains('squat') || name.contains('leg')) {
      return Icons.directions_run;
    } else if (name.contains('deadlift') || name.contains('row')) {
      return Icons.sports_gymnastics;
    } else if (name.contains('shoulder') || name.contains('lateral')) {
      return Icons.sports_handball;
    } else if (name.contains('tricep') || name.contains('extension')) {
      return Icons.sports_mma;
    } else if (name.contains('calf') || name.contains('raise')) {
      return Icons.directions_walk;
    } else if (name.contains('crunch') || name.contains('core') || name.contains('abs')) {
      return Icons.sports_tennis;
    } else {
      return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Exercises',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (selectedExercises.isNotEmpty)
            TextButton(
              onPressed: _addSelectedExercises,
              child: Text(
                'Add (${selectedExercises.length})',
                style: GoogleFonts.poppins(
                  color: Color(0xFF007AFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007AFF),
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        error!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF007AFF),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with selection info
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Exercises',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Select exercises to add to your workout',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          if (selectedExercises.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF007AFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFF007AFF).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${selectedExercises.length} selected',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF007AFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Muscle Group Filter
                    Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: muscleGroups.length + 1, // +1 for "All"
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // "All" option
                            return GestureDetector(
                              onTap: () => _filterExercisesByMuscle(null),
                              child: Container(
                                margin: EdgeInsets.only(right: 12),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedMuscleGroup == null ? Color(0xFF007AFF) : Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: selectedMuscleGroup == null ? [
                                    BoxShadow(
                                      color: Color(0xFF007AFF).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    'All',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          final muscleGroup = muscleGroups[index - 1];
                          final isSelected = selectedMuscleGroup?.id == muscleGroup.id;
                          
                          return GestureDetector(
                            onTap: () => _filterExercisesByMuscle(muscleGroup),
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF007AFF) : Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Color(0xFF007AFF).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: Center(
                                child: Text(
                                  muscleGroup.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Exercises List
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          final isSelected = selectedExercises.contains(exercise);
                          
                          return GestureDetector(
                            onTap: () => _toggleExerciseSelection(exercise),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 16),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF1A3A5C) : Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF007AFF) : Color(0xFF333333),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: Color(0xFF007AFF).withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Selection Checkbox
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Color(0xFF007AFF) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? Color(0xFF007AFF) : Color(0xFF666666),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
                                  SizedBox(width: 20),
                                  
                                  // Exercise Icon
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xFF333333),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      _getExerciseIcon(exercise.name),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  
                                  // Exercise Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (exercise.targetMuscle.isNotEmpty) ...[
                                          SizedBox(height: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF007AFF).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              exercise.targetMuscle,
                                              style: GoogleFonts.poppins(
                                                color: Color(0xFF007AFF),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  
                                  // Selection indicator
                                  if (isSelected)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(0xFF007AFF),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}