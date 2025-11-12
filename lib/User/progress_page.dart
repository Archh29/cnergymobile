import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './services/enhanced_progress_service.dart';
import './services/progress_analytics_service.dart';
import './models/goal_model.dart';
import './models/workout_session_model.dart';
import './models/attendance_model.dart';
import './models/progress_model.dart';
import './workout_heatmap_page.dart';
import './measurements_page.dart';
import './personal_records_page.dart';
import './goals_page.dart';
import './models/personal_record_model.dart';
import './models/muscle_analytics_model.dart';
import './services/muscle_analytics_service.dart';
import './services/profile_service.dart';
import './services/gym_utils_service.dart';
import './services/body_measurements_service.dart';
import './services/auth_service.dart';
import './services/subscription_service.dart';
import './manage_subscriptions_page.dart';
import './muscle_analytics_page.dart';
import './weekly_muscle_analytics_page.dart';
import './widgets/progress_tracker_widget.dart';
import './widgets/progressive_overload_tracker.dart';
import './body_measurements_page.dart';

class ComprehensiveDashboard extends StatefulWidget {
  @override
  _ComprehensiveDashboardState createState() => _ComprehensiveDashboardState();
}

class _ComprehensiveDashboardState extends State<ComprehensiveDashboard>
    with TickerProviderStateMixin {
    
  Map<String, dynamic> stats = {};
  List<GoalModel> goals = [];
  List<WorkoutSessionModel> recentSessions = [];
  List<WorkoutSessionModel> allSessions = [];
  List<AttendanceModel> recentAttendance = [];
  List<AttendanceModel> allAttendance = [];
  List<ProgressModel> progressData = [];
  Map<DateTime, int> workoutHeatmapData = {};
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, double> latestMeasurements = {};
  bool isLoading = true;
  List<PersonalRecordModel> personalRecords = [];
  MuscleAnalyticsData? muscleAnalytics;
  double? userHeight;
  double? userWeight;
  List<ProgressModel> bodyMeasurements = [];
  List<Map<String, dynamic>> _bodyMeasurementsData = [];
  String _selectedMeasurementPeriod = 'all';
  bool _hasAnnualMembership = false;
    
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
    _loadBodyMeasurementsData();
    _checkAnnualMembership();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh measurements when page becomes visible
    _refreshMeasurements();
  }

  Future<void> _refreshMeasurements() async {
    try {
      final refreshedMeasurements = await _getLatestMeasurementsFromProgress();
      if (mounted && refreshedMeasurements.isNotEmpty) {
        setState(() {
          latestMeasurements = refreshedMeasurements;
        });
      }
    } catch (e) {
      print('Error refreshing measurements: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
        
    try {
      final futures = await Future.wait([
        EnhancedProgressService.getComprehensiveStats(),
        EnhancedProgressService.fetchUserGoals(),
        EnhancedProgressService.fetchWorkoutSessions(),
        EnhancedProgressService.fetchAttendanceHistory(),
        EnhancedProgressService.fetchUserProgress(),
        EnhancedProgressService.fetchPersonalRecords(),
        MuscleAnalyticsService.getWeeklyStats(),
        _loadUserHeight(),
        _loadBodyMeasurements(),
      ]);

      if (mounted) {
        setState(() {
          stats = futures[0] as Map<String, dynamic>;
          goals = (futures[1] as List<GoalModel>).take(3).toList();
          allSessions = (futures[2] as List<WorkoutSessionModel>);
          recentSessions = allSessions.take(5).toList();
          recentAttendance = (futures[3] as List<AttendanceModel>).take(7).toList();
          allAttendance = futures[3] as List<AttendanceModel>; // Store all attendance for heatmap
          progressData = futures[4] as List<ProgressModel>;
          
          // Generate heatmap from all workout sessions and attendance
          workoutHeatmapData = _generateWorkoutHeatmapFromSessions(allSessions);
          
          
          personalRecords = (futures[5] as List<PersonalRecordModel>).take(3).toList();
          muscleAnalytics = futures[6] as MuscleAnalyticsData;
          bodyMeasurements = futures[8] as List<ProgressModel>;
          
          isLoading = false;
        });
      }
      
      // Get latest measurements from body measurements data AFTER setState
      final measurements = await _getLatestMeasurementsFromProgress();
      print('🔍 Latest measurements fetched: weight=${measurements['weight']}, bmi=${measurements['bmi']}');
      
      if (mounted) {
        setState(() {
          latestMeasurements = measurements;
        });
        
        _animationController.forward();
      }
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _getProgressiveOverloadStats() async {
    try {
      // Get user's programs
      final programs = await EnhancedProgressService.fetchUserRoutines();
      
      // Get actual workout data from progress tracker (where real workout sessions are saved)
      final progressData = await ProgressAnalyticsService.getAllProgress();
      
      // Count unique workout sessions by grouping progress data by date + hour
      Set<String> uniqueWorkoutSessions = {};
      for (final exerciseData in progressData.values) {
        for (final record in exerciseData) {
          final sessionKey = '${record.date.year}-${record.date.month}-${record.date.day}-${record.date.hour}';
          uniqueWorkoutSessions.add(sessionKey);
        }
      }
      
      final completedWorkouts = uniqueWorkoutSessions.length;
      
      // Progressive Overload Stats loaded
      // Programs: ${programs.length}, Sessions: $completedWorkouts
      
      return {
        'programs': programs.length,
        'workouts': completedWorkouts,
      };
    } catch (e) {
      print('Error getting progressive overload stats: $e');
      return {
        'programs': 0,
        'workouts': 0,
      };
    }
  }

  // Helper method to get actual workout count for Quick Stats
  Future<int> _getActualWorkoutCount() async {
    try {
      // Get actual workout data from progress tracker (where real workout sessions are saved)
      final progressData = await ProgressAnalyticsService.getAllProgress();
      
      // Count unique workout sessions by grouping progress data by date + hour
      Set<String> uniqueWorkoutSessions = {};
      for (final exerciseData in progressData.values) {
        for (final record in exerciseData) {
          final sessionKey = '${record.date.year}-${record.date.month}-${record.date.day}-${record.date.hour}';
          uniqueWorkoutSessions.add(sessionKey);
        }
      }
      
      final completedWorkouts = uniqueWorkoutSessions.length;
      
      // Quick Stats loaded: $completedWorkouts workouts
      
      return completedWorkouts;
    } catch (e) {
      print('Error getting actual workout count: $e');
      return 0;
    }
  }

  Map<DateTime, int> _generateWorkoutHeatmapFromSessions(List<WorkoutSessionModel> sessions) {
    final Map<DateTime, int> heatmapData = {};
    
    // ABSOLUTE REQUIREMENT: Only attendance days get any shading
    for (final attendance in allAttendance) {
      final dateKey = DateTime(
        attendance.checkIn.year,
        attendance.checkIn.month,
        attendance.checkIn.day,
      );
      
      // Start with light shading for attendance
      heatmapData[dateKey] = 1; // Light shading for attendance
      
      // Check if user also completed a program on the same day
      final completedProgramOnSameDay = sessions.any((session) {
        final sessionDateKey = DateTime(
          session.sessionDate.year,
          session.sessionDate.month,
          session.sessionDate.day,
        );
        return sessionDateKey == dateKey && session.completed;
      });
      
      // If user attended AND completed program, make it darker
      if (completedProgramOnSameDay) {
        heatmapData[dateKey] = 2; // Darker shading for attendance + completed program
      }
    }
    
    // NO SHADING for days without attendance, even if programs were completed
    // This ensures attendance is the absolute requirement
    
    return heatmapData;
  }


  Future<void> _loadUserHeight() async {
    try {
      final profileData = await ProfileService.getProfile();
      if (profileData != null) {
        if (profileData['height_cm'] != null) {
          userHeight = double.tryParse(profileData['height_cm'].toString());
        }
        if (profileData['weight_kg'] != null) {
          userWeight = double.tryParse(profileData['weight_kg'].toString());
        }
      }
    } catch (e) {
      print('Error loading user profile data: $e');
    }
  }

  Future<void> _refreshUserHeight() async {
    try {
      final profileData = await ProfileService.getProfile();
      if (profileData != null && profileData['height_cm'] != null) {
        userHeight = double.tryParse(profileData['height_cm'].toString());
        // Refreshed user height
        
        // Force refresh measurements to recalculate BMI with new height
        latestMeasurements = await _getLatestMeasurementsFromProgress();
        
        setState(() {}); // Trigger rebuild to update BMI
      }
    } catch (e) {
      print('Error refreshing user height: $e');
    }
  }

  Future<List<ProgressModel>> _loadBodyMeasurements() async {
    try {
      final measurements = await BodyMeasurementsService.getBodyMeasurements();
      // Loaded ${measurements.length} body measurements
      return measurements; // Fixed return type
    } catch (e) {
      print('Error loading body measurements: $e');
      return [];
    }
  }

  Future<Map<String, double>> _getLatestMeasurementsFromProgress() async {
    print('🔍 Getting latest measurements. bodyMeasurements count: ${bodyMeasurements.length}');
    
    // First try to get the latest body measurements from the API
    if (bodyMeasurements.isNotEmpty) {
      print('🔍 Found ${bodyMeasurements.length} body measurements');
      // Sort by date to get latest and oldest
      bodyMeasurements.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
      final latest = bodyMeasurements.first;
      print('🔍 Latest measurement: weight=${latest.weight}, bmi=${latest.bmi}, date=${latest.dateRecorded}');
      
      // Find starting weight (entry with "starting" or "profile" in notes)
      ProgressModel? startingWeight;
      for (var measurement in bodyMeasurements) {
        if (measurement.notes != null && 
            (measurement.notes!.toLowerCase().contains('starting') || 
             measurement.notes!.toLowerCase().contains('profile'))) {
          startingWeight = measurement;
          break;
        }
      }
      
      // If no starting weight found, use the oldest entry
      if (startingWeight == null && bodyMeasurements.isNotEmpty) {
        startingWeight = bodyMeasurements.last; // Last in sorted list = oldest
      }
      
      // Always recalculate BMI to ensure it's up-to-date with latest height
      double? calculatedBMI = latest.bmi;
      print('🔍 Initial BMI from latest: $calculatedBMI');
      
      // Always fetch latest height and recalculate BMI to ensure accuracy
      if (latest.weight != null && latest.weight! > 0) {
        // Always fetch the latest height from profile for accurate BMI calculation
        try {
          final profileData = await ProfileService.getProfile();
          if (profileData != null && profileData['height_cm'] != null) {
            final currentHeight = double.tryParse(profileData['height_cm'].toString());
            if (currentHeight != null && currentHeight > 0) {
              calculatedBMI = GymUtilsService.calculateBMI(latest.weight!, currentHeight);
              // Update userHeight for consistency
              userHeight = currentHeight;
            }
          }
        } catch (e) {
          print('Error fetching height for BMI calculation: $e');
          // Fallback to cached userHeight
          if (userHeight != null && userHeight! > 0) {
            calculatedBMI = GymUtilsService.calculateBMI(latest.weight!, userHeight!);
          }
        }
      }
      
      final result = {
        'weight': latest.weight ?? 0.0, // Current weight
        'starting_weight': startingWeight?.weight ?? latest.weight ?? 0.0, // Starting weight
        'bmi': calculatedBMI ?? 0.0,
        'chest': latest.chestCm ?? 0.0,
        'waist': latest.waistCm ?? 0.0,
        'hips': latest.hipsCm ?? 0.0,
        'arms': 0.0, // ProgressModel doesn't have armsCm
        'thighs': 0.0, // ProgressModel doesn't have thighsCm
      };
      
      print('🔍 Returning result: weight=${result['weight']}, bmi=${result['bmi']}');
      return result;
    }
    
    // Fallback to progress data if no body measurements
    print('🔍 No body measurements found, checking progressData...');
    if (progressData.isEmpty) {
      print('🔍 Progress data is also empty, returning zeros');
      return {
        'weight': 0.0,
        'starting_weight': 0.0,
        'bmi': 0.0,
        'chest': 0.0,
        'waist': 0.0,
        'hips': 0.0,
        'arms': 0.0,
        'thighs': 0.0,
      };
    }
    
    // Sort by date and get latest
    progressData.sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
    final latest = progressData.first;
    
    // Always recalculate BMI to ensure it's up-to-date with latest height
    double? calculatedBMI = latest.bmi;
    
    // Always fetch latest height and recalculate BMI to ensure accuracy
    if (latest.weight != null && latest.weight! > 0) {
      // Always fetch the latest height from profile for accurate BMI calculation
      try {
        final profileData = await ProfileService.getProfile();
        if (profileData != null && profileData['height_cm'] != null) {
          final currentHeight = double.tryParse(profileData['height_cm'].toString());
          if (currentHeight != null && currentHeight > 0) {
            calculatedBMI = GymUtilsService.calculateBMI(latest.weight!, currentHeight);
            // Update userHeight for consistency
            userHeight = currentHeight;
          }
        }
      } catch (e) {
        print('Error fetching height for BMI calculation: $e');
        // Fallback to cached userHeight
        if (userHeight != null && userHeight! > 0) {
          calculatedBMI = GymUtilsService.calculateBMI(latest.weight!, userHeight!);
        }
      }
    }
    
    final result = {
      'weight': latest.weight ?? 0.0,
      'starting_weight': latest.weight ?? 0.0, // For progress data fallback, use same as current
      'bmi': calculatedBMI ?? 0.0,
      'chest': latest.chestCm ?? 0.0,
      'waist': latest.waistCm ?? 0.0,
      'hips': latest.hipsCm ?? 0.0,
    };
    
    return result;
  }

  // Check if user has annual membership (Plan ID 1)
  Future<void> _checkAnnualMembership() async {
    // Check annual membership
    try {
      final userId = AuthService.getCurrentUserId();
      print('🔍 Progress Page - Checking annual membership for user ID: $userId');
      
      if (userId == null) {
        print('❌ Progress Page - User ID is null, setting _hasAnnualMembership to false');
        _hasAnnualMembership = false;
        if (mounted) setState(() {});
        return;
      }

      final subscriptionData = await SubscriptionService.getCurrentSubscription(userId);
      print('🔍 Progress Page - Subscription data received: $subscriptionData');
      
      _hasAnnualMembership = false;
      
      if (subscriptionData != null) {
        // First, check if user has active_membership (Plan ID 1) - this is returned separately by the API
        // even if they have Day Pass or Monthly as their current subscription
        if (subscriptionData['active_membership'] != null) {
          final activeMembership = subscriptionData['active_membership'];
          final status = activeMembership['status']?.toString().toLowerCase() ?? '';
          if (status == 'active') {
            _hasAnnualMembership = true;
            print('✅ Progress Page - Found active membership (Plan ID 1) in active_membership field');
          }
        }
        
        // Also check the current subscription (might be Plan ID 5 - Package Plan)
        if (!_hasAnnualMembership && subscriptionData['subscription'] != null) {
          final subscription = subscriptionData['subscription'];
          final planId = subscription['plan_id'];
          
          // Convert to int for comparison (handles both string and int)
          final planIdInt = planId is int ? planId : int.tryParse(planId.toString()) ?? 0;
          
          // Check if current subscription is Plan ID 5 (Package Plan)
          if (planIdInt == 5) {
            _hasAnnualMembership = true;
            print('✅ Progress Page - Found package plan (Plan ID 5) in current subscription');
          }
        }
        
        // Also check subscription history for Plan ID 5 if not found yet
        if (!_hasAnnualMembership) {
          try {
            if (subscriptionData['subscription_history'] != null) {
              final history = subscriptionData['subscription_history'] as List?;
              if (history != null) {
                for (var sub in history) {
                  final planId = sub['plan_id'];
                  final planIdInt = planId is int ? planId : int.tryParse(planId.toString()) ?? 0;
                  final status = sub['display_status']?.toString().toLowerCase() ?? '';
                  
                  // Check if it's active and has plan ID 5
                  if (planIdInt == 5 && status == 'active') {
                    _hasAnnualMembership = true;
                    print('✅ Progress Page - Found active package plan (Plan ID 5) in subscription history');
                    break;
                  }
                }
              }
            }
          } catch (e) {
            print('⚠️ Progress Page - Error checking subscription history: $e');
          }
        }
        
        if (mounted) {
          setState(() {});
        }
        
        print('✅ Progress Page - Annual membership check result: $_hasAnnualMembership');
      } else {
        print('❌ Progress Page - No subscription data found, setting _hasAnnualMembership to false');
        _hasAnnualMembership = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ Progress Page - Error checking annual membership: $e');
      _hasAnnualMembership = false;
      if (mounted) setState(() {});
    }
  }

  // Helper method to create locked overlay for premium features
  Widget _buildLockedState(String featureName) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.lock_outline,
              color: Color(0xFF4ECDC4),
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Premium Feature',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$featureName is available for annual members only.',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageSubscriptionsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Upgrade to Annual Membership',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
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
        child: isLoading
            ? Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ))
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: Color(0xFF4ECDC4),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildModernHeader(),
                        SizedBox(height: 24),
                        _buildProgressiveOverloadSection(),
                        SizedBox(height: 24),
                        _buildWeeklyMuscleAnalyticsSection(),
                        SizedBox(height: 24),
                        _buildWorkoutHeatmapSection(),
                        SizedBox(height: 24),
                        _buildMeasurementsSection(),
                        SizedBox(height: 24),
                        _buildPersonalRecordsSection(),
                        SizedBox(height: 24),
                        _buildQuickStats(),
                        SizedBox(height: 24),
                        _buildGoalsSection(),
                        SizedBox(height: 24),
                        _buildRecentActivity(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4ECDC4),
            Color(0xFF44A08D),
            Color(0xFF2D5A5A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 0,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Icon(Icons.dashboard_rounded, color: Colors.white, size: 36),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitness Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.8,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Track your progress and stay motivated',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressiveOverloadSection() {
    if (!_hasAnnualMembership) {
      return _buildLockedState('Progress Tracking');
    }
    
    return
      GestureDetector(
        onTap: _hasAnnualMembership ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgressiveOverloadTracker(),
            ),
          );
        } : null,
        child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF3A3A3A),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4ECDC4).withOpacity(0.3), Color(0xFF4ECDC4).withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                      width: 1,
                      ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progressive Overload Tracker',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Track your strength gains across programs',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[300],
                    size: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: _getProgressiveOverloadStats(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedOverloadStatCard(
                          'Programs',
                          '${data['programs'] ?? 0}',
                          Icons.list_alt,
                          Color(0xFF4ECDC4),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildEnhancedOverloadStatCard(
                          'Workouts',
                          '${data['workouts'] ?? 0}',
                          Icons.fitness_center,
                          Color(0xFF96CEB4),
                        ),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedOverloadStatCard(
                          'Programs',
                          '0',
                          Icons.list_alt,
                          Color(0xFF4ECDC4),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildEnhancedOverloadStatCard(
                          'Workouts',
                          '0',
                          Icons.fitness_center,
                          Color(0xFF96CEB4),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
      );
  }

  Widget _buildWeeklyMuscleAnalyticsSection() {
    if (!_hasAnnualMembership) {
      return _buildLockedState('Weekly Muscle Analytics');
    }
    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeeklyMuscleAnalyticsPage(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1B1B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF3A3A3A), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E44AD).withOpacity(0.3), Color(0xFF8E44AD).withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF8E44AD).withOpacity(0.3), width: 1),
              ),
              child: Center(
                child: Icon(Icons.analytics, color: Colors.white, size: 28),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Muscle Analytics',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'See trained muscles, frequency and intensity, with auto summary',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedOverloadStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2A2A2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverloadStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutHeatmapSection() {
    if (!_hasAnnualMembership) {
      return _buildLockedState('Workout Heatmap');
    }
    
    return
      GestureDetector(
        onTap: _hasAnnualMembership ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutHeatmapPage(
                heatmapData: workoutHeatmapData,
                workoutSessions: allSessions,
                attendanceData: allAttendance,
              ),
            ),
          );
        } : null,
        child: Container(
        padding: EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.calendar_view_month_rounded, color: Color(0xFFFF6B35), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workout Heatmap',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_monthName(selectedMonth)} $selectedYear',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Month selector
                PopupMenuButton<int>(
                  icon: Icon(Icons.calendar_view_month_rounded, color: Colors.white),
                  color: Color(0xFF2A2A2A),
                  onSelected: (m) {
                    setState(() {
                      selectedMonth = m;
                    });
                  },
                  itemBuilder: (context) => List.generate(12, (i) => i + 1)
                      .map((m) => PopupMenuItem(
                            value: m,
                            child: Text(_monthName(m), style: GoogleFonts.poppins(color: Colors.white)),
                          ))
                      .toList(),
                ),
                SizedBox(width: 8),
                // Year selector
                PopupMenuButton<int>(
                  icon: Icon(Icons.calendar_today_rounded, color: Colors.white),
                  color: Color(0xFF2A2A2A),
                  onSelected: (y) {
                    setState(() {
                      selectedYear = y;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: DateTime.now().year, child: Text('${DateTime.now().year}', style: GoogleFonts.poppins(color: Colors.white))),
                    PopupMenuItem(value: DateTime.now().year - 1, child: Text('${DateTime.now().year - 1}', style: GoogleFonts.poppins(color: Colors.white))),
                    PopupMenuItem(value: DateTime.now().year - 2, child: Text('${DateTime.now().year - 2}', style: GoogleFonts.poppins(color: Colors.white))),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildMonthGrid(selectedYear, selectedMonth),
          ],
        ),
      ),
      );
  }

  Widget _buildMonthGrid(int year, int month) {
    final int days = _daysInMonth(year, month);
    final DateTime firstDay = DateTime(year, month, 1);
    final int startWeekday = firstDay.weekday; // 1=Mon..7=Sun
    final int leadingBlanks = (startWeekday - 1);
    final totalCells = leadingBlanks + days;
    final int rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 12),
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: rows * 7,
          itemBuilder: (context, index) {
            final int dayNumber = index - leadingBlanks + 1;
            if (dayNumber < 1 || dayNumber > days) {
              return Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }
            final date = DateTime(year, month, dayNumber);
            final dateKey = DateTime(date.year, date.month, date.day);
            final int intensity = workoutHeatmapData[dateKey] ?? 0;
            return Container(
              height: 20,
              decoration: BoxDecoration(
                color: _getHeatmapColor(intensity),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Less',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            Row(
              children: List.generate(5, (index) => Container(
                margin: EdgeInsets.only(left: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getHeatmapColor(index),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
            Text(
              'More',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _daysInMonth(int year, int month) {
    final beginningNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final lastDayOfMonth = beginningNextMonth.subtract(Duration(days: 1));
    return lastDayOfMonth.day;
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return Color(0xFF2A2A2A);
      case 1:
        return Color(0xFF4ECDC4).withOpacity(0.3);
      case 2:
        return Color(0xFF4ECDC4).withOpacity(0.6);
      case 3:
        return Color(0xFF4ECDC4).withOpacity(0.8);
      case 4:
        return Color(0xFF4ECDC4);
      default:
        return Color(0xFF2A2A2A);
    }
  }


  Widget _buildMeasurementsSection() {
    if (!_hasAnnualMembership) {
      return _buildLockedState('Body Weight Tracker');
    }
    
    return
      GestureDetector(
        onTap: _hasAnnualMembership ? () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
              builder: (context) => MeasurementsPage(
                currentMeasurements: latestMeasurements,
                progressData: progressData,
                ),
              ),
            );
          
          // If measurements were updated, refresh the data
          if (result == true) {
            await _loadDashboardData();
          }
        } : null,
        child: Container(
        padding: EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF45B7D1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.monitor_weight_rounded, color: Color(0xFF45B7D1), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Weight Tracker',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your weight journey & stay motivated',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 20),
             // Weight & BMI Stats Section with Add Button
             _buildBodyWeightTrackerSection(),
             SizedBox(height: 20),
             // Body Measurements Tracking Section
             _buildBodyMeasurementsSection(),
          ],
        ),
      ),
      );
  }

  Widget _buildPersonalRecordsSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalRecordsPage(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.emoji_events_rounded, color: Color(0xFFFF6B35), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Records',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your PRs',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
              ],
            ),
            SizedBox(height: 20),
            if (personalRecords.isEmpty)
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: Colors.grey[600], size: 32),
                    SizedBox(height: 12),
              Text(
                      'No personal records yet',
                      style: GoogleFonts.poppins(color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
            else
              ...personalRecords.map((record) => _buildPRItem(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPRItem(PersonalRecordModel record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center_rounded, color: Color(0xFFFF6B35), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName ?? 'Unknown Exercise',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  record.formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            record.formattedWeight,
            style: GoogleFonts.poppins(
              color: Color(0xFFFF6B35),
                  fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildBodyWeightTrackerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Flexible(
               child: Text(
                 'Weight & BMI Stats',
                 style: GoogleFonts.poppins(
                   fontSize: 18,
                    fontWeight: FontWeight.w600,
                   color: Colors.white,
                 ),
               ),
             ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _showAddWeightDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4ECDC4),
                      Color(0xFF3BB5B0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF4ECDC4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Add Weight',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
              ),
              SizedBox(height: 16),
        // Measurement Cards
        Row(
          children: [
            Expanded(
              child: _buildMeasurementCard(
                'Weight',
                latestMeasurements['weight'] != null && latestMeasurements['weight']! > 0
                    ? '${latestMeasurements['weight']!.toStringAsFixed(1)} kg'
                    : '--',
                Icons.scale_rounded,
                Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _showBMIModal,
                child: _buildMeasurementCard(
                  'BMI',
                  latestMeasurements['bmi'] != null && latestMeasurements['bmi']! > 0
                      ? latestMeasurements['bmi']!.toStringAsFixed(1)
                      : '--',
                  Icons.pie_chart_rounded,
                  Color(0xFFFF6B35),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddWeightDialog() {
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 1),
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
                // Header with icon and title
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ECDC4).withOpacity(0.1),
                        Color(0xFF4ECDC4).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4ECDC4), Color(0xFF3BB5B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.scale_rounded,
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
                              'Add Weight',
                  style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Log your current weight',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Weight input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: weightController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Weight (kg)',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                            prefixIcon: Container(
                              margin: EdgeInsets.all(12),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF4ECDC4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.scale_rounded,
                                color: Color(0xFF4ECDC4),
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Notes input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: notesController,
                          maxLines: 3,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            prefixIcon: Container(
                              margin: EdgeInsets.all(12),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF4ECDC4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.note_alt_rounded,
                                color: Color(0xFF4ECDC4),
                                size: 20,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            hintText: 'Add notes about your weight (e.g., "after workout", "morning weight")',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveWeightFromModal(weightController, notesController),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4ECDC4),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save Weight',
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBMIModal() {
    final currentBMI = latestMeasurements['bmi'] ?? 0.0;
    final bmiCategory = _getBMICategory(currentBMI);
    final bmiColor = _getBMIColor(currentBMI);
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3), width: 1),
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
                // Header
              Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF6B35).withOpacity(0.1),
                        Color(0xFFFF6B35).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFE55A2B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.pie_chart_rounded,
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
                              'BMI Information',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Body Mass Index Categories',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Current BMI Display
                      if (currentBMI > 0) ...[
                        Container(
                          width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                bmiColor.withOpacity(0.2),
                                bmiColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: bmiColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Your BMI',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[300],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                currentBMI.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: bmiColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                bmiCategory,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: bmiColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                      // BMI Categories
                      Text(
                        'BMI Categories',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildBMICategory('Underweight', '< 18.5', Color(0xFF4ECDC4), currentBMI < 18.5),
                      _buildBMICategory('Normal Weight', '18.5 - 24.9', Color(0xFF00B894), currentBMI >= 18.5 && currentBMI < 25),
                      _buildBMICategory('Overweight', '25.0 - 29.9', Color(0xFFFFA726), currentBMI >= 25 && currentBMI < 30),
                      _buildBMICategory('Obesity Class I', '30.0 - 34.9', Color(0xFFFF6B35), currentBMI >= 30 && currentBMI < 35),
                      _buildBMICategory('Obesity Class II', '35.0 - 39.9', Color(0xFFE53E3E), currentBMI >= 35 && currentBMI < 40),
                      _buildBMICategory('Obesity Class III', '≥ 40.0', Color(0xFFC53030), currentBMI >= 40),
                      SizedBox(height: 16),
                      // Info Text
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[700]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'BMI is a screening tool that may indicate whether you are underweight, normal weight, overweight, or obese. It is not a diagnostic tool and should be used alongside other health assessments.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBMICategory(String category, String range, Color color, bool isCurrent) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent ? color.withOpacity(0.5) : Colors.grey[700]!,
          width: isCurrent ? 2 : 1,
        ),
                ),
                child: Row(
                  children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
              category,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                color: isCurrent ? color : Colors.white,
                        ),
                      ),
                    ),
          Text(
            range,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          if (isCurrent) ...[
            SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: color,
              size: 16,
              ),
            ],
          ],
        ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal Weight';
    if (bmi < 30) return 'Overweight';
    if (bmi < 35) return 'Obesity Class I';
    if (bmi < 40) return 'Obesity Class II';
    return 'Obesity Class III';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Color(0xFF4ECDC4);
    if (bmi < 25) return Color(0xFF00B894);
    if (bmi < 30) return Color(0xFFFFA726);
    if (bmi < 35) return Color(0xFFFF6B35);
    if (bmi < 40) return Color(0xFFE53E3E);
    return Color(0xFFC53030);
  }

  Future<void> _saveWeightFromModal(TextEditingController weightController, TextEditingController notesController) async {
    if (weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your weight'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final weight = double.tryParse(weightController.text);
      final notes = notesController.text.isNotEmpty ? notesController.text : null;

      if (weight == null) {
        throw Exception('Invalid weight value');
      }

      // Calculate BMI if height is available
      double? bmi;
      if (userHeight != null && userHeight! > 0) {
        bmi = GymUtilsService.calculateBMI(weight, userHeight!);
      }

      final result = await BodyMeasurementsService.addBodyMeasurement(
        weight: weight,
        bmi: bmi,
        notes: notes,
      );

      if (result['success']) {
        Navigator.pop(context);
        await _loadDashboardData();
        
        final message = result['message'] ?? 'Weight saved successfully';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Failed to save weight');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBodyMeasurementsSection() {
    // Get latest measurement to show preview
    Map<String, dynamic>? latestMeasurement;
    if (_bodyMeasurementsData.isNotEmpty) {
      latestMeasurement = _bodyMeasurementsData.first;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BodyMeasurementsPage(),
          ),
        ).then((_) => _loadBodyMeasurementsData()); // Refresh on return
      },
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.straighten_rounded,
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
                    'Body Measurements',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    latestMeasurement != null 
                      ? '${_countMeasurements(latestMeasurement)} measurements'
                      : 'Track your body composition',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 18),
          ],
        ),
      ),
    );
  }

  int _countMeasurements(Map<String, dynamic> measurement) {
    int count = 0;
    if (measurement['weight'] != null && measurement['weight'] != 0.0) count++;
    if (measurement['chest'] != null && measurement['chest'] != 0.0) count++;
    if (measurement['waist'] != null && measurement['waist'] != 0.0) count++;
    if (measurement['shoulders'] != null && measurement['shoulders'] != 0.0) count++;
    if (measurement['biceps_left'] != null && measurement['biceps_left'] != 0.0) count++;
    if (measurement['biceps_right'] != null && measurement['biceps_right'] != 0.0) count++;
    if (measurement['thighs'] != null && measurement['thighs'] != 0.0) count++;
    return count;
  }

  Widget _buildMeasurementFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip('all', 'All'),
          _buildFilterChip('14d', '14 Days'),
          _buildFilterChip('30d', '30 Days'),
          _buildFilterChip('3m', '3 Months'),
          _buildFilterChip('6m', '6 Months'),
          _buildFilterChip('1y', '1 Year'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedMeasurementPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMeasurementPeriod = value;
        });
        _loadBodyMeasurementsData();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF6C5CE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyMeasurementsDisplay() {
    if (_bodyMeasurementsData.isEmpty) {
      return Container(
        height: 250,
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.straighten_rounded,
                  color: Colors.grey[500],
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'No body measurements yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start tracking your body composition',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Comparison Header
        if (_bodyMeasurementsData.length > 1) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF6C5CE7).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF6C5CE7),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Progress Comparison',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                Spacer(),
                Text(
                  _getComparisonPeriod(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
          ),
        ],
      ),
          ),
          SizedBox(height: 16),
        ],
        
        // Body Parts List
        ..._buildBodyPartsList(),
      ],
    );
  }

  List<Widget> _buildBodyPartsList() {
    if (_bodyMeasurementsData.isEmpty) {
      return [];
    }

    // Get the latest measurement entry (newest first after sorting)
    final latestEntry = _bodyMeasurementsData.first;
    
    // Define body parts with their data keys
    final bodyParts = [
      {'name': 'Chest', 'icon': Icons.fitness_center, 'key': 'chest'},
      {'name': 'Shoulders', 'icon': Icons.accessibility_new, 'key': 'shoulders'},
      {'name': 'Biceps (L)', 'icon': Icons.fitness_center, 'key': 'biceps_left'},
      {'name': 'Biceps (R)', 'icon': Icons.fitness_center, 'key': 'biceps_right'},
      {'name': 'Waist', 'icon': Icons.straighten, 'key': 'waist'},
      {'name': 'Thighs', 'icon': Icons.directions_run, 'key': 'thighs'},
    ];

    return bodyParts.map((part) {
      final key = part['key'] as String;
      final value = latestEntry[key] as double?;
      
      // Don't show if no data or value is 0 (invalid measurement)
      if (value == null || value == 0.0) {
        return SizedBox.shrink();
      }
      
      // Calculate change from previous entry if available
      double change = 0.0;
      if (_bodyMeasurementsData.length > 1) {
        final previousEntry = _bodyMeasurementsData[1]; // Second newest (index 1)
        final previousValue = previousEntry[key] as double?;
        if (previousValue != null && previousValue != 0.0) {
          change = value - previousValue;
        }
      }
      
      return _buildBodyPartCard({
        'name': part['name'],
        'icon': part['icon'],
        'value': value,
        'change': change,
        'key': key,
      });
    }).toList();
  }

  Widget _buildBodyPartCard(Map<String, dynamic> part) {
    final name = part['name'] as String;
    final icon = part['icon'] as IconData;
    final value = part['value'] as double;
    final change = part['change'] as double;
    final key = part['key'] as String;
    final isCompact = MediaQuery.of(context).size.width < 340;
    
    Color changeColor;
    IconData changeIcon;
    String changeText;
    
    if (change > 0) {
      changeColor = Color(0xFF00B894);
      changeIcon = Icons.trending_up_rounded;
      changeText = '+${change.toStringAsFixed(1)} cm';
    } else if (change < 0) {
      changeColor = Color(0xFFE17055);
      changeIcon = Icons.trending_down_rounded;
      changeText = '${change.toStringAsFixed(1)} cm';
    } else {
      changeColor = Colors.grey[400]!;
      changeIcon = Icons.trending_flat_rounded;
      changeText = 'No change';
    }

    return GestureDetector(
      onTap: () => _showBodyPartLogs(name, key),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isCompact ? 12 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A2A2A),
              Color(0xFF1F1F1F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF6C5CE7).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0xFF6C5CE7).withOpacity(0.05),
              blurRadius: 16,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isCompact ? 44 : 56,
              height: isCompact ? 44 : 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6C5CE7).withOpacity(0.3),
                    Color(0xFF5A4FCF).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF6C5CE7).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Color(0xFF6C5CE7),
                size: isCompact ? 20 : 24,
              ),
            ),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${value.toStringAsFixed(1)} cm',
                    style: GoogleFonts.poppins(
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topRight,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: isCompact ? 6 : 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            changeColor.withOpacity(0.2),
                            changeColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: changeColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            changeIcon,
                            color: changeColor,
                            size: isCompact ? 16 : 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            changeText,
                            style: GoogleFonts.poppins(
                              fontSize: isCompact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: changeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: isCompact ? 28 : 32,
                      height: isCompact ? 28 : 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF6C5CE7).withOpacity(0.2),
                            Color(0xFF5A4FCF).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Color(0xFF6C5CE7).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF6C5CE7),
                        size: isCompact ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
            ),
          ),
        );
  }

  String _getComparisonPeriod() {
    final now = DateTime.now();
    switch (_selectedMeasurementPeriod) {
      case '14d':
        return 'Last 14 days';
      case '30d':
        return 'Last 30 days';
      case '3m':
        return 'Last 3 months';
      case '6m':
        return 'Last 6 months';
      case '1y':
        return 'Last year';
      default:
        return 'All time';
    }
  }

  void _showAddBodyMeasurementsDialog() {
    final controllers = {
      'chest': TextEditingController(),
      'shoulders': TextEditingController(),
      'biceps_left': TextEditingController(),
      'biceps_right': TextEditingController(),
      'waist': TextEditingController(),
      'thighs': TextEditingController(),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
      child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF6C5CE7).withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
                // Header
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6C5CE7).withOpacity(0.1),
                        Color(0xFF6C5CE7).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
              children: [
                Container(
                        width: 48,
                        height: 48,
                  decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF5A4FCF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.straighten_rounded,
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
                              'Add Body Measurements',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                                color: Colors.white,
                        ),
                      ),
                      Text(
                              'Enter measurements in centimeters (cm)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                                color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                
                // Instructions
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF6C5CE7).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF6C5CE7),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Measure around the widest part of each body part. Use a flexible measuring tape for accurate results.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildMeasurementField(
                          'Chest',
                          'Measure around the widest part of your chest',
                          Icons.fitness_center,
                          controllers['chest']!,
                        ),
                        _buildMeasurementField(
                          'Shoulders',
                          'Measure around the widest part of your shoulders',
                          Icons.accessibility_new,
                          controllers['shoulders']!,
                        ),
                        _buildMeasurementField(
                          'Biceps (Left)',
                          'Measure around the largest part of your left bicep',
                          Icons.fitness_center,
                          controllers['biceps_left']!,
                        ),
                        _buildMeasurementField(
                          'Biceps (Right)',
                          'Measure around the largest part of your right bicep',
                          Icons.fitness_center,
                          controllers['biceps_right']!,
                        ),
                        _buildMeasurementField(
                          'Waist',
                          'Measure around your natural waistline',
                          Icons.straighten,
                          controllers['waist']!,
                        ),
                        _buildMeasurementField(
                          'Thighs',
                          'Measure around the largest part of your thigh',
                          Icons.directions_run,
                          controllers['thighs']!,
            ),
            SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
              children: [
                Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveBodyMeasurements(controllers),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6C5CE7),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save Measurements',
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
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildMeasurementField(String title, String hint, IconData icon, TextEditingController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF6C5CE7),
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF6C5CE7).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Enter measurement in cm',
                labelStyle: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
                suffixText: 'cm',
                suffixStyle: GoogleFonts.poppins(
                  color: Color(0xFF6C5CE7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBodyMeasurements(Map<String, TextEditingController> controllers) async {
    // Validate that at least one field is filled
    bool hasData = false;
    Map<String, double> measurements = {};
    
    for (String key in controllers.keys) {
      final text = controllers[key]!.text.trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null && value > 0) {
          measurements[key] = value;
          hasData = true;
        }
      }
    }
    
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least one measurement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId != null) {
        // Save to database first (primary storage)
        final result = await BodyMeasurementsService.addBodyMeasurement(
          weight: measurements['weight'] ?? 0.0,
          chestCm: measurements['chest'],
          waistCm: measurements['waist'],
          hipsCm: measurements['thighs'], // Map thighs to hips for database
          armsCm: measurements['biceps_left'], // Use left bicep as arms measurement
          notes: 'Body measurements entry',
        );
        
        if (result['success'] == true) {
          // Also save to local storage for backup/offline access
          final prefs = await SharedPreferences.getInstance();
          final now = DateTime.now();
          final timestamp = now.millisecondsSinceEpoch;
          
          // Create measurement entry
          final measurementEntry = {
            'id': timestamp.toString(),
            'user_id': userId,
            'date_recorded': now.toIso8601String(),
            'chest': measurements['chest'],
            'shoulders': measurements['shoulders'],
            'biceps_left': measurements['biceps_left'],
            'biceps_right': measurements['biceps_right'],
            'waist': measurements['waist'],
            'thighs': measurements['thighs'],
            'created_at': now.toIso8601String(),
          };
          
          // Get existing measurements
          final existingData = prefs.getString('body_measurements_$userId') ?? '[]';
          final List<dynamic> measurementsList = json.decode(existingData);
          
          // Add new measurement
          measurementsList.add(measurementEntry);
          
          // Save back to storage
          await prefs.setString('body_measurements_$userId', json.encode(measurementsList));
          
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Body measurements saved successfully!'),
              backgroundColor: Color(0xFF6C5CE7),
            ),
          );
          
          // Refresh both data sources
          _loadBodyMeasurementsData();
          _loadBodyMeasurements();
        } else {
          throw Exception(result['message'] ?? 'Failed to save measurements');
        }
      } else {
        throw Exception('User not logged in');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving measurements: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBodyPartLogs(String bodyPartName, String bodyPartKey) {
    // Filter measurements that have data for this body part
    final relevantMeasurements = _bodyMeasurementsData.where((entry) {
      return entry[bodyPartKey] != null;
    }).toList();

    if (relevantMeasurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No measurement data available for $bodyPartName'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
      child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF6C5CE7).withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
                // Header
                Container(
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6C5CE7).withOpacity(0.15),
                        Color(0xFF5A4FCF).withOpacity(0.1),
                        Color(0xFF6C5CE7).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFF6C5CE7).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
              children: [
                Container(
                        width: 56,
                        height: 56,
                  decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6C5CE7),
                              Color(0xFF5A4FCF),
                              Color(0xFF4A3FBF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6C5CE7).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                              '$bodyPartName Progress',
                        style: GoogleFonts.poppins(
                                fontSize: 22,
                          fontWeight: FontWeight.bold,
                                color: Colors.white,
                        ),
                      ),
                            SizedBox(height: 4),
                      Text(
                              'Track your measurement history & trends',
                        style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey[300],
                                fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[600]!.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.grey[300],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                        // Summary Stats
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF6C5CE7).withOpacity(0.1),
                                Color(0xFF5A4FCF).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFF6C5CE7).withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6C5CE7).withOpacity(0.1),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                    ),
                  ],
                ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Entries',
                                  '${relevantMeasurements.length}',
                                  Icons.analytics_rounded,
                                  Color(0xFF6C5CE7),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Current',
                                  '${relevantMeasurements.last[bodyPartKey].toStringAsFixed(1)} cm',
                                  Icons.straighten_rounded,
                                  Colors.white,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Change',
                                  relevantMeasurements.length > 1 
                                    ? '${(relevantMeasurements.last[bodyPartKey] - relevantMeasurements.first[bodyPartKey]).toStringAsFixed(1)} cm'
                                    : '0.0 cm',
                                  Icons.trending_up_rounded,
                                  relevantMeasurements.length > 1 && (relevantMeasurements.last[bodyPartKey] - relevantMeasurements.first[bodyPartKey]) > 0
                                    ? Color(0xFF00B894)
                                    : relevantMeasurements.length > 1 && (relevantMeasurements.last[bodyPartKey] - relevantMeasurements.first[bodyPartKey]) < 0
                                      ? Color(0xFFE17055)
                                      : Colors.grey[400]!,
                                ),
                              ),
          ],
        ),
      ),
                        SizedBox(height: 24),
                        
                        // Measurement History
                        Text(
                          'Measurement History',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        ...relevantMeasurements.reversed.map((entry) {
                          final index = relevantMeasurements.indexOf(entry);
                          final isLatest = index == relevantMeasurements.length - 1;
                          final value = entry[bodyPartKey] as double;
                          final date = DateTime.parse(entry['date_recorded']);
                          
                          // Calculate change from previous entry
                          double change = 0.0;
                          String changeText = '';
                          Color changeColor = Colors.grey[400]!;
                          IconData changeIcon = Icons.remove;
                          
                          if (index > 0) {
                            final previousValue = relevantMeasurements[index - 1][bodyPartKey] as double;
                            change = value - previousValue;
                            
                            if (change > 0) {
                              changeColor = Color(0xFF00B894);
                              changeIcon = Icons.keyboard_arrow_up;
                              changeText = '+${change.toStringAsFixed(1)} cm';
                            } else if (change < 0) {
                              changeColor = Color(0xFFE17055);
                              changeIcon = Icons.keyboard_arrow_down;
                              changeText = '${change.toStringAsFixed(1)} cm';
                            } else {
                              changeText = 'No change';
                            }
                          } else {
                            changeText = 'First entry';
                          }
                          
    return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLatest 
                                  ? [
                                      Color(0xFF6C5CE7).withOpacity(0.15),
                                      Color(0xFF5A4FCF).withOpacity(0.1),
                                    ]
                                  : [
                                      Color(0xFF2A2A2A),
                                      Color(0xFF1F1F1F),
                                    ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLatest 
                                  ? Color(0xFF6C5CE7).withOpacity(0.3)
                                  : Colors.grey[700]!.withOpacity(0.5),
                                width: isLatest ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isLatest 
                                    ? Color(0xFF6C5CE7).withOpacity(0.1)
                                    : Colors.black.withOpacity(0.1),
                                  blurRadius: isLatest ? 12 : 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
      ),
      child: Row(
        children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isLatest 
                                        ? [
                                            Color(0xFF6C5CE7).withOpacity(0.4),
                                            Color(0xFF5A4FCF).withOpacity(0.3),
                                          ]
                                        : [
                                            Color(0xFF6C5CE7).withOpacity(0.2),
                                            Color(0xFF5A4FCF).withOpacity(0.1),
                                          ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFF6C5CE7).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.straighten_rounded,
                                    color: Color(0xFF6C5CE7),
                                    size: 22,
                                  ),
                                ),
                                SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                        '${value.toStringAsFixed(1)} cm',
                  style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                    color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _formatMeasurementDate(date),
                                        style: GoogleFonts.poppins(
                    fontSize: 14,
                                          color: Colors.grey[300],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    if (index > 0) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              changeColor.withOpacity(0.2),
                                              changeColor.withOpacity(0.1),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: changeColor.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              changeIcon,
                                              color: changeColor,
                                              size: 16,
                                            ),
                                            SizedBox(width: 6),
                Text(
                                              changeText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: changeColor,
                  ),
                ),
              ],
            ),
          ),
                                    ] else ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[600]!.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.grey[600]!.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'First entry',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (isLatest) ...[
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF6C5CE7),
                                              Color(0xFF5A4FCF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF6C5CE7).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'LATEST',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[700]!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatMeasurementDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _loadBodyMeasurementsData() async {
    try {
      // Fetch from database
      final dbMeasurements = await BodyMeasurementsService.getBodyMeasurements();
      
      if (dbMeasurements.isEmpty) {
        // If no DB data, try local storage for backward compatibility
        final userId = await AuthService.getCurrentUserId();
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          final data = prefs.getString('body_measurements_$userId') ?? '[]';
          final List<dynamic> measurementsList = json.decode(data);
          
          // Convert to the format expected by the UI
          _bodyMeasurementsData = measurementsList.cast<Map<String, dynamic>>();
          
          // Check if we have local data that needs to be migrated to database
          if (_bodyMeasurementsData.isNotEmpty) {
            await _migrateLocalDataToDatabase();
          }
          
          if (mounted) {
            setState(() {});
          }
        }
        return;
      }
      
      // Convert ProgressModel to Map format expected by UI
      _bodyMeasurementsData = dbMeasurements.map((m) => {
        'date_recorded': m.dateRecorded.toIso8601String(),
        'weight': m.weight,
        'chest': m.chestCm,
        'shoulders': m.armsCm, // Using armsCm as shoulders mapping
        'biceps_left': m.armsCm,
        'biceps_right': m.armsCm,
        'waist': m.waistCm,
        'thighs': m.thighsCm ?? m.hipsCm,
      }).toList();
      
      // Apply date filter based on selected period
      final now = DateTime.now();
      DateTime cutoffDate;
      
      switch (_selectedMeasurementPeriod) {
        case 'all':
          cutoffDate = DateTime(1970, 1, 1); // All time
          break;
        case '14d':
          cutoffDate = now.subtract(Duration(days: 14));
          break;
        case '30d':
          cutoffDate = now.subtract(Duration(days: 30));
          break;
        case '3m':
          cutoffDate = now.subtract(Duration(days: 90));
          break;
        case '6m':
          cutoffDate = now.subtract(Duration(days: 180));
          break;
        case '1y':
          cutoffDate = now.subtract(Duration(days: 365));
          break;
        default:
          cutoffDate = DateTime(1970, 1, 1); // All time
      }
      
      // Filter measurements within the selected period
      _bodyMeasurementsData = _bodyMeasurementsData.where((m) {
        final measurementDate = DateTime.parse(m['date_recorded']);
        return measurementDate.isAfter(cutoffDate) || measurementDate.isAtSameMomentAs(cutoffDate);
      }).toList();
      
      // Sort by date (newest first)
      _bodyMeasurementsData.sort((a, b) {
        final dateA = DateTime.parse(a['date_recorded']);
        final dateB = DateTime.parse(b['date_recorded']);
        return dateB.compareTo(dateA);
      });
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading body measurements: $e');
    }
  }

  Future<void> _migrateLocalDataToDatabase() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      // Get existing database measurements to avoid duplicates
      final dbMeasurements = await BodyMeasurementsService.getBodyMeasurements();
      final dbDates = dbMeasurements.map((m) => m.dateRecorded.toIso8601String().split('T')[0]).toSet();

      int migratedCount = 0;
      
      // Migrate local measurements that don't exist in database
      for (final localMeasurement in _bodyMeasurementsData) {
        final localDate = DateTime.parse(localMeasurement['date_recorded']).toIso8601String().split('T')[0];
        
        if (!dbDates.contains(localDate)) {
          // This local measurement doesn't exist in database, migrate it
          final result = await BodyMeasurementsService.addBodyMeasurement(
            weight: (localMeasurement['weight'] ?? 0.0).toDouble(),
            chestCm: (localMeasurement['chest'] ?? 0.0).toDouble(),
            waistCm: (localMeasurement['waist'] ?? 0.0).toDouble(),
            hipsCm: (localMeasurement['thighs'] ?? 0.0).toDouble(),
            armsCm: (localMeasurement['biceps_left'] ?? 0.0).toDouble(),
            notes: 'Migrated from local storage',
          );
          
          if (result['success'] == true) {
            migratedCount++;
          }
        }
      }
      
      if (migratedCount > 0) {
        // Migrated $migratedCount measurements
        // Refresh the database measurements after migration
        _loadBodyMeasurements();
      }
    } catch (e) {
      print('Error migrating local data to database: $e');
    }
  }

  Widget _buildMeasurementCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final goalStats = stats['goals'] ?? {};
    final attendanceStats = stats['attendance'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            'Goals',
            '${goalStats['achieved'] ?? 0}/${goalStats['total'] ?? 0}',
            'Achieved',
            Color(0xFF96CEB4),
            Icons.flag_rounded,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int>(
            future: _getActualWorkoutCount(),
            builder: (context, snapshot) {
              final workoutCount = snapshot.data ?? 0;
              return _buildQuickStatCard(
            'Workouts',
                '$workoutCount',
                'Completed',
            Color(0xFF45B7D1),
            Icons.fitness_center_rounded,
              );
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            'Gym Visits',
            '${attendanceStats['thisMonth'] ?? 0}',
            'This Month',
            Color(0xFFE74C3C),
            Icons.location_on_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF96CEB4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.flag_rounded, color: Color(0xFF96CEB4), size: 24),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Active Goals',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GoalsPage(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF96CEB4),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (goals.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No active goals',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...goals.map((goal) => _buildGoalItem(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalItem(GoalModel goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goal.statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: goal.statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.goal,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  goal.formattedTargetDate,
                  style: GoogleFonts.poppins(
                    color: goal.statusColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (goal.status == GoalStatus.active)
            IconButton(
              onPressed: () => _markGoalAchieved(goal),
              icon: Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF45B7D1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.history_rounded, color: Color(0xFF45B7D1), size: 24),
              ),
              SizedBox(width: 16),
              Text(
                'Recent Activity',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (recentSessions.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.fitness_center_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...recentSessions.take(3).map((session) => _buildActivityItem(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(WorkoutSessionModel session) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session.completed ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: session.statusColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.programName ?? 'Workout Session',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  session.formattedDate,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: session.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.completed ? 'Completed' : 'In Progress',
              style: GoogleFonts.poppins(
                color: session.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markGoalAchieved(GoalModel goal) async {
    final success = await EnhancedProgressService.updateGoalStatus(
      goal.id!,
      GoalStatus.achieved,
    );
        
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal marked as achieved! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDashboardData();
    }
  }
}
