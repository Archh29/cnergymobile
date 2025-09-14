import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/exercise_selection_model.dart';
import './models/member_model.dart';
import './services/routine_service.dart';
import './services/exercise_selection_service.dart';

class CoachExerciseSelectionPage extends StatefulWidget {
  final MemberModel selectedClient;
  final MuscleGroupModel muscleGroup;
  final Color selectedColor;
  final List<SelectedExerciseWithConfig> currentSelections;

  const CoachExerciseSelectionPage({
    Key? key,
    required this.selectedClient,
    required this.muscleGroup,
    required this.selectedColor,
    this.currentSelections = const [],
  }) : super(key: key);

  @override
  _CoachExerciseSelectionPageState createState() => _CoachExerciseSelectionPageState();
}

class _CoachExerciseSelectionPageState extends State<CoachExerciseSelectionPage> {
  List<ExerciseSelectionModel> availableExercises = [];
  List<SelectedExerciseWithConfig> selectedExercises = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedExercises = List.from(widget.currentSelections);
    _loadExercises();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      setState(() => isLoading = true);

      print('🔍 Loading exercises for muscle group: ${widget.muscleGroup.name} (ID: ${widget.muscleGroup.id})');
      final exercises = await RoutineService.getExercisesByMuscleGroup(widget.muscleGroup.id);
      print('📋 Loaded ${exercises.length} exercises');

      setState(() {
        availableExercises = exercises.map((exercise) {
          print('🏋️ Exercise: ${exercise.name} - ID: ${exercise.id}');
          return ExerciseSelectionModel(
            id: exercise.id ?? 0,
            name: exercise.name,
            description: exercise.description ?? '',
            imageUrl: exercise.imageUrl ?? '',
            targetMuscle: widget.muscleGroup.name, // Use muscle group name instead
            category: exercise.category ?? 'General',
            difficulty: exercise.difficulty ?? 'Intermediate',
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load exercises: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  bool _isExerciseSelected(ExerciseSelectionModel exercise) {
    return selectedExercises.any((selected) => selected.exercise.id == exercise.id);
  }

  SelectedExerciseWithConfig? _getSelectedExerciseConfig(ExerciseSelectionModel exercise) {
    try {
      return selectedExercises.firstWhere((selected) => selected.exercise.id == exercise.id);
    } catch (e) {
      return null;
    }
  }

  void _toggleExerciseSelection(ExerciseSelectionModel exercise) {
    setState(() {
      if (_isExerciseSelected(exercise)) {
        // Remove exercise
        selectedExercises.removeWhere((selected) => selected.exercise.id == exercise.id);
      } else {
        // Add exercise with default configuration
        selectedExercises.add(SelectedExerciseWithConfig(
          exercise: exercise,
          sets: 3,
          reps: '10',
          weight: '',
          restTime: 60,
          notes: '',
        ));
      }
    });
  }

  void _showExerciseConfigDialog(ExerciseSelectionModel exercise) {
    final existingConfig = _getSelectedExerciseConfig(exercise);
    final isSelected = existingConfig != null;
    
    // Controllers for the dialog
    final setsController = TextEditingController(text: (existingConfig?.sets ?? 3).toString());
    final repsController = TextEditingController(text: existingConfig?.reps ?? '10');
    final weightController = TextEditingController(text: existingConfig?.weight ?? '');
    final restController = TextEditingController(text: (existingConfig?.restTime ?? 60).toString());
    final notesController = TextEditingController(text: existingConfig?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Configure for ${widget.selectedClient.firstName}',
              style: GoogleFonts.poppins(
                color: widget.selectedColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sets
              _buildDialogInputField('Sets', setsController, TextInputType.number),
              SizedBox(height: 16),
              
              // Reps
              _buildDialogInputField('Reps', repsController, TextInputType.text),
              SizedBox(height: 16),
              
              // Weight
              _buildDialogInputField('Weight (optional)', weightController, TextInputType.text),
              SizedBox(height: 16),
              
              // Rest Time
              _buildDialogInputField('Rest Time (seconds)', restController, TextInputType.number),
              SizedBox(height: 16),
              
              // Notes
              _buildDialogInputField('Notes (optional)', notesController, TextInputType.text, maxLines: 3),
            ],
          ),
        ),
        actions: [
          if (isSelected)
            TextButton(
              onPressed: () {
                setState(() {
                  selectedExercises.removeWhere((selected) => selected.exercise.id == exercise.id);
                });
                Navigator.pop(context);
              },
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final sets = int.tryParse(setsController.text) ?? 3;
              final reps = repsController.text.isNotEmpty ? repsController.text : '10';
              final weight = weightController.text;
              final restTime = int.tryParse(restController.text) ?? 60;
              final notes = notesController.text;

              setState(() {
                // Remove existing if present
                selectedExercises.removeWhere((selected) => selected.exercise.id == exercise.id);
                
                // Add with new configuration
                selectedExercises.add(SelectedExerciseWithConfig(
                  exercise: exercise,
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  restTime: restTime,
                  notes: notes,
                ));
              });
              
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.selectedColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isSelected ? 'Update' : 'Add Exercise',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInputField(String label, TextEditingController controller, TextInputType keyboardType, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  List<ExerciseSelectionModel> get filteredExercises {
    if (searchQuery.isEmpty) return availableExercises;
    
    return availableExercises.where((exercise) {
      return exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             exercise.description.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, selectedExercises),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.muscleGroup.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'For ${widget.selectedClient.firstName} • ${_getSelectedCountForMuscle()} selected',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: widget.selectedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (_getSelectedCountForMuscle() > 0)
            TextButton(
              onPressed: () => Navigator.pop(context, selectedExercises),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(
                  color: widget.selectedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Client Info Header
          Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.selectedColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.selectedColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.selectedClient.initials,
                      style: GoogleFonts.poppins(
                        color: widget.selectedColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedClient.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${selectedExercises.length} total exercises selected',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.fitness_center,
                  color: widget.selectedColor,
                  size: 16,
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search ${widget.muscleGroup.name.toLowerCase()} exercises...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: widget.selectedColor),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Exercise List
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
                    ),
                  )
                : filteredExercises.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  int _getSelectedCountForMuscle() {
    return selectedExercises
        .where((selected) => selected.exercise.targetMuscle.toLowerCase() == widget.muscleGroup.name.toLowerCase())
        .length;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.fitness_center : Icons.search_off,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty 
                ? 'No exercises available'
                : 'No exercises found',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'No exercises found for ${widget.muscleGroup.name}'
                : 'Try adjusting your search terms',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                searchController.clear();
                setState(() => searchQuery = '');
              },
              child: Text(
                'Clear Search',
                style: GoogleFonts.poppins(
                  color: widget.selectedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseSelectionModel exercise) {
    final isSelected = _isExerciseSelected(exercise);
    final config = _getSelectedExerciseConfig(exercise);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? widget.selectedColor : Colors.grey[800]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showExerciseConfigDialog(exercise),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise Image/Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exercise.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fitness_center,
                                color: widget.selectedColor,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.fitness_center,
                          color: widget.selectedColor,
                          size: 24,
                        ),
                ),
                
                SizedBox(width: 16),
                
                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exercise.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          exercise.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 8),
                      
                      // Configuration display
                      if (isSelected && config != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.selectedColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${config.sets} sets × ${config.reps} reps${config.weight.isNotEmpty ? ' @ ${config.weight}' : ''}',
                            style: GoogleFonts.poppins(
                              color: widget.selectedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                exercise.difficulty,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Selection indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? widget.selectedColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? widget.selectedColor : Colors.grey[600]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
