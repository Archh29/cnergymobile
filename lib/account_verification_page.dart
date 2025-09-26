import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './User/services/auth_service.dart';
import 'login_screen.dart';
import 'user_dashboard.dart';
import 'coach_dashboard.dart';
import 'first_time_setup_screen.dart';
import 'welcome_onboarding_screen.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() => _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkIfVerificationNeeded();
  }

  Future<void> _checkIfVerificationNeeded() async {
    // If user doesn't need account verification, check profile completion
    if (!AuthService.needsAccountVerification()) {
      print('✅ User does not need account verification, checking profile completion');
      await _navigateBasedOnProfileCompletion();
      return;
    }
    
    // If user needs verification, check current status
    await _checkAccountStatus();
  }

  Future<void> _navigateBasedOnProfileCompletion() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        print('❌ No user ID found, redirecting to login');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      print('🔧 VERIFICATION: Checking profile completion for user $userId');
      final profileCompleted = await AuthService.isProfileCompleted();
      print('🔧 VERIFICATION: Profile completed: $profileCompleted');
      
      if (!profileCompleted) {
        print('🔧 VERIFICATION: User needs profile setup, navigating to WelcomeOnboardingScreen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => WelcomeOnboardingScreen(userId: userId)),
          );
        }
      } else {
        print('🔧 VERIFICATION: Profile completed, navigating to UserDashboard');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => _getHomeScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking profile completion: $e');
      // Fallback to UserDashboard if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => _getHomeScreen()),
        );
      }
    }
  }

  Future<void> _checkAccountStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      if (!AuthService.needsAccountVerification()) {
        print('✅ User no longer needs verification, checking profile completion');
        if (mounted) {
          await _navigateBasedOnProfileCompletion();
        }
        return;
      }

      // Force refresh user data from server
      print('🔄 Checking account status from server...');
      final accountStatus = await AuthService.checkAccountStatusFromServer();
      
      print('📊 Current account status: $accountStatus');
      
      if (accountStatus == 'approved') {
        // Account approved, check profile completion
        if (mounted) {
          print('✅ Account approved, checking profile completion');
          await _navigateBasedOnProfileCompletion();
        }
      } else if (accountStatus == 'rejected') {
        // Account rejected, show dialog and logout
        if (mounted) {
          print('❌ Account rejected, showing dialog');
          _showRejectedDialog();
        }
      } else {
        // Still pending
        if (mounted) {
          print('⏳ Account still pending');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your account is still pending verification'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking account status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Rejected',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            'Unfortunately, your account verification has been rejected. Please contact our staff for more information or create a new account.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B00),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final userName = AuthService.getUserFirstName();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Account Verification',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 60),
              
              // Welcome message
              Text(
                'Hello, $userName!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Status message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFFFF6B00),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Account Verification Pending',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF6B00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your account is currently under review by our staff. To complete the verification process and access all app features, please visit our front desk.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Instructions card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          color: const Color(0xFF4ECDC4),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'What to do next:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Step 1
                    _buildInstructionStep(
                      icon: Icons.location_on_outlined,
                      title: 'Visit Our Front Desk',
                      description: 'Come to our gym location during business hours',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Step 2
                    _buildInstructionStep(
                      icon: Icons.badge_outlined,
                      title: 'Bring Valid ID',
                      description: 'Present any valid photo ID for verification',
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Step 3
                    _buildInstructionStep(
                      icon: Icons.how_to_reg_outlined,
                      title: 'Complete Verification',
                      description: 'Our staff will verify your identity and approve your account',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Business hours info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: const Color(0xFF4ECDC4),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Business Hours',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Monday - Friday: 6:00 AM - 10:00 PM\nSaturday - Sunday: 7:00 AM - 9:00 PM',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Check status button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCheckingStatus ? null : _checkAccountStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isCheckingStatus
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Checking Status...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check Status',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Logout button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4ECDC4),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getHomeScreen() {
    print('🏠 Determining home screen for user type: ${AuthService.getUserType()}');
    
    if (AuthService.isCoach()) {
      print('👨‍🏫 Routing coach to CoachDashboard');
      return CoachDashboard();
    } else if (AuthService.isCustomer()) {
      print('👤 Routing customer to UserDashboard');
      return UserDashboard();
    } else if (AuthService.isAdmin()) {
      print('👑 Routing admin to UserDashboard');
      return UserDashboard(); // or AdminDashboard()
    } else if (AuthService.isStaff()) {
      print('👷 Routing staff to UserDashboard');
      return UserDashboard(); // or StaffDashboard()
    } else {
      print('⚠️ Unknown user type, redirecting to login');
      return const LoginScreen();
    }
  }
}
