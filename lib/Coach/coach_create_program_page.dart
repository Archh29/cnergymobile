import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "models/member_model.dart";

class CoachCreateProgramPage extends StatefulWidget {
  final Color selectedColor;
  const CoachCreateProgramPage({
    Key? key,
    this.selectedColor = const Color(0xFF4ECDC4),
  }) : super(key: key);

  @override
  _CoachCreateProgramPageState createState() => _CoachCreateProgramPageState();
}

class _CoachCreateProgramPageState extends State<CoachCreateProgramPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  String selectedGoal = "General Fitness";
  String selectedDifficulty = "Beginner";
  String selectedCategory = "Strength Training";
  String selectedDay = "Monday";
  List<String> selectedTags = [];
  Color selectedColor = Color(0xFF4ECDC4);
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = false;

  final List<String> availableGoals = [
    "General Fitness", "Muscle Building", "Strength", "Fat Loss", "Endurance"
  ];
  
  final List<String> availableDifficulties = [
    "Beginner", "Intermediate", "Advanced"
  ];

  final List<String> availableCategories = [
    "Strength Training", "Cardio", "HIIT", "Flexibility", "Sports Specific", "Rehabilitation"
  ];
  
  final List<String> availableDays = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];
  
  final List<String> availableTags = [
    "Strength", "Cardio", "HIIT", "Upper Body", "Lower Body", "Full Body", "Core"
  ];
  
  final List<Color> availableColors = [
    Color(0xFF4ECDC4), // Teal (primary)
    Color(0xFF45B7D1), // Blue
    Color(0xFF2ECC71), // Green
    Color(0xFF9B59B6), // Purple
    Color(0xFFE67E22), // Orange (reduced prominence)
    Color(0xFFE74C3C), // Red
    Color(0xFFF39C12), // Yellow
    Color(0xFF34495E), // Dark blue-gray
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.selectedColor;
    nameController.text = "New Program Template";
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Program',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Reusable program for multiple clients',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color(0xFF9E9E9E), // Changed to neutral gray instead of selectedColor
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            _buildExercisesSection(),
            SizedBox(height: 24),
            _buildCustomizationSection(),
            SizedBox(height: 32),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          _buildInputField(
            'Program Name *',
            nameController,
            'Enter program template name',
          ),
          SizedBox(height: 16),
          
          _buildDurationField(),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Goal *',
            selectedGoal,
            availableGoals,
            (value) => setState(() => selectedGoal = value!),
          ),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Difficulty',
            selectedDifficulty,
            availableDifficulties,
            (value) => setState(() => selectedDifficulty = value!),
          ),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Category',
            selectedCategory,
            availableCategories,
            (value) => setState(() => selectedCategory = value!),
          ),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Training Day',
            selectedDay,
            availableDays,
            (value) => setState(() => selectedDay = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Exercises',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: _startExerciseSelectionFlow,
                icon: Icon(Icons.add, color: selectedColor),
                label: Text(
                  exercises.isEmpty ? 'Add Exercises' : 'Modify Exercises',
                  style: GoogleFonts.poppins(
                    color: selectedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          if (exercises.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[800]!, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.fitness_center, color: Colors.grey[600], size: 48),
                  SizedBox(height: 12),
                  Text(
                    'No exercises added yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select muscle groups and exercises for this program template',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...exercises.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> exercise = entry.value;
              return _buildExerciseCard(exercise, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int index) {
    final exerciseColor = selectedColor;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exerciseColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: exerciseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: exerciseColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] ?? 'Exercise',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${exercise['sets'] ?? 3} sets × ${exercise['reps'] ?? 10} reps',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    if (exercise['muscle']?.isNotEmpty == true)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: exerciseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise['muscle'],
                          style: GoogleFonts.poppins(
                            color: exerciseColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: Icon(Icons.delete, color: Colors.red[400]),
              ),
            ],
          ),
          if (exercise['weight']?.isNotEmpty == true) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: exerciseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Target: ${exercise['weight']}',
                style: GoogleFonts.poppins(
                  color: exerciseColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          // Tags Selection
          Text(
            'Tags',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedTags.remove(tag);
                    } else {
                      selectedTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withOpacity(0.2)
                        : Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? selectedColor : Colors.grey[700]!, // Added border for unselected tags
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? selectedColor : Colors.grey[300], // Improved contrast for unselected tags
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          
          // Color Selection
          Text(
            'Color Theme',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((color) {
              final isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey[600]!, // Added subtle border for unselected colors
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          
          _buildInputField(
            'Description (Optional)',
            descriptionController,
            'Add a description for this program template',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Duration *',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        
        // Quick workout duration options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDurationChip('30 min', '30 minutes'),
            _buildDurationChip('45 min', '45 minutes'),
            _buildDurationChip('60 min', '60 minutes'),
            _buildDurationChip('75 min', '75 minutes'),
            _buildDurationChip('90 min', '90 minutes'),
            _buildDurationChip('Custom', 'custom'),
          ],
        ),
        SizedBox(height: 12),
        
        // Duration input field
        TextField(
          controller: durationController,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g., 45 minutes per session',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: selectedColor.withOpacity(0.5), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: Icon(
              Icons.schedule,
              color: selectedColor,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(String label, String value) {
    final isSelected = durationController.text.contains(value) || 
                      (value == 'custom' && !['30 minutes', '45 minutes', '60 minutes', '75 minutes', '90 minutes'].any((w) => durationController.text.contains(w)));
    
    return GestureDetector(
      onTap: () {
        if (value == 'custom') {
          durationController.clear();
        } else {
          durationController.text = value;
        }
        setState(() {});
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedColor : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            filled: true,
            fillColor: Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder( // Added focused border with selectedColor
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: selectedColor.withOpacity(0.5), width: 1),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!.withOpacity(0.3), width: 1), // Added subtle border
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF2A2A2A),
              style: GoogleFonts.poppins(color: Colors.white),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]), // Added dropdown icon
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _createProgram,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // Removed elevation for cleaner look
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Program',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  // Start the exercise selection flow
  Future<void> _startExerciseSelectionFlow() async {
    // For now, just add a sample exercise
    // TODO: Implement proper exercise selection
    setState(() {
      exercises.add({
        'name': 'Sample Exercise',
        'sets': 3,
        'reps': 10,
        'muscle': 'Chest',
        'weight': '50kg',
      });
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample exercise added. Full exercise selection coming soon!'),
        backgroundColor: selectedColor,
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
  }

  Future<void> _createProgram() async {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter a program name');
      return;
    }
    if (durationController.text.trim().isEmpty) {
      _showError('Please enter a duration');
      return;
    }
    if (exercises.isEmpty) {
      _showError('Please add at least one exercise');
      return;
    }

    setState(() => isLoading = true);
    try {
      // Create program data
      final programData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'duration': durationController.text.trim(),
        'goal': selectedGoal,
        'difficulty': selectedDifficulty,
        'category': selectedCategory,
        'scheduled_days': [selectedDay],
        'color': selectedColor.value.toString(),
        'tags': selectedTags.join(','),
        'exercises': exercises,
      };

      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Program template created successfully!'),
          backgroundColor: Color(0xFF4ECDC4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Error creating program: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
}
