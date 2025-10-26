import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'User/services/password_recovery_service.dart';

// 📌 1️⃣ Forgot Password Screen (Enter Email)
class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendResetCode() async {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }
    
    if (!PasswordRecoveryService.isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordRecoveryService.sendResetCode(email);
      
      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(email: email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              
              // Header Icon
              Center(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    color: Colors.white,
                    size: isSmallScreen ? 40 : 48,
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Title
              Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Subtitle
              Text(
                'Don\'t worry! Enter your email address and we\'ll send you a verification code to reset your password.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // Email Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
                    'Email Address',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null 
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey[500],
                          size: isSmallScreen ? 20 : 24,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // Send Code Button
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 48 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetCode,
              style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Send Verification Code',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Back to Login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: 'Remember your password? ',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF4ECDC4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// 📌 2️⃣ OTP Verification Screen
class OTPVerificationScreen extends StatefulWidget {
  final String email;
  
  const OTPVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> otpControllers = List.generate(5, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(5, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _getOTPCode() {
    return otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyCode() async {
    final code = _getOTPCode();
    
    if (code.length != 5) {
      setState(() {
        _errorMessage = 'Please enter the complete 5-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordRecoveryService.verifyResetCode(widget.email, code);
      
      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNewPasswordScreen(
              email: widget.email,
              verificationCode: code,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordRecoveryService.resendResetCode(widget.email);
      
      if (result['success']) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New verification code sent!'),
            backgroundColor: const Color(0xFF4ECDC4),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend code. Please try again.';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verify Code',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              
              // Header Icon
              Center(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B73FF), Color(0xFF9DD5EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  ),
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.white,
                    size: isSmallScreen ? 40 : 48,
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Title
              Text(
                'Check Your Email',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Subtitle
              RichText(
                text: TextSpan(
                  text: 'We sent a 5-digit verification code to ',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4ECDC4),
                        fontWeight: FontWeight.w600,
                      ),
            ),
          ],
        ),
      ),
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return Container(
                    width: screenWidth * 0.15,
                    height: isSmallScreen ? 56 : 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null 
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                        
                        if (value.isNotEmpty && index < 4) {
                          focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          focusNodes[index - 1].requestFocus();
                        }
                        
                        // Auto-verify when all fields are filled
                        if (index == 4 && value.isNotEmpty) {
                          final code = _getOTPCode();
                          if (code.length == 5) {
                            _verifyCode();
                          }
                        }
                      },
                    ),
                  );
                }),
              ),
              
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
          children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 48 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Verify Code',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Resend Code
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Resend code in ${_resendCountdown}s',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      )
                    : TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        child: _isResending
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                                ),
                              )
                            : Text(
                                'Resend Code',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF4ECDC4),
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// 📌 3️⃣ Create New Password Screen
class CreateNewPasswordScreen extends StatefulWidget {
  final String email;
  final String verificationCode;
  
  const CreateNewPasswordScreen({
    Key? key, 
    required this.email,
    required this.verificationCode,
  }) : super(key: key);

  @override
  _CreateNewPasswordScreenState createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _passwordStrength = '';

  Future<void> _resetPassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    
    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }
    
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    final validation = PasswordRecoveryService.validatePassword(password);
    if (!validation['isValid']) {
      setState(() {
        _errorMessage = validation['message'];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordRecoveryService.resetPassword(
        widget.email,
        widget.verificationCode,
        password,
        confirmPassword,
      );
      
      if (result['success']) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetSuccessScreen(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkPasswordStrength(String password) {
    final validation = PasswordRecoveryService.validatePassword(password);
    setState(() {
      _passwordStrength = validation['strength'];
    });
  }

  Color _getStrengthColor() {
    switch (_passwordStrength) {
      case 'weak':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    final validation = PasswordRecoveryService.validatePassword(passwordController.text);
    final errorsList = validation['errors'];
    final errors = errorsList != null ? (errorsList as List<dynamic>).cast<String>() : <String>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey[800],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: errors.length > 3 ? 1 : errors.length > 2 ? 2 : 3,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _getStrengthColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _passwordStrength.toUpperCase(),
              style: GoogleFonts.poppins(
                color: _getStrengthColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Requirements list
        ...errors.map((error) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.close,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                error,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )).toList(),
        // Success message if all requirements met
        if (errors.isEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'All requirements met!',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create New Password',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              SizedBox(height: isSmallScreen ? 20 : 40),
              
              // Header Icon
              Center(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF96CEB4), Color(0xFF4ECDC4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: isSmallScreen ? 40 : 48,
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Title
            Text(
                'Create New Password',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 12),
              
              // Subtitle
            Text(
                'Your new password must be different from your previous password and contain at least 8 characters.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // New Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Password',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null 
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
                          size: isSmallScreen ? 20 : 24,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      ),
                      onChanged: (value) {
                        _checkPasswordStrength(value);
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  
                  // Password Strength Indicator
                  if (passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildPasswordStrengthIndicator(),
                  ],
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Confirm Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Password',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null 
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[500],
                          size: isSmallScreen ? 20 : 24,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                            size: isSmallScreen ? 20 : 24,
                          ),
              onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: isSmallScreen ? 32 : 40),
              
              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: isSmallScreen ? 48 : 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[700],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Reset Password',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// 📌 4️⃣ Password Reset Success Screen
class PasswordResetSuccessScreen extends StatefulWidget {
  @override
  _PasswordResetSuccessScreenState createState() => _PasswordResetSuccessScreenState();
}

class _PasswordResetSuccessScreenState extends State<PasswordResetSuccessScreen> {
  bool _isNavigating = false;

  void _navigateToLogin() async {
    if (_isNavigating) return;
    
    setState(() {
      _isNavigating = true;
    });
    
    print('🔄 GestureDetector: Back to Sign In tapped');
    
    try {
      // Navigate back to login screen by popping all password recovery screens
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('❌ Navigation error: $e');
      // Fallback: just pop the current screen
      Navigator.of(context).pop();
    }
    
    // Reset the navigation state after a delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: isSmallScreen ? 48 : 56,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 24 : 32),
              
              // Success Title
              Text(
                'Password Reset Successful!',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 12 : 16),
              
              // Success Message
              Text(
                'Your password has been successfully reset. You can now sign in with your new password.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 40 : 48),
              
              // Back to Login Button
              GestureDetector(
                onTap: _isNavigating ? null : _navigateToLogin,
                child: Container(
                  width: double.infinity,
                  height: isSmallScreen ? 48 : 56,
                  decoration: BoxDecoration(
                    color: _isNavigating ? Colors.grey[600] : const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isNavigating 
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Back to Sign In',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}