import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

// Import all Coach components
import './Coach/coach_member_selector.dart';
import './Coach/coach_messages_page.dart' as CoachMessages;
import './Coach/coach_messages_dashboard.dart';
import './Coach/coach_profile_page.dart';
import './Coach/coach_progress_page.dart';
import './Coach/coach_routine_page.dart';
import './Coach/coach_schedule_page.dart';
import './Coach/session_management_page.dart';
import './Coach/coach_create_program_page.dart';
import './Coach/coach_workout_preview_page.dart';
import './Coach/models/member_model.dart';
import './Coach/services/coach_service.dart';
import './User/services/auth_service.dart';
import './login_screen.dart';
import './account_verification_page.dart';

class CoachDashboard extends StatefulWidget {
  @override
  _CoachDashboardState createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  MemberModel? selectedMember;
  List<MemberModel> assignedMembers = [];
  bool isLoadingMembers = true;
  bool _hasNotifications = false; // Added to track notifications
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Programs',
      color: Color(0xFFFF6B35),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Progress',
      color: Color(0xFF96CEB4),
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Schedule',
      color: Color(0xFF9B59B6),
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Members',
      color: Color(0xFF45B7D1),
    ),
    NavigationItem(
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer,
      label: 'Sessions',
      color: Color(0xFF4ECDC4),
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
    print('🔄 CoachDashboard initState called - Hot reload should work now');
    _loadSelectedIndex();
    _loadAssignedMembers();
    _initializeAnimations();
    _forceRefreshAuthData();
    
    // Log coach info for debugging
    if (AuthService.isLoggedIn()) {
      print('✅ Coach is logged in, proceeding with dashboard');
      print('👨‍🏫 Coach: ${AuthService.getUserFullName()}');
      print('🆔 Coach ID: ${AuthService.getCurrentUserId()}');
    }
  }

  @override
  void didUpdateWidget(CoachDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔄 CoachDashboard didUpdateWidget called - Hot reload detected');
    // Force refresh when widget updates (hot reload)
    _forceRefreshAuthData();
    // Also reload members after hot reload
    _loadAssignedMembers();
  }

  // Force refresh auth data to ensure hot reload works properly
  Future<void> _forceRefreshAuthData() async {
    try {
      await AuthService.forceRefresh();
      print('🔄 Coach dashboard auth data refreshed');
      
      // SECURITY FIX: Check if user needs account verification
      if (AuthService.needsAccountVerification()) {
        print('🔐 Coach needs account verification, redirecting to AccountVerificationScreen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AccountVerificationScreen()),
          );
        }
        return;
      }
      
      // Force a rebuild after refresh
      if (mounted) {
        setState(() {
          // This will trigger a rebuild
        });
      }
    } catch (e) {
      print('❌ Error refreshing auth data: $e');
    }
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
    print('🔄 DEBUG: Starting _loadAssignedMembers() in CoachDashboard');
    setState(() => isLoadingMembers = true);
    
    try {
      print('🔄 DEBUG: Calling CoachService.getAssignedMembers()');
      final members = await CoachService.getAssignedMembers();
      print('📊 DEBUG: Retrieved ${members.length} members from CoachService');
      
      setState(() {
        assignedMembers = members;
        print('📊 DEBUG: Set assignedMembers to ${assignedMembers.length} members');
        
        if (members.isNotEmpty && selectedMember == null) {
          selectedMember = members.first;
          print('✅ DEBUG: Auto-selected first member: ${selectedMember!.fullName}');
        } else if (members.isEmpty) {
          print('⚠️ DEBUG: No members found, selectedMember remains null');
          print('⚠️ DEBUG: This might indicate:');
          print('   - Coach has no assigned members in database');
          print('   - API endpoint issue');
          print('   - Coach ID mismatch');
          print('   - Database connection issue');
        } else {
          print('ℹ️ DEBUG: Members found but selectedMember already set: ${selectedMember?.fullName}');
        }
        isLoadingMembers = false;
      });
      
      print('✅ DEBUG: _loadAssignedMembers completed successfully');
    } catch (e) {
      print('❌ DEBUG: Error loading members: $e');
      print('❌ DEBUG: Stack trace: ${StackTrace.current}');
      setState(() => isLoadingMembers = false);
    }
  }

  void _onMemberSelected(MemberModel member) {
    setState(() {
      selectedMember = member;
    });
  }

  // Method to navigate to messages dashboard
  void _navigateToMessages() {
    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CoachMessagesDashboard(currentUserId: currentUserId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to get user information'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  List<Widget> _getPages() {
    // If no members assigned yet, show "No Members Assigned" message
    if (assignedMembers.isEmpty && !isLoadingMembers) {
      return [
        _buildNoMembersAssignedPrompt('routines'),
        _buildNoMembersAssignedPrompt('progress'),
        _buildNoMembersAssignedPrompt('schedule'),
        CoachMemberSelector(
          assignedMembers: assignedMembers,
          selectedMember: selectedMember,
          onMemberSelected: _onMemberSelected,
          isLoading: isLoadingMembers,
        ),
        _buildNoMembersAssignedPrompt('sessions'),
        CoachProfilePage(),
      ];
    }
    
    // If members exist but none selected, show "Select a Member" message
    if (selectedMember == null) {
      return [
        _buildSelectMemberPrompt(),
        _buildSelectMemberPrompt(),
        _buildSelectMemberPrompt(),
        CoachMemberSelector(
          assignedMembers: assignedMembers,
          selectedMember: selectedMember,
          onMemberSelected: _onMemberSelected,
          isLoading: isLoadingMembers,
        ),
        _buildSelectMemberPrompt(),
        CoachProfilePage(),
      ];
    }

    // Member is selected, show actual pages
    return [
      CoachRoutinePage(selectedMember: selectedMember!),
      CoachProgressPage(selectedMember: selectedMember!),
      CoachSchedulePage(selectedMember: selectedMember!),
      CoachMemberSelector(
        assignedMembers: assignedMembers,
        selectedMember: selectedMember,
        onMemberSelected: _onMemberSelected,
        isLoading: isLoadingMembers,
      ),
      SessionManagementPage(selectedMember: selectedMember!),
      CoachProfilePage(),
    ];
  }

  Widget _buildSelectMemberPrompt() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 12 : 20), // Reduced margin
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24), // Reduced padding
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16), // Smaller padding
              decoration: BoxDecoration(
                color: Color(0xFF45B7D1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                color: Color(0xFF45B7D1),
                size: isSmallScreen ? 36 : 48, // Smaller icon
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16), // Reduced spacing
            Text(
              'Select a Member',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 20, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 0), // Extra padding on small screens
              child: Text(
                'Choose a member from the Members tab to view their progress and manage their routines.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14, // Smaller text
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 3, // Prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    print('🔄 DEBUG: Refresh members button pressed');
                    _loadAssignedMembers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                    ),
                  ),
                  icon: Icon(
                    Icons.refresh,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  label: Text(
                    'Refresh',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _selectedIndex = 2);
                    _saveSelectedIndex(2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF45B7D1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 24, // Responsive padding
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                    ),
                  ),
                  icon: Icon(
                    Icons.people,
                    size: isSmallScreen ? 16 : 18, // Smaller icon
                  ),
                  label: Text(
                    'Go to Members',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14, // Responsive text
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // iPhone SE and similar
    
    return AppBar(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: isSmallScreen ? 60 : 80, // Reduced height for small screens
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // Smaller padding on small screens
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: isSmallScreen ? 16 : 20, // Smaller icon on small screens
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12), // Reduced spacing
          Flexible( // Added Flexible to prevent overflow
            child: Text(
              'Coach Dashboard',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18, // Responsive font size
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis, // Prevent text overflow
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: isSmallScreen ? 8 : 16), // Responsive margin
          child: IconButton(
            onPressed: _showNotificationsDialog,
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24, // Responsive icon size
                ),
                if (_hasNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isSmallScreen ? 6 : 8, // Smaller notification dot
                      height: isSmallScreen ? 6 : 8,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    
    return Container(
      height: isSmallScreen ? 70 : 90, // Reduced height for small screens
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(isSmallScreen ? 16 : 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: screenWidth, // Ensure full width
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navigationItems.length, (index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await _saveSelectedIndex(index);
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 4 : 8, // Reduced padding
                      vertical: isSmallScreen ? 4 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 8), // Smaller padding
                          decoration: BoxDecoration(
                            color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                          ),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? item.color : Colors.grey[400],
                            size: isSmallScreen ? 18 : 22, // Smaller icons
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4), // Reduced spacing
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 8 : 10, // Smaller text
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? item.color : Colors.grey[400],
                          ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFAB() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final fabSize = isSmallScreen ? 48.0 : 56.0; // Smaller FAB on small screens
    
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        width: fabSize,
        height: fabSize,
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
              blurRadius: isSmallScreen ? 15 : 20, // Reduced shadow
              offset: Offset(0, isSmallScreen ? 6 : 8),
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
            size: isSmallScreen ? 20 : 24, // Smaller icon
          ),
        ),
      ),
    );
  }

  Widget _buildNoMembersAssignedPrompt(String pageType) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700 || screenWidth < 350;
    
    // Get the appropriate icon, title, and message based on page type
    IconData icon;
    Color iconColor;
    String title;
    String message;
    
    switch (pageType) {
      case 'routines':
        icon = Icons.fitness_center_outlined;
        iconColor = Color(0xFFFF6B35);
        title = 'No Programs Available';
        message = 'You don\'t have any members assigned yet. Once members are assigned to you, you\'ll be able to manage their programs here.';
        break;
      case 'progress':
        icon = Icons.analytics_outlined;
        iconColor = Color(0xFF96CEB4);
        title = 'No Progress Data Available';
        message = 'You don\'t have any members assigned yet. Once members are assigned to you, you\'ll be able to track their progress here.';
        break;
      case 'schedule':
        icon = Icons.calendar_today_outlined;
        iconColor = Color(0xFF9B59B6);
        title = 'No Schedule Available';
        message = 'You don\'t have any members assigned yet. Once members are assigned to you, you\'ll be able to manage their schedule here.';
        break;
      case 'sessions':
        icon = Icons.timer_outlined;
        iconColor = Color(0xFF4ECDC4);
        title = 'No Sessions Available';
        message = 'You don\'t have any members assigned yet. Once members are assigned to you, you\'ll be able to track their workout sessions here.';
        break;
      default:
        icon = Icons.people_outline;
        iconColor = Color(0xFF45B7D1);
        title = 'No Members Assigned';
        message = 'You don\'t have any members assigned yet. Contact your administrator to get members assigned to you.';
    }
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(isSmallScreen ? 12 : 20),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
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
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isSmallScreen ? 36 : 48,
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 0),
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedIndex = 3); // Go to Members tab
                _saveSelectedIndex(3);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF45B7D1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 8 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                ),
              ),
              icon: Icon(
                Icons.people,
                size: isSmallScreen ? 14 : 16,
              ),
              label: Text(
                'Go to Members',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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

  void _showClientWorkoutSelector() {
    if (assignedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No clients assigned. Please assign clients first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Select Client for Workout',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: assignedMembers.length,
                      itemBuilder: (context, index) {
                        final member = assignedMembers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(0xFF4ECDC4).withOpacity(0.1),
                            child: Text(
                              member.fullName[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Color(0xFF4ECDC4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            member.fullName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            member.email,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              selectedMember = member;
                              _selectedIndex = 0; // Go to routines tab
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachCreateProgramPage(),
      ),
    ).then((result) {
      // Refresh routines if a program was created
      if (result == true) {
        // You can add refresh logic here if needed
        print('Program created successfully');
      }
    });
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
