import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/routine.models.dart';
import '../models/exercise_selection_model.dart';

class EnhancedMuscleGroupService {
  static const String baseUrl = "https://api.cnergy.site/exercises.php";

  // Fetch muscle groups with their primary parts from database
  static Future<List<MuscleGroupWithParts>> fetchMuscleGroupsWithParts() async {
    try {
      print('🔍 Fetching muscle groups with primary parts...');
      
      final url = '$baseUrl?action=fetchMusclesWithParts';
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
          final List<dynamic> muscleGroupsData = responseData['muscle_groups'] ?? [];
          
          return muscleGroupsData.map((group) => MuscleGroupWithParts.fromJson(group)).toList();
        } else {
          throw Exception(responseData['error'] ?? 'Failed to fetch muscle groups');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error fetching muscle groups with parts: $e');
      throw Exception('Failed to load muscle groups: $e');
    }
  }

  // Calculate completion percentage based on primary parts hit
  static double calculateMuscleGroupCompletion(
    String muscleGroupName, 
    List<SelectedExerciseWithConfig> selectedExercises,
    List<MuscleGroupWithParts> muscleGroups
  ) {
    // Find the muscle group
    final muscleGroup = muscleGroups.firstWhere(
      (group) => group.name.toLowerCase() == muscleGroupName.toLowerCase(),
      orElse: () => MuscleGroupWithParts(id: 0, name: '', primaryParts: []),
    );

    if (muscleGroup.primaryParts.isEmpty) return 0.0;

    // Get all primary parts that are being targeted by selected exercises
    Set<String> hitPrimaryParts = {};
    
    for (var exercise in selectedExercises) {
      final exercisePrimaryParts = _getPrimaryPartsForExercise(exercise.exercise, muscleGroup);
      hitPrimaryParts.addAll(exercisePrimaryParts);
    }
    
    final int totalPrimaryParts = muscleGroup.primaryParts.length;
    final int hitPrimaryPartsCount = hitPrimaryParts.length;
    
    final percentage = (hitPrimaryPartsCount / totalPrimaryParts) * 100;
    print('Muscle Group "$muscleGroupName": $hitPrimaryPartsCount/$totalPrimaryParts = ${percentage.toStringAsFixed(1)}%');
    
    return percentage;
  }
  
  // Get primary parts that this exercise targets for a specific muscle group
  static List<String> _getPrimaryPartsForExercise(
    ExerciseSelectionModel exercise, 
    MuscleGroupWithParts muscleGroup
  ) {
    List<String> targetedParts = [];
    
    // Parse the exercise's target muscle to find primary parts
    final targetMuscle = exercise.targetMuscle.toLowerCase().trim();
    final muscleParts = targetMuscle.split(',');
    
    for (var part in muscleParts) {
      final cleanPart = part.trim();
      if (cleanPart.isEmpty) continue;
      
      // Extract muscle name and role
      final muscleMatch = RegExp(r'^([^(]+)\s*\(([^)]+)\)').firstMatch(cleanPart);
      if (muscleMatch != null) {
        final muscle = muscleMatch.group(1)!.trim().toLowerCase();
        final role = muscleMatch.group(2)!.trim().toLowerCase();
        
        // Only consider primary muscles
        if (role == 'primary') {
          // Check if this muscle matches any of our primary parts
          for (var primaryPart in muscleGroup.primaryParts) {
            if (primaryPart.name.toLowerCase().trim() == muscle) {
              targetedParts.add(primaryPart.name);
            }
          }
        }
      }
    }
    
    return targetedParts;
  }

  // Get list of primary parts that are being targeted by selected exercises
  static List<PrimaryMusclePart> getTargetedPrimaryParts(
    String muscleGroupName,
    List<SelectedExerciseWithConfig> selectedExercises,
    List<MuscleGroupWithParts> muscleGroups
  ) {
    final muscleGroup = muscleGroups.firstWhere(
      (group) => group.name.toLowerCase() == muscleGroupName.toLowerCase(),
      orElse: () => MuscleGroupWithParts(id: 0, name: '', primaryParts: []),
    );

    Set<String> hitPrimaryParts = {};
    
    for (var exercise in selectedExercises) {
      final exercisePrimaryParts = _getPrimaryPartsForExercise(exercise.exercise, muscleGroup);
      hitPrimaryParts.addAll(exercisePrimaryParts);
    }
    
    return muscleGroup.primaryParts.where((part) => hitPrimaryParts.contains(part.name)).toList();
  }
  
  // Get list of primary parts that are NOT being targeted
  static List<PrimaryMusclePart> getUntargetedPrimaryParts(
    String muscleGroupName,
    List<SelectedExerciseWithConfig> selectedExercises,
    List<MuscleGroupWithParts> muscleGroups
  ) {
    final muscleGroup = muscleGroups.firstWhere(
      (group) => group.name.toLowerCase() == muscleGroupName.toLowerCase(),
      orElse: () => MuscleGroupWithParts(id: 0, name: '', primaryParts: []),
    );

    Set<String> hitPrimaryParts = {};
    
    for (var exercise in selectedExercises) {
      final exercisePrimaryParts = _getPrimaryPartsForExercise(exercise.exercise, muscleGroup);
      hitPrimaryParts.addAll(exercisePrimaryParts);
    }
    
    return muscleGroup.primaryParts.where((part) => !hitPrimaryParts.contains(part.name)).toList();
  }
}

// Model for muscle group with its primary parts
class MuscleGroupWithParts {
  final int id;
  final String name;
  final String imageUrl;
  final List<PrimaryMusclePart> primaryParts;

  MuscleGroupWithParts({
    required this.id,
    required this.name,
    this.imageUrl = '',
    required this.primaryParts,
  });

  factory MuscleGroupWithParts.fromJson(Map<String, dynamic> json) {
    return MuscleGroupWithParts(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      primaryParts: (json['primary_parts'] as List<dynamic>?)
          ?.map((part) => PrimaryMusclePart.fromJson(part))
          .toList() ?? [],
    );
  }
}

// Model for primary muscle part
class PrimaryMusclePart {
  final int id;
  final String name;
  final String description;

  PrimaryMusclePart({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory PrimaryMusclePart.fromJson(Map<String, dynamic> json) {
    return PrimaryMusclePart(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
