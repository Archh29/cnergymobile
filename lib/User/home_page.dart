import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../User/services/auth_service.dart';
import '../User/services/home_service.dart';

class HomePage extends StatefulWidget {
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
  
  // Loading state
  bool _isLoading = true;

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
  }

  Future<void> _loadData() async {
    try {
      final data = await HomeService.getHomeData();
      if (mounted) {
        setState(() {
          announcements = data['announcements'];
          merchItems = data['merchandise'];
          promotions = data['promotions'];
          _isLoading = false;
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
                        _buildRuleItem("1. Always wipe down equipment after use", isSmallScreen),
                        _buildRuleItem("2. Rerack weights after your workout", isSmallScreen),
                        _buildRuleItem("3. Respect other members' space and time", isSmallScreen),
                        _buildRuleItem("4. No dropping weights unnecessarily", isSmallScreen),
                        _buildRuleItem("5. Wear appropriate workout attire", isSmallScreen),
                        _buildRuleItem("6. Keep personal belongings in lockers", isSmallScreen),
                        _buildRuleItem("7. No photography without permission", isSmallScreen),
                        _buildRuleItem("8. Follow equipment time limits during peak hours", isSmallScreen),
                        _buildRuleItem("9. Report any equipment issues immediately", isSmallScreen),
                        _buildRuleItem("10. Be courteous and maintain gym etiquette", isSmallScreen),
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
              _buildQuickActionsSection(isSmallScreen, isThinScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildAnnouncementsSection(isSmallScreen, isThinScreen),
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
        : "Guest";
        
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigate to QR tab to check in!'),
                      backgroundColor: Color(0xFF45B7D1),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
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
        Text(
          'Announcements',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isLoading)
          _buildLoadingCard(isSmallScreen, isThinScreen)
        else if (announcements.isEmpty)
          _buildEmptyCard('No announcements available', isSmallScreen, isThinScreen)
        else
          ...announcements.map((announcement) => _buildAnnouncementCard(announcement, isSmallScreen, isThinScreen)),
      ],
    );
  }

  Widget _buildAnnouncementCard(AnnouncementItem announcement, bool isSmallScreen, bool isThinScreen) {
    // Convert hex color string to Color
    Color announcementColor = _hexToColor(announcement.color);
    
    return Container(
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
    );
  }

  Widget _buildMerchSection(bool isSmallScreen, bool isThinScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Merchandise',
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (_isLoading)
          Container(
            height: isSmallScreen ? 160 : 200,
            child: _buildLoadingCard(isSmallScreen, isThinScreen),
          )
        else if (merchItems.isEmpty)
          _buildEmptyCard('No merchandise available', isSmallScreen, isThinScreen)
        else ...[
          Container(
            height: isSmallScreen ? 160 : 200,
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
          SizedBox(height: isSmallScreen ? 8 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: merchItems.asMap().entries.map((entry) {
              return Container(
                width: isSmallScreen ? 6 : 8,
                height: isSmallScreen ? 6 : 8,
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(color: itemColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: itemColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isSmallScreen ? 12 : 16)
                ),
              ),
              child: Center(
                child: Icon(
                  _getIconData(item.icon),
                  size: isSmallScreen ? 36 : 48,
                  color: itemColor,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontSize: isThinScreen ? 11 : (isSmallScreen ? 12 : 14),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.price,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: itemColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        else
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
}