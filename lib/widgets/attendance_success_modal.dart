import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../User/models/attendance_model.dart';

// Helper function to show attendance success modal
void showAttendanceSuccessModal(BuildContext context, AttendanceResponse response) {
  if (!response.success || response.action.isEmpty) {
    return; // Don't show modal if not successful or no action
  }

  final isGuest = response.guestName != null && response.guestName!.isNotEmpty;
  final displayName = isGuest ? response.guestName! : (response.userName ?? 'User');
  final time = response.action == 'checked_in' 
      ? (response.checkInTime ?? '')
      : (response.checkOutTime ?? '');

  if (time.isEmpty) {
    return; // Don't show modal if time is missing
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AttendanceSuccessModal(
      action: response.action,
      userName: displayName,
      time: time,
      isGuest: isGuest,
      guestName: response.guestName,
    ),
  );
}

class AttendanceSuccessModal extends StatelessWidget {
  final String action; // 'checked_in' or 'checked_out'
  final String userName;
  final String time; // check_in_time or check_out_time
  final bool isGuest;
  final String? guestName;

  const AttendanceSuccessModal({
    Key? key,
    required this.action,
    required this.userName,
    required this.time,
    this.isGuest = false,
    this.guestName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCheckIn = action == 'checked_in';
    final displayName = isGuest && guestName != null ? guestName! : userName;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon with Animation
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isCheckIn 
                    ? Color(0xFF4ECDC4).withOpacity(0.2)
                    : Color(0xFFFF6B35).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCheckIn ? Icons.check_circle : Icons.logout,
                color: isCheckIn ? Color(0xFF4ECDC4) : Color(0xFFFF6B35),
                size: 48,
              ),
            ),
            SizedBox(height: 20),
            
                  // Success Message
                  Text(
                    isCheckIn 
                        ? 'Check-In Successful' 
                        : 'Check-Out Successful',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    isCheckIn 
                        ? 'You have been successfully checked in to the gym.' 
                        : 'You have been successfully checked out. Thank you for your visit!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
            SizedBox(height: 12),
            
            // User Name
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGuest ? Icons.person_outline : Icons.person,
                    color: Color(0xFF4ECDC4),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Time Information
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCheckIn 
                      ? Color(0xFF4ECDC4).withOpacity(0.3)
                      : Color(0xFFFF6B35).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: isCheckIn ? Color(0xFF4ECDC4) : Color(0xFFFF6B35),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _formatTime(time),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCheckIn ? Color(0xFF4ECDC4) : Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      // Parse the time string (format: YYYY-MM-DD HH:MM:SS)
      final dateTime = DateTime.parse(timeString);
      
      // Format: "MM/DD/YYYY at HH:MM AM/PM"
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final year = dateTime.year;
      
      int hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      
      return '$month/$day/$year at ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return timeString; // Return original if parsing fails
    }
  }
}

