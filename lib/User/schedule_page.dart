import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/workout_session_model.dart';
import './models/program_detail_model.dart';
import './models/routine_with_creator.dart';
import './services/enhanced_progress_service.dart';

class SchedulePage extends StatefulWidget {
  final List<WorkoutSessionModel> workoutSessions;
  const SchedulePage({Key? key, required this.workoutSessions}) : super(key: key);

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<WorkoutSessionModel> scheduledWorkouts = [];
  Map<String, List<WorkoutSessionModel>> weeklySchedule = {};
  List<RoutineWithCreator> availableRoutines = [];
  bool isLoading = false;
  bool isLoadingRoutines = false;

  @override
  void initState() {
    super.initState();
    _loadScheduledWorkouts();
    _loadAvailableRoutines();
  }

  void _loadScheduledWorkouts() {
    setState(() {
      // Filter for future workouts and organize by day
      final now = DateTime.now();
      scheduledWorkouts = widget.workoutSessions
          .where((session) => session.sessionDate.isAfter(now))
          .toList()
        ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

      // Organize workouts by scheduled day
      weeklySchedule = {};
      for (String day in ProgramDetailModel.weekDays) {
        weeklySchedule[day] = widget.workoutSessions
            .where((session) => session.scheduledDay == day)
            .toList();
      }
    });
  }

