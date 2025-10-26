import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../User/services/auth_service.dart';
import '../User/services/home_service.dart';
import '../User/services/schedule_service.dart';
import '../User/services/subscription_service.dart';
import '../User/models/schedule_model.dart';
import '../User/manage_subscriptions_page.dart';
                                                                                                                                                                                                                                                                                                
class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToQR;
  
  const HomePage({Key? key, this.onNavigateToQR}) : super(key: key);
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late PageController _merchPageController;
  int _currentMerchIndex = 0;

  // Data lists that will be populated from API
  List<AnnouncementItem> announcements = [];
  List<MerchItem> merchItems = [];
  List<PromotionItem> promotions = [];
  TodayWorkout? todayWorkout;
  
  // Loading state
  bool _isLoading = true;
  bool _hasAnnualMembership = false; // Check for Plan ID 1 (Annual) or Plan ID 5 (Package)
  
  // Announcement filters
  String _announcementFilter = 'all'; // 'all', 'newest', 'important', 'oldest'
  List<AnnouncementItem> _filteredAnnouncements = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _merchPageController = PageController(viewportFraction: 0.8);
    _animationController.forward();
    
    // Load data from API
    _loadData();
    _checkAnnualMembership();
  }

  Future<void> _loadData() async {
    try {
      // Get home data (announcements, merchandise, promotions)
      final data = await HomeService.getHomeData();
      
      // Load today's scheduled workout
      TodayWorkout? scheduledWorkout;
      try {
        print('🏠 Home Page: Loading today\'s workout...');
        print('🏠 Home Page: Today is ${DateTime.now().weekday} (${_getDayName(DateTime.now().weekday)})');
        scheduledWorkout = await ScheduleService.getTodayWorkoutFromAnyProgram();
        print('🏠 Home Page: Today\'s workout result: $scheduledWorkout');
        if (scheduledWorkout != null) {
          print('🏠 Home Page: Workout details - isRestDay: ${scheduledWorkout.isRestDay}, workoutName: ${scheduledWorkout.workoutName}');
        }
      } catch (e) {
        print('🏠 Home Page: Error loading today\'s workout: $e');
      }
      
      if (mounted) {
        setState(() {
          announcements = data['announcements'];
          merchItems = data['merchandise'];
          promotions = data['promotions'];
          todayWorkout = scheduledWorkout; // Use scheduled workout instead of API data
          _isLoading = false;
          _applyAnnouncementFilter();
        });
        
        // Start auto-scroll after data is loaded
        if (merchItems.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkAnnualMembership() async {
    print('🚀 Home Page - _checkAnnualMembership() method called!');
    try {
      final userId = AuthService.getCurrentUserId();
      print('🔍 Home Page - Checking annual membership for user ID: $userId');
      
      if (userId == null) {
        print('❌ Home Page - User ID is null, setting _hasAnnualMembership to false');
        _hasAnnualMembership = false;
        if (mounted) setState(() {});
        return;
      }

      final subscriptionData = await SubscriptionService.getCurrentSubscription(userId);
      print('🔍 Home Page - Subscription data received: $subscriptionData');
      
      if (subscriptionData != null && subscriptionData['subscription'] != null) {
        final subscription = subscriptionData['subscription'];
        final planId = subscription['plan_id'];
        
        // Check if user has premium access (Plan ID 1 or Plan ID 5 - Package Plan)
        _hasAnnualMembership = planId == 1 || planId == 5;
        
        if (mounted) {
          setState(() {});
        }
        
        print('✅ Home Page - Annual membership check: $_hasAnnualMembership (Plan ID: $planId)');
      } else {
        print('❌ Home Page - No subscription data found, setting _hasAnnualMembership to false');
        _hasAnnualMembership = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('❌ Home Page - Error checking annual membership: $e');
      _hasAnnualMembership = false;
      if (mounted) setState(() {});
    }
  }

  void _startAutoScroll() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _merchPageController.hasClients) {
        int nextPage = (_currentMerchIndex + 1) % merchItems.length;
        _merchPageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }


  Widget _buildLockedState(String featureName) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.lock_outline,
              color: Color(0xFF4ECDC4),
              size: 40,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Premium Feature',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '$featureName is available for annual members only.',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageSubscriptionsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Upgrade to Annual Membership',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _merchPageController.dispose();
    super.dispose();
  }

  void _showGymRulesModal() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375 || screenHeight < 667;
    final isThinScreen = screenWidth < 350;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          margin: EdgeInsets.symmetric(horizontal: isThinScreen ? 12 : 16),
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
            maxWidth: screenWidth * 0.9,
          ),
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
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rule,
                  color: Color(0xFFFF6B35),
                  size: isSmallScreen ? 28 : 32,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                'Gym Rules & Guidelines',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRuleItem("1. Consult coach or trainer on how to use the gym properly.", isSmallScreen),
                        _buildRuleItem("2. Use facilities and equipment at your own risk.", isSmallScreen),
                        _buildRuleItem("3. Return weights to rack after use.", isSmallScreen),
                        _buildRuleItem("4. Children under the age of 16 must have parents or guardians permission.", isSmallScreen),
                        _buildRuleItem("5. Report any damages to the management immediately DO NOT USE.", isSmallScreen),
                        _buildRuleItem("6. Stop exercising if you feel pain, discomfort, nausea, dizziness or shortness of breath.", isSmallScreen),
                        _buildRuleItem("7. Wear proper gym clothing. NO SLIPPERS.", isSmallScreen),
                        _buildRuleItem("8. NO LITTERING.", isSmallScreen),
                        _buildRuleItem("9. NO SMOKING", isSmallScreen),
                        _buildRuleItem("10. NO LOITERING", isSmallScreen),
                        _buildRuleItem("11. Use provided SANITZER STATIONS.", isSmallScreen),
                        _buildRuleItem("12. Please be COURTEOUS AND RESPECTFUL of other gym users.", isSmallScreen),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B35),
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
                  'Got it!',
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

  Widget _buildRuleItem(String rule, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 3 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 5 : 6,
            height: isSmallScreen ? 5 : 6,
            margin: EdgeInsets.only(
              top: isSmallScreen ? 6 : 8, 
              right: isSmallScreen ? 10 : 12
            ),
            decoration: BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              rule,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if not present
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Helper method to get IconData from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center': return Icons.fitness_center;
      case 'schedule': return Icons.schedule;
      case 'group': return Icons.group;
      case 'local_drink': return Icons.local_drink;
      case 'water_drop': return Icons.water_drop;
      case 'checkroom': return Icons.checkroom;
      case 'sports_handball': return Icons.sports_handball;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'school': return Icons.school;
      case 'people': return Icons.people;
      case 'star': return Icons.star;
      case 'gift': return Icons.card_giftcard;
      case 'celebration': return Icons.celebration;
      default: return Icons.info;
    }
  }

  // Loading card widget
  Widget _buildLoadingCard(bool isSmallScreen, bool isThinScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      ),
    );
  }

  // Empty state card widget
  Widget _buildEmptyCard(String message, bool isSmallScreen, bool isThinScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.grey[400],
          ),
        ),
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
      backgroundColor: Color(0xFF0F0F0F),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildTodayWorkoutSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildQuickActionsSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _hasAnnualMembership 
                ? _buildAnnouncementsSection(isSmallScreen, isThinScreen)
                : _buildLockedState('Announcements'),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildMerchSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildPromotionsSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 80 : 100), // Extra space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen, bool isThinScreen) {
    String userName = AuthService.isLoggedIn() 
        ? AuthService.getUserFullName() ?? "Member"
        : "Day Pass User";
        
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: isSmallScreen ? 15 : 20,
            offset: Offset(0, isSmallScreen ? 8 : 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: isThinScreen ? 18 : (isSmallScreen ? 20 : 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  'Ready for your workout?',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
            child: Icon(
              Icons.waving_hand,
              color: Colors.white,
              size: isSmallScreen ? 24 : 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayWorkoutSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Workout',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Show different content based on workout data availability
        if (todayWorkout != null)
          _buildWorkoutCard(isSmallScreen, isThinScreen)
        else
          _buildNoWorkoutCard(isSmallScreen, isThinScreen),
      ],
    );
  }

  Widget _buildWorkoutCard(bool isSmallScreen, bool isThinScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: todayWorkout!.isRestDay 
            ? [Color(0xFF6B73FF), Color(0xFF9DD5EA)]
            : [Color(0xFF96CEB4), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: (todayWorkout!.isRestDay ? Color(0xFF6B73FF) : Color(0xFF96CEB4)).withOpacity(0.3),
            blurRadius: isSmallScreen ? 15 : 20,
            offset: Offset(0, isSmallScreen ? 8 : 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
            child: Icon(
              todayWorkout!.isRestDay ? Icons.bed_outlined : Icons.fitness_center,
              color: Colors.white,
              size: isSmallScreen ? 28 : 36,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayWorkout!.isRestDay ? 'Rest Day' : (todayWorkout!.workoutName ?? 'Workout'),
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!todayWorkout!.isRestDay) ...[
                  SizedBox(height: 4),
                  if (todayWorkout!.scheduledTime != null)
                    Text(
                      'Scheduled at ${_formatTime(todayWorkout!.scheduledTime!)}',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  if (todayWorkout!.workoutDuration != null)
                    Text(
                      '${todayWorkout!.workoutDuration} minutes',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ] else ...[
                  SizedBox(height: 4),
                  Text(
                    'Take a well-deserved break',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                if (todayWorkout!.programGoal != null) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      todayWorkout!.programGoal!,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Display-only icon (no click functionality)
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            ),
            child: Icon(
              todayWorkout!.isRestDay ? Icons.spa : Icons.visibility,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWorkoutCard(bool isSmallScreen, bool isThinScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.grey[700]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
            child: Icon(
              Icons.schedule,
              color: Colors.grey[400],
              size: isSmallScreen ? 28 : 36,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Workout Scheduled',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[300],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create a program and schedule it for today',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Go to ',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Routines',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' → ',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      'Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[700]!.withOpacity(0.3),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: Colors.grey[400],
              size: isSmallScreen ? 20 : 24,
            ),
          ),
        ],
      ),
    );
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

  // Start workout method removed as requested
  /*Future<void> _startTodayWorkout() async {
    print('🔍 Debug - todayWorkout: $todayWorkout');
    print('🔍 Debug - workoutId: ${todayWorkout?.workoutId}');
    print('🔍 Debug - workoutName: ${todayWorkout?.workoutName}');
    print('🔍 Debug - isRestDay: ${todayWorkout?.isRestDay}');
    
    if (todayWorkout?.workoutId == null) {
      String message = 'No workout scheduled for today. ';
      if (todayWorkout == null) {
        message += 'Please create and schedule a workout program first.';
      } else if (todayWorkout!.isRestDay) {
        message += 'Today is a rest day.';
      } else {
        message += 'Workout data is incomplete.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Schedule Now',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to schedule page (assuming it's at index 2 in bottom navigation)
              DefaultTabController.of(context)?.animateTo(2);
            },
          ),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );

      // Create a RoutineModel from today's workout data
      // Using hardcoded routine ID 70 since API returns wrong program_id
      final routine = RoutineModel(
        id: todayWorkout?.routineId?.toString() ?? todayWorkout?.workoutId?.toString() ?? "0",
        name: todayWorkout!.workoutName ?? 'Workout',
        exercises: 0, // Will be loaded by the preview page
        duration: todayWorkout!.workoutDuration ?? '30',
        difficulty: 'Beginner', // Default difficulty
        createdBy: '', // User-created workout
        exerciseList: '', // Will be loaded by the preview page
        color: '0xFF4ECDC4', // Default color
        lastPerformed: 'Never',
        tags: ['scheduled', 'today'],
        goal: todayWorkout!.programGoal ?? 'General Fitness',
        completionRate: 0,
        totalSessions: 0,
        notes: 'Today\'s scheduled workout',
        scheduledDays: [todayWorkout!.dayOfWeek],
        version: 1.0,
      );

      // Close loading dialog
      Navigator.pop(context);
      
      // Navigate to workout preview page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StartWorkoutPreviewPage(
            routine: routine,
          ),
        ),
      );
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/

  Widget _buildQuickActionsSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Gym Rules',
                Icons.rule,
                Color(0xFFFF6B35),
                () => _showGymRulesModal(),
                isSmallScreen,
                isThinScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: _buildQuickActionCard(
                'Check In',
                Icons.qr_code_scanner,
                Color(0xFF45B7D1),
                () {
                  // Navigate to QR tab within the same dashboard
                  if (widget.onNavigateToQR != null) {
                    widget.onNavigateToQR!();
                  }
                },
                isSmallScreen,
                isThinScreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap, bool isSmallScreen, bool isThinScreen) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
              ),
              child: Icon(
                icon,
                color: color,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: isThinScreen ? 12 : (isSmallScreen ? 13 : 14),
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Announcements',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!_isLoading && announcements.isNotEmpty)
              GestureDetector(
                onTap: () => _showAnnouncementFilters(isSmallScreen, isThinScreen),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 16,
                        color: Color(0xFF4ECDC4),
                      ),
                      SizedBox(width: 4),
                      Text(
                        _getFilterDisplayName(_announcementFilter),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Color(0xFF4ECDC4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isLoading)
          _buildLoadingCard(isSmallScreen, isThinScreen)
        else if (_filteredAnnouncements.isEmpty)
          _buildEmptyCard('No announcements available', isSmallScreen, isThinScreen)
        else if (_filteredAnnouncements.length >= 4)
          // Make scrollable when 4 or more items
          SizedBox(
            height: isSmallScreen ? 200 : 220,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _filteredAnnouncements.length,
              itemBuilder: (context, index) {
                return _buildAnnouncementCard(_filteredAnnouncements[index], isSmallScreen, isThinScreen);
              },
            ),
          )
        else
          // Show all items when less than 4
          ..._filteredAnnouncements.map((announcement) => _buildAnnouncementCard(announcement, isSmallScreen, isThinScreen)),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem announcement, bool isSmallScreen, bool isThinScreen) {
    // Convert hex color string to Color
    Color announcementColor = _hexToColor(announcement.color);
    
    return GestureDetector(
      onTap: () => _showFullScreenAnnouncement(announcement, isSmallScreen, isThinScreen),
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: announcement.isImportant 
              ? Border.all(color: announcementColor.withOpacity(0.5), width: 2)
              : null,
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: announcementColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            ),
            child: Icon(
              _getIconData(announcement.icon),
              color: announcementColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (announcement.isImportant) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8, 
                          vertical: 2
                        ),
                        decoration: BoxDecoration(
                          color: announcementColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'IMPORTANT',
                          style: GoogleFonts.poppins(
                            fontSize: isThinScreen ? 8 : (isSmallScreen ? 9 : 10),
                            fontWeight: FontWeight.bold,
                            color: announcementColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  announcement.description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[400],
                    height: 1.3,
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

  Widget _buildMerchSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Merchandise',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!_isLoading && merchItems.isNotEmpty)
              GestureDetector(
                onTap: () => _showAllMerchandise(isSmallScreen, isThinScreen),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF4ECDC4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isLoading)
          Container(
            height: isSmallScreen ? 180 : 220,
            child: _buildLoadingCard(isSmallScreen, isThinScreen),
          )
        else if (merchItems.isEmpty)
          Container(
            height: isSmallScreen ? 120 : 140,
            child: _buildEmptyCard('No merchandise available', isSmallScreen, isThinScreen),
          )
        else ...[
          Container(
            height: isSmallScreen ? 180 : 220,
            child: PageView.builder(
              controller: _merchPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentMerchIndex = index;
                });
              },
              itemCount: merchItems.length,
              itemBuilder: (context, index) {
                return _buildMerchCard(merchItems[index], isSmallScreen, isThinScreen);
              },
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: merchItems.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: _currentMerchIndex == entry.key ? (isSmallScreen ? 20 : 24) : (isSmallScreen ? 6 : 8),
                height: isSmallScreen ? 6 : 8,
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentMerchIndex == entry.key
                      ? Color(0xFF4ECDC4)
                      : Colors.grey[600],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMerchCard(MerchItem item, bool isSmallScreen, bool isThinScreen) {
    // Convert hex color string to Color
    Color itemColor = _hexToColor(item.color);
    
    return GestureDetector(
      onTap: () => _showFullScreenMerchandise(item, isSmallScreen, isThinScreen),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
          border: Border.all(
            color: itemColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                    topRight: Radius.circular(isSmallScreen ? 16 : 20),
                  ),
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                          topRight: Radius.circular(isSmallScreen ? 16 : 20),
                        ),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                _getIconData(item.icon),
                                size: isSmallScreen ? 32 : 40,
                                color: itemColor,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(itemColor),
                                strokeWidth: 2,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getIconData(item.icon),
                          size: isSmallScreen ? 32 : 40,
                          color: itemColor,
                        ),
                      ),
              ),
            ),
            // Content section
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Name
                    Flexible(
                      child: Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 3),
                    // Price
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.price,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: itemColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Promotions',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isLoading)
          _buildLoadingCard(isSmallScreen, isThinScreen)
        else if (promotions.isEmpty)
          _buildEmptyCard('No promotions available', isSmallScreen, isThinScreen)
        else if (promotions.length >= 4)
          // Make scrollable when 4 or more items
          SizedBox(
            height: isSmallScreen ? 200 : 220,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                return _buildPromotionCard(promotions[index], isSmallScreen, isThinScreen);
              },
            ),
          )
        else
          // Show all items when less than 4
          ...promotions.map((promotion) => _buildPromotionCard(promotion, isSmallScreen, isThinScreen)),
      ],
    );
  }

  Widget _buildPromotionCard(PromotionItem promotion, bool isSmallScreen, bool isThinScreen) {
    // Convert hex color string to Color
    Color promotionColor = _hexToColor(promotion.color);
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            promotionColor.withOpacity(0.1),
            promotionColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: promotionColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: promotionColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            ),
            child: Icon(
              _getIconData(promotion.icon),
              color: promotionColor,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promotion.title,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  promotion.description,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey[400],
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  promotion.validUntil,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12, 
              vertical: isSmallScreen ? 4 : 6
            ),
            decoration: BoxDecoration(
              color: promotionColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              promotion.discount,
              style: GoogleFonts.poppins(
                fontSize: isThinScreen ? 9 : (isSmallScreen ? 10 : 12),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Apply announcement filters
  void _applyAnnouncementFilter() {
    List<AnnouncementItem> filtered = List.from(announcements);
    
    switch (_announcementFilter) {
      case 'newest':
        filtered.sort((a, b) {
          if (a.datePosted == null && b.datePosted == null) return 0;
          if (a.datePosted == null) return 1;
          if (b.datePosted == null) return -1;
          return b.datePosted!.compareTo(a.datePosted!);
        });
        break;
      case 'oldest':
        filtered.sort((a, b) {
          if (a.datePosted == null && b.datePosted == null) return 0;
          if (a.datePosted == null) return 1;
          if (b.datePosted == null) return -1;
          return a.datePosted!.compareTo(b.datePosted!);
        });
        break;
      case 'important':
        filtered = filtered.where((item) => item.isImportant).toList();
        break;
      case 'all':
      default:
        // Keep original order
        break;
    }
    
    _filteredAnnouncements = filtered;
  }

  // Get display name for filter
  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'important':
        return 'Important';
      case 'all':
      default:
        return 'All';
    }
  }

  // Show announcement filters
  void _showAnnouncementFilters(bool isSmallScreen, bool isThinScreen) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Announcements',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ...['all', 'newest', 'oldest', 'important'].map((filter) {
                return ListTile(
                  leading: Icon(
                    _getFilterIcon(filter),
                    color: _announcementFilter == filter ? Color(0xFF4ECDC4) : Colors.grey[400],
                  ),
                  title: Text(
                    _getFilterDisplayName(filter),
                    style: GoogleFonts.poppins(
                      color: _announcementFilter == filter ? Color(0xFF4ECDC4) : Colors.white,
                      fontWeight: _announcementFilter == filter ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: _announcementFilter == filter
                      ? Icon(Icons.check, color: Color(0xFF4ECDC4))
                      : null,
                  onTap: () {
                    setState(() {
                      _announcementFilter = filter;
                      _applyAnnouncementFilter();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // Get icon for filter
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'newest':
        return Icons.new_releases;
      case 'oldest':
        return Icons.history;
      case 'important':
        return Icons.priority_high;
      case 'all':
      default:
        return Icons.list;
    }
  }

  // Full-screen announcement view
  void _showFullScreenAnnouncement(AnnouncementItem announcement, bool isSmallScreen, bool isThinScreen) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        Color announcementColor = _hexToColor(announcement.color);
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: announcementColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getIconData(announcement.icon),
                        color: announcementColor,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Important badge
                        if (announcement.isImportant) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: announcementColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'IMPORTANT',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: announcementColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                        // Description
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            announcement.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[300],
                              height: 1.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        // Date posted
                        if (announcement.datePosted != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.grey[400],
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Posted: ${announcement.datePosted}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Full-screen merchandise view
  void _showFullScreenMerchandise(MerchItem item, bool isSmallScreen, bool isThinScreen) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hexToColor(item.color).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Full screen product image
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _hexToColor(item.color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hexToColor(item.color).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item.imageUrl!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    _getIconData(item.icon),
                                    size: 120,
                                    color: _hexToColor(item.color),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(_hexToColor(item.color)),
                                    strokeWidth: 3,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              _getIconData(item.icon),
                              size: 120,
                              color: _hexToColor(item.color),
                            ),
                          ),
                  ),
                ),
                // Price section
                Container(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _hexToColor(item.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _hexToColor(item.color).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.price,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _hexToColor(item.color),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show all merchandise in a grid view
  void _showAllMerchandise(bool isSmallScreen, bool isThinScreen) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(0xFF4ECDC4).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Merchandise',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: merchItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No merchandise available',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Modern grid layout
                              ...List.generate(
                                (merchItems.length / (isSmallScreen ? 1 : 2)).ceil(),
                                (rowIndex) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: List.generate(
                                        isSmallScreen ? 1 : 2,
                                        (colIndex) {
                                          final itemIndex = rowIndex * (isSmallScreen ? 1 : 2) + colIndex;
                                          if (itemIndex >= merchItems.length) {
                                            return Expanded(child: SizedBox());
                                          }
                                          
                                          return Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                right: colIndex == 0 && !isSmallScreen ? 8 : 0,
                                                left: colIndex == 1 ? 8 : 0,
                                              ),
                                              child: _buildModernMerchCard(
                                                merchItems[itemIndex], 
                                                isSmallScreen, 
                                                isThinScreen
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern merchandise card for the "View All" grid
  Widget _buildModernMerchCard(MerchItem item, bool isSmallScreen, bool isThinScreen) {
    Color itemColor = _hexToColor(item.color);
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _showFullScreenMerchandise(item, isSmallScreen, isThinScreen);
      },
      child: Container(
        height: isSmallScreen ? 200 : 180,
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: itemColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: itemColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                _getIconData(item.icon),
                                size: 32,
                                color: itemColor,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(itemColor),
                                strokeWidth: 2,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getIconData(item.icon),
                          size: 32,
                          color: itemColor,
                        ),
                      ),
              ),
            ),
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    // Price
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: itemColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.price,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: itemColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}