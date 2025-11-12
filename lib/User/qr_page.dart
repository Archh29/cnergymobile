import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import './services/auth_service.dart';
import './services/attendance_service.dart';
import './models/attendance_model.dart';
import '../widgets/attendance_success_modal.dart';

class QRPage extends StatefulWidget {
  @override
  _QRPageState createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  final GlobalKey _qrKey = GlobalKey();
  String? qrData;
  String? userName;
  String? userId;
  bool _isLoading = true;
  bool _isDownloading = false;
  Timer? _attendancePollingTimer;
  String? _lastAttendanceId;
  Set<String> _shownAttendanceIds = {}; // Track which attendance records we've already shown modals for
  bool? _lastCheckOutStatus; // Track if the last attendance had a check-out
  AttendanceModel? _currentAttendance; // Current attendance status to display on page
  DateTime? _lastCheckedDate; // Track the last date we checked attendance

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadUserData();
    // Monitoring will start after user data is loaded
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAttendanceMonitoring();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - check immediately for new attendance
      print('📱 App resumed - checking for new attendance immediately');
      if (userId != null && mounted) {
        _checkForNewAttendance();
      }
    }
  }

  void _startAttendanceMonitoring() {
    // Poll every 1 second to check for new attendance records (more frequent for immediate response)
    _attendancePollingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && userId != null) {
        _checkForNewAttendance();
      }
    });
    
    // Also check immediately when page loads
    if (userId != null) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _checkForNewAttendance();
        }
      });
    }
  }

  void _stopAttendanceMonitoring() {
    _attendancePollingTimer?.cancel();
    _attendancePollingTimer = null;
  }

  Future<void> _checkForNewAttendance() async {
    try {
      final userIdInt = int.tryParse(userId ?? '');
      if (userIdInt == null) {
        print('⚠️ QR Page: userId is null');
        return;
      }

      print('🔍 Checking attendance for user: $userIdInt');

      // Get today's date for filtering
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Check if date has changed - if so, reset everything
      if (_lastCheckedDate != null && _lastCheckedDate!.day != today.day) {
        print('📅 New day detected! Resetting attendance status.');
        setState(() {
          _currentAttendance = null;
          _lastAttendanceId = null;
          _lastCheckOutStatus = null;
          _shownAttendanceIds.clear();
        });
      }
      _lastCheckedDate = today;

      // Get attendance history
      final history = await AttendanceService.getAttendanceHistory(userIdInt, limit: 10);
      if (history.isEmpty) {
        print('⚠️ No attendance history found');
        setState(() {
          _currentAttendance = null;
          _lastAttendanceId = null;
        });
        return;
      }

      print('📋 Found ${history.length} attendance records');

      // Filter to only get today's attendance records
      final todayAttendance = history.where((attendance) {
        final checkInDate = DateTime(
          attendance.checkIn.year,
          attendance.checkIn.month,
          attendance.checkIn.day,
        );
        return checkInDate.isAtSameMomentAs(today);
      }).toList();

      if (todayAttendance.isEmpty) {
        print('📅 No attendance records for today');
        setState(() {
          _currentAttendance = null;
          _lastAttendanceId = null;
          _lastCheckOutStatus = null;
        });
        return;
      }

      print('📅 Found ${todayAttendance.length} attendance records for today');

      // Get the latest record for today (most recent check-in)
      final latestAttendance = todayAttendance.first;
      final currentAttendanceId = latestAttendance.id?.toString();
      
      print('📝 Latest attendance ID: $currentAttendanceId');
      print('📅 Check-in time: ${latestAttendance.checkIn}');
      print('📅 Check-out time: ${latestAttendance.checkOut}');
      
      if (currentAttendanceId == null) {
        print('⚠️ Attendance ID is null');
        return;
      }

      // Calculate time difference
      final timeDiff = now.difference(latestAttendance.checkIn).inSeconds;
      print('⏱️ Time difference: $timeDiff seconds (${(timeDiff / 60).toStringAsFixed(1)} minutes)');

      // Update current attendance status for display on page
      setState(() {
        _currentAttendance = latestAttendance;
      });

      // Check for check-out first (if user has checked out, prioritize showing check-out modal)
      final hasCheckOut = latestAttendance.checkOut != null;
      
      // Check if check-out status changed (was null, now has value) - this means user just checked out
      final checkOutJustHappened = _lastCheckOutStatus == false && hasCheckOut;
      
      // Only show modal if check-out JUST happened (status changed) and we haven't shown it yet
      if (hasCheckOut && checkOutJustHappened && !_shownAttendanceIds.contains('${currentAttendanceId}_out')) {
        print('✅ Check-out just happened! Showing modal once for ID: $currentAttendanceId');
        _showAttendanceModal(latestAttendance, 'checked_out');
        _shownAttendanceIds.add('${currentAttendanceId}_out');
        _lastCheckOutStatus = hasCheckOut;
        _lastAttendanceId = currentAttendanceId;
        return; // Don't show check-in modal if check-out was just shown
      }

      // Don't show modal for check-in - only show status on page
      // Just update the status tracking
      _lastCheckOutStatus = hasCheckOut;
      if (_lastAttendanceId != currentAttendanceId) {
        _lastAttendanceId = currentAttendanceId;
      }
    } catch (e, stackTrace) {
      // Print error for debugging
      print('❌ Error checking attendance: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Widget _buildAttendanceStatusCard(bool isSmallScreen) {
    final isCheckedIn = _currentAttendance?.checkOut == null;
    final checkInTime = _currentAttendance?.checkIn;
    final checkOutTime = _currentAttendance?.checkOut;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCheckedIn 
              ? [
                  Color(0xFF4ECDC4).withOpacity(0.1),
                  Color(0xFF44A08D).withOpacity(0.1),
                ]
              : [
                  Color(0xFFFF6B35).withOpacity(0.1),
                  Color(0xFFFF8E53).withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheckedIn 
              ? Color(0xFF4ECDC4).withOpacity(0.3)
              : Color(0xFFFF6B35).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCheckedIn ? Color(0xFF4ECDC4) : Color(0xFFFF6B35)).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCheckedIn 
                      ? Color(0xFF4ECDC4).withOpacity(0.2)
                      : Color(0xFFFF6B35).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCheckedIn ? Icons.check_circle : Icons.logout,
                  color: isCheckedIn ? Color(0xFF4ECDC4) : Color(0xFFFF6B35),
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? 'Currently Checked In' : 'Checked Out',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    if (checkInTime != null)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.login,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Check-in: ${_formatDateTime(checkInTime)}',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey[400],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (checkOutTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.logout,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Check-out: ${_formatDateTime(checkOutTime)}',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    return '$month/$day/$year ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _showAttendanceModal(AttendanceModel attendance, String action) {
    print('🎉 Showing attendance modal - Action: $action, ID: ${attendance.id}');
    
    // Create a response object from the attendance model
    final response = AttendanceResponse(
      success: true,
      action: action,
      message: action == 'checked_in' 
          ? 'Check-in successful' 
          : 'Check-out successful',
      userName: attendance.fullName,
      checkInTime: attendance.checkIn.toIso8601String(),
      checkOutTime: attendance.checkOut?.toIso8601String(),
    );

    if (mounted) {
      print('✅ Context is mounted, showing modal');
      showAttendanceSuccessModal(context, response);
    } else {
      print('⚠️ Context is not mounted, cannot show modal');
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadUserData() async {
    try {
      if (!AuthService.isLoggedIn()) {
        _showErrorAndReturn('Please log in to view your QR code');
        return;
      }

      final currentUserId = AuthService.getCurrentUserId();
      final fullName = AuthService.getUserFullName();

      if (currentUserId == null) {
        _showErrorAndReturn('Unable to get user information');
        return;
      }

      setState(() {
        userId = currentUserId.toString();
        userName = fullName ?? 'CNERGY Member';
        // Generate QR data with user ID for attendance scanning
        qrData = 'CNERGY_ATTENDANCE:$currentUserId';
        _isLoading = false;
      });
      
      // Start monitoring after user data is loaded
      _startAttendanceMonitoring();
    } catch (e) {
      _showErrorAndReturn('Error loading user data: $e');
    }
  }

  void _showErrorAndReturn(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _downloadQR() async {
    if (qrData == null) return;
    
    setState(() => _isDownloading = true);
    
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      if (kIsWeb) {
        // Web implementation
        final blob = html.Blob([pngBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'cnergy_attendance_qr_${userId ?? 'user'}.png')
          ..click();
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR Code download started!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        // Mobile implementation
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/cnergy_attendance_qr_${userId ?? 'user'}.png');
        await file.writeAsBytes(pngBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'QR Code saved to Downloads!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download QR Code: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    setState(() => _isDownloading = false);
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your QR code...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isSmallScreen = screenWidth < 360;
                final isMediumScreen = screenWidth < 400;
                
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4ECDC4).withOpacity(0.8), Color(0xFF44A08D).withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4ECDC4).withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.qr_code, color: Colors.white, size: isSmallScreen ? 20 : 28),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Attendance QR',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 16 : isMediumScreen ? 18 : 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 2 : 4),
                                Text(
                                  'Show this to staff for check-in/out',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isSmallScreen ? 11 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 40),
                    
                    // Current Attendance Status
                    if (_currentAttendance != null) _buildAttendanceStatusCard(isSmallScreen),
                    if (_currentAttendance != null) SizedBox(height: isSmallScreen ? 16 : 24),
                
                // QR Code Section
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: RepaintBoundary(
                          key: _qrKey,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF4ECDC4).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: qrData!,
                                  version: QrVersions.auto,
                                  size: isSmallScreen ? 150 : 200,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  
                                  embeddedImageStyle: QrEmbeddedImageStyle(
                                    size: Size(isSmallScreen ? 30 : 40, isSmallScreen ? 30 : 40),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),
                                Text(
                                  'Attendance QR Code',
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 6 : 8),
                                Text(
                                  userName!,
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 40),
                
                // Action Buttons
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4ECDC4).withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadQR,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isDownloading
                       ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.download),
                    label: Text(
                      _isDownloading ? 'Saving...' : 'Download QR Code',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Info Cards
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'How to use your QR code',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Show this QR code to gym staff when you arrive or leave. They will scan it to automatically check you in or out of the gym. Your attendance will be tracked for your workout sessions.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Security Info
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(0xFF45B7D1).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security, color: Color(0xFF45B7D1), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Secure & Private',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'This QR code contains your unique member ID and is encrypted for security. Only authorized CNERGY staff can use it for attendance tracking.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
    ),
    );
  }
}
