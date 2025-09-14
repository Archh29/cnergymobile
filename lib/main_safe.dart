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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize AuthService with error handling
    try {
      await AuthService.initialize();
      print('✅ AuthService initialized successfully');
    } catch (e) {
      print('❌ AuthService initialization failed: $e');
      // Continue anyway - the app will handle this gracefully
    }
    
    // Fix user_id storage with error handling
    try {
      await _fixUserIdStorage();
    } catch (e) {
      print('❌ Error fixing user_id storage: $e');
      // Continue anyway
    }
    
    runApp(MyApp());
  } catch (e) {
    print('❌ Critical error in main(): $e');
    // Run a minimal app that just shows an error screen
    runApp(ErrorApp(error: e.toString()));
  }
}

// Error app for critical failures
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                SizedBox(height: 20),
                Text(
                  'App Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please refresh the page or contact support.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Try to reload the page
                    if (GetPlatform.isWeb) {
                      // For web, reload the page
                      // ignore: undefined_prefixed_name
                      html.window.location.reload();
                    }
                  },
                  child: Text('Reload Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Function to fix user_id storage type with better error handling
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
    rethrow; // Re-throw to be caught by main()
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
      home: SafeAuthWrapper(), // Use safer wrapper
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

// Safer AuthWrapper with comprehensive error handling
class SafeAuthWrapper extends StatefulWidget {
  @override
  _SafeAuthWrapperState createState() => _SafeAuthWrapperState();
}

class _SafeAuthWrapperState extends State<SafeAuthWrapper> {
  bool _isChecking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('🔍 SafeAuthWrapper: Checking authentication status...');
      
      // Ensure AuthService is initialized
      if (!AuthService.isInitialized) {
        print('🔄 AuthService not initialized, initializing...');
        try {
          await AuthService.initialize();
        } catch (e) {
          print('❌ Failed to initialize AuthService: $e');
          _error = 'Failed to initialize authentication service';
          return;
        }
      }
      
      // If user is logged in, refresh their data from server
      if (AuthService.isLoggedIn()) {
        print('✅ User is logged in, refreshing data from server...');
        try {
          await AuthService.refreshUserData();
        } catch (e) {
          print('❌ Failed to refresh user data: $e');
          // Don't set error here - just log it and continue
        }
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _error = 'Authentication check failed: ${e.toString()}';
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
    if (_isChecking) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    try {
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

      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        print('❌ No user ID, showing LoginScreen');
        return const LoginScreen();
      }

      print('✅ User logged in - ID: $userId, Type: ${AuthService.getUserType()}');

      // Check user type first and route accordingly
      if (AuthService.isCoach()) {
        print('👨‍🏫 User is coach, showing CoachDashboard');
        return CoachDashboard();
      } else if (AuthService.isAdmin()) {
        print('👑 User is admin, showing UserDashboard');
        return UserDashboard();
      } else if (AuthService.isStaff()) {
        print('👷 User is staff, showing UserDashboard');
        return UserDashboard();
      } else if (AuthService.isCustomer()) {
        print('👤 User is customer, checking account status...');
        
        // Check account verification status
        final accountStatus = AuthService.getAccountStatus();
        print('🔐 Account status: $accountStatus');
        
        if (accountStatus == 'pending') {
          print('⏳ Account pending verification, showing AccountVerificationScreen');
          return const AccountVerificationScreen();
        } else if (accountStatus == 'rejected') {
          print('❌ Account rejected, logging out and showing LoginScreen');
          // Schedule logout for next frame to avoid state changes during build
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await AuthService.logout();
              Get.snackbar(
                "Account Rejected",
                "Your account has been rejected. Please contact support.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            } catch (e) {
              print('❌ Error during logout: $e');
            }
          });
          return const LoginScreen();
        } else if (accountStatus == 'approved') {
          print('✅ Account approved, checking profile completion...');
          
          // Use FutureBuilder for async profile completion check
          return FutureBuilder<bool>(
            future: AuthService.isProfileCompleted(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }
              
              if (snapshot.hasError) {
                print('❌ Error checking profile completion: ${snapshot.error}');
                // Default to showing UserDashboard if we can't check profile
                return UserDashboard();
              }
              
              final profileCompleted = snapshot.data ?? false;
              print('📋 Profile completed: $profileCompleted');
              
              if (!profileCompleted) {
                print('🔧 Customer needs profile setup, showing FirstTimeSetupScreen');
                return FirstTimeSetupScreen(userId: userId);
              } else {
                print('✅ Customer profile completed, showing UserDashboard');
                return UserDashboard();
              }
            },
          );
        }
      }

      // Fallback - if user type is unknown, show login
      print('⚠️ Unknown user type, redirecting to login');
      return const LoginScreen();
    } catch (e) {
      print('❌ Error in SafeAuthWrapper build: $e');
      return _buildErrorScreen();
    }
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
                  return Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: const Color(0xFFFF6B35),
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
              'CNERGY GYM',
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

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                _error ?? 'An unexpected error occurred',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isChecking = true;
                    _error = null;
                  });
                  _checkAuthStatus();
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






