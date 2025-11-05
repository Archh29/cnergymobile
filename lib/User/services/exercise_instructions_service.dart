import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseInstructionService {
  static const String baseUrl = 'https://api.cnergy.site/exercise_instructions.php';
  
  // Test method to check if API is reachable
  static Future<bool> testApiConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_exercise_details&exercise_id=1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));
      
      print('🔍 API Test - Status: ${response.statusCode}');
      print('🔍 API Test - Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('💥 API Test failed: $e');
      return false;
    }
  }
  
  static Future<ExerciseInstructionData?> getExerciseDetails(dynamic exerciseId) async {
    try {
      // Convert to int if it's a string
      final int id = exerciseId is String ? int.tryParse(exerciseId) ?? 0 : exerciseId;
      print('🔍 Converting exercise ID: $exerciseId (${exerciseId.runtimeType}) -> $id (int)');
      final url = '$baseUrl?action=get_exercise_details&exercise_id=$id';
      print('🔍 Fetching exercise details from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));

      print('📊 Response status: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('🔍 Parsed JSON data: $data');
          
          if (data['success'] == true) {
            print('✅ API returned success=true');
            if (data['exercise'] != null) {
              print('✅ Exercise data found: ${data['exercise']}');
              try {
                final exerciseData = ExerciseInstructionData.fromJson(data['exercise']);
                print('✅ Successfully parsed exercise data');
                return exerciseData;
              } catch (e) {
                print('💥 Error parsing exercise data: $e');
                print('💥 Stack trace: ${StackTrace.current}');
                return null;
              }
            } else {
              print('❌ Exercise data is null in response');
            }
          } else {
            print('❌ API returned success=false: ${data['error'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print('💥 Error parsing JSON response: $e');
          print('📋 Raw response body: ${response.body}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('📋 Error response body: ${response.body}');
      }
      return null;
    } catch (e) {
      print('💥 Error fetching exercise details: $e');
      return null;
    }
  }

  static Future<List<InstructionStep>> getExerciseInstructions(dynamic exerciseId) async {
    try {
      // Convert to int if it's a string
      final int id = exerciseId is String ? int.tryParse(exerciseId) ?? 0 : exerciseId;
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_exercise_instructions&exercise_id=$id'),
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

  static Future<Map<String, List<TargetMuscle>>> getExerciseMuscles(dynamic exerciseId) async {
    try {
      // Convert to int if it's a string
      final int id = exerciseId is String ? int.tryParse(exerciseId) ?? 0 : exerciseId;
      final response = await http.get(
        Uri.parse('$baseUrl?action=get_exercise_muscles&exercise_id=$id'),
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
    try {
      print('🔍 Parsing ExerciseInstructionData from JSON: $json');
      print('🔍 JSON keys: ${json.keys.toList()}');
      
      // Handle ID conversion (might be String or int)
      final dynamic idValue = json['id'];
      final int id = idValue is String ? int.tryParse(idValue) ?? 0 : (idValue ?? 0);
      print('🔍 Parsed ID: $id');
      
      print('🔍 Parsing name: ${json['name']}');
      print('🔍 Parsing description: ${json['description']}');
      print('🔍 Parsing image_url: ${json['image_url']}');
      print('🔍 Parsing video_url: ${json['video_url']}');
      print('🔍 Parsing instruction_steps: ${json['instruction_steps']}');
      print('🔍 Parsing benefits: ${json['benefits']}');
      print('🔍 Parsing target_muscles: ${json['target_muscles']}');
      
      return ExerciseInstructionData(
        id: id,
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
          'primary': (json['target_muscles']?['primary'] as List? ?? [])
              .map((m) => TargetMuscle.fromJson(m))
              .toList(),
          'secondary': (json['target_muscles']?['secondary'] as List? ?? [])
              .map((m) => TargetMuscle.fromJson(m))
              .toList(),
          'stabilizer': (json['target_muscles']?['stabilizer'] as List? ?? [])
              .map((m) => TargetMuscle.fromJson(m))
              .toList(),
        },
      );
    } catch (e) {
      print('💥 Error parsing ExerciseInstructionData: $e');
      print('📋 JSON data: $json');
      print('💥 Stack trace: ${StackTrace.current}');
      // Return a default object instead of rethrowing
      return ExerciseInstructionData(
        id: 0,
        name: 'Error Loading Exercise',
        description: 'Failed to load exercise data',
        imageUrl: '',
        videoUrl: '',
        instructionSteps: [],
        benefits: [],
        targetMuscles: {'primary': [], 'secondary': [], 'stabilizer': []},
      );
    }
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
    try {
      return InstructionStep(
        step: json['step'] ?? 0,
        instruction: json['instruction'] ?? '',
      );
    } catch (e) {
      print('💥 Error parsing InstructionStep: $e');
      return InstructionStep(step: 0, instruction: 'Error loading step');
    }
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
    try {
      return ExerciseBenefit(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
      );
    } catch (e) {
      print('💥 Error parsing ExerciseBenefit: $e');
      return ExerciseBenefit(title: 'Error', description: 'Failed to load benefit');
    }
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
    try {
      print('🔍 Parsing TargetMuscle from JSON: $json');
      
      // Handle ID conversion (might be String or int)
      final dynamic idValue = json['id'];
      final int id = idValue is String ? int.tryParse(idValue) ?? 0 : (idValue ?? 0);
      
      // Get name, handling various possible keys
      final String name = (json['name'] ?? json['muscle_name'] ?? '').toString();
      
      // Get image URL, handling various possible keys
      final String imageUrl = (json['image_url'] ?? json['muscle_image'] ?? '').toString();
      
      // Get parent_id
      final dynamic parentIdValue = json['parent_id'];
      final int? parentId = parentIdValue == null ? null : (parentIdValue is String ? int.tryParse(parentIdValue) : parentIdValue);
      
      // Get parent_name
      final String? parentName = json['parent_name']?.toString();
      
      // Get role
      final String role = json['role']?.toString() ?? 'primary';
      
      print('🔍 Parsed muscle: id=$id, name=$name, role=$role');
      
      if (name.isEmpty) {
        throw Exception('Muscle name is empty');
      }
      
      return TargetMuscle(
        id: id,
        name: name,
        imageUrl: imageUrl,
        parentId: parentId,
        parentName: parentName,
        role: role,
      );
    } catch (e, stackTrace) {
      print('💥 Error parsing TargetMuscle: $e');
      print('💥 Stack trace: $stackTrace');
      print('💥 JSON data: $json');
      return TargetMuscle(
        id: 0,
        name: 'Unknown Muscle',
        imageUrl: '',
        role: 'primary',
      );
    }
  }
}