  Future<void> _loadAvailableRoutines() async {
    setState(() => isLoadingRoutines = true);
    try {
      final userRoutines = await EnhancedProgressService.fetchUserRoutines();
      final coachRoutines = await EnhancedProgressService.fetchCoachRoutines();
      
      setState(() {
        availableRoutines = [
          ...userRoutines.map((routine) => RoutineWithCreator(
            routine: routine,
            creatorType: 'user',
          )),
          ...coachRoutines.map((routine) => RoutineWithCreator(
            routine: routine,
            creatorType: 'coach',
            creatorName: routine.createdBy != 'user' ? routine.createdBy : null,
          )),
        ];
      });
    } catch (e) {
      _showError('Failed to load routines: ${e.toString()}');
    } finally {
      setState(() => isLoadingRoutines = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Workout Schedule',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _showAddWorkoutDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyOverview(),
            SizedBox(height: 24),
            _buildWeeklySchedule(),
            SizedBox(height: 24),
            _buildUpcomingWorkouts(),
          ],
        ),
      ),
    );
  }

  // Keep all your existing build methods exactly the same
  Widget _buildWeeklyOverview() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildWeekDays(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeekDays() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        
    return List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dayName = ProgramDetailModel.getDayFromIndex(index);
      final hasScheduledWorkout = weeklySchedule[dayName]?.isNotEmpty ?? false;
      final hasWorkoutToday = widget.workoutSessions.any((session) =>
          session.sessionDate.day == date.day && 
          session.sessionDate.month == date.month &&
          session.sessionDate.year == date.year);
      final isToday = date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  
      return Column(
        children: [
          Text(
            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday
                  ? Color(0xFF4ECDC4)
                  : hasWorkoutToday
                      ? Color(0xFF96CEB4).withOpacity(0.8)
                      : hasScheduledWorkout
                          ? Color(0xFF96CEB4).withOpacity(0.3)
                          : Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: hasScheduledWorkout
                  ? Border.all(color: Color(0xFF96CEB4), width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: GoogleFonts.poppins(
                  color: isToday ? Colors.white : Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (hasScheduledWorkout)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFF96CEB4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildWeeklySchedule() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Schedule',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          ...ProgramDetailModel.weekDays.map((day) => _buildDaySchedule(day)).toList(),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final dayWorkouts = weeklySchedule[day] ?? [];
    final now = DateTime.now();
    final isToday = _isToday(day, now);
        
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? Color(0xFF4ECDC4).withOpacity(0.1) : Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Color(0xFF4ECDC4), width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Text(
              day.substring(0, 3),
              style: GoogleFonts.poppins(
                color: isToday ? Color(0xFF4ECDC4) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: dayWorkouts.isEmpty
                ? Text(
                    'Rest day',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dayWorkouts.map((workout) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        workout.focus ?? workout.programName ?? 'Workout',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
          ),
          if (dayWorkouts.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF96CEB4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${dayWorkouts.length}',
                style: GoogleFonts.poppins(
                  color: Color(0xFF96CEB4),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(String day, DateTime now) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayIndex = now.weekday - 1;
    return weekdays[todayIndex] == day;
  }

  Widget _buildUpcomingWorkouts() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Workouts',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          if (scheduledWorkouts.isEmpty)
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.schedule_rounded, color: Colors.grey[600], size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No scheduled workouts',
                    style: GoogleFonts.poppins(color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          else
            ...scheduledWorkouts.take(5).map((workout) => _buildWorkoutCard(workout)).toList(),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutSessionModel workout) {
    final color = Color(0xFF4ECDC4);
            
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutTitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatWorkoutDate(workout.sessionDate),
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                if (workout.scheduledDay != null)
                  Text(
                    '${workout.scheduledDay} • ${workout.nextWorkoutDay}',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
            color: Color(0xFF2A2A2A),
            onSelected: (value) => _handleWorkoutAction(value, workout),
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
    );
  }

  String _formatWorkoutDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
            
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';
            
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleWorkoutAction(String action, WorkoutSessionModel workout) {
    switch (action) {
      case 'edit':
        _showEditWorkoutDialog(workout);
        break;
      case 'delete':
        _deleteWorkout(workout);
        break;
    }
  }

  void _showAddWorkoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddWorkoutDialog(
        availableRoutines: availableRoutines,
        isLoadingRoutines: isLoadingRoutines,
        onWorkoutAdded: () {
          _loadScheduledWorkouts();
        },
        onRefreshRoutines: _loadAvailableRoutines,
      ),
    );
  }

  void _showEditWorkoutDialog(WorkoutSessionModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Workout',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Edit workout feature coming soon!',
          style: GoogleFonts.poppins(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteWorkout(WorkoutSessionModel workout) {
    setState(() {
      scheduledWorkouts.removeWhere((w) => w.id == workout.id);
    });
            
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Workout deleted'),
        backgroundColor: Color(0xFFE74C3C),
      ),
    );
  }
}

class _AddWorkoutDialog extends StatefulWidget {
  final List<RoutineWithCreator> availableRoutines;
  final bool isLoadingRoutines;
  final VoidCallback onWorkoutAdded;
  final VoidCallback onRefreshRoutines;

  const _AddWorkoutDialog({
    Key? key,
    required this.availableRoutines,
    required this.isLoadingRoutines,
    required this.onWorkoutAdded,
    required this.onRefreshRoutines,
  }) : super(key: key);

  @override
  _AddWorkoutDialogState createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<_AddWorkoutDialog> {
  String? selectedDay;
  RoutineWithCreator? selectedRoutine;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Text(
            'Schedule Workout',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          if (widget.isLoadingRoutines)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: Color(0xFF4ECDC4), size: 20),
              onPressed: widget.onRefreshRoutines,
              tooltip: 'Refresh routines',
            ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day Selection
            DropdownButtonFormField<String>(
              value: selectedDay,
              decoration: InputDecoration(
                labelText: 'Day of Week',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: Color(0xFF2A2A2A),
              items: ProgramDetailModel.weekDays.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(
                    day,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Routine Selection
            DropdownButtonFormField<RoutineWithCreator>(
              value: selectedRoutine,
              decoration: InputDecoration(
                labelText: 'Select Routine',
                labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                filled: true,
                fillColor: Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: selectedRoutine != null
                    ? Icon(
                        selectedRoutine!.creatorIcon,
                        color: selectedRoutine!.creatorColor,
                        size: 20,
                      )
                    : Icon(Icons.fitness_center, color: Colors.grey[400]),
              ),
              dropdownColor: Color(0xFF2A2A2A),
              isExpanded: true,
              items: widget.availableRoutines.map((routineWrapper) {
                return DropdownMenuItem(
                  value: routineWrapper,
                  child: Row(
                    children: [
                      Icon(
                        routineWrapper.creatorIcon,
                        color: routineWrapper.creatorColor,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              routineWrapper.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${routineWrapper.exercises} exercises • ${routineWrapper.duration} • ${routineWrapper.difficulty}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (routineWrapper.creatorType == 'coach')
                              Text(
                                'by ${routineWrapper.creatorName ?? 'Coach'}',
                                style: GoogleFonts.poppins(
                                  color: routineWrapper.creatorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoutine = value;
                });
              },
            ),
            SizedBox(height: 16),

            // Date Selection
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Workout Date',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                style: GoogleFonts.poppins(color: Colors.grey[400]),
              ),
              trailing: Icon(Icons.calendar_today_rounded, color: Color(0xFF4ECDC4)),
              onTap: _selectDate,
            ),

            // Routine Preview
            if (selectedRoutine != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedRoutine!.creatorColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          selectedRoutine!.creatorIcon,
                          color: selectedRoutine!.creatorColor,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Routine Preview',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      selectedRoutine!.goal,
                      style: GoogleFonts.poppins(
                        color: selectedRoutine!.creatorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selectedRoutine!.tags.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: selectedRoutine!.tags.take(3).map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedRoutine!.creatorColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.poppins(
                                color: selectedRoutine!.creatorColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveWorkout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4ECDC4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Schedule',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF4ECDC4),
              surface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (selectedDay == null || selectedRoutine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both day and routine'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      // Create workout session with selected routine
      final workoutSession = WorkoutSessionModel(
        memberProgramHdrId: 1, // You might need to get this from somewhere
        sessionDate: selectedDate,
        scheduledDay: selectedDay,
        focus: selectedRoutine!.goal,
        programName: selectedRoutine!.name,
        programGoal: selectedRoutine!.goal,
        notes: 'Scheduled from ${selectedRoutine!.creatorType} routine',
      );

      // Save to backend
      final success = await EnhancedProgressService.logWorkoutSession(workoutSession);
      
      if (success) {
        Navigator.pop(context);
        widget.onWorkoutAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedRoutine!.name} scheduled for $selectedDay!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        throw Exception('Failed to schedule workout');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
