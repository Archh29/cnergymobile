import 'package:flutter/material.dart';
import 'package:gym/SignUp.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import './User/services/auth_service.dart'; // Import your AuthService

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

    var url = Uri.parse('http://localhost/cynergy/loginapp.php');
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

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('📡 Login response: $data');

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

          // Add any additional user data from the response
          if (data.containsKey('user_name')) {
            userData['user_name'] = data['user_name'];
            userData['fname'] = data['user_name']; // For compatibility
          }
          if (data.containsKey('first_name')) {
            userData['fname'] = data['first_name'];
            userData['first_name'] = data['first_name'];
          }
          if (data.containsKey('last_name')) {
            userData['lname'] = data['last_name'];
            userData['last_name'] = data['last_name'];
          }
          if (data.containsKey('fname')) {
            userData['fname'] = data['fname'];
          }
          if (data.containsKey('lname')) {
            userData['lname'] = data['lname'];
          }
          if (data.containsKey('profile_completed')) {
            userData['profile_completed'] = data['profile_completed'];
          }
          if (data.containsKey('is_member')) {
            userData['is_member'] = data['is_member'];
          }
          if (data.containsKey('membership_status')) {
            userData['membership_status'] = data['membership_status'];
          }

          print('💾 Storing user data: $userData');

          // Use AuthService to set the current user - THIS IS THE KEY FIX!
          await AuthService.setCurrentUser(userId, userData);

          // Also store in SharedPreferences for backward compatibility
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('role', role);
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_id', userId.toString());
          await prefs.setString('email', email);

          // Verify the data was stored correctly
          print('✅ AuthService verification:');
          print('   - Is Logged In: ${AuthService.isLoggedIn()}');
          print('   - Current User ID: ${AuthService.getCurrentUserId()}');
          print('   - Current User: ${AuthService.getCurrentUser()}');

          String routeName = _getRouteFromRole(role);

          Get.snackbar(
            "Success",
            "Login successful! Welcome back ${AuthService.getUserFirstName()}.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );

          // Navigate to dashboard
          if (mounted) {
            Navigator.pushReplacementNamed(context, routeName);
          }
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

  String _getRouteFromRole(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return '/coachDashboard';
      case 'customer':
        return '/userDashboard';
      default:
        return '/login';
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
                        'Keep me logged in',
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
                  const SizedBox(height: 24),
                  
                  // Alternative: Create Account Button (more prominent)
                  
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
