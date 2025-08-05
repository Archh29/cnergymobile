import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all Coach components
import './Coach/coach_member_selector.dart';
import './Coach/coach_messages_page.dart' as CoachMessages;
import './Coach/coach_profile_page.dart';
import './Coach/coach_progress_page.dart';
import './Coach/coach_routine_page.dart';
import './Coach/models/member_model.dart';
import './Coach/services/coach_service.dart';

class CoachDashboard extends StatefulWidget {
  @override
  _CoachDashboardState createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  MemberModel? selectedMember;
  List<MemberModel> assignedMembers = [];
  bool isLoadingMembers = true;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Routines',
      color: Color(0xFFFF6B35),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Progress',
      color: Color(0xFF96CEB4),
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Members',
      color: Color(0xFF45B7D1),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      color: Color(0xFFE74C3C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
    _loadAssignedMembers();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('coach_selectedIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coach_selectedIndex', index);
  }

  Future<void> _loadAssignedMembers() async {
    setState(() => isLoadingMembers = true);
    
    try {
      final members = await CoachService.getAssignedMembers();
      setState(() {
        assignedMembers = members;
        if (members.isNotEmpty && selectedMember == null) {
          selectedMember = members.first;
        }
        isLoadingMembers = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      setState(() => isLoadingMembers = false);
    }
  }

  void _onMemberSelected(MemberModel member) {
    setState(() {
      selectedMember = member;
    });
  }

  // Method to navigate to messages page
  void _navigateToMessages() {
    if (selectedMember != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoachMessages.CoachMessagesPage(selectedMember: selectedMember),
        ),
      );
    } else {
      // Show a message if no member is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a member first'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Widget> _getPages() {
    if (selectedMember == null) {
      return [
        _buildSelectMemberPrompt(),
        _buildSelectMemberPrompt(),
        CoachMemberSelector(
          assignedMembers: assignedMembers,
          selectedMember: selectedMember,
          onMemberSelected: _onMemberSelected,
          isLoading: isLoadingMembers,
        ),
        CoachProfilePage(),
      ];
    }

    return [
      CoachRoutinePage(selectedMember: selectedMember!),
      CoachProgressPage(selectedMember: selectedMember!),
      CoachMemberSelector(
        assignedMembers: assignedMembers,
        selectedMember: selectedMember,
        onMemberSelected: _onMemberSelected,
        isLoading: isLoadingMembers,
      ),
      CoachProfilePage(),
    ];
  }

  Widget _buildSelectMemberPrompt() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF45B7D1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                color: Color(0xFF45B7D1),
                size: 48,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Select a Member',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose a member from the Members tab to view their progress and manage their routines.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedIndex = 2);
                _saveSelectedIndex(2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF45B7D1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.people),
              label: Text(
                'View Members',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();
    
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
      floatingActionButton: _buildModernFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Text(
            "COACH PANEL",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
          Spacer(),
          if (selectedMember != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
                    child: Text(
                      selectedMember!.initials,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4ECDC4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedMember!.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        selectedMember!.approvalStatusMessage,
                        style: GoogleFonts.poppins(
                          color: selectedMember!.isFullyApproved 
                              ? Color(0xFF4ECDC4) 
                              : Colors.orange,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => _showNotificationsDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navigationItems.length, (index) {
          final item = _navigationItems[index];
          final isSelected = _selectedIndex == index;
          
          return GestureDetector(
            onTap: () async {
              await _saveSelectedIndex(index);
              setState(() {
                _selectedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      color: isSelected ? item.color : Colors.grey[400],
                      size: 22,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? item.color : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildModernFAB() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF4ECDC4).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToMessages,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: Color(0xFF4ECDC4),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Coach Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No new notifications from your members.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
