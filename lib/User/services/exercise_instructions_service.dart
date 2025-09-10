import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseInstructionService {
  static const String baseUrl = 'http://localhost/cynergy/exercise_instructions.php';
  
  static Future<ExerciseInstructionData?> getExerciseDetails(int exerciseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise_instructions.php?action=get_exercise_details&exercise_id=$exerciseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ExerciseInstructionData.fromJson(data['exercise']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching exercise details: $e');
      return null;
    }
  }

  static Future<List<InstructionStep>> getExerciseInstructions(int exerciseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise_instructions.php?action=get_exercise_instructions&exercise_id=$exerciseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['instructions'] as List)
              .map((step) => InstructionStep.fromJson(step))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching exercise instructions: $e');
      return [];
    }
  }

  static Future<Map<String, List<TargetMuscle>>> getExerciseMuscles(int exerciseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise_instructions.php?action=get_exercise_muscles&exercise_id=$exerciseId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final muscles = data['target_muscles'] as Map<String, dynamic>;
          return {
            'primary': (muscles['primary'] as List)
                .map((m) => TargetMuscle.fromJson(m))
                .toList(),
            'secondary': (muscles['secondary'] as List)
                .map((m) => TargetMuscle.fromJson(m))
                .toList(),
            'stabilizer': (muscles['stabilizer'] as List)
                .map((m) => TargetMuscle.fromJson(m))
                .toList(),
          };
        }
      }
      return {'primary': [], 'secondary': [], 'stabilizer': []};
    } catch (e) {
      print('Error fetching exercise muscles: $e');
      return {'primary': [], 'secondary': [], 'stabilizer': []};
    }
  }
}

class ExerciseInstructionData {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final List<InstructionStep> instructionSteps;
  final List<ExerciseBenefit> benefits;
  final Map<String, List<TargetMuscle>> targetMuscles;

  ExerciseInstructionData({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.videoUrl,
    required this.instructionSteps,
    required this.benefits,
    required this.targetMuscles,
  });

  factory ExerciseInstructionData.fromJson(Map<String, dynamic> json) {
    return ExerciseInstructionData(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
      instructionSteps: (json['instruction_steps'] as List? ?? [])
          .map((step) => InstructionStep.fromJson(step))
          .toList(),
      benefits: (json['benefits'] as List? ?? [])
          .map((benefit) => ExerciseBenefit.fromJson(benefit))
          .toList(),
      targetMuscles: {
        'primary': (json['target_muscles']['primary'] as List? ?? [])
            .map((m) => TargetMuscle.fromJson(m))
            .toList(),
        'secondary': (json['target_muscles']['secondary'] as List? ?? [])
            .map((m) => TargetMuscle.fromJson(m))
            .toList(),
        'stabilizer': (json['target_muscles']['stabilizer'] as List? ?? [])
            .map((m) => TargetMuscle.fromJson(m))
            .toList(),
      },
    );
  }
}

class InstructionStep {
  final int step;
  final String instruction;

  InstructionStep({
    required this.step,
    required this.instruction,
  });

  factory InstructionStep.fromJson(Map<String, dynamic> json) {
    return InstructionStep(
      step: json['step'],
      instruction: json['instruction'] ?? '',
    );
  }
}

class ExerciseBenefit {
  final String title;
  final String description;

  ExerciseBenefit({
    required this.title,
    required this.description,
  });

  factory ExerciseBenefit.fromJson(Map<String, dynamic> json) {
    return ExerciseBenefit(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class TargetMuscle {
  final int id;
  final String name;
  final String imageUrl;
  final int? parentId;
  final String? parentName;
  final String role;

  TargetMuscle({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.parentId,
    this.parentName,
    required this.role,
  });

  factory TargetMuscle.fromJson(Map<String, dynamic> json) {
    return TargetMuscle(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      parentId: json['parent_id'],
      parentName: json['parent_name'],
      role: json['role'] ?? 'primary',
    );
  }
}
