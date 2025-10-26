import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/session_tracking_service.dart';
import '../services/auth_service.dart';

class SessionStatusWidget extends StatefulWidget {
  final int coachId;
  final VoidCallback? onSessionExpired;

  const SessionStatusWidget({
    Key? key,
    required this.coachId,
    this.onSessionExpired,
  }) : super(key: key);

  @override
  _SessionStatusWidgetState createState() => _SessionStatusWidgetState();
}

class _SessionStatusWidgetState extends State<SessionStatusWidget> {
  SessionStatus? _sessionStatus;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSessionStatus();
  }

  Future<void> _loadSessionStatus() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view session status';
        });
        return;
      }

      final sessionStatus = await SessionTrackingService.checkSessionAvailability(
        userId: currentUserId,
        coachId: widget.coachId,
      );

      if (!mounted) return;
      setState(() {
        _sessionStatus = sessionStatus;
        _isLoading = false;
      });

      // Notify parent if session is expired
      if (!sessionStatus.canStartWorkout && widget.onSessionExpired != null) {
        widget.onSessionExpired!();
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading session status: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'Loading session status...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red[600],
                ),
              ),
            ),
            TextButton(
              onPressed: _loadSessionStatus,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sessionStatus == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor().withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _sessionStatus!.statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!_sessionStatus!.canStartWorkout)
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manage-subscriptions');
              },
              child: Text(
                'Manage',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_sessionStatus == null) return Colors.grey;
    
    if (_sessionStatus!.canStartWorkout) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (_sessionStatus == null) return Icons.help_outline;
    
    if (_sessionStatus!.canStartWorkout) {
      return Icons.check_circle_outline;
    } else {
      return Icons.block;
    }
  }

  String _getStatusTitle() {
    if (_sessionStatus == null) return 'Session Status';
    
    if (_sessionStatus!.canStartWorkout) {
      return 'Session Available';
    } else {
      return 'Session Unavailable';
    }
  }

  void refresh() {
    _loadSessionStatus();
  }
}

class SessionStatusCard extends StatelessWidget {
  final SessionStatus sessionStatus;
  final VoidCallback? onManageSubscription;

  const SessionStatusCard({
    Key? key,
    required this.sessionStatus,
    this.onManageSubscription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sessionStatus.canStartWorkout 
                      ? Icons.check_circle 
                      : Icons.block,
                  color: sessionStatus.canStartWorkout 
                      ? Colors.green 
                      : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sessionStatus.canStartWorkout 
                        ? 'Workout Available' 
                        : 'Workout Unavailable',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: sessionStatus.canStartWorkout 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              sessionStatus.statusMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (!sessionStatus.canStartWorkout && onManageSubscription != null) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onManageSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Manage Subscription'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}












