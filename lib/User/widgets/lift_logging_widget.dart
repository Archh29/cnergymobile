import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/progress_analytics_service.dart';

class LiftLoggingWidget extends StatefulWidget {
  final VoidCallback? onLiftLogged;
  
  const LiftLoggingWidget({
    Key? key,
    this.onLiftLogged,
  }) : super(key: key);

  @override
  _LiftLoggingWidgetState createState() => _LiftLoggingWidgetState();
}

class _LiftLoggingWidgetState extends State<LiftLoggingWidget> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseController = TextEditingController();
  final _muscleGroupController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _notesController = TextEditingController();
  final _programController = TextEditingController();

  bool _isLoading = false;
  String _selectedMuscleGroup = '';

  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Shoulders',
    'Arms',
    'Legs',
    'Core',
    'Glutes',
    'Calves',
  ];

  @override
  void dispose() {
    _exerciseController.dispose();
    _muscleGroupController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _notesController.dispose();
    _programController.dispose();
    super.dispose();
  }

  Future<void> _logLift() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ProgressAnalyticsService.saveLift(
        exerciseName: _exerciseController.text.trim(),
        muscleGroup: _selectedMuscleGroup.isNotEmpty ? _selectedMuscleGroup : _muscleGroupController.text.trim(),
        weight: double.parse(_weightController.text),
        reps: int.parse(_repsController.text),
        sets: int.parse(_setsController.text),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        programName: _programController.text.trim().isNotEmpty ? _programController.text.trim() : null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lift logged successfully!'),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
        
        // Clear form
        _exerciseController.clear();
        _muscleGroupController.clear();
        _weightController.clear();
        _repsController.clear();
        _setsController.clear();
        _notesController.clear();
        _programController.clear();
        setState(() {
          _selectedMuscleGroup = '';
        });

        // Notify parent widget
        widget.onLiftLogged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log lift. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error logging lift: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging lift: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF1E1E1E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.add_circle,
                  color: const Color(0xFF4ECDC4),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Your Lift',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Exercise Name
            _buildTextField(
              controller: _exerciseController,
              label: 'Exercise Name',
              hint: 'e.g., Bench Press, Squat, Deadlift',
              icon: Icons.fitness_center,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Muscle Group Dropdown
            _buildMuscleGroupDropdown(),
            const SizedBox(height: 16),

            // Weight, Reps, Sets Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    hint: '0.0',
                    icon: Icons.scale,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _repsController,
                    label: 'Reps',
                    hint: '0',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _setsController,
                    label: 'Sets',
                    hint: '0',
                    icon: Icons.layers,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Program Name (Optional)
            _buildTextField(
              controller: _programController,
              label: 'Program Name (Optional)',
              hint: 'e.g., Push/Pull/Legs, 5/3/1',
              icon: Icons.list_alt,
            ),
            const SizedBox(height: 16),

            // Notes (Optional)
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'How did it feel? Any observations?',
              icon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Log Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _logLift,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Log Lift',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF4ECDC4),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF4ECDC4),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Muscle Group',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedMuscleGroup.isEmpty ? null : _selectedMuscleGroup,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.category,
                color: const Color(0xFF4ECDC4),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            hint: Text(
              'Select muscle group',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            items: _muscleGroups.map((String group) {
              return DropdownMenuItem<String>(
                value: group,
                child: Text(
                  group,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedMuscleGroup = newValue ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a muscle group';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}





