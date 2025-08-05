import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './User/services/auth_service.dart';

// Screens
import 'login_screen.dart';
import 'user_dashboard.dart';
import 'coach_dashboard.dart';
import 'first_time_setup_screen.dart';
import 'forgot_pass.dart';
import 'account_verification_page.dart';

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
      home: const InitialScreenLoader(), // CHANGED: Use async loader
      routes: {
        '/login': (context) => const LoginScreen(),
        '/userDashboard': (context) => UserDashboard(),
        '/coachDashboard': (context) => CoachDashboard(),
        '/FirstTimeSetup': (context) => const FirstTimeSetupScreenRoute(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/accountVerification': (context) => const AccountVerificationScreen(),
      },
    );
  }
}

// NEW: Async screen loader to handle profile completion check
class InitialScreenLoader extends StatefulWidget {
  const InitialScreenLoader({super.key});

  @override
  State<InitialScreenLoader> createState() => _InitialScreenLoaderState();
}

class _InitialScreenLoaderState extends State<InitialScreenLoader> {
  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
  }

  Future<void> _determineInitialScreen() async {
    print('🔍 Determining initial screen...');
    
    // Check if user is logged in
    if (!AuthService.isLoggedIn()) {
      print('❌ User not logged in, going to LoginScreen');
      _navigateToScreen(const LoginScreen());
      return;
    }

    final user = AuthService.getCurrentUser();
    if (user == null) {
      print('❌ No user data, going to LoginScreen');
      _navigateToScreen(const LoginScreen());
      return;
    }

    final userId = AuthService.getCurrentUserId()!;
    print('✅ User logged in - ID: $userId, Type: ${AuthService.getUserType()}');

    // Only customers (user_type_id = 4) need account verification and profile setup
    if (AuthService.isCustomer()) {
      print('👤 User is customer, checking account status...');
      
      // First check account verification status
      final accountStatus = user['account_status'] ?? 'pending';
      print('🔐 Account status: $accountStatus');
      
      if (accountStatus == 'pending') {
        print('⏳ Account pending verification, going to AccountVerificationScreen');
        _navigateToScreen(const AccountVerificationScreen());
        return;
      } else if (accountStatus == 'rejected') {
        print('❌ Account rejected, logging out and going to LoginScreen');
        await AuthService.logout();
        _navigateToScreen(const LoginScreen());
        return;
      } else if (accountStatus == 'approved') {
        print('✅ Account approved, checking profile completion...');
        
        // FIXED: Use async profile completion check
        final profileCompleted = await AuthService.isProfileCompleted();
        print('📋 Profile completed: $profileCompleted');
        
        if (!profileCompleted) {
          print('🔧 Customer needs profile setup, going to FirstTimeSetupScreen');
          _navigateToScreen(FirstTimeSetupScreen(userId: userId));
          return;
        } else {
          print('✅ Customer profile completed, going to UserDashboard');
          _navigateToScreen(UserDashboard());
          return;
        }
      }
    }

    // User is logged in and profile is complete (or not a customer)
    print('🏠 Going to appropriate dashboard...');
    _navigateToScreen(_getHomeScreen());
  }

  void _navigateToScreen(Widget screen) {
    // Use a slight delay to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => screen),
        );
      }
    });
  }

  Widget _getHomeScreen() {
    print('🏠 Determining home screen for user type: ${AuthService.getUserType()}');
    
    if (AuthService.isCustomer()) {
      return UserDashboard();
    } else if (AuthService.isCoach()) {
      return CoachDashboard();
    } else if (AuthService.isAdmin()) {
      return UserDashboard(); // or AdminDashboard()
    } else if (AuthService.isStaff()) {
      return UserDashboard(); // or StaffDashboard()
    } else {
      print('⚠️ Unknown user type, redirecting to login');
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while determining initial screen
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading animation
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up your experience',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NEW: Route wrapper for FirstTimeSetupScreen
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
