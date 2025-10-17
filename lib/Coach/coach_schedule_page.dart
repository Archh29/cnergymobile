import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/member_model.dart';
import '../User/models/schedule_model.dart';

class CoachSchedulePage extends StatefulWidget {
  final MemberModel selectedMember;

  const CoachSchedulePage({Key? key, required this.selectedMember}) : super(key: key);

  @override
  _CoachSchedulePageState createState() => _CoachSchedulePageState();
}

class _CoachSchedulePageState extends State<CoachSchedulePage>
    with TickerProviderStateMixin {
  List<ScheduleModel> weeklySchedule = [];
  List<ProgramForScheduling> programs = [];
  bool isLoading = true;
  String? errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMemberSchedule();
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

  Future<void> _loadMemberSchedule() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get current coach ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final coachId = prefs.getInt('user_id');
      
      if (coachId == null) {
        throw Exception('Coach not logged in');
      }

      // Load member's weekly schedule using coach API
      final scheduleResponse = await http.get(
        Uri.parse('https://api.cnergy.site/routines.php?action=get_member_schedule&user_id=${widget.selectedMember.id}&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (scheduleResponse.statusCode == 200) {
        final scheduleData = json.decode(scheduleResponse.body);
        if (scheduleData['success'] == true) {
          setState(() {
            weeklySchedule = (scheduleData['schedule'] as List)
                .map((item) => ScheduleModel.fromJson(item))
                .toList();
          });
        } else {
          throw Exception(scheduleData['error'] ?? 'Failed to load schedule');
        }
      } else {
        throw Exception('HTTP ${scheduleResponse.statusCode}: ${scheduleResponse.body}');
      }

      // Load member's programs for context
      final programsResponse = await http.get(
        Uri.parse('https://api.cnergy.site/routines.php?action=get_programs_for_scheduling&user_id=${widget.selectedMember.id}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (programsResponse.statusCode == 200) {
        final programsData = json.decode(programsResponse.body);
        if (programsData['success'] == true) {
          setState(() {
            programs = (programsData['programs'] as List)
                .map((item) => ProgramForScheduling.fromJson(item))
                .toList();
          });
        }
      }

      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading schedule: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading
            ? _buildLoadingState()
            : errorMessage != null
                ? _buildErrorState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _loadMemberSchedule,
                      color: Color(0xFF4ECDC4),
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 12 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            SizedBox(height: 20),
                            _buildWeeklySchedule(),
                            SizedBox(height: 20),
                            _buildProgramsOverview(),
                          ],
                        ),
                      ),
                    ),
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
            'Loading ${widget.selectedMember.fullName}\'s schedule...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading schedule',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage ?? 'Unknown error',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMemberSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
              child: Icon(
                Icons.calendar_today,
                color: Color(0xFF4ECDC4),
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.selectedMember.fullName}\'s Schedule',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 18 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    'Weekly workout schedule overview',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklySchedule() {
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...daysOfWeek.map((day) => _buildDayCard(day)).toList(),
      ],
    );
  }

  Widget _buildDayCard(String day) {
    final daySchedule = weeklySchedule.firstWhere(
      (schedule) => schedule.dayOfWeek == day,
      orElse: () => ScheduleModel(dayOfWeek: day),
    );

    final isToday = _isToday(day);
    final isRestDay = daySchedule.isRestDay;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isToday 
            ? Color(0xFF4ECDC4).withOpacity(0.1)
            : Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: isToday 
            ? Border.all(color: Color(0xFF4ECDC4), width: 2)
            : Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          // Day indicator
          Container(
            width: isSmallScreen ? 50 : 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSmallScreen ? day.substring(0, 3) : day,
                  style: GoogleFonts.poppins(
                    color: isToday ? Color(0xFF4ECDC4) : Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isToday)
                  Text(
                    'Today',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF4ECDC4),
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 16),
          // Workout details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRestDay) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.bed_outlined,
                        color: Colors.grey[400],
                        size: isSmallScreen ? 16 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          'Rest Day',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Take a well-deserved break',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (daySchedule.workoutName != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Color(0xFF4ECDC4),
                        size: isSmallScreen ? 16 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          daySchedule.workoutName!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  if (daySchedule.workoutDuration != null)
                    Text(
                      '${daySchedule.workoutDuration} minutes',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (daySchedule.scheduledTime != null)
                    Text(
                      'Scheduled at ${_formatTime(daySchedule.scheduledTime!)}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey[500],
                        size: isSmallScreen ? 16 : 20,
                      ),
                      SizedBox(width: isSmallScreen ? 6 : 8),
                      Expanded(
                        child: Text(
                          'No workout scheduled',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Tap to schedule a workout',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8, 
              vertical: isSmallScreen ? 3 : 4
            ),
            decoration: BoxDecoration(
              color: isRestDay 
                  ? Colors.grey[700]
                  : isToday
                      ? Color(0xFF4ECDC4)
                      : Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
            ),
            child: Text(
              isRestDay ? 'Rest' : 'Workout',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsOverview() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Programs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (programs.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF2A2A2A)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    color: Colors.grey[500],
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No programs available',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Create programs in the Routines tab',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...programs.map((program) => _buildProgramCard(program)).toList(),
      ],
    );
  }

  Widget _buildProgramCard(ProgramForScheduling program) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  program.goal,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: isSmallScreen ? 3 : 4
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
                ),
                child: Text(
                  program.difficulty,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            '${program.totalWorkouts} workouts available',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          if (program.workouts.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            Wrap(
              spacing: isSmallScreen ? 4 : 8,
              runSpacing: isSmallScreen ? 4 : 8,
              children: program.workouts.take(isSmallScreen ? 2 : 3).map((workout) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8, 
                  vertical: isSmallScreen ? 3 : 4
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 4 : 6),
                ),
                child: Text(
                  workout.name,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
            ),
            if (program.workouts.length > (isSmallScreen ? 2 : 3))
              Padding(
                padding: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
                child: Text(
                  '+${program.workouts.length - (isSmallScreen ? 2 : 3)} more workouts',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final today = now.weekday;
    final dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return dayMap[day] == today;
  }

  String _formatTime(String timeString) {
    try {
      final time = timeString.split(':');
      final hour = int.parse(time[0]);
      final minute = time[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return timeString;
    }
  }
}
