import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import './User/services/guest_session_service.dart';
import 'walk_in_session_status_screen.dart';

class WalkInQRDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const WalkInQRDisplayScreen({
    super.key,
    required this.sessionData,
  });

  @override
  State<WalkInQRDisplayScreen> createState() => _WalkInQRDisplayScreenState();
}

class _WalkInQRDisplayScreenState extends State<WalkInQRDisplayScreen> {
  Map<String, dynamic>? _currentSessionData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSessionData = widget.sessionData;
    _initializeSessionData();
  }

  Future<void> _initializeSessionData() async {
    // If session data is not provided (e.g., after refresh), load from local storage
    if (_currentSessionData == null) {
      final savedData = await GuestSessionService.getGuestSessionData();
      if (savedData != null) {
        setState(() {
          _currentSessionData = savedData;
        });
      }
    } else {
      // Save session data to local storage when first loaded
      await GuestSessionService.saveGuestSessionData(_currentSessionData!);
    }
    
    // Check session status
    _checkSessionStatus();
  }

  Future<void> _checkSessionStatus() async {
    if (_currentSessionData == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GuestSessionService.getGuestSession(
        _currentSessionData!['id'],
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _currentSessionData = result['data'];
        });
        
        // Save updated session data
        await GuestSessionService.saveGuestSessionData(_currentSessionData!);
      } else {
        Get.snackbar(
          'Error',
          'Failed to get session data: ${result['message']}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check session status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is String) {
      try {
        final parsedAmount = double.parse(amount);
        return parsedAmount.toStringAsFixed(2);
      } catch (e) {
        return '0.00';
      }
    } else if (amount is num) {
      return amount.toStringAsFixed(2);
    }
    return '0.00';
  }

  String _getStatusText() {
    if (_currentSessionData == null) return 'Unknown';
    
    final status = _currentSessionData!['status'];
    final paidValue = _currentSessionData!['paid'];
    
    // Handle different data types for paid field
    bool paid = false;
    if (paidValue == 1 || paidValue == '1' || paidValue == true) {
      paid = true;
    }
    
    if (status == 'approved' && paid) {
      return 'Ready to Use';
    } else if (status == 'approved' && !paid) {
      return 'Approved - Pending Payment';
    } else if (status == 'pending') {
      return 'Pending Payment';
    } else if (status == 'rejected') {
      return 'Rejected';
    }
    return 'Unknown';
  }

  Color _getStatusColor() {
    final status = _getStatusText();
    switch (status) {
      case 'Ready to Use':
        return Colors.green;
      case 'Approved - Pending Payment':
        return Colors.blue;
      case 'Pending Payment':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _canShowQR() {
    if (_currentSessionData == null) return false;
    
    final status = _currentSessionData!['status'];
    final paidValue = _currentSessionData!['paid'];
    
    // Handle different data types for paid field
    bool paid = false;
    if (paidValue == 1 || paidValue == '1' || paidValue == true) {
      paid = true;
    }
    
    return status == 'approved' && paid;
  }

  Future<void> _cancelSession() async {
    if (_currentSessionData == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Cancel Request',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this walk-in request? You will need to register again if you want to access the gym.',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GuestSessionService.cancelGuestSession(
        _currentSessionData!['id'],
      );

      if (result['success'] == true) {
        // Clear device-specific flag first
        if (_currentSessionData != null && _currentSessionData!['id'] != null) {
          await GuestSessionService.clearActiveWalkInRequest(_currentSessionData!['id']);
        }
        
        // Clear local session data
        await GuestSessionService.clearGuestSessionData();
        
        // Navigate back to previous screen
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            result['message'] ?? 'Failed to cancel session',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to cancel session: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _canCancelSession() async {
    if (_currentSessionData == null) return false;
    
    final sessionId = _currentSessionData!['id'];
    if (sessionId == null) return false;
    
    // Check if this device has an active request
    final hasActiveRequest = await GuestSessionService.hasActiveWalkInRequest(sessionId);
    if (!hasActiveRequest) return false;
    
    final status = _currentSessionData!['status'];
    final paidValue = _currentSessionData!['paid'];
    
    bool paid = false;
    if (paidValue == 1 || paidValue == '1' || paidValue == true) {
      paid = true;
    }
    
    // Can cancel if status is pending or approved but not paid
    return status == 'pending' || (status == 'approved' && !paid);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // If session can be cancelled, show cancel dialog
        final canCancel = await _canCancelSession();
        if (canCancel) {
          final shouldCancel = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                'Cancel Request',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'You have a pending walk-in request. You need to cancel the request to go back. Do you want to cancel?',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'No',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Yes, Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldCancel == true) {
            _cancelSession();
          }
        } else {
          // If session cannot be cancelled, allow normal back navigation
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B35)),
            onPressed: () async {
              // If session can be cancelled, show cancel dialog
              final canCancel = await _canCancelSession();
              if (canCancel) {
                final shouldCancel = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: Text(
                      'Cancel Request',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    content: Text(
                      'You have a pending walk-in request. You need to cancel the request to go back. Do you want to cancel?',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[300],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'No',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Yes, Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldCancel == true) {
                  _cancelSession();
                }
              } else {
                Navigator.pop(context);
              }
            },
          ),
        title: Text(
          'Walk-in Session',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
            onPressed: _checkSessionStatus,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Walk-in Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFFF6B35),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentSessionData?['guest_name'] ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _currentSessionData?['guest_type']?.toString().toUpperCase() ?? 'UNKNOWN',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: GoogleFonts.poppins(
                              color: _getStatusColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Amount Paid',
                            '₱${_formatAmount(_currentSessionData?['amount_paid'])}',
                            Icons.payment,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            'Valid Until',
                            _formatDate(_currentSessionData?['valid_until']),
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Section
              if (_canShowQR()) ...[
                // Welcome Message when approved and paid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to CNERGY!',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your walk-in session is ready! You can now access the gym facilities.',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Session Active',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Pending Status
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusText() == 'Pending Payment' || _getStatusText() == 'Approved - Pending Payment'
                            ? Icons.payment 
                            : _getStatusText() == 'Ready to Use'
                                ? Icons.check_circle
                                : Icons.error_outline,
                        color: _getStatusColor(),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStatusText(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusText() == 'Pending Payment'
                            ? 'Please proceed to the counter to complete payment and activate your session.'
                            : _getStatusText() == 'Approved - Pending Payment'
                                ? 'Your session is approved! Please proceed to the counter to complete payment and activate your session.'
                                : _getStatusText() == 'Ready to Use'
                                    ? 'Your session is ready! You can now access the gym facilities.'
                                    : 'Your session request has been rejected. Please contact staff for assistance.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action Buttons
              FutureBuilder<bool>(
                future: _canCancelSession(),
                builder: (context, snapshot) {
                  final canCancel = snapshot.data ?? false;
                  if (!canCancel) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      // Cancel Button (shown when session can be cancelled)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _cancelSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cancel_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CANCEL REQUEST',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFF6B35),
                          width: 2,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _checkSessionStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFF6B35),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                                ),
                              )
                            : Text(
                                'REFRESH STATUS',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WalkInSessionStatusScreen(
                                sessionData: _currentSessionData!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'VIEW DETAILS',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF6B35),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
