import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import './models/routine.models.dart';
import './models/program_template_model.dart';
import './services/coach_service.dart';
import './services/routine_service.dart';
import './services/program_template_service.dart' as programservice;
import 'coach_client_selection_page.dart';
import 'coach_create_routine_page.dart';

class CoachRoutinePage extends StatefulWidget {
  final MemberModel? selectedMember;
  
  const CoachRoutinePage({
    Key? key,
    this.selectedMember,
  }) : super(key: key);

  @override
  _CoachRoutinePageState createState() => _CoachRoutinePageState();
}

class _CoachRoutinePageState extends State<CoachRoutinePage> with SingleTickerProviderStateMixin {
  List<MemberModel> assignedMembers = [];
  Map<int, List<RoutineModel>> memberRoutines = {};
  List<ProgramTemplateModel> programTemplates = [];
  List<Map<String, dynamic>> coachTemplates = [];
  bool isLoading = true;
  bool isLoadingTemplates = true;
  late TabController _tabController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _showFab = _tabController.index == 0;
      });
      // Load templates when switching to second tab
      if (_tabController.index == 1 && coachTemplates.isEmpty) {
        _loadCoachTemplates();
      }
    });
    _loadCoachData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoachTemplates() async {
    try {
      setState(() {
        isLoadingTemplates = true;
      });

      final templates = await RoutineService.getCoachTemplates('current_coach_id');
      
      setState(() {
        coachTemplates = templates;
        isLoadingTemplates = false;
      });
    } catch (e) {
      print('Error loading coach templates: $e');
      setState(() {
        isLoadingTemplates = false;
      });
    }
  }

  Future<void> _loadCoachData() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);
      
      // Load assigned members
      final members = await CoachService.getAssignedMembers();
      
      final templates = await programservice.ProgramTemplateService.getCoachProgramTemplates();
      
      // Load routines for each member
      Map<int, List<RoutineModel>> routines = {};
      for (var member in members) {
        try {
          final memberRoutines = await CoachService.getMemberRoutines(member.id);
          routines[member.id] = memberRoutines;
        } catch (e) {
          print('Error loading routines for member ${member.id}: $e');
          routines[member.id] = [];
        }
      }
      
      if (!mounted) return;
      setState(() {
        assignedMembers = members;
        memberRoutines = routines;
        programTemplates = templates;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showError('Failed to load coach data: ${e.toString()}');
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Color(0xFF0F0F0F),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFF4ECDC4),
              unselectedLabelColor: Colors.grey[400],
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Color(0xFF4ECDC4),
                  width: 3,
                ),
                insets: EdgeInsets.symmetric(horizontal: 20),
              ),
              tabs: [
                Tab(
                  child: Text(
                    "CLIENT ROUTINES",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    "TEMPLATES",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClientsTab(),
                _buildTemplatesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showFab
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44B7B8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _tabController.index == 0 
                    ? _navigateToClientSelection()
                    : _createNewTemplate(),
                label: Text(
                  _tabController.index == 0 ? "CREATE ROUTINE" : "CREATE TEMPLATE",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            )
          : null,
    );
  }

  Widget _buildClientsTab() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (assignedMembers.isEmpty) {
      return _buildEmptyClientsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignedMembers.length,
      itemBuilder: (context, index) {
        final member = assignedMembers[index];
        final routines = memberRoutines[member.id] ?? [];
        return _buildClientCard(member, routines);
      },
    );
  }

  Widget _buildEmptyClientsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No clients assigned yet',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Clients will appear here once they request you as their coach',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(MemberModel member, List<RoutineModel> routines) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        children: [
          // Client Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Client Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Color(0xFF4ECDC4).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: member.profileImage != null && member.profileImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: Image.network(
                            member.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  member.initials,
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF4ECDC4),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            member.initials,
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${routines.length} routine${routines.length != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: member.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: member.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _navigateToCreateRoutineForClient(member),
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF4ECDC4),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          
          // Routines List
          if (routines.isNotEmpty) ...[
            Divider(color: Colors.grey[800], height: 1),
            ...routines.map((routine) => _buildRoutineItem(routine, member)),
          ] else ...[
            Divider(color: Colors.grey[800], height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'No routines created yet',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutineItem(RoutineModel routine, MemberModel member) {
    final routineColor = _parseRoutineColor(routine.color);
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: routineColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: routineColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.fitness_center,
              color: routineColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${routine.exercises} exercises • ${routine.duration}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                if (routine.tags.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: routine.tags.take(2).map((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: routineColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: routineColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                routine.formattedCreatedDate,
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getBalancedDifficultyColor(routine.difficulty).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  routine.difficultyText,
                  style: GoogleFonts.poppins(
                    color: _getBalancedDifficultyColor(routine.difficulty),
                    fontSize: 10,
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

  Widget _buildTemplatesTab() {
    if (isLoadingTemplates) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (coachTemplates.isEmpty) {
      return _buildEmptyTemplatesState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coachTemplates.length,
      itemBuilder: (context, index) {
        final template = coachTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildEmptyTemplatesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No Templates Created',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create workout templates to quickly assign to your clients',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _createNewTemplate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create Your First Template',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final templateColor = Color(int.parse(template['color'] ?? '4288073396'));
    final tags = List<String>.from(template['tags'] ?? []);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: templateColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTemplateOptions(template),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: templateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: templateColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: templateColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template['name'] ?? 'Untitled Template',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${template['exercise_count'] ?? 0} exercises • ${template['duration'] ?? '30'} min',
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
                        Text(
                          _formatDate(template['created_at']),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(template['difficulty'] ?? 'Beginner').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template['difficulty'] ?? 'Beginner',
                            style: GoogleFonts.poppins(
                              color: _getDifficultyColor(template['difficulty'] ?? 'Beginner'),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tags.take(3).map((tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: templateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: templateColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildProgramStat(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[500],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleProgramAction(String action, ProgramTemplateModel template) {
    switch (action) {
      case 'assign':
        _showAssignProgramDialog(template);
        break;
      case 'duplicate':
        _showDuplicateProgramDialog(template);
        break;
      case 'edit':
        _showEditProgramDialog(template);
        break;
      case 'delete':
        _showDeleteProgramDialog(template);
        break;
    }
  }

  void _showAssignProgramDialog(ProgramTemplateModel template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<MemberModel>>(
          future: programservice.ProgramTemplateService.getAvailableMembers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: CircularProgressIndicator(),
              );
            }

            final availableMembers = snapshot.data ?? [];

            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                'Assign Program',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Assign "${template.name}" to:',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ...availableMembers.map((member) => ListTile(
                    title: Text(
                      '${member.firstName} ${member.lastName}',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      final success = await programservice.ProgramTemplateService.assignProgramToMember(
                        template.id,
                        member.id,
                      );
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Program assigned to ${member.firstName} ${member.lastName}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to assign program'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  )).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDuplicateProgramDialog(ProgramTemplateModel template) {
    final TextEditingController nameController = TextEditingController(
      text: '${template.name} (Copy)',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Duplicate Program',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter a name for the duplicated program:',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Program name',
                  hintStyle: GoogleFonts.inter(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  final success = await programservice.ProgramTemplateService.duplicateProgramTemplate(
                    template.id,
                    nameController.text.trim(),
                  );
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Program duplicated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCoachData(); // Refresh the list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to duplicate program'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: Text(
                'Duplicate',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProgramDialog(ProgramTemplateModel template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController(text: template.name);
        final descriptionController = TextEditingController(text: template.description);
        
        return AlertDialog(
          title: Text('Edit Program Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Program Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final updates = {
                    'name': nameController.text,
                    'description': descriptionController.text,
                  };
                  
                  final success = await programservice.ProgramTemplateService
                      .updateProgramTemplate(template.id, updates);
                  
                  Navigator.of(context).pop();
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Program template updated successfully')),
                    );
                    _loadCoachData(); // Refresh the list
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update program template')),
                    );
                  }
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteProgramDialog(ProgramTemplateModel template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'Delete Program',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await programservice.ProgramTemplateService.deleteProgramTemplate(template.id);
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCoachData(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete program'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }



  void _navigateToClientSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachClientSelectionPage(
          selectedColor: Color(0xFF4ECDC4),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadCoachData();
      }
    });
  }

  void _navigateToCreateRoutineForClient(MemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachCreateRoutinePage(
          selectedClient: member,
          selectedColor: Color(0xFF4ECDC4),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadCoachData();
      }
    });
  }

  Color _getBalancedCategoryColor(ProgramTemplateCategory category) {
    switch (category) {
      case ProgramTemplateCategory.beginner_friendly:
        return Color(0xFF2ECC71);
      case ProgramTemplateCategory.weight_loss:
        return Color(0xFFE74C3C);
      case ProgramTemplateCategory.muscle_building:
        return Color(0xFF4ECDC4);
      case ProgramTemplateCategory.strength_training:
        return Color(0xFF34495E);
      case ProgramTemplateCategory.endurance:
        return Color(0xFF3498DB);
      case ProgramTemplateCategory.rehabilitation:
        return Color(0xFF27AE60);
      case ProgramTemplateCategory.sports_specific:
        return Color(0xFF8E44AD);
      case ProgramTemplateCategory.general_fitness:
        return Color(0xFFF1C40F); // Changed from orange to amber
    }
  }

  Color _getBalancedDifficultyColor(RoutineDifficulty difficulty) {
    switch (difficulty) {
      case RoutineDifficulty.beginner:
        return Color(0xFF2ECC71);
      case RoutineDifficulty.intermediate:
        return Color(0xFFF1C40F); // Changed from orange to amber
      case RoutineDifficulty.advanced:
        return Color(0xFFE67E22);
      case RoutineDifficulty.expert:
        return Color(0xFFE74C3C);
    }
  }

  Color _parseRoutineColor(String colorString) {
    try {
      if (colorString.isEmpty) return Color(0xFF4ECDC4);
      
      // Handle different color formats
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } else if (colorString.startsWith('0x')) {
        return Color(int.parse(colorString));
      } else {
        // Try parsing as integer
        final colorInt = int.tryParse(colorString);
        if (colorInt != null) {
          return Color(colorInt);
        }
      }
    } catch (e) {
      print('Error parsing color: $colorString, using default');
    }
    
    // Fallback to default teal color
    return Color(0xFF4ECDC4);
  }

  void _createNewTemplate() {
    // Navigate to template creation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachCreateRoutinePage(
          selectedClient: null, // No specific client for template
          isTemplate: true,
        ),
      ),
    ).then((_) {
      // Refresh templates when returning
      if (_tabController.index == 1) {
        _loadCoachTemplates();
      }
    });
  }

  void _showTemplateOptions(Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              template['name'] ?? 'Untitled Template',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${template['exercise_count'] ?? 0} exercises • ${template['duration'] ?? '30'} min',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.people, color: Color(0xFF4ECDC4)),
              title: Text(
                'Assign to Client',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _assignTemplateToClient(template);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.orange),
              title: Text(
                'Edit Template',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement template editing
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Template editing coming soon!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Template',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteTemplate(template);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _assignTemplateToClient(Map<String, dynamic> template) async {
    // Use the existing assigned members from the coach data
    if (assignedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No clients available to assign template to'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Assign Template',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a client to assign "${template['name']}" template to:',
                style: GoogleFonts.poppins(color: Colors.grey[300]),
              ),
              SizedBox(height: 16),
              ...assignedMembers.map((member) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF4ECDC4),
                  child: Text(
                    member.initials,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  member.fullName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  member.email,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _performTemplateAssignment(template, member);
                },
              )).toList(),
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
        ],
      ),
    );
  }

  Future<void> _performTemplateAssignment(Map<String, dynamic> template, MemberModel member) async {
    try {
      print('DEBUG - Attempting to assign template ${template['id']} to client ${member.id}');
      
      final success = await RoutineService.assignTemplateToClient(
        templateId: template['id'].toString(),
        clientId: member.id.toString(),
        coachId: 'current_coach_id',
      );
      
      print('DEBUG - Assignment result: $success');
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template assigned to ${member.fullName} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh the templates list and coach data
        _loadCoachTemplates();
        _loadCoachData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign template to ${member.fullName}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('DEBUG - Assignment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Delete Template',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${template['name']}"? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.grey[300]),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement template deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Template deletion coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference <= 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Color(0xFF2ECC71);
      case 'intermediate':
        return Color(0xFFF39C12);
      case 'advanced':
        return Color(0xFFE67E22);
      case 'expert':
        return Color(0xFFE74C3C);
      default:
        return Color(0xFF2ECC71);
    }
  }
}
