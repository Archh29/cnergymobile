import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';
import './services/routine_services.dart';
import './create_routine_page.dart';
import './start_workout_preview.dart';
import './widgets/session_status_widget.dart';

class RoutinePage extends StatefulWidget {
  @override
  _RoutinePageState createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> with SingleTickerProviderStateMixin {
  List<RoutineModel> myRoutines = [];
  List<RoutineModel> coachAssignedRoutines = [];
  List<RoutineModel> templateRoutines = [];
  List<WorkoutSession> workoutHistory = [];
  late TabController _tabController;
  bool _showFab = true;
  bool isProMember = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _membershipDetails;
  int _totalRoutines = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {
        _showFab = _tabController.index == 0 && _canCreateRoutine();
        print('🔄 Tab changed to ${_tabController.index}, show FAB: $_showFab');
      });
    });
    _loadData();
  }

  bool _canCreateRoutine() {
    if (isProMember) {
      print('🔓 Premium user - can create unlimited routines');
      return true;
    }
    bool canCreate = myRoutines.length < 1;
    print('🔒 Basic user - has ${myRoutines.length} routines, can create: $canCreate');
    return canCreate;
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await RoutineService.getCurrentUserId();
      
      // Force refresh membership status to get latest from server
      print('🔄 Force refreshing membership status...');
      await RoutineService.forceRefreshMembershipStatus();
      
      // Load data from separate endpoints for each tab
      print('🔄 Loading data from separate endpoints...');
      
      // Load user-created routines (Tab 1)
      final userRoutinesResponse = await RoutineService.fetchUserCreatedRoutines();
      
      // Load coach-created routines (Tab 2)
      final coachRoutinesResponse = await RoutineService.fetchCoachCreatedRoutines();
      
      // Load workout history
      final history = await RoutineService.getWorkoutHistory();
      
      if (!mounted) return;
      
      setState(() {
        // Use separate endpoints for each tab
        myRoutines = userRoutinesResponse.myRoutines;
        coachAssignedRoutines = coachRoutinesResponse.coachAssigned;
        templateRoutines = coachRoutinesResponse.templateRoutines;
        workoutHistory = history;
        isProMember = userRoutinesResponse.isPremium; // Use user routines for membership status
        _totalRoutines = userRoutinesResponse.totalRoutines + coachRoutinesResponse.totalRoutines;
        _membershipDetails = userRoutinesResponse.membershipStatus;
        _isLoading = false;
        _showFab = _tabController.index == 0 && _canCreateRoutine();
        
        print('📊 Routine data loaded from separate endpoints:');
        print('   - My routines (Tab 1): ${myRoutines.length}');
        print('   - Coach assigned (Tab 2): ${coachAssignedRoutines.length}');
        print('   - Template routines (Tab 3): ${templateRoutines.length}');
        print('   - Is premium: $isProMember');
        print('   - Can create routine: ${_canCreateRoutine()}');
        print('   - Show FAB: $_showFab');
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().contains('User not logged in')
            ? 'Please log in to view your routines'
            : 'Failed to load routines. Please try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _loadData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleRoutineAction(String action, RoutineModel routine) async {
    switch (action) {
      case 'edit':
        _showEditRoutineModal(routine);
        break;
      case 'duplicate':
        await _duplicateRoutine(routine);
        break;
      case 'share':
        _showShareOptions(routine);
        break;
      case 'delete':
        _showDeleteConfirmation(routine);
        break;
    }
  }

  void _showEditRoutineModal(RoutineModel routine) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality coming soon'),
        backgroundColor: Color(0xFF4ECDC4),
      ),
    );
  }

  Future<void> _duplicateRoutine(RoutineModel routine) async {
    if (!isProMember && !_canCreateRoutine()) {
      _showBasicUserLimitDialog();
      return;
    }

    try {
      final duplicatedRoutine = RoutineModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${routine.name} (Copy)',
        exercises: routine.exercises,
        duration: '', // Duration removed
        difficulty: routine.difficulty,
        createdBy: 'user',
        exerciseList: routine.exerciseList,
        color: routine.color,
        lastPerformed: 'Never',
        tags: [], // Tags removed
        goal: '', // Goal removed
        completionRate: 0,
        totalSessions: 0,
        notes: routine.notes,
        scheduledDays: List.from(routine.scheduledDays),
        version: 1.0,
      );

      final result = await RoutineService.createRoutine(duplicatedRoutine);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine duplicated successfully'),
            backgroundColor: Color(0xFF96CEB4),
          ),
        );
        _loadData();
      } else {
        if (result['membership_required'] == true) {
          _showBasicUserLimitDialog();
        } else {
          throw Exception(result['error'] ?? 'Failed to duplicate routine');
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error duplicating routine: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showShareOptions(RoutineModel routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF0F0F0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Routine',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.copy, color: Color(0xFF4ECDC4)),
              title: Text(
                'Copy to Clipboard',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: routine.toJson().toString()));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Routine copied to clipboard'),
                    backgroundColor: Color(0xFF4ECDC4),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Color(0xFFFF6B35)),
              title: Text(
                'Share via Apps',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Native sharing coming soon'),
                    backgroundColor: Color(0xFFFF6B35),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(RoutineModel routine) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Text(
                'Delete Routine',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${routine.name}"?\n\nThis action cannot be undone and will permanently remove all associated data.',
            style: GoogleFonts.poppins(
              color: Colors.grey[300],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRoutine(routine);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoutine(RoutineModel routine) async {
    try {
      final success = await RoutineService.deleteRoutine(routine.id);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Routine deleted successfully'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
        _loadData();
      } else {
        throw Exception('Failed to delete routine');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting routine: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBasicUserLimitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 12),
              Text(
                'Routine Limit Reached',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Basic users can only have 1 routine at a time.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'To create a new routine, you need to:',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Delete your existing routine, or\n• Upgrade to Premium for unlimited routines',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUpgradeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upgrade to Premium',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
              SizedBox(width: 12),
              Text(
                'Upgrade to Premium',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock Premium Features:',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              _buildFeatureItem('✓ Unlimited Routines'),
              _buildFeatureItem('✓ Coach-Assigned Programs'),
              _buildFeatureItem('✓ Advanced Analytics'),
              _buildFeatureItem('✓ Priority Support'),
              _buildFeatureItem('✓ Export Workout Data'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Color(0xFFFFD700), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Starting at ₱500/month',
                        style: GoogleFonts.poppins(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Redirecting to subscription page...'),
                    backgroundColor: Color(0xFFFFD700),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        feature,
        style: GoogleFonts.poppins(
          color: Colors.grey[300],
          fontSize: 14,
        ),
      ),
    );
  }

  void _navigateToCreateRoutine() async {
    if (!isProMember && !_canCreateRoutine()) {
      _showBasicUserLimitDialog();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoutinePage(
          isProMember: isProMember,
          currentRoutineCount: myRoutines.length,
        ),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  void _showRoutineCalendar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Routine Calendar',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Calendar feature coming soon! This will show your scheduled routines and workout history.',
            style: GoogleFonts.poppins(
              color: Colors.grey[300],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString));
    } catch (e) {
      return Color(0xFF96CEB4);
    }
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(RoutineModel routine) {
    final stats = RoutineService.calculateRoutineStats(workoutHistory, routine.name);
    final routineColor = _getColorFromString(routine.color);
    
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: routineColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${routine.completionRate}%',
                style: GoogleFonts.poppins(
                  color: routineColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: routine.completionRate / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(routineColor),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 12),
          // Last Performance
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.grey[500], size: 16),
              SizedBox(width: 8),
              Text(
                'Last performed: ${stats['lastPerformed']}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error Loading Routines',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong. Please try again.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your routines...',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0F0F),
                    Color(0xFF0F0F0F),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Programs',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                    ),
                    child: GestureDetector(
                      onTap: _showRoutineCalendar,
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFF4ECDC4),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Modern Tab Bar
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: "My Routines"),
                  Tab(text: "Coach Assigned"),
                  Tab(text: "Templates"),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyRoutinesTab(),
                  _buildCoachRoutinesTab(),
                  _buildTemplatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateRoutine,
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              elevation: 8,
              icon: Icon(Icons.add_rounded),
              label: Text(
                "Create Routine",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildMyRoutinesTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    List<RoutineModel> displayRoutines = myRoutines;
    
    if (!isProMember && displayRoutines.length > 1) {
      displayRoutines = displayRoutines.take(1).toList();
    }

    return displayRoutines.isEmpty
        ? Center(
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fitness_center_rounded, color: Color(0xFF4ECDC4), size: 48),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No Routines Yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _canCreateRoutine()
                        ? 'Create your first routine to get started with your fitness journey!'
                        : 'You have reached the routine limit.\n\nDelete your existing routine to create a new one.',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  if (_canCreateRoutine())
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateRoutine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B35),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.add_rounded, color: Colors.white),
                      label: Text(
                        'Create Routine',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _showBasicUserLimitDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Upgrade to Premium',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadData,
            color: Color(0xFF4ECDC4),
            backgroundColor: Color(0xFF1A1A1A),
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: displayRoutines.length,
              itemBuilder: (context, index) {
                final routine = displayRoutines[index];
                return _buildRoutineCard(routine, showActions: true);
              },
            ),
          );
  }

  Widget _buildCoachRoutinesTab() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();

    final list = coachAssignedRoutines;
    if (list.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, color: Color(0xFF4ECDC4), size: 48),
              ),
              SizedBox(height: 20),
              Text(
                'Coach Routines',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'No coach-assigned routines yet. Your coach will assign personalized routines here.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color(0xFF4ECDC4),
      backgroundColor: Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final routine = list[index];
          return _buildRoutineCard(routine, showActions: false);
        },
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_isLoading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();

    final list = templateRoutines;
    if (list.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF96CEB4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.library_books_rounded, color: Color(0xFF96CEB4), size: 48),
              ),
              SizedBox(height: 20),
              Text(
                'Routine Templates',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'No templates yet. Templates created by admins will appear here.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color(0xFF96CEB4),
      backgroundColor: Color(0xFF1A1A1A),
      child: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final routine = list[index];
          return _buildRoutineCard(routine, showActions: false);
        },
      ),
    );
  }

  Widget _buildRoutineCard(RoutineModel routine, {bool showActions = true}) {
    final routineColor = _getColorFromString(routine.color);
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [routineColor, routineColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: routineColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showActions)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                    color: Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) => _handleRoutineAction(value, routine),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, color: Color(0xFF4ECDC4), size: 20),
                            SizedBox(width: 12),
                            Text('Edit', style: GoogleFonts.poppins(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, color: Color(0xFF96CEB4), size: 20),
                            SizedBox(width: 12),
                            Text('Duplicate', style: GoogleFonts.poppins(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_rounded, color: Color(0xFFFF6B35), size: 20),
                            SizedBox(width: 12),
                            Text('Share', style: GoogleFonts.poppins(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildInfoChip(Icons.format_list_numbered_rounded, "${routine.exercises} exercises", routineColor),
                _buildInfoChip(Icons.trending_up_rounded, routine.difficulty, routineColor),
              ],
            ),
            SizedBox(height: 20),
            Text(
              routine.exerciseList.isEmpty ? "No exercises listed" : routine.exerciseList,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 24),
            // Show session status for coach-created routines
            if (routine.createdBy.isNotEmpty && routine.createdBy != 'null' && routine.createdBy != '0') ...[
              Builder(
                builder: (context) {
                  final coachId = int.tryParse(routine.createdBy);
                  if (coachId != null) {
                    return SessionStatusWidget(
                      coachId: coachId,
                      onSessionExpired: () {
                        // Optionally refresh the page or show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Session expired. Please manage your subscription.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
              SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [routineColor, routineColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: routineColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StartWorkoutPreviewPage(routine: routine),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: 24),
                label: Text(
                  "Start Workout",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
