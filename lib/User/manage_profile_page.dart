import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'services/profile_service.dart';

class ManageProfilePage extends StatefulWidget {
  @override
  _ManageProfilePageState createState() => _ManageProfilePageState();
}

class _ManageProfilePageState extends State<ManageProfilePage> with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  
  final List<Map<String, dynamic>> profileSettings = [
    {
      'title': 'Edit Profile',
      'icon': Icons.edit,
      'color': Color(0xFF4ECDC4),
      'route': 'EditProfilePage',
    },
    {
      'title': 'Change Password',
      'icon': Icons.lock_outline,
      'color': Color(0xFF96CEB4),
      'route': 'ChangePasswordPage',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Manage Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.white, size: 20),
            ),
            onPressed: () => _showLogoutDialog(),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Profile Settings Section
                _buildSectionTitle('Profile Settings'),
                SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: profileSettings.length,
                  itemBuilder: (context, index) {
                    final setting = profileSettings[index];
                    return _buildProfileOption(
                      title: setting['title'],
                      icon: setting['icon'],
                      iconColor: setting['color'],
                      onTap: () => _navigateWithTransition(
                        context, 
                        SettingsDetailPage(title: setting['title'], color: setting['color']),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 24),
                
                
                SizedBox(height: 40),
                
                // App Version
                Center(
                  child: Text(
                    'App Version 2.1.0',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title, {Color color = const Color(0xFF4ECDC4)}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required String title,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ?? Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Color(0xFFFF6B35),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Handle logout logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged out successfully',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Color(0xFF4ECDC4),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _navigateWithTransition(BuildContext context, Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class SettingsDetailPage extends StatefulWidget {
  final String title;
  final Color color;

  SettingsDetailPage({required this.title, required this.color});

  @override
  _SettingsDetailPageState createState() => _SettingsDetailPageState();
}

class _SettingsDetailPageState extends State<SettingsDetailPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Controllers for form fields
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _mnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bdayController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _workoutDaysController = TextEditingController();
  final TextEditingController _equipmentController = TextEditingController();
  
  // Password change controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Profile data
  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _genders = [];
  bool _isLoading = true;
  String? _error;
  
  // Selected values
  String? _selectedGenderId;
  String? _selectedFitnessLevel;
  String? _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fnameController.dispose();
    _mnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _bdayController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _bodyFatController.dispose();
    _workoutDaysController.dispose();
    _equipmentController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load profile data and genders in parallel
      final results = await Future.wait([
        ProfileService.getProfile(),
        ProfileService.getGenders(),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      final genders = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _profileData = profileData;
        _genders = genders;
        _isLoading = false;
      });

      // Populate form fields
      _populateFormFields();
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _populateFormFields() {
    if (_profileData != null) {
      _fnameController.text = _profileData!['fname'] ?? '';
      _mnameController.text = _profileData!['mname'] ?? '';
      _lnameController.text = _profileData!['lname'] ?? '';
      _emailController.text = _profileData!['email'] ?? '';
      _bdayController.text = _profileData!['bday'] ?? '';
      _heightController.text = _profileData!['height_cm']?.toString() ?? '';
      _weightController.text = _profileData!['weight_kg']?.toString() ?? '';
      _targetWeightController.text = _profileData!['target_weight']?.toString() ?? '';
      _bodyFatController.text = _profileData!['body_fat']?.toString() ?? '';
      _workoutDaysController.text = _profileData!['workout_days_per_week']?.toString() ?? '';
      _equipmentController.text = _profileData!['equipment_access'] ?? '';
      
      _selectedGenderId = _profileData!['gender_id']?.toString();
      _selectedFitnessLevel = _profileData!['fitness_level'];
      _selectedActivityLevel = _profileData!['activity_level'];
    }
  }

  Future<void> _saveChanges() async {
    try {
      if (widget.title == 'Change Password') {
        // Handle password change
        if (_currentPasswordController.text.isEmpty || 
            _newPasswordController.text.isEmpty || 
            _confirmPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All password fields are required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_newPasswordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New password and confirm password do not match'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await ProfileService.changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle profile update
        if (_fnameController.text.isEmpty || 
            _lnameController.text.isEmpty || 
            _emailController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('First name, last name, and email are required'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await ProfileService.updateProfile(
          fname: _fnameController.text,
          mname: _mnameController.text,
          lname: _lnameController.text,
          email: _emailController.text,
          bday: _bdayController.text,
          genderId: _selectedGenderId ?? '',
          fitnessLevel: _selectedFitnessLevel ?? '',
          heightCm: _heightController.text,
          weightKg: _weightController.text,
          targetWeight: _targetWeightController.text,
          bodyFat: _bodyFatController.text,
          activityLevel: _selectedActivityLevel ?? '',
          workoutDaysPerWeek: _workoutDaysController.text,
          equipmentAccess: _equipmentController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color.withOpacity(0.8), widget.color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.title == 'Edit Profile' ? Icons.edit :
                        widget.title == 'Change Password' ? Icons.lock_outline :
                        widget.title == 'Manage Notifications' ? Icons.notifications_outlined :
                        Icons.privacy_tip_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _getSubtitle(),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

// Content based on page type
if (widget.title == 'Edit Profile') 
  _buildEditProfileContent()
else if (widget.title == 'Change Password')
  _buildChangePasswordContent(),

SizedBox(height: 40),

              
              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.color, widget.color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (widget.title) {
      case 'Edit Profile':
        return 'Update your personal information';
      case 'Change Password':
        return 'Keep your account secure';
      case 'Manage Notifications':
        return 'Control what alerts you receive';
      case 'Privacy Settings':
        return 'Manage your data and visibility';
      default:
        return '';
    }
  }

  Widget _buildEditProfileContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Error loading profile: $_error',
              style: GoogleFonts.poppins(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('First Name', _fnameController, Icons.person_outline),
        SizedBox(height: 16),
        _buildInputField('Middle Name', _mnameController, Icons.person_outline),
        SizedBox(height: 16),
        _buildInputField('Last Name', _lnameController, Icons.person_outline),
        SizedBox(height: 16),
        _buildInputField('Email Address', _emailController, Icons.email_outlined),
        SizedBox(height: 16),
        _buildInputField('Birthday (YYYY-MM-DD)', _bdayController, Icons.cake_outlined),
        SizedBox(height: 16),
        _buildDropdownField('Gender', _selectedGenderId, _genders.map((g) => {'value': g['id'].toString(), 'label': g['type'].toString()}).toList(), (value) {
          setState(() => _selectedGenderId = value);
        }),
        SizedBox(height: 16),
        _buildInputField('Height (cm)', _heightController, Icons.height),
        SizedBox(height: 16),
        _buildInputField('Weight (kg)', _weightController, Icons.monitor_weight_outlined),
        SizedBox(height: 16),
        _buildInputField('Target Weight (kg)', _targetWeightController, Icons.flag_outlined),
        SizedBox(height: 16),
        _buildInputField('Body Fat %', _bodyFatController, Icons.analytics_outlined),
        SizedBox(height: 16),
        _buildDropdownField('Fitness Level', _selectedFitnessLevel, [
          {'value': 'Beginner', 'label': 'Beginner'},
          {'value': 'Intermediate', 'label': 'Intermediate'},
          {'value': 'Advanced', 'label': 'Advanced'},
        ], (value) {
          setState(() => _selectedFitnessLevel = value);
        }),
        SizedBox(height: 16),
        _buildDropdownField('Activity Level', _selectedActivityLevel, [
          {'value': 'Sedentary', 'label': 'Sedentary'},
          {'value': 'Light', 'label': 'Light'},
          {'value': 'Moderate', 'label': 'Moderate'},
          {'value': 'Active', 'label': 'Active'},
        ], (value) {
          setState(() => _selectedActivityLevel = value);
        }),
        SizedBox(height: 16),
        _buildInputField('Workout Days per Week', _workoutDaysController, Icons.calendar_today),
        SizedBox(height: 16),
        _buildInputField('Equipment Access', _equipmentController, Icons.fitness_center, maxLines: 3),
      ],
    );
  }

  Widget _buildChangePasswordContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField('Current Password', _currentPasswordController, Icons.lock_outline, isPassword: true),
        SizedBox(height: 16),
        _buildInputField('New Password', _newPasswordController, Icons.lock_outline, isPassword: true),
        SizedBox(height: 16),
        _buildInputField('Confirm New Password', _confirmPasswordController, Icons.lock_outline, isPassword: true),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Requirements:',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              _buildRequirement('At least 8 characters', _newPasswordController.text.length >= 8),
              _buildRequirement('At least one uppercase letter', _newPasswordController.text.contains(RegExp(r'[A-Z]'))),
              _buildRequirement('At least one number', _newPasswordController.text.contains(RegExp(r'[0-9]'))),
              _buildRequirement('At least one special character', _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? value, List<Map<String, String>> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2A2A2A)),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            dropdownColor: Color(0xFF1A1A1A),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Select $label',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option['value'],
                child: Text(option['label']!),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2A2A2A)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            maxLines: maxLines,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: widget.color),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Color(0xFF4ECDC4) : Colors.grey[600],
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: isMet ? Colors.white : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}