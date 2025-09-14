import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/subscription_model.dart';
import 'services/subscription_service.dart';
import 'services/auth_service.dart';

class ManageSubscriptionsPage extends StatefulWidget {
  const ManageSubscriptionsPage({Key? key}) : super(key: key);

  @override
  _ManageSubscriptionsPageState createState() => _ManageSubscriptionsPageState();
}

class _ManageSubscriptionsPageState extends State<ManageSubscriptionsPage> {
  // Future to hold the subscription plans
  late Future<List<SubscriptionPlan>> _subscriptionPlansFuture;
  
  // Loading states
  bool _isRequestingPlan = false;
  String? _monthlyPlanStatus;
  List<UserSubscription> _userSubscriptions = [];
  
  @override
  void initState() {
    super.initState();
    
    // Check if user is logged in
    if (!AuthService.isLoggedIn()) {
      // Redirect to login page or show error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginRequiredDialog();
      });
      return;
    }
    
    _subscriptionPlansFuture = SubscriptionService.getSubscriptionPlansWithRetry();
    _loadMonthlySubscriptionStatus();
    _loadUserSubscriptions();
  }

  Future<void> _loadUserSubscriptions() async {
    try {
      final uid = AuthService.getCurrentUserId();
      if (uid == null) return;
      final subs = await SubscriptionService.getUserSubscriptions(uid);
      if (!mounted) return;
      setState(() { _userSubscriptions = subs; });
    } catch (_) {}
  }

  Future<void> _loadMonthlySubscriptionStatus() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;
      final subs = await SubscriptionService.getUserSubscriptions(currentUserId);
      final now = DateTime.now();
      UserSubscription? activeMonthly;
      for (final sub in subs) {
        final isMembership = sub.planName.toLowerCase().contains('member fee');
        if (isMembership) continue;
        DateTime? end;
        try { end = DateTime.parse(sub.endDate); } catch (_) { end = null; }
        if (end == null) continue;
        final isActive = (sub.getStatusDisplayName().toLowerCase() == 'approved' || sub.getStatusDisplayName().toLowerCase() == 'active') && !end.isBefore(DateTime(now.year, now.month, now.day));
        if (isActive) { activeMonthly = sub; break; }
      }
      if (activeMonthly != null) {
        final end = DateTime.parse(activeMonthly!.endDate);
        final today = DateTime(now.year, now.month, now.day);
        final until = DateTime(end.year, end.month, end.day);
        final remainingDays = until.difference(today).inDays;
        final daysLeft = remainingDays < 0 ? 0 : remainingDays;
        final endText = '${until.day}/${until.month}/${until.year}';
        setState(() { _monthlyPlanStatus = 'Monthly plan: ${daysLeft} day${daysLeft == 1 ? '' : 's'} left (until $endText)'; });
      } else {
        setState(() { _monthlyPlanStatus = 'Not subscribed to any monthly plan'; });
      }
    } catch (e) {
      setState(() { _monthlyPlanStatus = 'Not subscribed to any monthly plan'; });
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text(
          'Login Required',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'You need to be logged in to view subscription plans.',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: Text(
              'Go Back',
              style: GoogleFonts.poppins(color: Color(0xFF4ECDC4)),
            ),
          ),
        ],
      ),
    );
  }

  // Method to refresh the data
  void _refreshData() {
    setState(() {
      _subscriptionPlansFuture = SubscriptionService.getSubscriptionPlansWithRetry();
    });
  }

  void _showPlanUpdatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final items = _userSubscriptions;
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long, color: Color(0xFF4ECDC4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Plan Request Updates',
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final sub = items[index];
                        final statusColor = sub.getStatusColor();
                        final statusText = sub.getStatusDisplayName();
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.25)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                statusText.toLowerCase().contains('pending')
                                    ? Icons.hourglass_top
                                    : statusText.toLowerCase().contains('approved') || statusText.toLowerCase().contains('active')
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                color: statusColor,
                                size: 18,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.planName,
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: 2),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          statusText,
                                          style: GoogleFonts.poppins(color: statusColor, fontSize: 12),
                                        ),
                                        Text(
                                          'Ends: ' + sub.getFormattedEndDate(),
                                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user info
    final currentUser = AuthService.getCurrentUser();
    final isUserMember = AuthService.isUserMember();
    
    if (!AuthService.isLoggedIn()) {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Subscriptions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF0F0F0F),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4).withOpacity(0.8), Color(0xFF45B7D1).withOpacity(0.8)],
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
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.subscriptions,
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
                          'Membership Plans',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Welcome ${AuthService.getUserFirstName()}!',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (_monthlyPlanStatus != null) ...[
                          SizedBox(height: 6),
                          Text(
                            _monthlyPlanStatus!,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (isUserMember)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'MEMBER',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                ],
              ),
            ),
            SizedBox(height: 24),
            // Updates moved to modal; button in header opens it
            
            // Subscription Plans List
            Expanded(
              child: FutureBuilder<List<SubscriptionPlan>>(
                future: _subscriptionPlansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading subscription plans...',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading plans',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              snapshot.error.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4ECDC4),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No subscription plans available',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final plans = snapshot.data!;
                    
                    return ListView.builder(
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        
                        return DynamicSubscriptionCard(
                          plan: plan,
                          userIsMember: isUserMember,
                          onTap: () => _showPlanDialog(context, plan),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanDialog(BuildContext context, SubscriptionPlan plan) {
    final isUserMember = AuthService.isUserMember();
    
    // Note: Member Fee can be stacked with monthly plans; do not block selection here.

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Color(0xFF4ECDC4),
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                plan.planName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (plan.hasDiscount) ...[
                    Text(
                      plan.getFormattedDiscountedPrice()!,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      plan.getFormattedPrice(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ] else ...[
                    Text(
                      plan.getFormattedPrice(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Are you sure you want to request this subscription plan? Your request will be sent to the admin for approval. Please proceed to the front desk to pay the required amount for activation.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isRequestingPlan 
                          ? null 
                          : () => _requestSubscriptionPlan(context, plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isRequestingPlan
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Request Plan',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showMembersOnlyDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Members Only',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This plan is only available to gym members. Please become a member first to access this plan.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Understood',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestSubscriptionPlan(BuildContext context, SubscriptionPlan plan) async {
    Navigator.pop(context); // Close the dialog first
    
    // Get current user ID from auth service
    final currentUserId = AuthService.getCurrentUserId();
    
    if (currentUserId == null) {
      _showErrorSnackBar(context, 'User not logged in. Please login first.');
      return;
    }
  
    setState(() {
      _isRequestingPlan = true;
    });
  
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
              ),
              SizedBox(height: 16),
              Text(
                'Submitting request...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await SubscriptionService.requestSubscriptionPlan(
        userId: currentUserId,
        planId: plan.id,
      );

      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        // Show success dialog
        _showSuccessDialog(context, result);
      } else {
        // Show error message
        _showErrorSnackBar(context, result.message);
      }
    } catch (error) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar(context, 'An unexpected error occurred: $error');
    } finally {
      setState(() {
        _isRequestingPlan = false;
      });
    }
  }

  void _showSuccessDialog(BuildContext context, SubscriptionRequestResponse result) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF4ECDC4),
                  size: 48,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Request Submitted!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                result.message,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              if (result.data != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request ID:',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '#${result.data!.subscriptionId}',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4ECDC4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plan:',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            result.data!.planName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got It',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class DynamicSubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool userIsMember;
  final VoidCallback onTap;

  const DynamicSubscriptionCard({
    Key? key,
    required this.plan,
    required this.userIsMember,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAccessible = !plan.isMemberOnly || userIsMember;
    final Color cardColor = _getCardColor();
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: plan.hasDiscount ? Border.all(color: cardColor, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColor.withOpacity(0.8),
                    cardColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Row(
                    children: [
                      if (plan.hasDiscount)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            plan.getFormattedDiscountPercentage()!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (plan.isMemberOnly)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'MEMBERS ONLY',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (plan.hasDiscount || plan.isMemberOnly) SizedBox(height: 12),
                  
                  // Plan Name
                  Text(
                    plan.planName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Price
                  Row(
                    children: [
                      if (plan.hasDiscount) ...[
                        Text(
                          plan.getFormattedDiscountedPrice()!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          plan.getFormattedPrice(),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else ...[
                        Text(
                          plan.getFormattedPrice(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 10),
                  // Plan type and duration badges (show for all plans)
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Text(
                          plan.getPlanTypeText(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: Text(
                          plan.getDurationText(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Features
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Show members only message if not accessible
                  if (!isAccessible) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This plan is only available to gym members',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // Features list
                  ...plan.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isAccessible ? cardColor : Colors.grey,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature.featureName,
                                style: GoogleFonts.poppins(
                                  color: isAccessible
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (feature.description.isNotEmpty) ...[
                                SizedBox(height: 2),
                                Text(
                                  feature.description,
                                  style: GoogleFonts.poppins(
                                    color: isAccessible
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.3),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  SizedBox(height: 16),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAccessible ? cardColor : Colors.grey[800],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isAccessible ? 'Select Plan' : 'Members Only',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCardColor() {
    if (plan.isMemberOnly) {
      return Color(0xFFFFD700); // Gold for premium/member plans
    } else if (plan.hasDiscount) {
      return Color(0xFF4ECDC4); // Teal for discounted plans
    } else {
      return Color(0xFF45B7D1); // Blue for regular plans
    }
  }
}
