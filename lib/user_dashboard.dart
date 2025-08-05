import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'User/qr_page.dart';
import 'User/progress_page.dart';
import 'User/profile_page.dart';
import 'User/messages_page.dart';
import 'User/routine_page.dart';
import 'User/home_page.dart';
import './User/services/auth_service.dart';
import './User/manage_subscriptions_page.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  final List<Widget> _pages = [
     HomePage(),
     RoutinePage(),
     ComprehensiveDashboard(),
     QRPage(),
     ProfilePage(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      color: const Color(0xFF4ECDC4),
    ),
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Programs',
      color: const Color(0xFFFF6B35),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Progress',
      color: const Color(0xFF96CEB4),
    ),
    NavigationItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'QR',
      color: const Color(0xFF45B7D1),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      color: const Color(0xFFE74C3C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadSelectedIndex();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  Future<void> _initializeAuth() async {
    await AuthService.initialize();
        
    if (!AuthService.isLoggedIn()) {
      print('User not logged in - consider redirecting to login page');
    } else {
      print('User logged in: ${AuthService.getUserFullName()}');
      print('User ID: ${AuthService.getCurrentUserId()}');
      print('Is Member: ${AuthService.isUserMember()}');
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedIndex', index);
  }

  void _showNotificationsDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
        
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24),
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: const Color(0xFFFF6B35),
                  size: isSmallScreen ? 28 : 32,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Notifications',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have no new notifications.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 28 : 32,
                     vertical: isSmallScreen ? 10 : 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionsMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
        
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
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
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Subscription Options',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 16,
                  vertical: isSmallScreen ? 4 : 8,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.subscriptions,
                    color: const Color(0xFF4ECDC4),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                title: Text(
                  'View Plans',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                subtitle: Text(
                  'Browse available subscription plans',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSubscriptionsPage(),
                    ),
                  );
                },
              ),
              if (AuthService.isLoggedIn()) ...[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 16,
                    vertical: isSmallScreen ? 4 : 8,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45B7D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: const Color(0xFF45B7D1),
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  title: Text(
                    'My Requests',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    'View your subscription request history',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Subscription history coming soon!'),
                        backgroundColor: const Color(0xFF45B7D1),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: isSmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMessages() {
    // Check if user is logged in and get current user ID
    if (!AuthService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to access messages'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId == null) {
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
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(currentUserId: currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375 || screenHeight < 667;
    final isThinScreen = screenWidth < 350;
        
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(isSmallScreen, isThinScreen),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildModernBottomNav(isSmallScreen, isThinScreen),
      floatingActionButton: _buildModernFAB(isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmallScreen, bool isThinScreen) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: isSmallScreen ? 70 : 80,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              "CNERGY",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : (isThinScreen ? 16 : 22),
                letterSpacing: isThinScreen ? 1.0 : 1.5,
                color: Colors.white,
              ),
              overflow: TextOverflow.visible,
              softWrap: false,
              maxLines: 1,
              textAlign: TextAlign.start,
            ),
          ),
          const Spacer(),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: isSmallScreen ? 4 : 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.subscriptions,
                color: const Color(0xFF4ECDC4),
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            onPressed: _showSubscriptionsMenu,
            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 32 : 40,
              minHeight: isSmallScreen ? 32 : 40,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_none,
                color: Colors.white,
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            onPressed: _showNotificationsDialog,
            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 32 : 40,
              minHeight: isSmallScreen ? 32 : 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav(bool isSmallScreen, bool isThinScreen) {
    return Container(
      height: isSmallScreen ? 75 : 90,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isThinScreen ? 4 : (isSmallScreen ? 8 : 12),
                     vertical: isSmallScreen ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? item.color : Colors.grey[400],
                          size: isSmallScreen ? 18 : 22,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Flexible(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: isThinScreen ? 8 : (isSmallScreen ? 9 : 10),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? item.color : Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildModernFAB(bool isSmallScreen) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        width: isSmallScreen ? 48 : 56,
        height: isSmallScreen ? 48 : 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToMessages, // Updated to use the new method
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: isSmallScreen ? 20 : 24,
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