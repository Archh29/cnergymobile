import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/member_model.dart';
import 'services/coach_service.dart';

class SessionManagementPage extends StatefulWidget {
  final MemberModel? selectedMember;

  const SessionManagementPage({Key? key, this.selectedMember}) : super(key: key);

  @override
  _SessionManagementPageState createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  List<SessionUsageRecord> sessionHistory = [];
  bool isLoading = true;
  String? errorMessage;
  MemberModel? selectedMember;

  @override
  void initState() {
    super.initState();
    selectedMember = widget.selectedMember;
    _loadSessionHistory();
  }

  Future<void> _loadSessionHistory() async {
    if (selectedMember == null) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_session_management.php?action=get-session-history&member_id=${selectedMember!.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            final responseData = data['data'] as Map<String, dynamic>;
            sessionHistory = (responseData['history'] as List)
                .map((item) => SessionUsageRecord.fromJson(item))
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Failed to load session history';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Failed to load session history';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _undoSessionUsage(SessionUsageRecord record) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/coach_session_management.php?action=undo-session-usage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usage_id': record.id,
          'member_id': selectedMember!.id,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session usage undone successfully'),
              backgroundColor: Color(0xFF4ECDC4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadSessionHistory(); // Refresh the list
        } else {
          _showErrorDialog(data['message'] ?? 'Failed to undo session usage');
        }
      } else {
        _showErrorDialog('Failed to undo session usage');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _adjustSessionCount(int adjustment) async {
    if (selectedMember == null) return;

    try {
      final response = await http.post(
        Uri.parse('https://api.cnergy.site/coach_session_management.php?action=adjust-session-count'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'member_id': selectedMember!.id,
          'adjustment': adjustment,
          'reason': 'Manual adjustment by coach',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session count adjusted successfully'),
              backgroundColor: Color(0xFF4ECDC4),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadSessionHistory(); // Refresh the list
        } else {
          _showErrorDialog(data['message'] ?? 'Failed to adjust session count');
        }
      } else {
        _showErrorDialog('Failed to adjust session count');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Error',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Adjust Session Count',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the number of sessions to add (positive) or remove (negative)',
              style: GoogleFonts.poppins(color: Colors.grey[300], fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., +2 or -1',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF4ECDC4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF4ECDC4)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final adjustment = int.tryParse(controller.text);
              if (adjustment != null && adjustment != 0) {
                Navigator.pop(context);
                _adjustSessionCount(adjustment);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Adjust',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: selectedMember == null
            ? _buildNoMemberSelected()
            : isLoading
                ? _buildLoadingState()
                : errorMessage != null
                    ? _buildErrorState()
                    : _buildSessionHistory(),
      ),
    );
  }

  Widget _buildNoMemberSelected() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              color: Color(0xFF45B7D1),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No Member Selected',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please select a member to view their session history.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'Error Loading Sessions',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage!,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSessionHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory() {
    return Column(
      children: [
        // Member Info Header
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6B35).withOpacity(0.8), Color(0xFFFF8E53).withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedMember!.fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Session Package Management',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Adjust Session Count Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAdjustmentDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Adjust',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Session History List
        Expanded(
          child: sessionHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sessionHistory.length,
                  itemBuilder: (context, index) {
                    final record = sessionHistory[index];
                    return _buildSessionRecord(record);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No Session History',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This member hasn\'t used any sessions yet.',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionRecord(SessionUsageRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF6B35).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Color(0xFFFF6B35),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.memberName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Session Used',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Date: ${record.usageDate}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Time: ${record.createdAt.split(' ')[1] ?? ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Remaining: ${record.remainingSessions} sessions',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFF6B35),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showUndoConfirmation(record),
            icon: Icon(
              Icons.undo,
              color: Color(0xFFFF6B35),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showUndoConfirmation(SessionUsageRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Undo Session Usage',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to undo the session usage on ${record.usageDate}? This will add 1 session back to the member\'s package.',
          style: GoogleFonts.poppins(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _undoSessionUsage(record);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF6B35),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Undo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionUsageRecord {
  final int id;
  final String usageDate;
  final String createdAt;
  final int remainingSessions;
  final String rateType;
  final String subscriptionStatus;
  final String memberName;
  final int memberId;

  SessionUsageRecord({
    required this.id,
    required this.usageDate,
    required this.createdAt,
    required this.remainingSessions,
    required this.rateType,
    required this.subscriptionStatus,
    required this.memberName,
    required this.memberId,
  });

  factory SessionUsageRecord.fromJson(Map<String, dynamic> json) {
    return SessionUsageRecord(
      id: json['id'],
      usageDate: json['usage_date'],
      createdAt: json['created_at'],
      remainingSessions: json['remaining_sessions'] ?? 0,
      rateType: json['rate_type'] ?? '',
      subscriptionStatus: json['subscription_status'] ?? '',
      memberName: json['member_name'] ?? 'Unknown Member',
      memberId: json['member_id'] ?? 0,
    );
  }
}
