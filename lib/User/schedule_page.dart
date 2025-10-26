import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/schedule_model.dart';
import './services/schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<ProgramForScheduling> _programs = [];
  Map<String, ScheduleModel> _currentSchedule = {};
  ProgramForScheduling? _selectedProgram;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final programs = await ScheduleService.getProgramsForScheduling();
      
      setState(() {
        _programs = programs;
        _isLoading = false;
        if (programs.isNotEmpty) {
          // Auto-select the most recent program (first in list)
          _selectedProgram = programs.first;
          _loadScheduleForProgram(_selectedProgram!.programId);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadScheduleForProgram(int programId) async {
    try {
      final schedule = await ScheduleService.getSchedule(programId);
      setState(() {
        _currentSchedule = schedule.isNotEmpty ? schedule : ScheduleService.createEmptySchedule();
      });
    } catch (e) {
      // If no schedule exists, create empty one
      setState(() {
        _currentSchedule = ScheduleService.createEmptySchedule();
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_selectedProgram == null) return;

    try {
      final scheduleData = ScheduleService.formatScheduleForApi(_currentSchedule);
      await ScheduleService.createSchedule(_selectedProgram!.programId, scheduleData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Schedule updated!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Color(0xFF4ECDC4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save schedule: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Color(0xFFFF6B35),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _assignWorkoutToDay(String day, WorkoutForScheduling workout) {
    setState(() {
      _currentSchedule[day] = _currentSchedule[day]!.copyWith(
        workoutId: workout.workoutId,
        workoutName: workout.name,
        workoutDuration: workout.duration,
        isRestDay: false,
      );
    });
    // Auto-save when workout is assigned
    _saveSchedule();
  }

  void _setRestDay(String day) {
    setState(() {
      _currentSchedule[day] = _currentSchedule[day]!.copyWith(
        workoutId: null,
        workoutName: null,
        workoutDuration: null,
        isRestDay: true,
        scheduledTime: null,
      );
    });
    // Auto-save when rest day is set
    _saveSchedule();
  }

  void _setScheduledTime(String day, TimeOfDay time) {
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
    setState(() {
      _currentSchedule[day] = _currentSchedule[day]!.copyWith(
        scheduledTime: timeString,
      );
    });
    // Auto-save when time is set
    _saveSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375 || screenHeight < 667;
    
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            )
          : _errorMessage != null
              ? _buildErrorWidget(isSmallScreen)
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 10),
                      if (_programs.isNotEmpty) ...[
                        _buildHeader(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 24),
                        _buildWeeklySchedule(isSmallScreen),
                      ] else
                        _buildNoProgramsWidget(isSmallScreen),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Plan your workout week',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }


  Widget _buildErrorWidget(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isSmallScreen ? 60 : 80,
            color: Color(0xFFFF6B35),
          ),
          SizedBox(height: 20),
          Text(
            'Error Loading Programs',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPrograms,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule(bool isSmallScreen) {
    if (_selectedProgram == null) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Weekly Plan',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 16 : 20),
        ...(_weekDays.map((day) => _buildDayCard(day, isSmallScreen)).toList()),
      ],
    );
  }

  Widget _buildDayCard(String day, bool isSmallScreen) {
    final schedule = _currentSchedule[day];
    final isToday = day == _getTodayName();
    final hasWorkout = schedule?.workoutId != null;
    
    return GestureDetector(
      onTap: () => _showWorkoutSelector(day),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          border: Border.all(
            color: isToday 
              ? Color(0xFF4ECDC4)
              : (hasWorkout ? Color(0xFF96CEB4).withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
            width: isToday ? 2 : 1,
          ),
          boxShadow: isToday ? [
            BoxShadow(
              color: Color(0xFF4ECDC4).withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Day indicator
            Container(
              width: isSmallScreen ? 60 : 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.poppins(
                      color: isToday ? Color(0xFF4ECDC4) : Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isToday)
                    Text(
                      'Today',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 16),
            // Workout info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasWorkout 
                      ? schedule!.workoutName ?? 'Workout'
                      : 'Rest Day',
                    style: GoogleFonts.poppins(
                      color: hasWorkout ? Colors.white : Colors.grey[400],
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasWorkout && schedule?.scheduledTime != null)
                    Text(
                      'at ${_formatTime(schedule!.scheduledTime!)}',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF96CEB4),
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  Text(
                    'Tap to ${hasWorkout ? 'change' : 'add workout'}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: isSmallScreen ? 11 : 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Status icon
            Icon(
              hasWorkout 
                ? Icons.fitness_center
                : Icons.bed_outlined,
              color: hasWorkout ? Color(0xFF96CEB4) : Colors.grey[400],
              size: isSmallScreen ? 24 : 28,
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: isSmallScreen ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkoutSelector(String day) async {
    // Get current user ID to properly categorize programs
    final currentUserId = await ScheduleService.getCurrentUserId();
    
    // Separate workouts by program type
    List<WorkoutForScheduling> myWorkouts = [];
    List<WorkoutForScheduling> coachWorkouts = [];
    
    for (var program in _programs) {
      // Apply same logic as backend:
      // - Admin programs (type 3): always accessible (treat as coach programs for UI)
      // - Coach programs (type 4): if created by current user, treat as user programs
      // - User programs (null/0): always user programs
      
      bool isCoachProgram = false;
      
      if (program.createdByTypeId == 3) {
        // Admin programs - show in coach section
        isCoachProgram = true;
      } else if (program.createdByTypeId == 4) {
        // Coach programs - check if created by current user
        if (program.createdBy != null && int.tryParse(program.createdBy!) == currentUserId) {
          // Created by current user - treat as user program
          isCoachProgram = false;
        } else {
          // Created by different coach - treat as coach program
          isCoachProgram = true;
        }
      } else {
        // User programs (null or other types)
        isCoachProgram = false;
      }
      
      if (isCoachProgram) {
        coachWorkouts.addAll(program.workouts);
      } else {
        myWorkouts.addAll(program.workouts);
      }
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
                      onTap: () {
                        _setRestDay(day);
                        Navigator.pop(context);
                      },
                    ),
                    
                    Divider(color: Colors.grey[700]),
                    
                    // Show message if no workouts at all
                    if (myWorkouts.isEmpty && coachWorkouts.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No workouts available. Create a program first.',
                          style: GoogleFonts.poppins(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      // My Programs Section
                      if (myWorkouts.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Color(0xFF4ECDC4), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'My Programs',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF4ECDC4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...myWorkouts.map((workout) => ListTile(
                          leading: Icon(Icons.fitness_center, color: Color(0xFF96CEB4)),
                          title: Text(
                            workout.name,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: workout.duration != null 
                            ? Text(
                                '${workout.duration} minutes',
                                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                              )
                            : null,
                          onTap: () {
                            _assignWorkoutToDay(day, workout);
                            Navigator.pop(context);
                            _showTimeSelector(day);
                          },
                        )),
                      ],
                      
                      // Coach Programs Section
                      if (coachWorkouts.isNotEmpty) ...[
                        if (myWorkouts.isNotEmpty)
                          Divider(color: Colors.grey[700], height: 32),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: Color(0xFFFFB74D), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Coach Programs',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFFFFB74D),
                                  fontSize: 16,
            fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...coachWorkouts.map((workout) => ListTile(
                          leading: Icon(Icons.fitness_center, color: Color(0xFFFFB74D)),
                          title: Text(
                            workout.name,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          subtitle: workout.duration != null 
                            ? Text(
                                '${workout.duration} minutes',
                                style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
                              )
                            : null,
                          onTap: () {
                            _assignWorkoutToDay(day, workout);
                            Navigator.pop(context);
                            _showTimeSelector(day);
                          },
                        )),
                      ],
                    ],
                    
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
    final currentSchedule = _currentSchedule[day];
    TimeOfDay initialTime = TimeOfDay(hour: 9, minute: 0);
    
    if (currentSchedule?.scheduledTime != null) {
      final timeParts = currentSchedule!.scheduledTime!.split(':');
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

  Widget _buildNoProgramsWidget(bool isSmallScreen) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
            Icons.fitness_center_outlined,
            size: isSmallScreen ? 60 : 80,
              color: Colors.grey[600],
            ),
            SizedBox(height: 20),
            Text(
            'No Programs Found',
              style: GoogleFonts.poppins(
                color: Colors.white,
              fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
            'Create a workout program first to schedule it.',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: isSmallScreen ? 14 : 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to Programs tab (index 1)
              DefaultTabController.of(context)?.animateTo(1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Go to Programs',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getTodayName() {
    final today = DateTime.now().weekday;
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[today - 1];
  }

  String _formatTime(String timeString) {
    try {
      final parts = timeString.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final time = TimeOfDay(hour: hour, minute: minute);
      return time.format(context);
    } catch (e) {
      return timeString;
    }
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
                      onPressed: () {
                        final selectedTime = TimeOfDay(hour: selectedHour, minute: selectedMinute);
                        _setScheduledTime(day, selectedTime);
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
}