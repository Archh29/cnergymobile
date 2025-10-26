import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './User/services/guest_session_service.dart';

class WalkInSessionStatusScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const WalkInSessionStatusScreen({
    super.key,
    required this.sessionData,
  });

  @override
  _WalkInSessionStatusScreenState createState() => _WalkInSessionStatusScreenState();
}

class _WalkInSessionStatusScreenState extends State<WalkInSessionStatusScreen> {
  Map<String, dynamic>? _sessionData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sessionData = widget.sessionData;
  }

  Future<void> _refreshSessionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GuestSessionService.getGuestSession(_sessionData!['id']);
      
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _sessionData = result['data'];
        });
        
        // Update local storage
        await GuestSessionService.saveGuestSessionData(_sessionData!);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Session status refreshed"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Failed to refresh session data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getStatusText() {
    if (_sessionData == null) return 'Unknown';
    
    final status = _sessionData!['status'];
    final paidValue = _sessionData!['paid'];
    
    // Handle different data types for paid field
    bool paid = false;
    if (paidValue == 1 || paidValue == '1' || paidValue == true) {
      paid = true;
    }
    
    if (status == 'approved' && paid) {
      return 'Active';
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
      case 'Active':
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

  bool _isSessionValid() {
    if (_sessionData == null) return false;
    return GuestSessionService.isGuestSessionValid(_sessionData!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B35)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Session Details',
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
            onPressed: _refreshSessionData,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Session Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor().withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusText() == 'Active' 
                            ? Icons.check_circle
                            : _getStatusText() == 'Pending Payment'
                                ? Icons.payment
                                : Icons.error,
                        color: _getStatusColor(),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusText(),
                      style: GoogleFonts.poppins(
                        color: _getStatusColor(),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusText() == 'Active'
                          ? 'Your session is ready to use'
                          : _getStatusText() == 'Pending Payment'
                              ? 'Please complete payment at the counter'
                              : 'Your session request was not approved',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Session Details
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
                    Text(
                      'Session Information',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Walk-in Name', _sessionData?['guest_name'] ?? 'Unknown', Icons.person),
                    _buildDetailRow('Session Type', _sessionData?['guest_type']?.toString().toUpperCase() ?? 'UNKNOWN', Icons.category),
                    _buildDetailRow('Amount Paid', '₱${_formatAmount(_sessionData?['amount_paid'])}', Icons.payment),
                    _buildDetailRow('Session ID', _sessionData?['id']?.toString() ?? 'Unknown', Icons.tag),
                    _buildDetailRow('Created At', _formatDateTime(_sessionData?['created_at']), Icons.schedule),
                    _buildDetailRow('Valid Until', _formatDateTime(_sessionData?['valid_until']), Icons.timer),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              
              const SizedBox(height: 24),
              
              // Action Buttons
              if (_getStatusText() == 'Pending Payment') ...[
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
                    onPressed: _refreshSessionData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'CHECK PAYMENT STATUS',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ] else ...[
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
                          onPressed: _refreshSessionData,
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
                                  'REFRESH',
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
                          onPressed: () => Navigator.pop(context),
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
                            'BACK',
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
              
              const SizedBox(height: 16),
              
              // Info Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getStatusText() == 'Active'
                            ? 'Your session is ready! You can now access the gym facilities.'
                            : _getStatusText() == 'Pending Payment'
                                ? 'Please proceed to the counter to complete payment. Your session will be activated once payment is confirmed.'
                                : 'Your session request was not approved. Please contact staff for assistance.',
                        style: GoogleFonts.poppins(
                          color: Colors.blue[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.day}/${date.month}/${date.year} $displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    
    // Handle both string and number types
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
}
