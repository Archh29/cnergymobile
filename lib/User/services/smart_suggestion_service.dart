import 'dart:math';
import 'package:flutter/material.dart';

class SmartSuggestionService {
  // Set experience variations
  static const Map<String, List<String>> suggestionVariations = {
    'easy': [
      "This set felt easy - you can handle more weight",
      "Great reps! Consider increasing weight",
      "Easy set - try heavier weight next time",
      "You're getting stronger! Time to increase weight",
      "Light work! You can handle more weight",
      "Easy peasy! Consider adding more weight",
      "Smooth set! You can definitely go heavier",
      "Too easy! Time to challenge yourself more"
    ],
    'moderate': [
      "Perfect intensity! This weight is working well",
      "Great set! Keep this weight",
      "Perfect - this weight is ideal for you",
      "Excellent! This weight is perfect",
      "Spot on! This weight is working great",
      "Just right! This weight is perfect",
      "Sweet spot! Keep this weight",
      "Perfect challenge! This weight is ideal"
    ],
    'hard': [
      "This weight is too heavy - consider reducing weight",
      "Too heavy - try lighter weight for better form",
      "Hard set - consider reducing weight",
      "This weight is challenging - try lighter weight",
      "Form over weight - consider reducing weight",
      "Too tough! Try lighter weight for better form",
      "Heavy set! Consider reducing weight",
      "Form first! Try lighter weight"
    ]
  };

  // Get a random suggestion for the given experience
  static String getRandomSuggestion(String experience) {
    final suggestions = suggestionVariations[experience.toLowerCase()];
    if (suggestions == null || suggestions.isEmpty) {
      return "Keep up the great work!";
    }
    
    final random = Random();
    return suggestions[random.nextInt(suggestions.length)];
  }

  // Determine suggestion type based on experience
  static String getSuggestionType(String experience) {
    switch (experience.toLowerCase()) {
      case 'easy':
        return 'weight_increase';
      case 'moderate':
        return 'maintain_weight';
      case 'hard':
        return 'weight_decrease';
      default:
        return 'maintain_weight';
    }
  }

  // Get suggestion icon based on experience
  static IconData getSuggestionIcon(String experience) {
    switch (experience.toLowerCase()) {
      case 'easy':
        return Icons.lightbulb_outline;
      case 'moderate':
        return Icons.check_circle_outline;
      case 'hard':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  // Get suggestion color based on experience
  static Color getSuggestionColor(String experience) {
    switch (experience.toLowerCase()) {
      case 'easy':
        return Color(0xFF4ECDC4); // Teal
      case 'moderate':
        return Color(0xFF2ECC71); // Green
      case 'hard':
        return Color(0xFFE74C3C); // Red
      default:
        return Color(0xFF4ECDC4); // Teal
    }
  }

  // Analyze set performance and generate suggestion
  static Map<String, dynamic> generateSuggestion({
    required String experience,
    required int reps,
    required double weight,
    required String exerciseName,
  }) {
    // Smart logic: Consider both experience AND rep range
    final smartSuggestion = _getSmartSuggestion(experience, reps);
    final suggestion = smartSuggestion['message'];
    final type = smartSuggestion['type'];
    final icon = smartSuggestion['icon'];
    final color = smartSuggestion['color'];

    return {
      'message': suggestion,
      'type': type,
      'icon': icon,
      'color': color,
      'experience': experience,
      'reps': reps,
      'weight': weight,
      'exerciseName': exerciseName,
    };
  }

  // Smart suggestion logic considering both experience and rep range
  static Map<String, dynamic> _getSmartSuggestion(String experience, int reps) {
    // Optimal rep range is 6-12 reps
    const int optimalMinReps = 6;
    const int optimalMaxReps = 12;
    
    // Determine if reps are in optimal range
    bool isOptimalRange = reps >= optimalMinReps && reps <= optimalMaxReps;
    bool isTooFewReps = reps < optimalMinReps;
    bool isTooManyReps = reps > optimalMaxReps;

    switch (experience.toLowerCase()) {
      case 'easy':
        if (isTooManyReps) {
          // Easy + Too many reps = Definitely increase weight
          return {
            'message': getRandomSuggestion('easy'),
            'type': 'weight_increase',
            'icon': Icons.lightbulb_outline,
            'color': Color(0xFF4ECDC4), // Teal
          };
        } else if (isOptimalRange) {
          // Easy + Optimal reps = Increase weight
          return {
            'message': getRandomSuggestion('easy'),
            'type': 'weight_increase',
            'icon': Icons.lightbulb_outline,
            'color': Color(0xFF4ECDC4), // Teal
          };
        } else {
          // Easy + Too few reps = Increase weight (but mention form)
          return {
            'message': "Easy set but only $reps reps - increase weight and focus on form",
            'type': 'weight_increase',
            'icon': Icons.lightbulb_outline,
            'color': Color(0xFF4ECDC4), // Teal
          };
        }

      case 'moderate':
        if (isTooManyReps) {
          // Moderate + Too many reps = Increase weight
          return {
            'message': "Good intensity but $reps reps is too many - increase weight",
            'type': 'weight_increase',
            'icon': Icons.trending_up,
            'color': Color(0xFF4ECDC4), // Teal
          };
        } else if (isOptimalRange) {
          // Moderate + Optimal reps = Perfect, maintain weight
          return {
            'message': getRandomSuggestion('moderate'),
            'type': 'maintain_weight',
            'icon': Icons.check_circle_outline,
            'color': Color(0xFF2ECC71), // Green
          };
        } else {
          // Moderate + Too few reps = Decrease weight
          return {
            'message': "Moderate difficulty but only $reps reps - decrease weight for better form",
            'type': 'weight_decrease',
            'icon': Icons.warning_amber_rounded,
            'color': Color(0xFFE74C3C), // Red
          };
        }

      case 'hard':
        if (isTooManyReps) {
          // Hard + Too many reps = This shouldn't happen, but maintain weight
          return {
            'message': "Hard set with $reps reps - keep this weight for now",
            'type': 'maintain_weight',
            'icon': Icons.check_circle_outline,
            'color': Color(0xFF2ECC71), // Green
          };
        } else if (isOptimalRange) {
          // Hard + Optimal reps = Perfect challenge, maintain weight
          return {
            'message': "Perfect challenge! Hard set with $reps reps - keep this weight",
            'type': 'maintain_weight',
            'icon': Icons.check_circle_outline,
            'color': Color(0xFF2ECC71), // Green
          };
        } else {
          // Hard + Too few reps = Definitely decrease weight
          return {
            'message': getRandomSuggestion('hard'),
            'type': 'weight_decrease',
            'icon': Icons.warning_amber_rounded,
            'color': Color(0xFFE74C3C), // Red
          };
        }

      default:
        return {
          'message': "Keep up the great work!",
          'type': 'maintain_weight',
          'icon': Icons.info_outline,
          'color': Color(0xFF4ECDC4), // Teal
        };
    }
  }

  // Get experience options for the modal
  static List<Map<String, dynamic>> getExperienceOptions() {
    return [
      {
        'id': 'easy',
        'label': '😌 Easy',
        'description': 'This set felt easy',
        'color': 0xFF4ECDC4,
      },
      {
        'id': 'moderate',
        'label': '😐 Moderate',
        'description': 'This set felt challenging but manageable',
        'color': 0xFF2ECC71,
      },
      {
        'id': 'hard',
        'label': '😤 Hard',
        'description': 'This set felt very difficult',
        'color': 0xFFE74C3C,
      },
    ];
  }
}
