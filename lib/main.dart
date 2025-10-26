import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './User/services/auth_service.dart';
import './debug_data_check.dart';
import './restore_workout_data.dart';
import './force_restore_data.dart';

// Screens
import 'login_screen.dart';
import 'user_dashboard.dart';
import 'coach_dashboard.dart';
import 'first_time_setup_screen.dart';
import 'welcome_onboarding_screen.dart';
import 'forgot_pass.dart';
import 'account_verification_page.dart';
import 'account_deactivated_page.dart';

// Coach Pages
import 'Coach/coach_messages_page.dart';
import 'Coach/session_management_page.dart';
import 'Coach/coach_routine_page.dart';
import 'Coach/models/member_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 🔐 Initialize AuthService to load user from storage
  await AuthService.initialize();
  
  // FIXED: Ensure user_id is stored as integer in SharedPreferences
  await _fixUserIdStorage();
  
  // Test weights debug
  await _testWeightsDebug();
  
  // Check all your data
  await DebugDataCheck.checkAllData();
  
  // Force restore all your data
  await ForceRestoreData.forceRestoreAllData();
  
  runApp(MyApp());
}

// ADDED: Function to fix user_id storage type
Future<void> _fixUserIdStorage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user_id exists and fix its type
    if (prefs.containsKey('user_id')) {
      // Try to get as int first
      int? userId = prefs.getInt('user_id');
      
      // If null, it might be stored as string
      if (userId == null) {
        String? userIdString = prefs.getString('user_id');
        if (userIdString != null && userIdString.isNotEmpty) {
          userId = int.tryParse(userIdString);
          
          if (userId != null) {
            // Remove the string version and save as int
            await prefs.remove('user_id');
            await prefs.setInt('user_id', userId);
            print('Fixed user_id storage: converted "$userIdString" to $userId (int)');
          }
        }
      }
    }
    
    // Also check and fix other user-related integer fields
    final fieldsToFix = ['id', 'user_type_id', 'gender_id'];
    for (String field in fieldsToFix) {
      if (prefs.containsKey(field)) {
        int? value = prefs.getInt(field);
        if (value == null) {
          String? stringValue = prefs.getString(field);
          if (stringValue != null && stringValue.isNotEmpty) {
            int? intValue = int.tryParse(stringValue);
            if (intValue != null) {
              await prefs.remove(field);
              await prefs.setInt(field, intValue);
              print('Fixed $field storage: converted "$stringValue" to $intValue (int)');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Error fixing user_id storage: $e');
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF6B00),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B00), width: 2),
          ),
          hintStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      home: AuthWrapper(), // CHANGED: Use AuthWrapper for better account status handling
      routes: {
        '/login': (context) => const LoginScreen(),
        '/userDashboard': (context) => UserDashboard(),
        '/coachDashboard': (context) => CoachDashboard(),
        '/FirstTimeSetup': (context) => const FirstTimeSetupScreenRoute(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/accountVerification': (context) => const AccountVerificationScreen(),
        '/coach-messages': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is MemberModel) {
            return CoachMessagesPage(selectedMember: args);
          }
          return CoachMessagesPage();
        },
        '/coach-session-management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is MemberModel) {
            return SessionManagementPage(selectedMember: args);
          }
          return SessionManagementPage();
        },
        '/coach-routines': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is MemberModel) {
            return CoachRoutinePage(selectedMember: args);
          }
          return CoachRoutinePage();
        },
      },
    );
  }
}

// NEW: AuthWrapper to handle authentication and account status
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('🔍 AuthWrapper: Checking authentication status...');
      
      // Ensure AuthService is initializedr
      if (!AuthService.isInitialized) {
        print('🔄 AuthService not initialized, initializing...');
        await AuthService.initialize();
        
      }
      
      // If user is logged in, refresh their data from server
      if (AuthService.isLoggedIn()) {
        print('✅ User is logged in, refreshing data from server...');
        await AuthService.refreshUserData();
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      
      // Check if the error is due to account deactivation
      if (e.toString().contains('Account deactivated')) {
        print('🚫 Account deactivated detected - redirecting to deactivation page');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AccountDeactivatedPage(),
            ),
          );
          return;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🚀 BUILD METHOD CALLED - TEMPORARY FIX ACTIVE');
    if (_isChecking) {
      return _buildLoadingScreen();
    }

    // Check if user is logged in
    if (!AuthService.isLoggedIn()) {
      print('❌ User not logged in, showing LoginScreen');
      return const LoginScreen();
    }

    final user = AuthService.getCurrentUser();
    if (user == null) {
      print('❌ No user data, showing LoginScreen');
      return const LoginScreen();
    }

    final userId = AuthService.getCurrentUserId()!;
    print('✅ User logged in - ID: $userId, Type: ${AuthService.getUserType()}');
    print('🔍 User type checks - isCustomer: ${AuthService.isCustomer()}, isCoach: ${AuthService.isCoach()}, isAdmin: ${AuthService.isAdmin()}, isStaff: ${AuthService.isStaff()}');

    // SECURITY FIX: Check if user needs account verification
    if (AuthService.needsAccountVerification()) {
      print('🔐 User needs account verification, showing AccountVerificationScreen');
      return const AccountVerificationScreen();
    }

    // TEMPORARY FIX: Force show first-time setup if profile is not completed
    print('🔧 TEMPORARY FIX: Checking profile completion for all users...');
    print('🔧 TEMPORARY FIX: User ID: $userId, User Type: ${AuthService.getUserType()}');
    return FutureBuilder<bool>(
      future: AuthService.isProfileCompleted(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        final profileCompleted = snapshot.data ?? false;
        print('📋 Profile completed (temp fix): $profileCompleted');
        print('🔧 TEMPORARY FIX: About to show FirstTimeSetupScreen for user $userId');
        
        if (!profileCompleted) {
          print('🔧 User needs profile setup (temp fix), showing WelcomeOnboardingScreen');
          return WelcomeOnboardingScreen(userId: userId);
        } else {
          print('✅ Profile completed (temp fix), routing based on user type');
          return _getHomeScreen();
        }
      },
    );
  }


  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/gym.logo.png',
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Loading animation
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'CYNERGY GYM',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            
            Text(
              'Loading your experience...',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getHomeScreen() {
    // First check if user is logged in
    if (!AuthService.isLoggedIn()) {
      print('🔐 User not logged in, showing login screen');
      return const LoginScreen();
    }
    
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

// Route wrapper for FirstTimeSetupScreen
class FirstTimeSetupScreenRoute extends StatelessWidget {
  const FirstTimeSetupScreenRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.getCurrentUserId();
    if (userId != null) {
      return FirstTimeSetupScreen(userId: userId);
    }
    return FirstTimeSetupScreen(); // For new registrations
  }
}

// Debug function to test weights
Future<void> _testWeightsDebug() async {
  try {
    print('🔍 Testing weights for user 61, exercise 23...');
    
    final response = await http.get(
      Uri.parse('https://api.cnergy.site/debug_weights.php?user_id=61&exercise_id=23'),
      headers: {"Content-Type": "application/json"},
    );
    
    print('📊 Debug response status: ${response.statusCode}');
    print('📋 Debug response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ Debug data received:');
      print('  - Logged sets count: ${data['logged_sets_count']}');
      print('  - Program weights count: ${data['program_weights_count']}');
      print('  - Logged sets: ${json.encode(data['logged_sets'])}');
      print('  - Program weights: ${json.encode(data['program_weights'])}');
    }
  } catch (e) {
    print('💥 Error testing weights: $e');
  }
}
