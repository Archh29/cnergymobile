import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './services/enhanced_progress_service.dart';
import './models/goal_model.dart';

class GoalsPage extends StatefulWidget {
  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<GoalModel> goals = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => isLoading = true);
    
    try {
      final fetchedGoals = await EnhancedProgressService.fetchUserGoals();
      if (mounted) {
        setState(() {
          goals = fetchedGoals;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading goals: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
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
          'My Goals',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: Colors.white),
            onPressed: _showAddGoalDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ))
          : Column(
              children: [
                _buildFilterTabs(),
                Expanded(child: _buildGoalsList()),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Row(
        children: [
          _buildFilterTab('all', 'All'),
          SizedBox(width: 12),
          _buildFilterTab('active', 'Active'),
          SizedBox(width: 12),
          _buildFilterTab('achieved', 'Achieved'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label) {
    final isSelected = selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = filter;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4ECDC4) : Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsList() {
    final filteredGoals = goals.where((goal) {
      switch (selectedFilter) {
        case 'active':
          return goal.status == GoalStatus.active;
        case 'achieved':
          return goal.status == GoalStatus.achieved;
        default:
          return true;
      }
    }).toList();

    if (filteredGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, color: Colors.grey[600], size: 64),
            SizedBox(height: 16),
            Text(
              goals.isEmpty ? 'No goals yet' : 'No ${selectedFilter} goals',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Set your first fitness goal!',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = filteredGoals[index];
        return _buildGoalCard(goal);
      },
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goal.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: goal.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  goal.status == GoalStatus.achieved 
                      ? Icons.check_circle_rounded 
                      : Icons.flag_rounded,
                  color: goal.statusColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.goal,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (goal.status == GoalStatus.active)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                  color: Color(0xFF2A2A2A),
                  onSelected: (value) => _handleGoalAction(value, goal),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                          SizedBox(width: 12),
                          Text('Mark Complete', style: GoogleFonts.poppins(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Cancel Goal', style: GoogleFonts.poppins(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.grey[400], size: 16),
              SizedBox(width: 8),
              Text(
                'Target: ${goal.formattedTargetDate}',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: goal.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.status.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: goal.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleGoalAction(String action, GoalModel goal) async {
    switch (action) {
      case 'complete':
        await _markGoalAchieved(goal);
        break;
      case 'cancel':
        await _cancelGoal(goal);
        break;
    }
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
      _loadGoals();
    }
  }

  Future<void> _cancelGoal(GoalModel goal) async {
    final success = await EnhancedProgressService.updateGoalStatus(
      goal.id!,
      GoalStatus.cancelled,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Goal cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadGoals();
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGoalDialog(
        onGoalAdded: () {
          _loadGoals();
        },
      ),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  final VoidCallback onGoalAdded;

  const _AddGoalDialog({Key? key, required this.onGoalAdded}) : super(key: key);

  @override
  _AddGoalDialogState createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final TextEditingController goalController = TextEditingController();
  DateTime? targetDate;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Add New Goal',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: goalController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Goal Description',
              labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
              filled: true,
              fillColor: Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Target Date (Optional)',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            subtitle: Text(
              targetDate != null 
                  ? '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                  : 'No target date set',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            trailing: Icon(Icons.calendar_today_rounded, color: Color(0xFF4ECDC4)),
            onTap: _selectDate,
          ),
        ],
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
          onPressed: isLoading ? null : _saveGoal,
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
                  'Save',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
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
    if (picked != null) {
      setState(() {
        targetDate = picked;
      });
    }
  }

  Future<void> _saveGoal() async {
    if (goalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a goal description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = await EnhancedProgressService.getCurrentUserId();
      final goal = GoalModel(
        userId: userId,
        goal: goalController.text.trim(),
        targetDate: targetDate,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
      );

      final success = await EnhancedProgressService.createGoal(goal);

      if (success) {
        Navigator.pop(context);
        widget.onGoalAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal added successfully!'),
            backgroundColor: Color(0xFF4ECDC4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add goal'),
            backgroundColor: Colors.red,
          ),
        );
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
