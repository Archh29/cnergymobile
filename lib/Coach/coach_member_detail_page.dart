import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import '../User/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CoachMemberDetailPage extends StatefulWidget {
  final MemberModel member;

  const CoachMemberDetailPage({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  _CoachMemberDetailPageState createState() => _CoachMemberDetailPageState();
}

class _CoachMemberDetailPageState extends State<CoachMemberDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? sessionInfo;

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  Future<void> _loadMemberDetails() async {
    setState(() => isLoading = true);
    try {
      final coachId = await _getCoachId();
      if (coachId != null) {
        await _loadSessionInfo(coachId);
      }
    } catch (e) {
      print('Error loading member details: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<int?> _getCoachId() async {
    try {
      return AuthService.getCurrentUserId();
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadSessionInfo(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_api.php?action=get-remaining-sessions&user_id=${widget.member.id}&coach_id=$coachId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            sessionInfo = data;
          });
        }
      }
    } catch (e) {
      print('Error loading session info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Member Details',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMemberHeader(),
                  SizedBox(height: 24),
                  _buildBasicInfoSection(),
                  SizedBox(height: 24),
                  _buildSubscriptionAndSessionSection(),
                  SizedBox(height: 24),
                  _buildApprovalStatusSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4).withOpacity(0.2), Color(0xFF44A08D).withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFF4ECDC4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                widget.member.initials,
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.fullName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.member.email,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                if (widget.member.phone != null) ...[
                  SizedBox(height: 4),
                  Text(
                    widget.member.phone!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildInfoRow('Full Name', widget.member.fullName),
          if (widget.member.genderName != null)
            _buildInfoRow('Gender', widget.member.genderName!),
          if (widget.member.age > 0)
            _buildInfoRow('Age', '${widget.member.age} years old'),
          if (widget.member.birthDate != null)
            _buildInfoRow('Birth Date', _formatDate(widget.member.birthDate!)),
          if (widget.member.height != null)
            _buildInfoRow('Height', '${widget.member.height} cm'),
          if (widget.member.weight != null)
            _buildInfoRow('Weight', '${widget.member.weight} kg'),
          if (widget.member.fitnessLevel != null)
            _buildInfoRow('Fitness Level', widget.member.fitnessLevel!),
          if (widget.member.joinDate != null)
            _buildInfoRow('Member Since', _formatDate(widget.member.joinDate!)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionAndSessionSection() {
    final rateType = widget.member.rateType ?? sessionInfo?['rate_type'] ?? 'N/A';
    final expiresAt = widget.member.expiresAt;
    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final daysRemaining = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inDays
        : null;
    final remainingSessions = widget.member.remainingSessions ?? sessionInfo?['remaining_sessions'];
    final sessionPackageCount = sessionInfo?['session_package_count'];
    final monthlyRate = sessionInfo?['monthly_rate'];
    final sessionPackageRate = sessionInfo?['session_package_rate'];

    return _buildSection(
      title: 'Subscription & Sessions',
      icon: Icons.card_membership,
      child: Column(
        children: [
          _buildInfoRow('Rate Type', _formatRateType(rateType)),
          if (rateType == 'package' && remainingSessions != null) ...[
            _buildInfoRow(
              'Remaining Sessions',
              '$remainingSessions',
              valueColor: remainingSessions > 0 ? Colors.green : Colors.red,
            ),
            if (sessionPackageCount != null)
              _buildInfoRow('Total Sessions', '$sessionPackageCount'),
            if (sessionPackageRate != null)
              _buildInfoRow('Package Rate', '₱${sessionPackageRate.toStringAsFixed(2)}'),
          ] else if (rateType == 'monthly') ...[
            if (monthlyRate != null)
              _buildInfoRow('Monthly Rate', '₱${monthlyRate.toStringAsFixed(2)}'),
            if (remainingSessions != null) ...[
              _buildInfoRow(
                'Remaining Sessions',
                '$remainingSessions',
                valueColor: remainingSessions > 0 ? Colors.green : Colors.red,
              ),
            ],
          ] else if (rateType == 'hourly') ...[
            _buildInfoRow('Sessions', 'Pay per session'),
          ],
          if (expiresAt != null) ...[
            SizedBox(height: 8),
            Divider(color: Colors.grey[800], height: 1),
            SizedBox(height: 8),
            _buildInfoRow(
              'Expiration Date',
              _formatDate(expiresAt),
            ),
            _buildInfoRow(
              'Status',
              (isExpired || (remainingSessions != null && remainingSessions <= 0))
                  ? 'Expired'
                  : (daysRemaining != null && daysRemaining > 0
                      ? '$daysRemaining days remaining'
                      : 'Active'),
              valueColor: (isExpired || (remainingSessions != null && remainingSessions <= 0))
                  ? Colors.red
                  : (daysRemaining != null && daysRemaining <= 7
                      ? Colors.orange
                      : Colors.green),
            ),
          ] else if (rateType != 'hourly') ...[
            // Check if expired by sessions even if no expiration date
            if (remainingSessions != null && remainingSessions <= 0)
              _buildInfoRow('Status', 'Expired (No sessions remaining)', valueColor: Colors.red)
            else
              _buildInfoRow('Status', 'No expiration date'),
          ],
        ],
      ),
    );
  }

  Widget _buildApprovalStatusSection() {
    return _buildSection(
      title: 'Approval Status',
      icon: Icons.verified_user,
      child: Column(
        children: [
          _buildInfoRow(
            'Coach Approval',
            widget.member.coachApproval ?? 'N/A',
            valueColor: widget.member.isCoachApproved ? Colors.green : Colors.orange,
          ),
          _buildInfoRow(
            'Staff Approval',
            widget.member.staffApproval ?? 'N/A',
            valueColor: widget.member.isStaffApproved ? Colors.green : Colors.orange,
          ),
          _buildInfoRow(
            'Overall Status',
            widget.member.isFullyApprovedByBoth ? 'Fully Approved' : 'Pending',
            valueColor: widget.member.isFullyApprovedByBoth ? Colors.green : Colors.orange,
          ),
          if (widget.member.coachApprovedAt != null)
            _buildInfoRow('Coach Approved', _formatDate(widget.member.coachApprovedAt!)),
          if (widget.member.staffApprovedAt != null)
            _buildInfoRow('Staff Approved', _formatDate(widget.member.staffApprovedAt!)),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Color(0xFF4ECDC4), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRateType(String rateType) {
    switch (rateType.toLowerCase()) {
      case 'hourly':
        return 'Hourly Rate';
      case 'monthly':
        return 'Monthly Plan';
      case 'package':
        return 'Session Package';
      default:
        return rateType;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

