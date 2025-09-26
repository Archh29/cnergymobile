import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './models/member_model.dart';
import './services/coach_service.dart';
import 'detail_pages/attendance_detail_page.dart';
import 'detail_pages/workout_logs_detail_page.dart';
import 'detail_pages/personal_records_detail_page.dart';
import 'detail_pages/progress_over_time_detail_page.dart';

class CoachProgressPage extends StatefulWidget {
  final MemberModel selectedMember;

  const CoachProgressPage({Key? key, required this.selectedMember}) : super(key: key);

  @override
  _CoachProgressPageState createState() => _CoachProgressPageState();
}

class _CoachProgressPageState extends State<CoachProgressPage>
    with TickerProviderStateMixin {
  Map<String, dynamic> memberData = {};
  List<Map<String, dynamic>> sessionHistory = [];
  List<Map<String, dynamic>> memberRoutines = [];
  Map<String, dynamic> monitoringData = {};
  bool isLoading = true;
  List<MemberModel> assignedMembers = [];
  MemberModel? currentMember;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    currentMember = widget.selectedMember;
    _loadAssignedMembersAndProgress();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedMembersAndProgress() async {
    if (!mounted) return;
    print('🔍 COACH PROGRESS: Starting to load data for member ID: ${currentMember?.id}');
    setState(() => isLoading = true);

    try {
      print('🔍 COACH PROGRESS: Calling API endpoints...');
      final futures = await Future.wait([
        CoachService.getAssignedMembers(),
        _getMemberSessionHistory(currentMember!.id),
        _getMemberRoutines(currentMember!.id),
        _getMemberMonitoringData(currentMember!.id),
      ]);

      if (mounted) {
        print('🔍 COACH PROGRESS: API calls completed, processing results...');
        setState(() {
          assignedMembers = futures[0] as List<MemberModel>;
          print('🔍 COACH PROGRESS: Assigned members count: ${assignedMembers.length}');
          
          // Ensure currentMember is present in list; if not, prepend it
          if (assignedMembers.indexWhere((m) => m.id == currentMember!.id) == -1) {
            print('🔍 COACH PROGRESS: Current member not in assigned list, adding it');
            assignedMembers = [currentMember!, ...assignedMembers];
          }
          
          sessionHistory = futures[1] as List<Map<String, dynamic>>;
          print('🔍 COACH PROGRESS: Session history count: ${sessionHistory.length}');
          
          memberRoutines = futures[2] as List<Map<String, dynamic>>;
          print('🔍 COACH PROGRESS: Member routines count: ${memberRoutines.length}');
          
          monitoringData = futures[3] as Map<String, dynamic>;
          print('🔍 COACH PROGRESS: Monitoring data keys: ${monitoringData.keys.toList()}');
          
          isLoading = false;
        });
        _animationController.forward();
        print('🔍 COACH PROGRESS: Data loading completed successfully');
      }
    } catch (e) {
      print('❌ COACH PROGRESS: Error loading member data: $e');
      print('❌ COACH PROGRESS: Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getMemberSessionHistory(int memberId) async {
    try {
      print('🔍 SESSION HISTORY: Fetching for member ID: $memberId');
      final url = 'https://api.cnergy.site/coach_session_management.php?action=get-session-history&member_id=$memberId';
      print('🔍 SESSION HISTORY: URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 SESSION HISTORY: Response status: ${response.statusCode}');
      print('🔍 SESSION HISTORY: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 SESSION HISTORY: Parsed data: $data');
        
        if (data['success'] == true) {
          final responseData = data['data'] as Map<String, dynamic>;
          final history = List<Map<String, dynamic>>.from(responseData['history'] ?? []);
          print('🔍 SESSION HISTORY: Found ${history.length} session records');
          return history;
        } else {
          print('❌ SESSION HISTORY: API returned success: false - ${data['message']}');
        }
      } else {
        print('❌ SESSION HISTORY: HTTP error ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ SESSION HISTORY: Error fetching session history: $e');
      print('❌ SESSION HISTORY: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getMemberRoutines(int memberId) async {
    try {
      print('🔍 MEMBER ROUTINES: Fetching for member ID: $memberId');
      final coachId = await CoachService.getCoachId();
      print('🔍 MEMBER ROUTINES: Coach ID: $coachId');
      
      final url = 'https://api.cnergy.site/coach_api.php?action=coach-created-routines&member_id=$memberId';
      print('🔍 MEMBER ROUTINES: URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 MEMBER ROUTINES: Response status: ${response.statusCode}');
      print('🔍 MEMBER ROUTINES: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 MEMBER ROUTINES: Parsed data: $data');
        
        if (data['success'] == true) {
          final routines = List<Map<String, dynamic>>.from(data['routines'] ?? []);
          print('🔍 MEMBER ROUTINES: Found ${routines.length} routines');
          return routines;
        } else {
          print('❌ MEMBER ROUTINES: API returned success: false - ${data['message']}');
        }
      } else {
        print('❌ MEMBER ROUTINES: HTTP error ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ MEMBER ROUTINES: Error fetching member routines: $e');
      print('❌ MEMBER ROUTINES: Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getMemberMonitoringData(int memberId) async {
    try {
      print('🔍 MONITORING DATA: Fetching for member ID: $memberId');
      print('🔍 MONITORING DATA: Starting Future.wait with 8 API calls');
      print('🔍 MONITORING DATA: 1. Attendance data');
      print('🔍 MONITORING DATA: 2. Workout logs');
      print('🔍 MONITORING DATA: 3. Profile details');
      print('🔍 MONITORING DATA: 4. Fitness goals');
      print('🔍 MONITORING DATA: 5. Personal records');
      print('🔍 MONITORING DATA: 6. Progress over time');
      print('🔍 MONITORING DATA: 7. Muscle analytics');
      print('🔍 MONITORING DATA: 8. Compliance metrics');
      
      print('🔍 MONITORING DATA: About to call _getMemberProgressOverTime for member ID: $memberId');
      final futures = await Future.wait([
        _getMemberAttendanceData(memberId),
        _getMemberWorkoutLogs(memberId),
        _getMemberProfileDetails(memberId),
        _getMemberFitnessGoals(memberId),
        _getMemberPersonalRecords(memberId),
        _getMemberProgressOverTime(memberId),
        _getMemberMuscleAnalytics(memberId),
        _getMemberComplianceMetrics(memberId),
      ]);
      print('🔍 MONITORING DATA: Future.wait completed, checking progress over time result');
      print('🔍 MONITORING DATA: Future.wait completed with ${futures.length} results');

      final result = {
        'attendance': futures[0],
        'workoutLogs': futures[1],
        'profileDetails': futures[2],
        'fitnessGoals': futures[3],
        'personalRecords': futures[4],
        'progressOverTime': futures[5],
        'muscleAnalytics': futures[6],
        'complianceMetrics': futures[7],
      };
      
      print('🔍 MONITORING DATA: Collected data summary:');
      print('🔍 MONITORING DATA: - Attendance keys: ${(futures[0] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Workout logs keys: ${(futures[1] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Profile details keys: ${(futures[2] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Fitness goals keys: ${(futures[3] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Personal records keys: ${(futures[4] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Progress over time keys: ${(futures[5] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Muscle analytics keys: ${(futures[6] as Map).keys.toList()}');
      print('🔍 MONITORING DATA: - Compliance metrics keys: ${(futures[7] as Map).keys.toList()}');
      
      return result;
    } catch (e) {
      print('❌ MONITORING DATA: Error fetching member monitoring data: $e');
      print('❌ MONITORING DATA: Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberAttendanceData(int memberId) async {
    try {
      print('🔍 ATTENDANCE: Fetching for member ID: $memberId');
      final url = 'https://api.cnergy.site/coach_member_monitoring.php?action=get-attendance&member_id=$memberId';
      print('🔍 ATTENDANCE: URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 ATTENDANCE: Response status: ${response.statusCode}');
      print('🔍 ATTENDANCE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 ATTENDANCE: Parsed data: $data');
        
        if (data['success'] == true) {
          final result = Map<String, dynamic>.from(data['data'] ?? {});
          print('🔍 ATTENDANCE: Found data with keys: ${result.keys.toList()}');
          return result;
        } else {
          print('❌ ATTENDANCE: API returned success: false - ${data['message']}');
        }
      } else {
        print('❌ ATTENDANCE: HTTP error ${response.statusCode}');
      }
      return {};
    } catch (e) {
      print('❌ ATTENDANCE: Error fetching attendance data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberWorkoutLogs(int memberId) async {
    try {
      print('🔍 WORKOUT LOGS: Fetching for member ID: $memberId');
      final url = 'https://api.cnergy.site/coach_member_monitoring.php?action=get-workout-logs&member_id=$memberId';
      print('🔍 WORKOUT LOGS: URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 WORKOUT LOGS: Response status: ${response.statusCode}');
      print('🔍 WORKOUT LOGS: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 WORKOUT LOGS: Parsed data: $data');
        
        if (data['success'] == true) {
          final result = Map<String, dynamic>.from(data['data'] ?? {});
          print('🔍 WORKOUT LOGS: Found data with keys: ${result.keys.toList()}');
          return result;
        } else {
          print('❌ WORKOUT LOGS: API returned success: false - ${data['message']}');
        }
      } else {
        print('❌ WORKOUT LOGS: HTTP error ${response.statusCode}');
      }
      return {};
    } catch (e) {
      print('❌ WORKOUT LOGS: Error fetching workout logs: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberProfileDetails(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-profile-details&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        }
      }
      return {};
    } catch (e) {
      print('Error fetching profile details: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberFitnessGoals(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-fitness-goals&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        }
      }
      return {};
    } catch (e) {
      print('Error fetching fitness goals: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberPersonalRecords(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-personal-records&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        }
      }
      return {};
    } catch (e) {
      print('Error fetching personal records: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberProgressOverTime(int memberId) async {
    try {
      print('🔍 PROGRESS OVER TIME: METHOD CALLED for member ID: $memberId');
      print('🔍 PROGRESS OVER TIME: Fetching for member ID: $memberId');
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-progress-over-time&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 PROGRESS OVER TIME: Response status: ${response.statusCode}');
      print('🔍 PROGRESS OVER TIME: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 PROGRESS OVER TIME: Parsed data: $data');
        
        if (data['success'] == true) {
          final progressData = Map<String, dynamic>.from(data['data'] ?? {});
          print('🔍 PROGRESS OVER TIME: Progress data keys: ${progressData.keys.toList()}');
          print('🔍 PROGRESS OVER TIME: Weight progress: ${progressData['weight_progress']}');
          print('🔍 PROGRESS OVER TIME: Strength progress: ${progressData['strength_progress']}');
          print('🔍 PROGRESS OVER TIME: Attendance progress: ${progressData['attendance_progress']}');
          return progressData;
        }
      }
      print('❌ PROGRESS OVER TIME: API returned success: false or status != 200');
      return {};
    } catch (e) {
      print('❌ PROGRESS OVER TIME: Error fetching progress over time: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberMuscleAnalytics(int memberId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-muscle-analytics&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        }
      }
      return {};
    } catch (e) {
      print('Error fetching muscle analytics: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMemberComplianceMetrics(int memberId) async {
    try {
      print('🔍 COMPLIANCE METRICS: Fetching for member ID: $memberId');
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_member_monitoring.php?action=get-compliance-metrics&member_id=$memberId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('🔍 COMPLIANCE METRICS: Response status: ${response.statusCode}');
      print('🔍 COMPLIANCE METRICS: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 COMPLIANCE METRICS: Parsed data: $data');
        
        if (data['success'] == true) {
          final result = Map<String, dynamic>.from(data['data'] ?? {});
          print('🔍 COMPLIANCE METRICS: Found data with keys: ${result.keys.toList()}');
          return result;
        } else {
          print('❌ COMPLIANCE METRICS: API returned success: false - ${data['message']}');
        }
      } else {
        print('❌ COMPLIANCE METRICS: HTTP error ${response.statusCode}');
      }
      return {};
    } catch (e) {
      print('❌ COMPLIANCE METRICS: Error fetching compliance metrics: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 COACH PROGRESS BUILD: isLoading: $isLoading');
    print('🔍 COACH PROGRESS BUILD: currentMember: ${currentMember?.fullName} (ID: ${currentMember?.id})');
    print('🔍 COACH PROGRESS BUILD: sessionHistory count: ${sessionHistory.length}');
    print('🔍 COACH PROGRESS BUILD: memberRoutines count: ${memberRoutines.length}');
    print('🔍 COACH PROGRESS BUILD: monitoringData keys: ${monitoringData.keys.toList()}');
    print('🔍 COACH PROGRESS BUILD: assignedMembers count: ${assignedMembers.length}');
    
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadAssignedMembersAndProgress,
                  color: Color(0xFF4ECDC4),
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMemberSelector(),
                        SizedBox(height: 12),
                        _buildMemberHeader(),
                        SizedBox(height: 20),
                _buildBodyWeightSection(),
                SizedBox(height: 20),
                _buildAttendanceSection(),
                SizedBox(height: 20),
                _buildWorkoutStatsSection(),
                SizedBox(height: 20),
                _buildPersonalRecordsSection(),
                SizedBox(height: 20),
                _buildGoalsSection(),
                SizedBox(height: 20),
                _buildProgressOverTimeSection(),
                SizedBox(height: 20),
                _buildSessionOverview(),
                SizedBox(height: 20),
                _buildRoutinesSection(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMemberSelector() {
    if (assignedMembers.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.group, color: Color(0xFF4ECDC4), size: 18),
          SizedBox(width: 12),
          Expanded(
            child: DropdownButton<MemberModel>(
              value: currentMember,
              dropdownColor: Color(0xFF1A1A1A),
              isExpanded: true,
              underline: SizedBox.shrink(),
              iconEnabledColor: Colors.white,
              style: GoogleFonts.poppins(color: Colors.white),
              items: assignedMembers.map((m) => DropdownMenuItem<MemberModel>(
                value: m,
                child: Text(m.fullName, style: GoogleFonts.poppins(color: Colors.white)),
              )).toList(),
              onChanged: (member) async {
                if (member == null) return;
                if (!mounted) return;
                setState(() {
                  currentMember = member;
                  isLoading = true;
                });
                try {
                  print('🔍 MEMBER SWITCH: Loading data for member ID: ${member.id}');
                  final futures = await Future.wait([
                    _getMemberSessionHistory(member.id),
                    _getMemberRoutines(member.id),
                    _getMemberMonitoringData(member.id),
                  ]);
                  if (!mounted) return;
                  setState(() {
                    sessionHistory = futures[0] as List<Map<String, dynamic>>;
                    memberRoutines = futures[1] as List<Map<String, dynamic>>;
                    monitoringData = futures[2] as Map<String, dynamic>;
                    isLoading = false;
                  });
                  print('🔍 MEMBER SWITCH: Data loaded successfully for member ID: ${member.id}');
                } catch (e) {
                  if (!mounted) return;
                  setState(() { isLoading = false; });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load member data'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ),
        ],
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
            'Loading ${widget.selectedMember.fname}\'s progress...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberHeader() {
    final member = currentMember ?? widget.selectedMember;
    final totalSessions = sessionHistory.length;
    final activeRoutines = memberRoutines.length;
    final remainingSessions = sessionHistory.isNotEmpty ? (sessionHistory.first['remaining_sessions'] ?? 0) : 0;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF96CEB4), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF96CEB4).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  member.initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${member.fullName}\'s Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Rate Type: ${sessionHistory.isNotEmpty ? (sessionHistory.first['rate_type'] ?? 'N/A') : 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Member since ${member.createdAt.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    if (member.status != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Status: ${member.status}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: remainingSessions > 0 ? remainingSessions / 10 : 0,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$remainingSessions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Sessions',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderMetric(
                  'Total Sessions',
                  '$totalSessions',
                  Icons.fitness_center,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'Active Routines',
                  '$activeRoutines',
                  Icons.list_alt,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'Remaining',
                  '$remainingSessions',
                  Icons.timer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionOverview() {
    final member = currentMember ?? widget.selectedMember;
    final totalSessions = sessionHistory.length;
    final thisWeekSessions = _getThisWeekSessions();
    final thisMonthSessions = _getThisMonthSessions();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Session Overview',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Coach View',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Member Session Activity Summary',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildProgressItem(
                  'Total Sessions Used',
                  '$totalSessions',
                  totalSessions > 0 ? 1.0 : 0.0,
                  Color(0xFF4ECDC4),
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  'This Week',
                  '$thisWeekSessions sessions',
                  thisWeekSessions > 0 ? 1.0 : 0.0,
                  Color(0xFF96CEB4),
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  'This Month',
                  '$thisMonthSessions sessions',
                  thisMonthSessions > 0 ? 1.0 : 0.0,
                  Color(0xFFFF6B35),
                ),
                SizedBox(height: 12),
                _buildProgressItem(
                  'Subscription Status',
                  member.status ?? 'Unknown',
                  member.status == 'active' ? 1.0 : 0.5,
                  member.status == 'active' ? Color(0xFF10B981) : Color(0xFFFF6B35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getThisWeekSessions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(Duration(days: 6));
    
    return sessionHistory.where((session) {
      final sessionDate = DateTime.tryParse(session['usage_date'] ?? '');
      if (sessionDate == null) return false;
      return sessionDate.isAfter(weekStart.subtract(Duration(days: 1))) && 
             sessionDate.isBefore(weekEnd.add(Duration(days: 1)));
    }).length;
  }

  int _getThisMonthSessions() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    return sessionHistory.where((session) {
      final sessionDate = DateTime.tryParse(session['usage_date'] ?? '');
      if (sessionDate == null) return false;
      return sessionDate.isAfter(monthStart.subtract(Duration(days: 1))) && 
             sessionDate.isBefore(monthEnd.add(Duration(days: 1)));
    }).length;
  }

  Widget _buildProgressItem(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildRoutinesSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF96CEB4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt, color: Color(0xFF96CEB4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Member Routines',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (memberRoutines.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.list_alt_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No routines assigned to ${(currentMember ?? widget.selectedMember).fname}',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...memberRoutines.take(5).map((routine) => _buildRoutineItem(routine)).toList(),
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF96CEB4).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF96CEB4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine['routine_name'] ?? routine['goal'] ?? 'Untitled Routine',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Created: ${_formatDate(routine['created_at'])}',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF96CEB4),
                    fontSize: 12,
                  ),
                ),
                if (routine['completion_rate'] != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Progress: ${routine['completion_rate']}%',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF96CEB4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              routine['difficulty'] ?? 'Beginner',
              style: GoogleFonts.poppins(
                color: Color(0xFF96CEB4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildBodyWeightSection() {
    final profileDetails = monitoringData['profileDetails'] ?? {};
    final heightCm = _parseDouble(profileDetails['height_cm']) ?? 0.0;
    final weightKg = _parseDouble(profileDetails['weight_kg']) ?? 0.0;
    final targetWeight = _parseDouble(profileDetails['target_weight']) ?? 0.0;
    final weightProgress = List<Map<String, dynamic>>.from(monitoringData['progressOverTime']?['weight_progress'] ?? []);
    
    double bmi = 0.0;
    String bmiCategory = 'Unknown';
    Color bmiColor = Colors.grey;
    
    if (heightCm > 0 && weightKg > 0) {
      final heightM = heightCm / 100;
      bmi = weightKg / (heightM * heightM);
      
      if (bmi < 18.5) {
        bmiCategory = 'Underweight';
        bmiColor = Color(0xFF4ECDC4);
      } else if (bmi >= 18.5 && bmi < 25) {
        bmiCategory = 'Normal';
        bmiColor = Color(0xFF10B981);
      } else if (bmi >= 25 && bmi < 30) {
        bmiCategory = 'Overweight';
        bmiColor = Color(0xFFFF6B35);
      } else {
        bmiCategory = 'Obese';
        bmiColor = Color(0xFFEF4444);
      }
    }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.monitor_weight, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Body Weight & BMI',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (heightCm > 0 && weightKg > 0) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Current Weight',
                    '${weightKg.toStringAsFixed(1)} kg',
                    'Latest',
                    Color(0xFF4ECDC4),
                    Icons.fitness_center,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'BMI',
                    bmi.toStringAsFixed(1),
                    bmiCategory,
                    bmiColor,
                    Icons.speed,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Height',
                    '${heightCm.toStringAsFixed(0)} cm',
                    'Current',
                    Color(0xFF96CEB4),
                    Icons.height,
                  ),
                ),
              ],
            ),
            if (targetWeight > 0) ...[
              SizedBox(height: 16),
              _buildWeightProgressCard(weightKg, targetWeight),
            ],
            if (weightProgress.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildWeightChart(weightProgress),
            ],
          ] else
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Body weight data not available. Member needs to complete profile.',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
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
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightProgressCard(double currentWeight, double targetWeight) {
    final progress = targetWeight > currentWeight 
        ? (currentWeight / targetWeight).clamp(0.0, 1.0)
        : (targetWeight / currentWeight).clamp(0.0, 1.0);
    final weightDiff = (targetWeight - currentWeight).abs();
    final isGaining = targetWeight > currentWeight;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${weightDiff.toStringAsFixed(1)} kg ${isGaining ? 'to gain' : 'to lose'}',
                style: GoogleFonts.poppins(
                  color: isGaining ? Color(0xFF10B981) : Color(0xFFFF6B35),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation(
              isGaining ? Color(0xFF10B981) : Color(0xFFFF6B35),
            ),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> weightProgress) {
    if (weightProgress.isEmpty) return SizedBox.shrink();

    // Get the last 7 data points for the chart
    final chartData = weightProgress.length > 7 ? weightProgress.sublist(weightProgress.length - 7) : weightProgress;
    final maxValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Progress Over Time',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((point) {
                final value = _parseDouble(point['value']) ?? 0.0;
                final date = point['date'] ?? '';
                final height = (valueRange > 0 ? ((value - minValue) / valueRange * 60) + 10 : 10).toDouble();
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: height,
                      decoration: BoxDecoration(
                        color: Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatChartDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(0)}kg',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAttendanceSection() {
    final attendanceData = monitoringData['attendance'] ?? {};
    final totalCheckIns = _parseInt(attendanceData['total_checkins']) ?? 0;
    final thisWeekCheckIns = _parseInt(attendanceData['this_week_checkins']) ?? 0;
    final thisMonthCheckIns = _parseInt(attendanceData['this_month_checkins']) ?? 0;
    final attendanceStreak = _parseInt(attendanceData['current_streak']) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceDetailPage(
              member: currentMember!,
              attendanceData: attendanceData,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.calendar_today, color: Color(0xFF4ECDC4), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Attendance',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Color(0xFF4ECDC4), size: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalistCard('Total', '$totalCheckIns', Color(0xFF4ECDC4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('This Week', '$thisWeekCheckIns', Color(0xFF96CEB4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('This Month', '$thisMonthCheckIns', Color(0xFFFF6B35)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Streak', '$attendanceStreak', Color(0xFFFFD93D)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalistCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAttendanceChart(List<Map<String, dynamic>> weeklyData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF96CEB4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Attendance Pattern',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weeklyData.map((day) {
              final dayName = day['day'] ?? '';
              final checkIns = _parseInt(day['checkins']) ?? 0;
              final maxCheckIns = weeklyData.map((d) => _parseInt(d['checkins']) ?? 0).reduce((a, b) => a > b ? a : b);
              final height = maxCheckIns > 0 ? (checkIns / maxCheckIns) * 40.0 : 0.0;
              
              return Column(
                children: [
                  Container(
                    width: 20,
                    height: height,
                    decoration: BoxDecoration(
                      color: checkIns > 0 ? Color(0xFF96CEB4) : Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    dayName.substring(0, 3),
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '$checkIns',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLastCheckInCard(dynamic lastCheckIn) {
    // Handle case where lastCheckIn is false or null
    if (lastCheckIn == null || lastCheckIn == false || lastCheckIn is! Map) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF4ECDC4), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Check-in',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'No check-in data available',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    final checkInTime = lastCheckIn['check_in'] ?? '';
    final checkOutTime = lastCheckIn['check_out'] ?? '';
    final duration = _calculateDuration(checkInTime, checkOutTime);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, color: Color(0xFF4ECDC4), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Visit',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDateTime(checkInTime),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                if (duration.isNotEmpty)
                  Text(
                    'Duration: $duration',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF4ECDC4),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(String checkIn, String checkOut) {
    if (checkIn.isEmpty || checkOut.isEmpty) return '';
    
    try {
      final checkInTime = DateTime.parse(checkIn);
      final checkOutTime = DateTime.parse(checkOut);
      final duration = checkOutTime.difference(checkInTime);
      
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildWorkoutStatsSection() {
    final workoutData = monitoringData['workoutLogs'] ?? {};
    final totalWorkouts = _parseInt(workoutData['total_workouts']) ?? 0;
    final totalSets = _parseInt(workoutData['total_sets']) ?? 0;
    final totalReps = _parseInt(workoutData['total_reps']) ?? 0;
    final totalWeight = _parseDouble(workoutData['total_weight']) ?? 0.0;
    final thisWeekWorkouts = _parseInt(workoutData['this_week_workouts']) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutLogsDetailPage(
              member: currentMember!,
              workoutData: workoutData,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3)),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fitness_center, color: Color(0xFFFF6B35), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Workout Logs',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Color(0xFFFF6B35), size: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalistCard('Total Workouts', '$totalWorkouts', Color(0xFFFF6B35)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('This Week', '$thisWeekWorkouts', Color(0xFF4ECDC4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Total Sets', '$totalSets', Color(0xFF96CEB4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Total Reps', '$totalReps', Color(0xFF10B981)),
                ),
              ],
            ),
            if (totalWeight > 0) ...[
              SizedBox(height: 12),
              _buildMinimalistCard('Total Weight', '${totalWeight.toStringAsFixed(1)} kg', Color(0xFFFFD93D)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutMetric(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalWeightCard(double totalWeight) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFF6B35).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.scale, color: Color(0xFFFF6B35), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Weight Lifted',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${totalWeight.toStringAsFixed(0)} kg',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMuscleGroupsCard(List<Map<String, dynamic>> topMuscleGroups) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Muscle Groups This Week',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          ...topMuscleGroups.take(3).map((muscle) => _buildMuscleGroupItem(muscle)).toList(),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupItem(Map<String, dynamic> muscle) {
    final muscleName = muscle['muscle_group'] ?? 'Unknown';
    final exerciseCount = muscle['exercise_count'] ?? 0;
    final totalReps = muscle['total_reps'] ?? 0;
    final workoutSessions = muscle['workout_sessions'] ?? 0;
    final color = _getMuscleGroupColor(muscleName);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _getMuscleGroupIcon(muscleName),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscleName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$exerciseCount exercises • $workoutSessions sessions',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalReps',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'reps',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMuscleGroupColor(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Color(0xFF4ECDC4);
      case 'back':
        return Color(0xFF96CEB4);
      case 'shoulders':
        return Color(0xFFFF6B35);
      case 'biceps':
        return Color(0xFF45B7D1);
      case 'triceps':
        return Color(0xFF9B59B6);
      case 'legs':
        return Color(0xFFE74C3C);
      case 'glutes':
        return Color(0xFFF39C12);
      case 'abs':
        return Color(0xFF2ECC71);
      case 'forearms':
        return Color(0xFF34495E);
      case 'calves':
        return Color(0xFFE67E22);
      default:
        return Color(0xFF95A5A6);
    }
  }

  String _getMuscleGroupIcon(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return '💪';
      case 'back':
        return '🦾';
      case 'shoulders':
        return '🏋️';
      case 'biceps':
        return '💪';
      case 'triceps':
        return '🦾';
      case 'legs':
        return '🦵';
      case 'glutes':
        return '🍑';
      case 'abs':
        return '🔥';
      case 'forearms':
        return '🤏';
      case 'calves':
        return '🦶';
      default:
        return '💪';
    }
  }

  Widget _buildRecentWorkoutsCard(List<Map<String, dynamic>> recentWorkouts) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Workouts',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          ...recentWorkouts.take(3).map((workout) => _buildRecentWorkoutItem(workout)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutItem(Map<String, dynamic> workout) {
    final date = workout['log_date'] ?? '';
    final sets = _parseInt(workout['actual_sets']) ?? 0;
    final reps = _parseInt(workout['actual_reps']) ?? 0;
    final weight = _parseDouble(workout['total_kg']) ?? 0.0;
    final exerciseName = workout['exercise_name'] ?? 'Unknown Exercise';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sets sets × $reps reps',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (weight > 0)
                Text(
                  '${weight.toStringAsFixed(0)} kg',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalRecordsSection() {
    final personalRecords = monitoringData['personalRecords'] ?? {};
    final records = List<Map<String, dynamic>>.from(personalRecords['records'] ?? []);
    final totalRecords = records.length;

    // Calculate recent records (last 30 days)
    final recentRecords = records.where((record) {
      final date = record['achieved_date'];
      if (date == null) return false;
      try {
        final recordDate = DateTime.parse(date);
        final now = DateTime.now();
        return now.difference(recordDate).inDays <= 30;
      } catch (e) {
        return false;
      }
    }).length;

    // Find the heaviest lift
    final heaviestLift = records.fold<double>(0, (max, record) {
      final weight = _parseDouble(record['max_weight']) ?? 0.0;
      return weight > max ? weight : max;
    });

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalRecordsDetailPage(
              member: currentMember!,
              personalRecordsData: personalRecords,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.emoji_events, color: Color(0xFF10B981), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Personal Records',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Color(0xFF10B981), size: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalistCard('Total PRs', '$totalRecords', Color(0xFF10B981)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Recent PRs', '$recentRecords', Color(0xFF4ECDC4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Heaviest Lift', '${heaviestLift.toStringAsFixed(1)} kg', Color(0xFFFF6B35)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecordItem(Map<String, dynamic> record) {
    final exerciseName = record['exercise_name'] ?? 'Unknown Exercise';
    final weight = _parseDouble(record['max_weight']) ?? 0.0;
    final reps = _parseInt(record['max_reps']) ?? 0;
    final date = record['achieved_date'] ?? '';
    final recordType = record['record_type'] ?? 'PR';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(date),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recordType,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${weight.toStringAsFixed(1)} kg',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (reps > 0)
                Text(
                  '× $reps reps',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection() {
    final goalsData = monitoringData['fitnessGoals'] ?? {};
    final goals = List<Map<String, dynamic>>.from(goalsData['goals'] ?? []);
    final completedGoals = goals.where((goal) => goal['is_achieved'] == true).length;
    final totalGoals = goals.length;
    final progressPercentage = totalGoals > 0 ? (completedGoals / totalGoals * 100).round() : 0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flag, color: Color(0xFF8B5CF6), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Fitness Goals Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedGoals/$totalGoals',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF8B5CF6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (totalGoals > 0) ...[
            _buildGoalsProgressCard(completedGoals, totalGoals, progressPercentage),
            SizedBox(height: 16),
          ],
          if (goals.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No fitness goals set yet',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                  Text(
                    'Help your member set their fitness goals!',
                    style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...goals.take(5).map((goal) => _buildGoalItem(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalsProgressCard(int completedGoals, int totalGoals, int progressPercentage) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$progressPercentage%',
                style: GoogleFonts.poppins(
                  color: Color(0xFF8B5CF6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            minHeight: 6,
          ),
          SizedBox(height: 8),
          Text(
            '$completedGoals of $totalGoals goals completed',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    final goalName = goal['goal_name'] ?? 'Unknown Goal';
    final isAchieved = goal['is_achieved'] == true;
    final createdAt = goal['created_at'] ?? '';
    final achievedAt = goal['achieved_at'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAchieved 
              ? Color(0xFF10B981).withOpacity(0.3)
              : Color(0xFF8B5CF6).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isAchieved ? Color(0xFF10B981) : Color(0xFF8B5CF6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Set: ${_formatDate(createdAt)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                if (isAchieved && achievedAt != null)
                  Text(
                    'Achieved: ${_formatDate(achievedAt)}',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAchieved 
                  ? Color(0xFF10B981).withOpacity(0.2)
                  : Color(0xFF8B5CF6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isAchieved ? Color(0xFF10B981) : Color(0xFF8B5CF6),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  isAchieved ? 'Achieved' : 'In Progress',
                  style: GoogleFonts.poppins(
                    color: isAchieved ? Color(0xFF10B981) : Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverTimeSection() {
    final progressData = monitoringData['progressOverTime'] ?? {};
    final weightProgress = List<Map<String, dynamic>>.from(progressData['weight_progress'] ?? []);
    final strengthProgress = List<Map<String, dynamic>>.from(progressData['strength_progress'] ?? []);
    final attendanceProgress = List<Map<String, dynamic>>.from(progressData['attendance_progress'] ?? []);
    final volumeProgress = List<Map<String, dynamic>>.from(progressData['volume_progress'] ?? []);
    final complianceProgress = List<Map<String, dynamic>>.from(progressData['compliance_progress'] ?? []);

    // Calculate trends
    final weightTrend = _calculateProgressTrend(weightProgress);
    final strengthTrend = _calculateProgressTrend(strengthProgress);
    final attendanceTrend = _calculateProgressTrend(attendanceProgress);
    final volumeTrend = _calculateProgressTrend(volumeProgress);
    final complianceTrend = _calculateProgressTrend(complianceProgress);

    final totalDataPoints = weightProgress.length + strengthProgress.length + attendanceProgress.length + volumeProgress.length + complianceProgress.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgressOverTimeDetailPage(
              member: currentMember!,
              progressData: progressData,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF06B6D4).withOpacity(0.3)),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF06B6D4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.trending_up, color: Color(0xFF06B6D4), size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Progress Over Time',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Color(0xFF06B6D4), size: 16),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMinimalistCard('Weight', weightTrend, Color(0xFF4ECDC4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Strength', strengthTrend, Color(0xFFFF6B35)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Attendance', attendanceTrend, Color(0xFF96CEB4)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMinimalistCard('Volume', volumeTrend, Color(0xFF10B981)),
                ),
              ],
            ),
            if (totalDataPoints > 0) ...[
              SizedBox(height: 12),
              _buildMinimalistCard('Data Points', '$totalDataPoints', Color(0xFF06B6D4)),
            ],
          ],
        ),
      ),
    );
  }

  String _calculateProgressTrend(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 'No Data';
    
    final firstValue = _parseDouble(data.first['value']) ?? 0.0;
    final lastValue = _parseDouble(data.last['value']) ?? 0.0;
    final change = lastValue - firstValue;
    final percentage = firstValue > 0 ? (change / firstValue * 100) : 0;
    
    if (percentage > 5) return '↗️ +${percentage.toStringAsFixed(0)}%';
    if (percentage < -5) return '↘️ ${percentage.toStringAsFixed(0)}%';
    return '➡️ Stable';
  }

  Widget _buildProgressChart(String title, List<Map<String, dynamic>> data, Color color, String unit) {
    if (data.isEmpty) return SizedBox.shrink();

    // Get the last 7 data points for the chart
    final chartData = data.length > 7 ? data.sublist(data.length - 7) : data;
    final maxValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((d) => _parseDouble(d['value']) ?? 0.0).reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;
    
    print('🔍 PROGRESS CHART: Chart data: $chartData');
    print('🔍 PROGRESS CHART: Max value: $maxValue, Min value: $minValue, Range: $valueRange');

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.map((point) {
                final value = _parseDouble(point['value']) ?? 0.0;
                final date = point['date'] ?? '';
                final height = (valueRange > 0 ? ((value - minValue) / valueRange * 60) + 10 : 10).toDouble();
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatChartDate(date),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(0)}$unit',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatChartDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildSessionHistory() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF45B7D1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.history, color: Color(0xFF45B7D1), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Session History',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (sessionHistory.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.history_outlined, color: Colors.grey[600], size: 32),
                  SizedBox(height: 8),
                  Text(
                    'No session history found',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...sessionHistory.take(10).map((session) => _buildSessionHistoryItem(session)).toList(),
        ],
      ),
    );
  }

  Widget _buildSessionHistoryItem(Map<String, dynamic> session) {
    final usageDate = session['usage_date'] ?? '';
    final createdAt = session['created_at'] ?? '';
    final remainingSessions = session['remaining_sessions'] ?? 0;
    final rateType = session['rate_type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF45B7D1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF45B7D1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Color(0xFF45B7D1),
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Used',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Date: $usageDate',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Time: ${_formatTime(createdAt)}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Remaining: $remainingSessions sessions',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF45B7D1),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFF45B7D1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rateType.toUpperCase(),
              style: GoogleFonts.poppins(
                color: Color(0xFF45B7D1),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
