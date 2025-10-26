import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './services/user_training_preferences_service.dart';
import './services/auth_service.dart';

class TrainingFocusSettingsPage extends StatefulWidget {
  const TrainingFocusSettingsPage({Key? key}) : super(key: key);

  @override
  State<TrainingFocusSettingsPage> createState() => _TrainingFocusSettingsPageState();
}

class _TrainingFocusSettingsPageState extends State<TrainingFocusSettingsPage> {
  bool _loading = true;
  String _selectedFocus = 'full_body';
  List<int> _selectedCustomGroups = [];
  List<Map<String, dynamic>> _availableMuscleGroups = [];
  List<Map<String, dynamic>> _dismissedWarnings = [];
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _loading = true; });
    try {
      // Use AuthService to match the same user ID as WeeklyMuscleAnalyticsService
      _userId = await AuthService.getCurrentUserId();

      print('🔍 🔍 🔍 TRAINING FOCUS SETTINGS - USER ID FROM AUTHSERVICE: $_userId 🔍 🔍 🔍');

      if (_userId == null) {
        throw Exception('User not logged in');
      }

      // Load preferences
      final userPrefs = await UserTrainingPreferencesService.getPreferences(_userId!);
      _selectedFocus = userPrefs['training_focus'] ?? 'full_body';
      _selectedCustomGroups = userPrefs['custom_muscle_groups'] != null
          ? List<int>.from(userPrefs['custom_muscle_groups'])
          : [];

      // Load muscle groups for custom selection
      _availableMuscleGroups = await UserTrainingPreferencesService.getMuscleGroups();

      // Load dismissed warnings
      _dismissedWarnings = await UserTrainingPreferencesService.getDismissedWarnings(_userId!);

      if (!mounted) return;
      setState(() { _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_userId == null) return;

    print('🔍 SAVING PREFERENCES:');
    print('   User ID: $_userId');
    print('   Training Focus: $_selectedFocus');
    print('   Selected Custom Groups: $_selectedCustomGroups');
    print('   Will send custom groups: ${_selectedFocus == 'custom' ? _selectedCustomGroups : null}');

    try {
      final success = await UserTrainingPreferencesService.savePreferences(
        userId: _userId!,
        trainingFocus: _selectedFocus,
        customMuscleGroups: _selectedFocus == 'custom' ? _selectedCustomGroups : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Training focus updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate settings changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  Future<void> _resetDismissals() async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Reset All Warnings?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'This will show all previously dismissed muscle group warnings again.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reset', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await UserTrainingPreferencesService.resetDismissals(userId: _userId!);
        if (success) {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All warnings reset')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text('Training Focus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _savePreferences,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildFocusOptions(),
                const SizedBox(height: 24),
                if (_selectedFocus == 'custom') ...[
                  _buildCustomMuscleSelection(),
                  const SizedBox(height: 24),
                ],
                _buildDismissedWarningsSection(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF00D4AA).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Color(0xFF00D4AA), size: 24),
              SizedBox(width: 12),
              Text(
                'Customize Your Tracking',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Choose which muscle groups you want to track in your weekly analytics. The system will only analyze and warn you about the selected groups.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training Focus',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        _buildFocusOption(
          'full_body',
          'Full Body',
          'Track all muscle groups for balanced development',
          Icons.accessibility_new,
          Color(0xFF00D4AA),
        ),
        _buildFocusOption(
          'upper_body',
          'Upper Body Focus',
          'Track chest, back, shoulders, arms, and core',
          Icons.fitness_center,
          Color(0xFF6366F1),
        ),
        _buildFocusOption(
          'lower_body',
          'Lower Body Focus',
          'Track legs, glutes, and calves',
          Icons.directions_run,
          Color(0xFFF59E0B),
        ),
        _buildFocusOption(
          'custom',
          'Custom Selection',
          'Choose specific muscle groups to track',
          Icons.tune,
          Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildFocusOption(String value, String title, String description, IconData icon, Color color) {
    final isSelected = _selectedFocus == value;
    return GestureDetector(
      onTap: () => setState(() { _selectedFocus = value; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Color(0xFF2A2A2A),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMuscleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Muscle Groups',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableMuscleGroups.map((group) {
            final groupId = group['id'] as int;
            final groupName = group['name'] as String;
            final isSelected = _selectedCustomGroups.contains(groupId);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCustomGroups.remove(groupId);
                  } else {
                    _selectedCustomGroups.add(groupId);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Color(0xFFEC4899), Color(0xFFEC4899).withOpacity(0.8)],
                        )
                      : null,
                  color: isSelected ? null : Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Color(0xFFEC4899) : Color(0xFF2A2A2A),
                  ),
                ),
                child: Text(
                  groupName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDismissedWarningsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dismissed Warnings',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_dismissedWarnings.isNotEmpty)
              TextButton(
                onPressed: _resetDismissals,
                child: Text(
                  'Reset All',
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        if (_dismissedWarnings.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No warnings have been dismissed',
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
            ),
          )
        else
          ..._dismissedWarnings.map((warning) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF2A2A2A)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_off, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warning['muscle_group_name'],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Dismissed ${warning['dismiss_count']}x',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (warning['is_permanent'] == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Permanent',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}

