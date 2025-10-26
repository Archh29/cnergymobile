import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'first_time_setup_screen.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  final int userId;
  
  const WelcomeOnboardingScreen({
    super.key,
    required this.userId,
  });

  @override
  _WelcomeOnboardingScreenState createState() => _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  int currentPage = 0;
  final int totalPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _proceedToSetup();
    }
  }

  void _proceedToSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FirstTimeSetupScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content - Make it scrollable
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                children: [
                  _buildWelcomePage(isSmallScreen),
                  _buildFeaturesPage(isSmallScreen),
                  _buildReadyPage(isSmallScreen),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: List.generate(totalPages, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < totalPages - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= currentPage 
                    ? const Color(0xFFFF6B35) 
                    : Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: isSmallScreen ? 16 : 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add some top spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // Animated Logo/Icon
                Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: isSmallScreen ? 50 : 60,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Title with emoji
                Text(
                  'Welcome to\nCnergy Gym 💪',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 26 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Exciting subtitle
                Text(
                  'Transform your fitness journey with our\nall-in-one gym management platform!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 30),
                
                // Quick feature highlights
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildQuickFeature('🎯', 'Personalized Workouts'),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildQuickFeature('📊', 'Progress Tracking'),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildQuickFeature('👨‍💼', 'Expert Coaching'),
                    ],
                  ),
                ),
                
                // Add bottom spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesPage(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: isSmallScreen ? 16 : 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add some top spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // Features icon
                Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: isSmallScreen ? 40 : 50,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Title
                Text(
                  'Powerful Features\nAwait You! 🚀',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 20 : 30),
                
                // Features list with gym-specific features
                _buildFeatureItem(
                  Icons.qr_code_scanner,
                  'QR Code Check-in',
                  'Quick and secure gym access',
                  isSmallScreen,
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                _buildFeatureItem(
                  Icons.fitness_center,
                  'Smart Routines',
                  'AI-powered workout recommendations',
                  isSmallScreen,
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                _buildFeatureItem(
                  Icons.analytics,
                  'Progress Analytics',
                  'Track your fitness journey with detailed insights',
                  isSmallScreen,
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                _buildFeatureItem(
                  Icons.message,
                  'Coach Communication',
                  'Direct messaging with your personal trainer',
                  isSmallScreen,
                ),
                
                // Add bottom spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 32 : 40,
          height: isSmallScreen ? 32 : 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B35).withOpacity(0.2),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 16 : 20,
            color: const Color(0xFFFF6B35),
          ),
        ),
        
        SizedBox(width: isSmallScreen ? 12 : 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyPage(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 32,
              vertical: isSmallScreen ? 16 : 24,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add some top spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
                
                // Ready icon with premium badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: isSmallScreen ? 100 : 120,
                      height: isSmallScreen ? 100 : 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.rocket_launch,
                        size: isSmallScreen ? 50 : 60,
                        color: Colors.white,
                      ),
                    ),
                    // Premium badge
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Title
                Text(
                  'Ready to Transform\nYour Fitness? 🎯',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 26 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 16 : 20),
                
                // Subtitle
                Text(
                  'Join thousands of members who have transformed their lives with Cnergy Gym\'s comprehensive fitness platform!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Premium benefits
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[900]!,
                        Colors.grey[850]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildBenefitItem('💎', 'Premium Membership Access', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildBenefitItem('🏋️‍♂️', 'Unlimited Workout Routines', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildBenefitItem('📈', 'Advanced Progress Tracking', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildBenefitItem('👨‍💼', 'Personal Coach Sessions', isSmallScreen),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      _buildBenefitItem('📱', 'Smart Gym Check-in', isSmallScreen),
                    ],
                  ),
                ),
                
                // Add bottom spacing for small screens
                SizedBox(height: isSmallScreen ? 20 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFeature(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String emoji, String text, bool isSmallScreen) {
    return Row(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: isSmallScreen ? 16 : 20),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      child: Row(
        children: [
          // Skip button (only show on first page)
          if (currentPage == 0)
            Expanded(
              child: TextButton(
                onPressed: _proceedToSetup,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          if (currentPage == 0) SizedBox(width: isSmallScreen ? 12 : 16),
          
          // Next/Get Started button
          Expanded(
            flex: currentPage == 0 ? 2 : 1,
            child: Container(
              height: isSmallScreen ? 48 : 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _nextPage,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentPage == totalPages - 1 ? 'Start My Journey!' : 'Continue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Icon(
                          currentPage == totalPages - 1 
                              ? Icons.rocket_launch 
                              : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
