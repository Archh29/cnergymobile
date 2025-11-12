import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/user_model.dart';
import './services/user_service.dart';
import  './services/auth_service.dart';// Import AuthService
import './services/membership_service.dart';
import 'achievements_page.dart';
import 'manage_profile_page.dart';
import 'manage_subscriptions_page.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';
import 'personal_training_page.dart';
import 'pages/subscription_history_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  UserModel? currentUser;
  bool isLoading = true;
  String? errorMessage;
  
  // Membership information
  Map<String, dynamic>? membershipInfo;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
    _loadMembershipData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // FIXED: Use AuthService instead of directly reading SharedPreferences
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('🔍 Loading user data from AuthService...');
      
      // FIXED: Get user ID from AuthService (which returns int?)
      final userId = AuthService.getCurrentUserId();
      
      if (userId == null) {
        print('❌ No user ID found in AuthService');
        setState(() {
          errorMessage = 'No user logged in';
          isLoading = false;
        });
        return;
      }

      print('✅ Found user ID: $userId');
      
      // Use UserService.fetchCurrentUser() which handles the AuthService integration
      final user = await UserService.fetchCurrentUser();
      
      if (user != null) {
        setState(() {
          currentUser = user;
          isLoading = false;
        });
        print('✅ User loaded: ${user.fullName}, Premium: ${user.isPremium}');
      } else {
        setState(() {
          errorMessage = 'Failed to load user data';
          isLoading = false;
        });
        print('❌ Failed to load user data');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        errorMessage = 'Error loading user data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMembershipData() async {
    try {
      print('🔍 Loading membership data...');
      final membership = await MembershipService.getMembershipInfo();
      setState(() {
        membershipInfo = membership;
      });
      print('✅ Membership loaded: ${membership['has_membership']}');
    } catch (e) {
      print('❌ Error loading membership data: $e');
      // Don't set error state for membership, just log it
    }
  }


  Future<void> _updateUserData(Map<String, dynamic> updates) async {
    if (currentUser == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // FIXED: Use the user ID from the current user model
      final success = await UserService.updateUserFields(currentUser!.id, updates);
      
      if (success) {
        // Reload user data to get the latest information
        await _loadUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating profile: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Enhanced Premium Badge Widget with Membership Info
  Widget _buildPremiumBadgeWithMembership() {
    return Column(
      children: [
        // Premium Badge
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionHistoryPage(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD700), // Gold
                  Color(0xFFFFA500), // Orange
                  Color(0xFFFF8C00), // Dark Orange
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  'Premium Member',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Membership Information (centered) - Monthly plan status removed
        if (membershipInfo != null && !membershipInfo!['has_membership']) ...[
          SizedBox(height: 12),
          Center(child: _buildNoMembershipInfo()),
        ],
      ],
    );
  }

  Widget _buildMembershipInfo() {
    final membership = membershipInfo!;
    final isExpired = membership['is_expired'] ?? false;
    final isExpiringSoon = membership['is_expiring_soon'] ?? false;
    final daysRemaining = membership['days_remaining'] ?? 0;
    final membershipType = membership['membership_type'] ?? 'Monthly';
    final endDate = membership['end_date'] ?? '';

    // Determine badge colors and text based on status
    List<Color> badgeColors;
    String statusText;
    
    if (isExpired) {
      badgeColors = [Color(0xFFFF6B6B), Color(0xFFFF5252), Color(0xFFE53935)];
      statusText = 'Monthly Plan - Expired';
    } else if (isExpiringSoon) {
      badgeColors = [Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00)];
      statusText = 'Monthly Plan - Expires in $daysRemaining days';
    } else {
      badgeColors = [Color(0xFF4ECDC4), Color(0xFF26A69A), Color(0xFF00695C)];
      statusText = 'Monthly Plan - Active';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionHistoryPage(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: badgeColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: badgeColors[0].withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              statusText,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMembershipInfo() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9E9E9E),
            Color(0xFF757575),
            Color(0xFF424242),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF9E9E9E).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            'No active membership',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    if (currentUser == null) return;

    final fnameController = TextEditingController(text: currentUser!.fname);
    final mnameController = TextEditingController(text: currentUser!.mname);
    final lnameController = TextEditingController(text: currentUser!.lname);
    final emailController = TextEditingController(text: currentUser!.email);
    final bdayController = TextEditingController(
      text: currentUser!.bday.toIso8601String().split('T')[0]
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(fnameController, 'First Name'),
                SizedBox(height: 16),
                _buildTextField(mnameController, 'Middle Name'),
                SizedBox(height: 16),
                _buildTextField(lnameController, 'Last Name'),
                SizedBox(height: 16),
                _buildTextField(emailController, 'Email'),
                SizedBox(height: 16),
                _buildTextField(bdayController, 'Birthday (YYYY-MM-DD)'),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(color: Colors.grey[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final updates = {
                            'fname': fnameController.text.trim(),
                            'mname': mnameController.text.trim(),
                            'lname': lnameController.text.trim(),
                            'email': emailController.text.trim(),
                            'bday': bdayController.text.trim(),
                          };
                          
                          Navigator.pop(context);
                          _updateUserData(updates);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[700]!),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4ECDC4)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: isLoading
                ? _buildLoadingWidget()
                : errorMessage != null
                    ? _buildErrorWidget()
                    : _buildProfileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
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
            errorMessage!,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
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

  Widget _buildProfileContent() {
    if (currentUser == null) return Container();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header with premium badge
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35).withOpacity(0.8), Color(0xFFFF8E53).withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile picture and edit button removed per request
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        currentUser!.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (currentUser!.isPremium) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        color: Color(0xFFFFD700),
                        size: 24,
                      ),
                    ],
                  ],
                ),
                // Premium Badge with Membership Info - Now using backend data
                if (currentUser!.isPremium) ...[
                  SizedBox(height: 16),
                  _buildPremiumBadgeWithMembership(),
                ],
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Personal Training Card - Now navigates to separate page
          _buildPersonalTrainingCard(),
          SizedBox(height: 24),
          
          // Menu sections
          _buildMenuSection(
            'Personal',
            [
              _buildMenuItem(Icons.emoji_events, 'Achievements', Color(0xFFFFD700), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AchievementsPage()));
              }),
              _buildMenuItem(Icons.person, 'Manage Profile', Color(0xFF4ECDC4), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ManageProfilePage()));
              }),
            ],
          ),
          SizedBox(height: 16),
          _buildMenuSection(
            'Account',
            [
              _buildMenuItem(Icons.subscriptions, 'Subscriptions', Color(0xFF96CEB4), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSubscriptionsPage()));
              }),
            ],
          ),
          SizedBox(height: 16),
          _buildMenuSection(
            'Legal',
            [
              _buildMenuItem(Icons.privacy_tip, 'Privacy Policy', Color(0xFF9B59B6), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyPolicyPage()));
              }),
              _buildMenuItem(Icons.article, 'Terms & Conditions', Color(0xFF34495E), () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TermsConditionsPage()));
              }),
            ],
          ),
          SizedBox(height: 32),
          
          // Action buttons
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF6B35).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(Icons.logout),
              label: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _confirmSignOut(context),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // New Personal Training Card that navigates to separate page
  Widget _buildPersonalTrainingCard() {
    if (currentUser == null) return Container();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4).withOpacity(0.8), Color(0xFF44A08D).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PersonalTrainingPage(currentUser: currentUser),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.fitness_center, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Coaching',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentUser!.isPremium
                           ? 'Manage your personal coaching sessions'
                          : 'Upgrade to access personal coaching',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIXED: Use AuthService for sign out
  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
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
                  color: Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  color: Color(0xFFFF6B35),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Are you sure you want to sign out?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      // FIXED: Use AuthService logout method
      await AuthService.logout();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
