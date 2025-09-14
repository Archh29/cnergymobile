import 'package:flutter/material.dart';
import 'package:gym/SignUp.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import './User/services/auth_service.dart';
import 'user_dashboard.dart';
import 'account_verification_page.dart';
import 'coach_dashboard.dart'; // Import CoachDashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool obscurePassword = true;
  bool isLoading = false;
  bool rememberMe = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // JWT and security
  String? jwtToken;
  final Map<String, String> _cookies = {};

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    
    // Load remembered email
    _loadRememberedEmail();
  }

  // Load remembered email from SharedPreferences
  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final shouldRemember = prefs.getBool('remember_me') ?? false;
      
      if (shouldRemember && rememberedEmail != null) {
        setState(() {
          emailController.text = rememberedEmail;
          rememberMe = true;
        });
      }
    } catch (e) {
      print('❌ Error loading remembered email: $e');
    }
  }

  // Save remembered email to SharedPreferences
  Future<void> _saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('remembered_email', email);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      print('❌ Error saving remembered email: $e');
    }
  }

  String sanitizeInput(String input) {
    return input.replaceAll(RegExp(r'[<>/\\]'), '');
  }

  bool validateInputs(String email, String password) {
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill in all fields",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      Get.snackbar(
        "Error",
        "Please enter a valid email address",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      List<String> cookies = rawCookie.split(',');
      for (String cookie in cookies) {
        List<String> parts = cookie.split(';')[0].split('=');
        if (parts.length == 2) {
          _cookies[parts[0].trim()] = parts[1].trim();
        }
      }
    }
  }

  Map<String, String> _getCookieHeaders() {
    if (_cookies.isEmpty) return {};
    String cookieString = _cookies.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
    return {'Cookie': cookieString};
  }

  Future<void> _handleSuccessfulLogin(int userId, Map<String, dynamic> userData, String role, String token) async {
    try {
      print('🔄 Handling successful login for user: $userId, role: $role');
      
      // Set the current user in AuthService
      await AuthService.setCurrentUser(userId, userData);
      
      // Force refresh user data from server to get latest account_status
      print('📡 Refreshing user data from server...');
      await AuthService.refreshUserData();
      
      // Also store in SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', role);
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_id', userId.toString());
      await prefs.setString('email', userData['email'] ?? '');
      
      // Save remembered email if remember me is checked
      await _saveRememberedEmail(userData['email'] ?? '');

      if (mounted) {
        if (AuthService.isCoach()) {
          print('👨‍🏫 Coach login successful, navigating to CoachDashboard');
          Get.snackbar(
            "Success",
            "Welcome back Coach ${AuthService.getUserFirstName()}!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => CoachDashboard()),
            (Route<dynamic> route) => false,
          );
          return;
        } else if (AuthService.isAdmin() || AuthService.isStaff()) {
          print('👑 Admin/Staff login successful');
          Get.snackbar(
            "Success",
            "Welcome back ${AuthService.getUserFirstName()}!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => UserDashboard()),
            (Route<dynamic> route) => false,
          );
          return;
        } else if (AuthService.isCustomer()) {
          // For customers, check account status
          final accountStatus = AuthService.getAccountStatus();
          print('🔍 Customer Login Success - Account Status: $accountStatus');
          
          switch (accountStatus) {
            case 'approved':
              Get.snackbar(
                "Success",
                "Login successful! Welcome back ${AuthService.getUserFirstName()}.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => UserDashboard()),
                (Route<dynamic> route) => false,
              );
              break;
            case 'rejected':
              // Show rejection dialog and logout
              _showAccountRejectedDialog();
              break;
            case 'pending':
            default:
              Get.snackbar(
                "Account Pending",
                "Your account is pending verification. Please visit our front desk.",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountVerificationScreen()),
                (Route<dynamic> route) => false,
              );
              break;
          }
        } else {
          // Unknown user type
          print('⚠️ Unknown user type after login');
          Get.snackbar(
            "Login Error",
            "Unknown user type. Please contact support.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          await AuthService.logout();
        }
      }
    } catch (e) {
      print('❌ Error handling successful login: $e');
      Get.snackbar(
        "Login Error",
        "An error occurred during login. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showAccountRejectedDialog() {
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
            'Your account verification has been rejected. Please contact our staff for more information or create a new account.',
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
                // Stay on login screen - no navigation needed
              },
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void loginUser() async {
    if (isLoading) return;

    String email = sanitizeInput(emailController.text.trim());
    String password = sanitizeInput(passwordController.text.trim());

    if (!validateInputs(email, password)) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    var url = Uri.parse('https://api.cnergy.site/loginapp.php');
    Map<String, dynamic> requestData = {
      "email": email,
      "password": password,
    };

    try {
      print('🔐 Attempting login for: $email');
      
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ..._getCookieHeaders(),
        },
        body: jsonEncode(requestData),
      );

      _updateCookies(response);

      // Parse response body regardless of status code
      var data = jsonDecode(response.body);
      print('📡 Login response: $data');

      if (response.statusCode == 200) {
        // Check for error first
        if (data.containsKey("error")) {
          String errorMessage = data["error"];
          Get.snackbar(
            "Login Failed",
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // Check for successful login
        if (data.containsKey("jwt_token") && data.containsKey("user_role")) {
          String role = data['user_role'];
          String token = data['jwt_token'];

          // Check if admin/staff trying to access mobile
          if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'staff') {
            Get.snackbar(
              "Access Denied",
              "Admin and Staff access is only available through the web interface. Please use your computer to access the admin panel.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            return;
          }

          // Extract user ID - this is crucial!
          int? userId;
          if (data.containsKey('user_id')) {
            // Handle both string and int user_id
            if (data['user_id'] is String) {
              userId = int.tryParse(data['user_id']);
            } else if (data['user_id'] is int) {
              userId = data['user_id'];
            }
          }

          if (userId == null) {
            print('❌ No user_id found in login response');
            Get.snackbar(
              "Login Error",
              "Invalid user data received. Please try again.",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          print('👤 User ID extracted: $userId');

          // Create user data object for AuthService
          Map<String, dynamic> userData = {
            'user_id': userId,
            'id': userId, // Some parts of your code might expect 'id'
            'email': email,
            'user_type': role,
            'user_role': role,
            'jwt_token': token,
          };

          int userTypeId = 0;
          switch (role.toLowerCase()) {
            case 'admin': userTypeId = 1; break;
            case 'staff': userTypeId = 2; break;
            case 'coach': userTypeId = 3; break;
            case 'customer':
            case 'member': userTypeId = 4; break;
          }
          userData['user_type_id'] = userTypeId;

          print('💾 Storing user data: $userData');

          // Handle successful login with account status checking
          await _handleSuccessfulLogin(userId, userData, role, token);

        } else {
          print('❌ Missing jwt_token or user_role in response');
          Get.snackbar(
            "Login Error",
            "Invalid response from server. Please try again.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else if (response.statusCode == 401) {
        // Handle 401 Unauthorized - show the error message from response
        String errorMessage = "Invalid email or password";
        if (data.containsKey("error")) {
          errorMessage = data["error"];
        }
        print('❌ Login failed: $errorMessage');
        Get.snackbar(
          "Login Failed",
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        print('❌ Server error: ${response.statusCode}');
        Get.snackbar(
          "Server Error",
          "Server error (${response.statusCode}). Please try again later.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Login error: $e'); // For debugging
      Get.snackbar(
        "Connection Error",
        "Unable to connect to server. Please check your internet connection.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Updated navigation method - using direct navigation instead of named routes
  void _navigateToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignUpPage(),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  // Logo and branding section
                  Column(
                    children: [
                      // Logo
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
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Brand name
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "C",
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF6B35),
                              ),
                            ),
                            TextSpan(
                              text: "NERGY GYM",
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Transform Your Fitness Journey",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  // Login form section
                  const SizedBox(height: 32),
                  
                  // Email input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: const Color(0xFFFF6B35),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: const Color(0xFFFF6B35),
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Remember me checkbox
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            rememberMe = !rememberMe;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: rememberMe ? const Color(0xFFFF6B35) : Colors.transparent,
                            border: Border.all(
                              color: rememberMe ? const Color(0xFFFF6B35) : Colors.grey[600]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: rememberMe
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Remember me',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : loginUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'SIGN IN',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Forgot password? ',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/forgotPassword');
                        },
                        child: Text(
                          'Recover here',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF6B35),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Create account section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToCreateAccount,
                        child: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF6B35),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
