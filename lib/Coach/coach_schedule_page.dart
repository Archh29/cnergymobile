import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/member_model.dart';
import '../User/models/schedule_model.dart';
import '../User/services/auth_service.dart';

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
      // Get current coach ID from AuthService (same fix as CoachService)
      final coachId = AuthService.getCurrentUserId();
      
      if (coachId == null || coachId == 0) {
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

      // Load member's programs for context (only coach-created programs for this user)
      final programsResponse = await http.get(
        Uri.parse('https://api.cnergy.site/routines.php?action=get_programs_for_scheduling&user_id=${widget.selectedMember.id}&coach_id=$coachId'),
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

    return GestureDetector(
      onTap: () => _showEditScheduleDialog(day, daySchedule),
      child: Container(
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
      ),
    );
  }

  Future<void> _showEditScheduleDialog(String day, ScheduleModel currentSchedule) async {
    // Use the same bottom sheet style as user schedule page
    _showWorkoutSelector(day, currentSchedule);
  }

  void _showWorkoutSelector(String day, ScheduleModel currentSchedule) {
    // Collect all workouts from all programs
    List<WorkoutForScheduling> allWorkouts = [];
    for (var program in programs) {
      allWorkouts.addAll(program.workouts);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Fixed Header
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Workout for $day',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Scrollable Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Rest Day Option
                    ListTile(
                      leading: Icon(Icons.bed_outlined, color: Colors.grey[400]),
                      title: Text(
                        'Rest Day',
                        style: GoogleFonts.poppins(color: Colors.grey[400]),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _saveSchedule(
                          day,
                          true, // isRestDay
                          null, // programId
                          null, // workoutId
                          null, // scheduledTime
                          '', // notes
                        );
                      },
                    ),
                    
                    Divider(color: Colors.grey[700]),
                    
                    // Show message if no workouts
                    if (allWorkouts.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No workouts available. Create a program first.',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      // All Workouts
                      ...allWorkouts.map((workout) {
                        // Find the program this workout belongs to
                        ProgramForScheduling? workoutProgram;
                        for (var program in programs) {
                          if (program.workouts.any((w) => w.workoutId == workout.workoutId)) {
                            workoutProgram = program;
                            break;
                          }
                        }
                        
                        return ListTile(
                          leading: Icon(Icons.fitness_center, color: Color(0xFF96CEB4)),
                          title: Text(
                            workout.name,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${workout.duration} minutes',
                                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                              ),
                              if (workoutProgram != null)
                                Text(
                                  workoutProgram.name,
                                  style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 11),
                                ),
                            ],
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            if (workoutProgram != null) {
                              await _saveSchedule(
                                day,
                                false, // isRestDay
                                workoutProgram.programId,
                                workout.workoutId,
                                '09:00:00', // default time
                                '', // notes
                              );
                              // Show time selector after saving workout
                              _showTimeSelector(day);
                            }
                          },
                        );
                      }),
                    
                    // Bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeSelector(String day) {
    // Get current scheduled time or default to 9:00 AM
    final currentSchedule = weeklySchedule.firstWhere(
      (s) => s.dayOfWeek == day,
      orElse: () => ScheduleModel(dayOfWeek: day),
    );
    TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
    
    if (currentSchedule.scheduledTime != null) {
      final timeParts = currentSchedule.scheduledTime!.split(':');
      if (timeParts.length >= 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 9,
          minute: int.tryParse(timeParts[1]) ?? 0,
        );
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => _buildModernTimePicker(day, initialTime, scrollController),
      ),
    );
  }

  Widget _buildModernTimePicker(String day, TimeOfDay initialTime, ScrollController scrollController) {
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;
    
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Set Time for $day',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    // Digital Time Display
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hour display
                          Text(
                            selectedHour.toString().padLeft(2, '0'),
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            ':',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // Minute display
                          Text(
                            selectedMinute.toString().padLeft(2, '0'),
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Time Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Hour Controls
                        _buildTimeControl(
                          'Hour',
                          selectedHour.toString().padLeft(2, '0'),
                          Color(0xFF4ECDC4),
                          () => setModalState(() {
                            selectedHour = (selectedHour + 1) % 24;
                          }),
                          () => setModalState(() {
                            selectedHour = selectedHour == 0 ? 23 : selectedHour - 1;
                          }),
                        ),
                        
                        // Minute Controls
                        _buildTimeControl(
                          'Minute',
                          selectedMinute.toString().padLeft(2, '0'),
                          Color(0xFF96CEB4),
                          () => setModalState(() {
                            selectedMinute = (selectedMinute + 15) % 60;
                          }),
                          () => setModalState(() {
                            selectedMinute = selectedMinute == 0 ? 45 : selectedMinute - 15;
                          }),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Quick Time Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildQuickTimeButton('6:00 AM', 6, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 6;
                            selectedMinute = 0;
                          });
                        }),
                        _buildQuickTimeButton('9:00 AM', 9, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 9;
                            selectedMinute = 0;
                          });
                        }),
                        _buildQuickTimeButton('12:00 PM', 12, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 12;
                            selectedMinute = 0;
                          });
                        }),
                        _buildQuickTimeButton('3:00 PM', 15, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 15;
                            selectedMinute = 0;
                          });
                        }),
                        _buildQuickTimeButton('6:00 PM', 18, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 18;
                            selectedMinute = 0;
                          });
                        }),
                        _buildQuickTimeButton('8:00 PM', 20, 0, selectedHour, selectedMinute, () {
                          setModalState(() {
                            selectedHour = 20;
                            selectedMinute = 0;
                          });
                        }),
                      ],
                    ),
                    
                    // Action Buttons
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[600]!),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final timeString = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}:00';
                                // Get current schedule to preserve workout selection
                                final currentSchedule = weeklySchedule.firstWhere(
                                  (s) => s.dayOfWeek == day,
                                  orElse: () => ScheduleModel(dayOfWeek: day),
                                );
                                await _saveSchedule(
                                  day,
                                  false, // isRestDay
                                  currentSchedule.programId,
                                  currentSchedule.workoutId,
                                  timeString,
                                  '', // notes
                                );
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4ECDC4),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Set Time',
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
                    
                    // Bottom padding for safe area
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeControl(String label, String value, Color color, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        // Up button
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.keyboard_arrow_up,
              color: color,
              size: 28,
            ),
          ),
        ),
        SizedBox(height: 8),
        // Down button
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: color,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickTimeButton(String label, int hour, int minute, int currentHour, int currentMinute, VoidCallback onTap) {
    final bool isSelected = currentHour == hour && currentMinute == minute;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? Color(0xFF4ECDC4).withOpacity(0.2)
            : Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
              ? Color(0xFF4ECDC4)
              : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected
              ? Color(0xFF4ECDC4)
              : Colors.grey[300],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _saveSchedule(
    String day,
    bool isRestDay,
    int? programId,
    int? workoutId,
    String? scheduledTime,
    String notes,
  ) async {
    try {
      final coachId = AuthService.getCurrentUserId();
      if (coachId == null || coachId == 0) {
        throw Exception('Coach not logged in');
      }

      // If no program selected, use the first available program
      int memberProgramId = programId ?? (programs.isNotEmpty ? programs.first.programId : 0);
      
      if (memberProgramId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please create a program first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Format time properly (HH:MM:SS)
      String formattedTime = scheduledTime ?? '09:00:00';
      if (formattedTime.length == 5) {
        formattedTime = '$formattedTime:00';
      }

      final response = await http.post(
        Uri.parse('https://api.cnergy.site/routines.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'action': 'coach_update_schedule',
          'user_id': widget.selectedMember.id,
          'coach_id': coachId,
          'member_program_id': memberProgramId,
          'day_of_week': day,
          'workout_id': isRestDay ? null : workoutId,
          'scheduled_time': isRestDay ? null : formattedTime,
          'is_rest_day': isRestDay,
          'notes': notes.isEmpty ? null : notes,
          'action_type': 'update',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Schedule updated successfully'),
              backgroundColor: Color(0xFF4ECDC4),
            ),
          );
          // Reload schedule
          await _loadMemberSchedule();
        } else {
          throw Exception(data['error'] ?? 'Failed to update schedule');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
