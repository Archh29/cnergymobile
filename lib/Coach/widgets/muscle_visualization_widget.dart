import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MuscleVisualizationWidget extends StatefulWidget {
  final String? exerciseName;
  final int? programId;
  final int? userId;
  final List<String>? exerciseNames;

  const MuscleVisualizationWidget({
    Key? key,
    this.exerciseName,
    this.programId,
    this.userId,
    this.exerciseNames,
  }) : super(key: key);

  @override
  _MuscleVisualizationWidgetState createState() => _MuscleVisualizationWidgetState();
}

class _MuscleVisualizationWidgetState extends State<MuscleVisualizationWidget> {
  List<MuscleData> _muscles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMuscles();
  }

  @override
  void didUpdateWidget(MuscleVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if parameters changed
    if (oldWidget.exerciseName != widget.exerciseName ||
        oldWidget.programId != widget.programId ||
        oldWidget.exerciseNames != widget.exerciseNames) {
      _loadMuscles();
    }
  }

  Future<void> _loadMuscles() async {
    setState(() => _isLoading = true);

    try {
      List<MuscleData> muscles = [];

      if (widget.exerciseName != null && widget.exerciseName!.isNotEmpty) {
        // Load muscles for a specific exercise
        muscles = await _fetchMusclesByExercise(widget.exerciseName!);
      } else if (widget.programId != null && widget.userId != null) {
        // Load muscles for a program
        muscles = await _fetchMusclesByProgram(widget.programId!, widget.userId!);
      } else if (widget.exerciseNames != null && widget.exerciseNames!.isNotEmpty) {
        // Load muscles for multiple exercises
        muscles = await _fetchMusclesByExercises(widget.exerciseNames!);
      }

      if (mounted) {
        setState(() {
          _muscles = muscles;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading muscles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<MuscleData>> _fetchMusclesByExercise(String exerciseName) async {
    try {
      final url = 'https://api.cnergy.site/exercise_muscles.php?action=get_muscles_by_exercise&exercise_name=${Uri.encodeComponent(exerciseName)}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> musclesData = data['muscles'] ?? [];
          return musclesData.map((m) => MuscleData.fromJson(m)).toList();
        }
      }
    } catch (e) {
      print('Error fetching muscles by exercise: $e');
    }
    return [];
  }

  Future<List<MuscleData>> _fetchMusclesByProgram(int programId, int userId) async {
    try {
      final url = 'https://api.cnergy.site/exercise_muscles.php?action=get_muscles_by_program&program_id=$programId&user_id=$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> musclesData = data['muscles'] ?? [];
          return musclesData.map((m) => MuscleData.fromJson(m)).toList();
        }
      }
    } catch (e) {
      print('Error fetching muscles by program: $e');
    }
    return [];
  }

  Future<List<MuscleData>> _fetchMusclesByExercises(List<String> exerciseNames) async {
    try {
      final url = 'https://api.cnergy.site/exercise_muscles.php?action=get_muscles_by_exercises';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'exercise_names': exerciseNames}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> musclesData = data['muscles'] ?? [];
          return musclesData.map((m) => MuscleData.fromJson(m)).toList();
        }
      }
    } catch (e) {
      print('Error fetching muscles by exercises: $e');
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );
    }

    if (_muscles.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              color: Colors.grey[600],
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'No muscle data available',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.accessibility_new,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Muscles Targeted',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _muscles.map((muscle) => _buildMuscleChip(muscle)).toList(),
          ),
          SizedBox(height: 16),
          _buildMuscleImages(),
        ],
      ),
    );
  }

  Widget _buildMuscleChip(MuscleData muscle) {
    Color roleColor;
    String roleLabel;

    switch (muscle.role) {
      case 'primary':
        roleColor = Color(0xFF4ECDC4);
        roleLabel = 'Primary';
        break;
      case 'secondary':
        roleColor = Color(0xFF6C5CE7);
        roleLabel = 'Secondary';
        break;
      default:
        roleColor = Colors.grey;
        roleLabel = 'Support';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: roleColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6),
          Text(
            muscle.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          if (muscle.exerciseCount != null && muscle.exerciseCount! > 1) ...[
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${muscle.exerciseCount}x',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMuscleImages() {
    // Get muscles with images
    final musclesWithImages = _muscles.where((m) => m.imageUrl.isNotEmpty).toList();

    if (musclesWithImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[800]),
        SizedBox(height: 12),
        Text(
          'Muscle Diagram',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: musclesWithImages.length,
            separatorBuilder: (context, index) => SizedBox(width: 12),
            itemBuilder: (context, index) {
              final muscle = musclesWithImages[index];
              return _buildMuscleImageCard(muscle);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleImageCard(MuscleData muscle) {
    Color roleColor = muscle.role == 'primary' 
        ? Color(0xFF4ECDC4) 
        : muscle.role == 'secondary'
            ? Color(0xFF6C5CE7)
            : Colors.grey;

    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                muscle.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Text(
              muscle.name,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleIconGrid() {
    if (_muscles.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[800]),
        SizedBox(height: 12),
        Text(
          'Muscle Groups',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _muscles.map((muscle) => _buildMuscleIconCard(muscle)).toList(),
        ),
      ],
    );
  }

  Widget _buildMuscleIconCard(MuscleData muscle) {
    Color roleColor = muscle.role == 'primary' 
        ? Color(0xFF4ECDC4) 
        : muscle.role == 'secondary'
            ? Color(0xFF6C5CE7)
            : Colors.grey;

    IconData muscleIcon = _getMuscleIcon(muscle.name);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            roleColor.withOpacity(0.3),
            roleColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            muscleIcon,
            color: roleColor,
            size: 36,
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              muscle.name,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMuscleIcon(String muscleName) {
    final name = muscleName.toLowerCase();
    
    if (name.contains('chest') || name.contains('pec')) {
      return Icons.favorite;
    } else if (name.contains('back') || name.contains('lat')) {
      return Icons.view_column;
    } else if (name.contains('shoulder') || name.contains('delt')) {
      return Icons.accessibility_new;
    } else if (name.contains('bicep') || name.contains('arm')) {
      return Icons.fitness_center;
    } else if (name.contains('tricep')) {
      return Icons.sports_martial_arts;
    } else if (name.contains('forearm')) {
      return Icons.back_hand;
    } else if (name.contains('leg') || name.contains('quad') || name.contains('ham')) {
      return Icons.directions_walk;
    } else if (name.contains('calf')) {
      return Icons.directions_run;
    } else if (name.contains('glute')) {
      return Icons.chair;
    } else if (name.contains('core') || name.contains('abs') || name.contains('oblique')) {
      return Icons.grain;
    } else if (name.contains('trap')) {
      return Icons.keyboard_arrow_up;
    } else {
      return Icons.sports_gymnastics;
    }
  }
}

class MuscleData {
  final int id;
  final String name;
  final String imageUrl;
  final String role;
  final int? exerciseCount;

  MuscleData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.role,
    this.exerciseCount,
  });

  factory MuscleData.fromJson(Map<String, dynamic> json) {
    return MuscleData(
      id: int.parse(json['id'].toString()),
      name: json['name'].toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      role: json['role']?.toString() ?? 'primary',
      exerciseCount: json['exercise_count'] != null 
          ? int.parse(json['exercise_count'].toString())
          : null,
    );
  }
}

