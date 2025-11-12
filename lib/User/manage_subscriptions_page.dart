import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/subscription_model.dart';
import 'services/subscription_service.dart';
import 'services/auth_service.dart';
import 'pages/subscription_details_page.dart';

class ManageSubscriptionsPage extends StatefulWidget {
  final int? highlightPlanId; // Plan ID to highlight (e.g., 1 for Gym Membership)
  
  const ManageSubscriptionsPage({Key? key, this.highlightPlanId}) : super(key: key);

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
  
  // Pending request state
  Map<String, dynamic>? _pendingRequest;
  bool _isLoadingPendingRequest = false;
  
  // Dialog state tracking
  bool _isLoadingDialogOpen = false;
  bool _isDisposed = false;
  
  // Track previous subscription statuses to detect approval
  List<String> _previousSubscriptionStatuses = [];
  
  // GlobalKey for scrolling to highlighted plan
  final GlobalKey _highlightedPlanKey = GlobalKey();
  bool _hasScrolledToHighlight = false;
  final ScrollController _scrollController = ScrollController();
  
  // GlobalKey for scrolling to pending request section
  final GlobalKey _pendingRequestSectionKey = GlobalKey();
  
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
    
    _loadAvailablePlansForUser();
    _loadMonthlySubscriptionStatus();
    _loadUserSubscriptions();
    _loadPendingRequest();
  }
  
  // Removed _loadCurrentSubscription - now handled in SubscriptionDetailsPage
  
  void _scrollToHighlightedPlan() {
    if (_hasScrolledToHighlight) return;
    
    try {
      if (_highlightedPlanKey.currentContext != null) {
        Scrollable.ensureVisible(
          _highlightedPlanKey.currentContext!,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll to show the card near top of screen
        );
        _hasScrolledToHighlight = true;
        print('✅ Scrolled to highlighted plan (plan_id: ${widget.highlightPlanId})');
      } else {
        print('⚠️ Highlighted plan key context is null, retrying...');
        // Retry after a delay
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && !_hasScrolledToHighlight) {
            _scrollToHighlightedPlan();
          }
        });
      }
    } catch (e) {
      print('❌ Error scrolling to highlighted plan: $e');
    }
  }
  
  // Scroll to pending request section after successful subscription request
  void _scrollToPendingRequestSection() {
    if (!mounted || _isDisposed) return;
    
    try {
      if (_pendingRequestSectionKey.currentContext != null) {
        print('📜 Scrolling to pending request section...');
        Scrollable.ensureVisible(
          _pendingRequestSectionKey.currentContext!,
          duration: Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll to show the section near the top
        );
        print('✅ Scrolled to pending request section');
      } else {
        print('⚠️ Pending request section key context is null, retrying...');
        // Retry after a delay to allow widget tree to build
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted && !_isDisposed && _pendingRequestSectionKey.currentContext != null) {
            try {
              Scrollable.ensureVisible(
                _pendingRequestSectionKey.currentContext!,
                duration: Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                alignment: 0.1,
              );
              print('✅ Scrolled to pending request section (retry)');
            } catch (e) {
              print('❌ Error scrolling to pending request section (retry): $e');
            }
          }
        });
      }
    } catch (e) {
      print('❌ Error scrolling to pending request section: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    // Clean up any open dialogs
    if (_isLoadingDialogOpen && mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (e) {
        // Ignore errors when disposing
      }
    }
    super.dispose();
  }

  Future<void> _loadAvailablePlansForUser() async {
    try {
      final uid = AuthService.getCurrentUserId();
      if (uid == null) return;
      
      // Get available subscription plans (for subscribing to new plans)
      _subscriptionPlansFuture = SubscriptionService.getAvailablePlansForUser(uid);
    } catch (e) {
      print('Error loading available plans: $e');
      _subscriptionPlansFuture = Future.value([]);
    }
  }

  Future<List<SubscriptionPlan>> _getUserAvailedPlans(int userId) async {
    try {
      // Get user's subscription history to find availed plans
      final historyData = await SubscriptionService.getSubscriptionHistory(userId);
      print('Debug: History data received: $historyData');
      
      // Also get current subscription directly for better reliability
      final currentSubscriptionData = await SubscriptionService.getCurrentSubscription(userId);
      print('Debug: Current subscription data received: $currentSubscriptionData');
      
      if (historyData == null && currentSubscriptionData == null) {
        print('Debug: No history or current subscription data received');
        return [];
      }

      List<SubscriptionPlan> availedPlans = [];

      // Check for current subscription - try both sources
      Map<String, dynamic>? currentSub;
      if (currentSubscriptionData != null && currentSubscriptionData['subscription'] != null) {
        currentSub = currentSubscriptionData['subscription'];
        print('Debug: Found current subscription from getCurrentSubscription API: ${currentSub?['plan_name']}');
      } else if (historyData != null && historyData['current_subscription'] != null) {
        currentSub = historyData['current_subscription'];
        print('Debug: Found current subscription from getSubscriptionHistory API: ${currentSub?['plan_name']}');
      }
      
      if (currentSub != null) {
        final planName = currentSub['plan_name']?.toString() ?? 'Unknown Plan';
        final isMembership = planName.toLowerCase().contains('gym membership fee') || 
                            planName.toLowerCase().contains('membership');
        final isMemberRate = planName.toLowerCase().contains('member rate') || 
                            planName.toLowerCase().contains('member monthly') ||
                            (planName.toLowerCase().contains('member') && 
                             !planName.toLowerCase().contains('non-member') && 
                             !planName.toLowerCase().contains('non member'));
        final isDayPass = planName.toLowerCase().contains('day pass');
        
        // Convert price string to double safely
        final priceStr = currentSub['original_price']?.toString() ?? 
                        currentSub['price']?.toString() ?? 
                        currentSub['discounted_price']?.toString() ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;
        
        final discountedPriceStr = currentSub['discounted_price']?.toString();
        final discountedPrice = discountedPriceStr != null ? double.tryParse(discountedPriceStr) : null;
        
         // Debug: Log the duration values
        print('Debug: duration_months from API: ${currentSub['duration_months']} (type: ${currentSub['duration_months'].runtimeType})');
        print('Debug: duration_days from API: ${currentSub['duration_days']} (type: ${currentSub['duration_days'].runtimeType})');
        
        // Get plan_id (subscription plan ID, not subscription ID)
        final planId = currentSub['plan_id'] ?? currentSub['id'] ?? 0;
        print('Debug: Current subscription plan_id: $planId, subscription id: ${currentSub['id']}');
        
        final plan = SubscriptionPlan(
          id: planId, // Use plan_id, not subscription id
          planName: planName,
          price: price,
          discountedPrice: discountedPrice,
          durationMonths: int.tryParse(currentSub['duration_months']?.toString() ?? '1') ?? 1,
          durationDays: currentSub['duration_days'] != null ? int.tryParse(currentSub['duration_days'].toString()) : null,
          isMemberOnly: isMembership || isMemberRate,
          isAvailable: true,
          features: [],
          description: isMembership 
              ? 'Annual membership - Can access everything, unlimited access' 
              : isDayPass
                  ? 'Day pass - 1 day access, standard rate, limited access'
                  : isMemberRate
                      ? 'Monthly access (member rate) - Discounted rate, 1 month, unlimited access'
                      : 'Monthly access (standard rate) - Standard rate, 1 month, limited access',
        );
        
        print('Debug: Created plan with durationMonths: ${plan.durationMonths}, durationDays: ${plan.durationDays}');
        print('Debug: Plan duration text: ${plan.getDurationText()}');
        availedPlans.add(plan);
        print('Debug: Added current subscription: ${plan.planName} - ₱${plan.price}');
      } else {
        print('Debug: No current subscription found in either API response');
      }

      // Add coach packages from requests array
      if (historyData != null && historyData['requests'] != null) {
        final requests = historyData['requests'] as List<dynamic>;
        print('Debug: Found ${requests.length} coach requests');
        
        for (var coach in requests) {
          if (coach['status'] == 'active' || coach['status'] == 'approved') {
            final coachName = coach['coach_name'] ?? 'Unknown Coach';
            final rateStr = coach['session_package_rate']?.toString() ?? 
                           coach['monthly_rate']?.toString() ?? '0';
            final rate = double.tryParse(rateStr) ?? 0.0;
            final rateType = coach['rate_type']?.toString() ?? 'package';
            
            final plan = SubscriptionPlan(
              id: coach['request_id'] ?? 0,
              planName: 'Coach Package - $coachName',
              price: rate,
              discountedPrice: null,
              durationMonths: rateType == 'monthly' ? 1 : 0,
              isMemberOnly: false,
              isAvailable: true,
              features: [],
              description: 'Personal coaching with $coachName (${coach['coach_specialty'] ?? 'General Coaching'})',
            );
            availedPlans.add(plan);
            print('Debug: Added coach package: ${plan.planName} - ₱${plan.price}');
          }
        }
      }

      // Add gym membership and other subscriptions from the subscriptions array
      // We need to get this from a different API call since it's not in the current response
      try {
        final userSubs = await SubscriptionService.getUserSubscriptions(userId);
        print('Debug: Found ${userSubs.length} user subscriptions');
        
        for (var sub in userSubs) {
          final planName = sub.planName;
          final isMembership = planName.toLowerCase().contains('gym membership fee') || 
                              planName.toLowerCase().contains('membership');
          final isMemberRate = planName.toLowerCase().contains('member rate') || 
                            planName.toLowerCase().contains('member monthly') ||
                            (planName.toLowerCase().contains('member') && 
                             !planName.toLowerCase().contains('non-member') && 
                             !planName.toLowerCase().contains('non member'));
          final isDayPass = planName.toLowerCase().contains('day pass');
          
          // Skip if this is the same as current subscription
          bool isCurrentSub = false;
          if (currentSub != null && sub.id.toString() == currentSub['id'].toString()) {
            isCurrentSub = true;
          } else if (historyData != null && historyData['current_subscription'] != null && 
              sub.id.toString() == historyData['current_subscription']['id'].toString()) {
            isCurrentSub = true;
          }
          
          if (isCurrentSub) {
            print('Debug: Skipping subscription ${sub.id} - it is the current subscription');
            continue;
          }
          
          final plan = SubscriptionPlan(
            id: sub.id,
            planName: planName,
            price: sub.price,
            discountedPrice: sub.discountedPrice,
            durationMonths: isMembership ? 12 : isDayPass ? 0 : 1,
            isMemberOnly: isMembership || isMemberRate,
            isAvailable: true,
            features: [],
            description: isMembership 
                ? 'Annual membership - Can access everything, unlimited access' 
                : isDayPass
                    ? 'Day pass - 1 day access, standard rate, limited access'
                    : isMemberRate
                        ? 'Monthly access (member rate) - Discounted rate, 1 month, unlimited access'
                        : 'Monthly access (standard rate) - Standard rate, 1 month, limited access',
          );
          availedPlans.add(plan);
          print('Debug: Added subscription: ${plan.planName} - ₱${plan.price}');
        }
      } catch (e) {
        print('Debug: Error getting user subscriptions: $e');
      }

      // Filter out individual Monthly Access plan if user has combination package
      bool hasCombinationPackage = availedPlans.any((plan) => 
          plan.planName.toLowerCase().contains('membership + 1 month access'));
      
      print('Debug: Has combination package: $hasCombinationPackage');
      
      if (hasCombinationPackage) {
        int removedCount = availedPlans.length;
        availedPlans.removeWhere((plan) => 
            (plan.planName.toLowerCase().contains('monthly access (member rate)') && 
             plan.price == 0.0) ||
            (plan.planName.toLowerCase().contains('gym membership fee') && 
             plan.price == 0.0));
        removedCount = removedCount - availedPlans.length;
        print('Debug: Filtered out $removedCount individual plan(s) due to combination package');
      }

      print('Debug: Total availed plans found: ${availedPlans.length}');
      for (var plan in availedPlans) {
        print('Debug: Plan - ${plan.planName}, Price: ₱${plan.price}, Type: ${plan.isMembershipPlan ? "Membership" : "Monthly"}');
      }

      return availedPlans;
    } catch (e) {
      print('Error getting user availed plans: $e');
      return [];
    }
  }

  Future<void> _loadUserSubscriptions() async {
    try {
      final uid = AuthService.getCurrentUserId();
      if (uid == null || !mounted) return;
      final subs = await SubscriptionService.getUserSubscriptions(uid);
      if (!mounted) return;
      
      // Check for newly approved subscriptions
      if (_previousSubscriptionStatuses.isNotEmpty && subs.isNotEmpty) {
        for (int i = 0; i < subs.length && i < _previousSubscriptionStatuses.length; i++) {
          final previousStatus = _previousSubscriptionStatuses[i].toLowerCase();
          final currentStatus = subs[i].getStatusDisplayName().toLowerCase();
          
          // If status changed from pending to approved/active
          if ((previousStatus.contains('pending') || previousStatus == 'pending_approval') &&
              (currentStatus.contains('approved') || currentStatus.contains('active'))) {
            // Show success modal
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSubscriptionSuccessModal(subs[i]);
            });
            break; // Only show one modal at a time
          }
        }
      }
      
      // Update previous statuses
      _previousSubscriptionStatuses = subs.map((s) => s.getStatusDisplayName()).toList();
      
      if (mounted) setState(() { _userSubscriptions = subs; });
    } catch (_) {}
  }

  Future<void> _loadPendingRequest() async {
    try {
      final uid = AuthService.getCurrentUserId();
      if (uid == null || !mounted) return;
      
      if (mounted) setState(() { _isLoadingPendingRequest = true; });
      
      final pendingData = await SubscriptionService.getUserPendingRequest(uid);
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
          _pendingRequest = pendingData;
          _isLoadingPendingRequest = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) setState(() { _isLoadingPendingRequest = false; });
      print('Error loading pending request: $e');
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    await _loadAvailablePlansForUser();
    if (!mounted) return;
    
    await _loadUserSubscriptions();
    if (!mounted) return;
    
    await _loadMonthlySubscriptionStatus();
    if (!mounted) return;
    
    await _loadPendingRequest();
    if (!mounted) return;
    
    if (mounted) setState(() {});
  }

  Future<void> _loadMonthlySubscriptionStatus() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null || !mounted) return;
      final subs = await SubscriptionService.getUserSubscriptions(currentUserId);
      if (!mounted) return;
      
      final now = DateTime.now();
      UserSubscription? activeMonthly;
      for (final sub in subs) {
        final isMembership = sub.planName.toLowerCase().contains('member fee') || 
                             sub.planName.toLowerCase().contains('gym membership fee') ||
                             sub.planName.toLowerCase().contains('day pass');
        if (isMembership) continue;
        
        // Only consider actual monthly plans (Member Monthly Plan, Non-Member Monthly Plan, etc.)
        final isMonthlyPlan = sub.planName.toLowerCase().contains('monthly') || 
                              sub.planName.toLowerCase().contains('month access');
        if (!isMonthlyPlan) continue;
        
        DateTime? end;
        try { end = DateTime.parse(sub.endDate); } catch (_) { end = null; }
        if (end == null) continue;
        final isActive = (sub.getStatusDisplayName().toLowerCase() == 'approved' || sub.getStatusDisplayName().toLowerCase() == 'active') && !end.isBefore(DateTime(now.year, now.month, now.day));
        if (isActive) { activeMonthly = sub; break; }
      }
      
      if (!mounted) return;
      
      if (activeMonthly != null) {
        final end = DateTime.parse(activeMonthly!.endDate);
        final today = DateTime(now.year, now.month, now.day);
        final until = DateTime(end.year, end.month, end.day);
        final remainingDays = until.difference(today).inDays;
        final daysLeft = remainingDays < 0 ? 0 : remainingDays;
        final endText = '${until.day}/${until.month}/${until.year}';
        if (mounted) setState(() { _monthlyPlanStatus = 'Monthly plan: ${daysLeft} day${daysLeft == 1 ? '' : 's'} left (until $endText)'; });
      } else {
        if (mounted) setState(() { _monthlyPlanStatus = 'Not subscribed to any monthly plan'; });
      }
    } catch (e) {
      if (mounted) setState(() { _monthlyPlanStatus = 'Not subscribed to any monthly plan'; });
    }
  }

  void _showSubscriptionSuccessModal(UserSubscription subscription) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF4ECDC4),
                  size: 48,
                ),
              ),
              SizedBox(height: 24),
              
              // Title
              Text(
                'Payment Successful',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Message
              Text(
                'Your subscription payment has been successfully processed and approved.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              
              // Subscription Details Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subscriptions, color: Color(0xFF4ECDC4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subscription.planName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Valid until: ${subscription.getFormattedEndDate()}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
      body: Container(
        // Full black background - no overflow
        color: Color(0xFF0F0F0F),
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modern Plans Availed Card - matches subscription card design
                      Container(
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFF4ECDC4).withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4ECDC4).withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header with gradient
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4ECDC4).withOpacity(0.9),
                                    Color(0xFF45B7D1).withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                              ),
                              child: Row(
                                children: [
                                  // Modern icon container
                                  Container(
                                    padding: EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.card_membership_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title with member badge
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Plans Availed',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 24,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ),
                                            if (AuthService.isUserMember())
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFFD700).withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.white.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFFFFD700).withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star_rounded,
                                                      color: Colors.black,
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'MEMBER',
                                                      style: GoogleFonts.poppins(
                                                        color: Colors.black,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        // Welcome message
                                        Text(
                                          'Welcome ${AuthService.getUserFirstName()}!',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.95),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (_monthlyPlanStatus != null) ...[
                                          SizedBox(height: 6),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.25),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.info_outline_rounded,
                                                  color: Colors.white.withOpacity(0.9),
                                                  size: 14,
                                                ),
                                                SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    _monthlyPlanStatus!,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white.withOpacity(0.95),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action button section
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SubscriptionDetailsPage(),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.visibility_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  label: Text(
                                    'View Subscription Details',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF4ECDC4),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 6,
                                    shadowColor: Color(0xFF4ECDC4).withOpacity(0.4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // Pending Request Section
                      if (_pendingRequest != null && _pendingRequest!['has_pending_request'] == true) 
                        _buildPendingRequestSection(),
                      
                      // Only show Available Plans section if there's no pending request
                      if (_pendingRequest == null || _pendingRequest!['has_pending_request'] != true) ...[
                        SizedBox(height: 24),
                        
                        // Subscription Plans List Header
                        Text(
                          'Available Plans',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Subscription Plans List
                        FutureBuilder<List<SubscriptionPlan>>(
                        future: _subscriptionPlansFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(
                              padding: EdgeInsets.all(40),
                              child: Center(
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
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Container(
                              padding: EdgeInsets.all(40),
                              child: Center(
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
                              ),
                            );
                          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            // Check if user has pending request
                            if (_pendingRequest != null && _pendingRequest!['has_pending_request'] == true) {
                              return Container(
                                padding: EdgeInsets.all(40),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.hourglass_top,
                                        color: Colors.orange,
                                        size: 64,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Request Pending',
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
                                          'You already have a pending request. Please wait for approval or cancel it first before requesting a new plan.',
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
                                          'Refresh Status',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            // Show current subscriptions if no new plans are available
                            if (_userSubscriptions.isNotEmpty) {
                              return Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    margin: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF4ECDC4),
                                          size: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'You are already subscribed to:',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _refreshData,
                                          icon: Icon(
                                            Icons.refresh,
                                            color: Color(0xFF4ECDC4),
                                            size: 20,
                                          ),
                                          tooltip: 'Refresh subscriptions',
                                        ),
                                      ],
                                    ),
                                  ),
                                  ..._userSubscriptions.map((subscription) {
                                    return Container(
                                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2A2A2A),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Color(0xFF4ECDC4).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                subscription.planName,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: subscription.getStatusColor().withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  subscription.getStatusDisplayName(),
                                                  style: GoogleFonts.poppins(
                                                    color: subscription.getStatusColor(),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Duration: ${subscription.getDurationText()}',
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF4ECDC4),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Quantity: ${subscription.getQuantityText()}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Start Date: ${subscription.getFormattedStartDate()}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'End Date: ${subscription.getFormattedEndDate()}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Amount: ${subscription.getFormattedEffectivePrice()}',
                                            style: GoogleFonts.poppins(
                                              color: Color(0xFF4ECDC4),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            } else {
                              return Container(
                                padding: EdgeInsets.all(40),
                                child: Center(
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
                                ),
                              );
                            }
                          } else {
                            final plans = snapshot.data!;
                            
                            // Check if we need to scroll to highlighted plan
                            final hasHighlightedPlan = widget.highlightPlanId != null && 
                                plans.any((plan) => plan.id == widget.highlightPlanId);
                            
                            // Scroll to highlighted plan after list is built (only once)
                            if (hasHighlightedPlan && !_hasScrolledToHighlight) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                Future.delayed(Duration(milliseconds: 1000), () {
                                  if (mounted && !_hasScrolledToHighlight) {
                                    _scrollToHighlightedPlan();
                                  }
                                });
                              });
                            }
                            
                            // Build the list of plan cards
                            return Column(
                              children: plans.map((plan) {
                                final isHighlighted = widget.highlightPlanId != null && 
                                                     plan.id == widget.highlightPlanId;
                                
                                return Container(
                                  key: isHighlighted ? _highlightedPlanKey : ValueKey('plan_${plan.id}'),
                                  margin: EdgeInsets.only(bottom: 16),
                                  child: DynamicSubscriptionCard(
                                    plan: plan,
                                    userIsMember: isUserMember,
                                    onTap: () => _showPlanDialog(context, plan),
                                    isHighlighted: isHighlighted,
                                  ),
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                      ],
                      
                      // Add bottom padding to prevent cutoff
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanDialog(BuildContext context, SubscriptionPlan plan) {
    final isUserMember = AuthService.isUserMember();
    
    // If plan is locked, show info dialog instead of request dialog
    if (plan.isLocked) {
      _showLockedPlanInfoDialog(context, plan);
      return;
    }
    
    // Check if user has active subscription of the same plan
    final activeSamePlan = _userSubscriptions.firstWhere(
      (sub) => sub.planName.toLowerCase() == plan.planName.toLowerCase() && 
               (sub.statusName.toLowerCase() == 'approved' || sub.statusName.toLowerCase() == 'active'),
      orElse: () => UserSubscription(
        id: 0,
        planName: '',
        price: 0,
        statusName: '',
        startDate: '',
        endDate: '',
      ),
    );
    
    final hasActiveSamePlan = activeSamePlan.id > 0;
    final hasAnyActivePlan = _userSubscriptions.any(
      (sub) => sub.statusName.toLowerCase() == 'approved' || sub.statusName.toLowerCase() == 'active',
    );

    // State variables for dialog - use LOCAL state, not widget state
    // This prevents setState from affecting the dialog and causing navigation issues
    // Day Pass (plan.id == 6) is always 1 session, no quantity selector
    final bool isDayPass = plan.id == 6;
    int selectedPeriods = 1; // Always 1 for Day Pass
    bool isRenewal = hasActiveSamePlan;
    bool isAdvancePayment = hasAnyActivePlan && !hasActiveSamePlan;
    
    // Determine max periods based on plan type
    // Day Pass doesn't allow multiple periods
    int maxPeriods = 12; // Default max
    if (isDayPass) {
      maxPeriods = 1; // Day Pass is always 1 session
      selectedPeriods = 1; // Force to 1 for Day Pass
    } else if (plan.isMembershipPlan) {
      maxPeriods = 5; // Max 5 years for membership
    } else if (plan.isMonthlyPlan) {
      maxPeriods = 24; // Max 24 months for monthly plans
    }
    
    // Determine max hours for expiration message
    final maxHours = 12; // All plans (including Day Pass): 12 hours

    // Create ValueNotifier outside showDialog so it persists across rebuilds
    // This prevents widget setState from affecting the dialog and causing navigation issues
    final ValueNotifier<bool> isRequestingInDialog = ValueNotifier<bool>(false);
    
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          
          // Calculate total price
          double calculateTotalPrice() {
            final basePrice = plan.effectivePrice;
            return basePrice * selectedPeriods;
          }
          
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.9),
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
              child: SingleChildScrollView(
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
                      plan.getDisplayName(),
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
                        Text(
                          ' / ${plan.id == 6 ? "1 Session" : plan.getDurationText()}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    
                    // Show active subscription info if renewal
                    if (hasActiveSamePlan) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Subscription',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4ECDC4),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Expires: ${activeSamePlan.getFormattedEndDate()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 16),
                    
                    // Subscription Type Selection
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription Type',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          if (hasActiveSamePlan) ...[
                            // Renewal option
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  isRenewal = true;
                                  isAdvancePayment = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isRenewal ? Color(0xFF4ECDC4).withOpacity(0.2) : Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isRenewal ? Color(0xFF4ECDC4) : Colors.grey[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isRenewal ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      color: isRenewal ? Color(0xFF4ECDC4) : Colors.grey[400],
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Renewal',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Extend your current subscription',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (hasAnyActivePlan && !hasActiveSamePlan) ...[
                            SizedBox(height: 8),
                            // Advance Payment option
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  isAdvancePayment = true;
                                  isRenewal = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdvancePayment ? Color(0xFF4ECDC4).withOpacity(0.2) : Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAdvancePayment ? Color(0xFF4ECDC4) : Colors.grey[700]!,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isAdvancePayment ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      color: isAdvancePayment ? Color(0xFF4ECDC4) : Colors.grey[400],
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Advance Payment',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Pay in advance while subscription is active',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (!hasAnyActivePlan) ...[
                            // New Subscription option
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFF4ECDC4),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: Color(0xFF4ECDC4),
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'New Subscription',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Start a new subscription',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Period Selection - Hide for Day Pass (plan.id == 6)
                    if (!isDayPass) ...[
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Number of ${plan.isMembershipPlan ? "Years" : plan.getDurationText().toLowerCase().replaceAll("1 ", "").replaceAll("s", "")}s:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[700]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: selectedPeriods > 1
                                            ? () {
                                                setDialogState(() {
                                                  selectedPeriods--;
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.remove,
                                            color: selectedPeriods > 1 ? Colors.white : Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$selectedPeriods',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: selectedPeriods < maxPeriods
                                            ? () {
                                                setDialogState(() {
                                                  selectedPeriods++;
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.add,
                                            color: selectedPeriods < maxPeriods ? Colors.white : Colors.grey[600],
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Total Duration: ${_formatTotalDuration(plan, selectedPeriods)}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Color(0xFF4ECDC4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    // Total Price
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '₱${calculateTotalPrice().toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4ECDC4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    Text(
                      'Your request will be sent to the admin for approval. Please proceed to the front desk to pay the required amount for activation within $maxHours hours.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
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
                          child: ValueListenableBuilder<bool>(
                            valueListenable: isRequestingInDialog,
                            builder: (context, isRequesting, child) {
                              return ElevatedButton(
                                onPressed: isRequesting 
                                    ? null 
                                      : () {
                                        // Update LOCAL dialog state to disable button
                                        // This prevents multiple clicks and uses dialog state, not widget state
                                        isRequestingInDialog.value = true;
                                        
                                        // Call request function - it will handle showing loading dialog
                                        // and closing both dialogs after the request completes
                                        // IMPORTANT: Don't close the purchase dialog here - let _requestSubscriptionPlan handle it
                                        // This prevents accidentally closing the subscription page
                                        _requestSubscriptionPlan(
                                          dialogContext, // Pass the dialog's context (NOT widget context)
                                          plan, 
                                          renewal: isRenewal,
                                          advancePayment: isAdvancePayment,
                                          periods: isDayPass ? 1 : selectedPeriods, // Force 1 for Day Pass
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF4ECDC4),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isRequesting
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        isRenewal ? 'Renew Plan' : 'Request Plan',
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _formatTotalDuration(SubscriptionPlan plan, int periods) {
    // Day Pass (plan.id == 6) is always 1 session
    if (plan.id == 6) {
      return '1 Session';
    }
    if (plan.isMembershipPlan) {
      if (periods == 1) return '1 Year';
      return '$periods Years';
    } else if (plan.durationDays != null && plan.durationDays! > 0) {
      final totalDays = plan.durationDays! * periods;
      if (totalDays == 1) return '1 Day';
      return '$totalDays Days';
    } else {
      final totalMonths = plan.durationMonths * periods;
      if (totalMonths == 1) return '1 Month';
      if (totalMonths == 12) return '1 Year';
      if (totalMonths % 12 == 0) return '${totalMonths ~/ 12} Years';
      return '$totalMonths Months';
    }
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

  void _requestSubscriptionPlan(
    BuildContext dialogContext, 
    SubscriptionPlan plan, {
    bool renewal = false,
    bool advancePayment = false,
    int periods = 1,
  }) async {
    if (!mounted || _isDisposed) return;
    
    // Get current user ID from auth service
    final currentUserId = AuthService.getCurrentUserId();
    
    if (currentUserId == null) {
      // If dialog context is still valid, try to close it
      try {
        if (Navigator.of(dialogContext, rootNavigator: false).canPop()) {
          Navigator.of(dialogContext, rootNavigator: false).pop();
        }
      } catch (e) {
        print('⚠️ Error closing dialog for null user: $e');
      }
      // Show error snackbar using current widget context
      if (mounted && !_isDisposed && context.mounted) {
        _showErrorSnackBar(context, 'User not logged in. Please login first.');
      }
      return;
    }
    
    // CRITICAL: Check if widget is still mounted BEFORE any operations
    if (!mounted || _isDisposed) {
      print('❌ Widget disposed before starting subscription request');
      print('   mounted: $mounted, _isDisposed: $_isDisposed');
      // Try to close the purchase dialog if it's still open
      try {
        if (Navigator.of(dialogContext, rootNavigator: false).canPop()) {
          Navigator.of(dialogContext, rootNavigator: false).pop();
        }
      } catch (e) {
        // Ignore
      }
      return;
    }
    
    // Verify widget context is still valid
    if (!context.mounted) {
      print('❌ Widget context is not mounted');
      // Try to close the purchase dialog if it's still open
      try {
        if (Navigator.of(dialogContext, rootNavigator: false).canPop()) {
          Navigator.of(dialogContext, rootNavigator: false).pop();
        }
      } catch (e) {
        // Ignore
      }
      return;
    }
    
    print('✅ Widget is mounted and context is valid - proceeding with request');
    print('📌 Showing loading dialog using purchase dialog context (no setState)');
  
    // CRITICAL: Don't call setState here - this might cause the widget to rebuild
    // and close the purchase dialog, which could then close the subscription page
    // Instead, just show the loading dialog directly using the dialog context
    // We'll update the state after the dialogs are closed
  
    // Show loading dialog using the purchase dialog's context
    // This ensures it appears on top and uses a valid context that won't cause navigation issues
    NavigatorState? dialogNavigator;
    
    try {
      // Use dialogContext (the purchase dialog's context) to show the loading dialog
      // This ensures the loading dialog is shown in the same overlay as the purchase dialog
      // and doesn't interfere with the widget's state or navigation
      showDialog(
        context: dialogContext, // Use purchase dialog's context, not widget's context
        barrierDismissible: false,
        builder: (loadingDialogContext) {
          // Store the navigator from the loading dialog's context
          dialogNavigator = Navigator.of(loadingDialogContext);
          print('📌 Stored loading dialog navigator: $dialogNavigator');
          return Dialog(
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
          );
        },
      );
      
      // Wait for dialog to be fully shown
      await Future.delayed(Duration(milliseconds: 150));
      print('✅ Loading dialog shown successfully');
      
      // CRITICAL: DON'T call setState here!
      // This would cause the widget to rebuild, which could close the purchase dialog
      // and potentially cause navigation issues. The dialog uses its own local state.
      // Just set the flag for tracking (not for UI updates)
      _isLoadingDialogOpen = true;
    } catch (e, stackTrace) {
      print('❌ Error showing loading dialog: $e');
      print('Stack trace: $stackTrace');
      // If we can't show the loading dialog, close the purchase dialog and show error
      try {
        if (Navigator.of(dialogContext, rootNavigator: false).canPop()) {
          Navigator.of(dialogContext, rootNavigator: false).pop();
        }
      } catch (e2) {
        print('⚠️ Error closing purchase dialog: $e2');
      }
      if (mounted && !_isDisposed && context.mounted) {
        _showErrorSnackBar(context, 'Failed to start subscription request. Please try again.');
      }
      return; // Exit early if we can't show the loading dialog
    }

    try {
      print('📤 Requesting subscription: planId=${plan.id}, userId=$currentUserId, periods=$periods, renewal=$renewal, advancePayment=$advancePayment');
      
      final result = await SubscriptionService.requestSubscriptionPlan(
        userId: currentUserId,
        planId: plan.id,
        renewal: renewal,
        advancePayment: advancePayment,
        periods: periods,
      );

      print('📥 Subscription request response: success=${result.success}, message=${result.message}');
      print('📌 Widget state - mounted: $mounted, _isDisposed: $_isDisposed');
      print('📌 Dialog navigator: $dialogNavigator');
      
      // CRITICAL: Check widget state BEFORE closing any dialogs
      final isWidgetMounted = mounted && !_isDisposed;
      final isContextValid = isWidgetMounted && context.mounted;
      
      if (!isWidgetMounted) {
        print('❌ CRITICAL: Widget is not mounted after API response');
        // Try to close dialogs anyway
        if (dialogNavigator != null && dialogNavigator!.mounted && dialogNavigator!.canPop()) {
          try {
            dialogNavigator!.pop();
          } catch (e) {
            // Ignore
          }
        }
        _isLoadingDialogOpen = false;
        return;
      }
      
      if (!isContextValid) {
        print('❌ CRITICAL: Context is not valid');
        _isLoadingDialogOpen = false;
        return;
      }
      
      print('✅ Widget is mounted and context is valid - closing dialogs');

      // Step 1: Close loading dialog first (the topmost dialog)
      bool loadingDialogClosed = false;
      
      if (dialogNavigator != null) {
        try {
          if (dialogNavigator!.mounted && dialogNavigator!.canPop()) {
            dialogNavigator!.pop();
            print('✅ Loading dialog closed using stored navigator');
            loadingDialogClosed = true;
          } else {
            print('⚠️ Stored navigator cannot pop');
          }
        } catch (e) {
          print('❌ Error closing loading dialog: $e');
        }
      }
      
      // Fallback: Try closing loading dialog using context
      if (!loadingDialogClosed && isContextValid) {
        try {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop();
            print('✅ Loading dialog closed using context (root)');
            loadingDialogClosed = true;
          }
        } catch (e) {
          print('❌ Error closing loading dialog with context: $e');
        }
      }
      
      // Step 2: Close purchase dialog (the dialog underneath)
      // CRITICAL: We need to close the purchase dialog, but we must be very careful
      // to NOT close the subscription page. The purchase dialog was shown using
      // the widget's context, so we need to pop it using that same context
      // BUT we must ensure we're only popping the dialog, not the page
      bool purchaseDialogClosed = false;
      
      // The purchase dialog was shown with showDialog(context: context) where context
      // is the widget's context. So we need to close it using the widget's context
      // but with rootNavigator: false to ensure we're only closing the dialog overlay
      try {
        // First, try using the dialogContext that was passed in (this is the purchase dialog's builder context)
        // But this might not work if the dialog was already disposed
        final purchaseDialogNavigator = Navigator.of(dialogContext, rootNavigator: false);
        if (purchaseDialogNavigator.canPop()) {
          // Check how many routes are on this navigator
          // If there's only one route (the page), we shouldn't pop
          // If there are multiple routes (page + dialog), we can pop the dialog
          purchaseDialogNavigator.pop();
          print('✅ Purchase dialog closed using dialogContext');
          purchaseDialogClosed = true;
        } else {
          print('⚠️ Purchase dialog navigator cannot pop');
        }
      } catch (e) {
        print('⚠️ Error closing purchase dialog with dialogContext: $e');
      }
      
      // Alternative: Try using widget context with rootNavigator: false
      // This should only close dialogs on the widget's navigator, not the page itself
      if (!purchaseDialogClosed && isContextValid) {
        try {
          // Use rootNavigator: false to ensure we're only working with dialogs,
          // not the page navigation stack
          final widgetNavigator = Navigator.of(context, rootNavigator: false);
          // Check if we can pop - this should be true if there's a dialog
          if (widgetNavigator.canPop()) {
            widgetNavigator.pop();
            print('✅ Purchase dialog closed using widget context (non-root)');
            purchaseDialogClosed = true;
          } else {
            print('⚠️ Widget navigator cannot pop - no dialogs to close');
          }
        } catch (e) {
          print('❌ Error closing purchase dialog with widget context: $e');
        }
      }
      
      // Always clear loading state
      _isLoadingDialogOpen = false;
      
      if (!loadingDialogClosed) {
        print('⚠️ WARNING: Could not close loading dialog');
      }
      if (!purchaseDialogClosed) {
        print('⚠️ WARNING: Could not close purchase dialog');
      }
      
      // Update state
      if (isWidgetMounted) {
        setState(() {
          _isLoadingDialogOpen = false;
        });
      }

      // Small delay to ensure dialogs are fully closed before refreshing
      await Future.delayed(Duration(milliseconds: 200));
      
      // CRITICAL: Verify widget is still mounted after closing dialogs
      if (!mounted || _isDisposed || !context.mounted) {
        print('❌ CRITICAL: Widget became unmounted after closing dialogs');
        print('   This indicates the subscription page was navigated away from');
        return;
      }

      if (result.success) {
        // Refresh available plans and user subscriptions FIRST
        // This ensures the pending request section appears immediately
        if (mounted && !_isDisposed) {
          print('🔄 Refreshing data after successful subscription request...');
          await _refreshData();
          print('✅ Data refreshed, pending request should now be visible');
          
          // Show success snackbar instead of dialog - this won't interfere with navigation
          // The pending request section will be visible immediately after refresh
          if (mounted && !_isDisposed && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Subscription request submitted successfully!',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Color(0xFF4ECDC4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 3),
              ),
            );
            
            // Scroll to pending request section after UI updates
            // Use post-frame callback to ensure the widget tree is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToPendingRequestSection();
            });
          }
        } else {
          print('⚠️ Widget not mounted after subscription request, cannot refresh');
        }
      } else {
        // Show error message with better handling
        String errorMessage = result.message.isNotEmpty ? result.message : 'Failed to request subscription';
        print('❌ Subscription request failed: $errorMessage');
        
        if (errorMessage.contains('already have a pending request')) {
          // Refresh data to show pending request section
          if (mounted && !_isDisposed) {
            await _refreshData();
          }
        }
        
        // Show error snackbar only if widget is mounted
        if (mounted && !_isDisposed && context.mounted) {
          _showErrorSnackBar(context, errorMessage);
        }
      }
    } catch (error, stackTrace) {
      print('❌ Exception in _requestSubscriptionPlan: $error');
      print('Stack trace: $stackTrace');
      
      // Close loading dialog on error - same logic as success case
      bool dialogClosed = false;
      
      // Method 1: Use stored dialog navigator
      if (dialogNavigator != null) {
        try {
          if (dialogNavigator!.mounted && dialogNavigator!.canPop()) {
            dialogNavigator!.pop();
            print('✅ Loading dialog closed on error using stored navigator');
            dialogClosed = true;
          }
        } catch (e) {
          print('❌ Error closing dialog on error: $e');
        }
      }
      
      // Method 2: Fallback - try with current context
      if (!dialogClosed && mounted && !_isDisposed && context.mounted) {
        try {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop();
            print('✅ Loading dialog closed on error using context');
            dialogClosed = true;
          }
        } catch (e) {
          print('❌ Error with context on error: $e');
        }
      }
      
      // Always clear loading state
      _isLoadingDialogOpen = false;
      
      if (!dialogClosed) {
        print('⚠️ WARNING: Could not close dialog on error');
      }
      
      // Update state if widget is still mounted
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoadingDialogOpen = false;
        });
      }
      
      // Small delay before showing error
      await Future.delayed(Duration(milliseconds: 150));
      
      if (mounted && !_isDisposed && context.mounted) {
        String errorMessage = 'An unexpected error occurred';
        if (error is Exception) {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        } else if (error is String) {
          errorMessage = error;
        }
        _showErrorSnackBar(context, errorMessage);
      }
    } finally {
      // Always clear loading state
      if (mounted && !_isDisposed) {
        setState(() {
          _isRequestingPlan = false;
          // _isLoadingDialogOpen is already set to false in closeLoadingDialog
        });
      }
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

  void _showLockedPlanInfoDialog(BuildContext context, SubscriptionPlan plan) {
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Plan Locked',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                plan.getDisplayName(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.lockMessage ?? 'This plan is currently unavailable',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelPendingRequest() async {
    final uid = AuthService.getCurrentUserId();
    if (uid == null || !mounted) return;

    try {
      if (mounted) setState(() { _isLoadingPendingRequest = true; });
      
      final result = await SubscriptionService.cancelPendingRequest(uid);
      
      if (result.success) {
        if (mounted) await _refreshData();
        if (mounted) _showSuccessSnackBar('Pending request cancelled successfully');
      } else {
        if (mounted) _showErrorSnackBar(context, result.message);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(context, 'Error cancelling request: $e');
    } finally {
      if (mounted) setState(() { _isLoadingPendingRequest = false; });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPendingRequestSection() {
    final pendingData = _pendingRequest!['pending_request'];
    final isExpired = _pendingRequest!['is_expired'] ?? false;
    
    // Safely parse time_remaining_hours (could be int, double, string, or null)
    double timeRemainingHours = 0.0;
    final timeRemainingValue = _pendingRequest!['time_remaining_hours'];
    if (timeRemainingValue != null) {
      if (timeRemainingValue is num) {
        timeRemainingHours = timeRemainingValue.toDouble();
      } else if (timeRemainingValue is String) {
        timeRemainingHours = double.tryParse(timeRemainingValue) ?? 0.0;
      }
    }
    
    // Get periods and total price with safe parsing
    int periods = 1;
    final periodsValue = pendingData['periods'];
    if (periodsValue != null) {
      if (periodsValue is int) {
        periods = periodsValue;
      } else if (periodsValue is num) {
        periods = periodsValue.toInt();
      } else if (periodsValue is String) {
        periods = int.tryParse(periodsValue) ?? 1;
      }
    }
    
    // Get total price with safe parsing
    double totalPrice = 0.0;
    final totalPriceValue = pendingData['total_price'] ?? pendingData['amount_paid'];
    if (totalPriceValue != null) {
      if (totalPriceValue is num) {
        totalPrice = totalPriceValue.toDouble();
      } else if (totalPriceValue is String) {
        totalPrice = double.tryParse(totalPriceValue) ?? 0.0;
      }
    }
    
    // Determine duration text based on plan type with safe parsing
    int durationMonths = 1;
    final durationMonthsValue = pendingData['duration_months'];
    if (durationMonthsValue != null) {
      if (durationMonthsValue is int) {
        durationMonths = durationMonthsValue;
      } else if (durationMonthsValue is num) {
        durationMonths = durationMonthsValue.toInt();
      } else if (durationMonthsValue is String) {
        durationMonths = int.tryParse(durationMonthsValue) ?? 1;
      }
    }
    
    int durationDays = 0;
    final durationDaysValue = pendingData['duration_days'];
    if (durationDaysValue != null) {
      if (durationDaysValue is int) {
        durationDays = durationDaysValue;
      } else if (durationDaysValue is num) {
        durationDays = durationDaysValue.toInt();
      } else if (durationDaysValue is String) {
        durationDays = int.tryParse(durationDaysValue) ?? 0;
      }
    }
    
    String quantityText = '';
    if (durationDays > 0) {
      quantityText = periods > 1 ? '$periods periods' : '1 period';
    } else if (durationMonths >= 12) {
      quantityText = periods > 1 ? '$periods years' : '1 year';
    } else {
      quantityText = periods > 1 ? '$periods months' : '1 month';
    }
    
    // Format total price
    final formattedTotalPrice = '₱${totalPrice.toStringAsFixed(2)}';
    
    // All plans (including Day Pass): 12 hours expiration
    final maxHours = 12.0;
    
    // Ensure expiration doesn't exceed max hours
    final displayHours = timeRemainingHours > maxHours 
        ? maxHours 
        : (timeRemainingHours < 0.0 ? 0.0 : timeRemainingHours);
    
    return Container(
      key: _pendingRequestSectionKey, // Add key for scrolling to this section
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpired ? Icons.error : Icons.hourglass_top,
                color: isExpired ? Colors.red : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                isExpired ? 'Request Expired' : 'Pending Request',
                style: GoogleFonts.poppins(
                  color: isExpired ? Colors.red : Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Plan: ${pendingData['plan_name']}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity: $quantityText',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Total: $formattedTotalPrice',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4ECDC4),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isExpired) ...[
            SizedBox(height: 4),
            Text(
              'Expires in: ${displayHours.toStringAsFixed(1)} hours',
              style: GoogleFonts.poppins(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please go to the front desk to process your payment within ${maxHours.toInt()} hours',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoadingPendingRequest ? null : _cancelPendingRequest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoadingPendingRequest
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Text(
                          'Cancel Request',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Refresh',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    
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

  void _showErrorSnackBar(BuildContext context, String message) {
    if (!mounted || _isDisposed) return;
    
    try {
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
              if (mounted && !_isDisposed) {
                try {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                } catch (e) {
                  // Ignore errors when hiding snackbar
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      // Ignore errors when showing snackbar
      print('Error showing snackbar: $e');
    }
  }

  void _showPlansAvailedDetails() async {
    try {
      final uid = AuthService.getCurrentUserId();
      if (uid == null) return;

      // Get user's availed plans
      final availedPlans = await _getUserAvailedPlans(uid);
      
      if (availedPlans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No availed plans found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D2D),
                    const Color(0xFF1E1E1E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4ECDC4).withOpacity(0.2),
                          const Color(0xFF45B7D1).withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ECDC4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.list_alt,
                            color: Color(0xFF4ECDC4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plans Availed Details',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Your subscription history',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      itemCount: availedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = availedPlans[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2D2D2D),
                                const Color(0xFF1E1E1E),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: plan.isMembershipPlan 
                                  ? const Color(0xFF9C27B0).withOpacity(0.3)
                                  : plan.planName.toLowerCase().contains('coach')
                                      ? const Color(0xFFFF9800).withOpacity(0.3)
                                      : const Color(0xFF4CAF50).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: plan.isMembershipPlan 
                                    ? const Color(0xFF9C27B0).withOpacity(0.1)
                                    : plan.planName.toLowerCase().contains('coach')
                                        ? const Color(0xFFFF9800).withOpacity(0.1)
                                        : const Color(0xFF4CAF50).withOpacity(0.1),
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
                                      color: plan.isMembershipPlan 
                                          ? const Color(0xFF9C27B0).withOpacity(0.2)
                                          : plan.planName.toLowerCase().contains('coach')
                                              ? const Color(0xFFFF9800).withOpacity(0.2)
                                              : const Color(0xFF4CAF50).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      plan.isMembershipPlan 
                                          ? Icons.card_membership 
                                          : plan.planName.toLowerCase().contains('coach')
                                              ? Icons.fitness_center
                                              : Icons.subscriptions,
                                      color: plan.isMembershipPlan 
                                          ? const Color(0xFF9C27B0)
                                          : plan.planName.toLowerCase().contains('coach')
                                              ? const Color(0xFFFF9800)
                                              : const Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      plan.getDisplayName(),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: plan.isMembershipPlan 
                                          ? const Color(0xFF9C27B0)
                                          : plan.planName.toLowerCase().contains('coach')
                                              ? const Color(0xFFFF9800)
                                              : const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      plan.isMembershipPlan 
                                          ? 'MEMBERSHIP' 
                                          : plan.planName.toLowerCase().contains('coach')
                                              ? 'COACH'
                                              : 'MONTHLY',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
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
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Price',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plan.getFormattedPrice(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Duration',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          plan.getDurationText(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (plan.description?.isNotEmpty == true) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    plan.description!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error showing plans availed details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading plans details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DynamicSubscriptionCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool userIsMember;
  final VoidCallback onTap;
  final bool isHighlighted;

  const DynamicSubscriptionCard({
    Key? key,
    required this.plan,
    required this.userIsMember,
    required this.onTap,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  _DynamicSubscriptionCardState createState() => _DynamicSubscriptionCardState();
}

class _DynamicSubscriptionCardState extends State<DynamicSubscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize glow animation for highlighted card
    if (widget.isHighlighted) {
      _glowController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500),
      );
      
      _glowAnimation = Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ));
      
      // Start pulsing animation
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.isHighlighted) {
      _glowController.dispose();
    }
    super.dispose();
  }

  Color _getCardColor() {
    // Color theory-based plan colors for visual distinction and meaning
    
    // Plan ID 1: Gym Membership (Annual) - GOLD/YELLOW
    // Meaning: Premium, luxury, exclusivity, value
    // Gold represents the highest tier, excellence, and long-term commitment
    if (widget.plan.id == 1) {
      return Color(0xFFFFD700); // Gold - Premium membership
    }
    
    // Plan ID 2: Member Monthly Access - TEAL/CYAN
    // Meaning: Trust, reliability, membership benefits
    // Teal represents balance, renewal, and member-exclusive benefits
    if (widget.plan.id == 2) {
      return Color(0xFF4ECDC4); // Teal - Member monthly
    }
    
    // Plan ID 3: Non-Member Monthly Access - BLUE
    // Meaning: Accessibility, standard service, professionalism
    // Blue represents trust, stability, and universal access
    if (widget.plan.id == 3) {
      return Color(0xFF45B7D1); // Sky Blue - Standard monthly
    }
    
    // Plan ID 5: Combination Package - PURPLE/VIOLET
    // Meaning: Value, special offer, combination of benefits
    // Purple represents premium value, special deals, and exclusivity
    if (widget.plan.id == 5) {
      return Color(0xFF9C27B0); // Purple - Combination package
    }
    
    // Plan ID 6: Day Pass - ORANGE
    // Meaning: Energy, trial, short-term access
    // Orange represents enthusiasm, trial experiences, and temporary access
    if (widget.plan.id == 6) {
      return Color(0xFFFF9800); // Orange - Day pass
    }
    
    // Fallback: Determine color by plan characteristics
    final planName = widget.plan.planName.toLowerCase();
    
    // Gym Membership plans - Gold for premium
    if (widget.plan.isMembershipPlan || planName.contains('gym membership')) {
      return Color(0xFFFFD700); // Gold
    }
    
    // Member-only monthly plans - Teal for membership benefits
    if (widget.plan.isMemberOnly && widget.plan.isMonthlyPlan) {
      return Color(0xFF4ECDC4); // Teal
    }
    
    // Combination packages - Purple for special value
    if (planName.contains('combination') || planName.contains('package')) {
      return Color(0xFF9C27B0); // Purple
    }
    
    // Day passes - Orange for trial/short-term
    if (planName.contains('day pass') || widget.plan.durationDays != null && widget.plan.durationDays! <= 1) {
      return Color(0xFFFF9800); // Orange
    }
    
    // Standard monthly plans (non-member) - Blue for accessibility
    if (widget.plan.isMonthlyPlan && !widget.plan.isMemberOnly) {
      return Color(0xFF45B7D1); // Sky Blue
    }
    
    // Default: Green for general plans (growth, health)
    return Color(0xFF4CAF50); // Green - General/Health-focused
  }

  @override
  Widget build(BuildContext context) {
    final bool isAccessible = !widget.plan.isMemberOnly || widget.userIsMember;
    final bool isPlanLocked = widget.plan.isLocked;
    final Color cardColor = _getCardColor();
    
    // Debug: Log features for this plan
    print('🔍 DynamicSubscriptionCard: Plan "${widget.plan.planName}" has ${widget.plan.features.length} features');
    if (widget.plan.features.isNotEmpty) {
      for (final feature in widget.plan.features) {
        print('🔍   - Feature: ${feature.featureName} - ${feature.description}');
      }
    } else {
      print('⚠️ DynamicSubscriptionCard: Plan "${widget.plan.planName}" has NO features');
    }
    
    // Build box shadows with glow effect if highlighted
    List<BoxShadow> boxShadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ];
    
    if (widget.isHighlighted) {
      // Add glowing shadow effect
      boxShadows.addAll([
        BoxShadow(
          color: Color(0xFFFFD700).withOpacity(0.6),
          blurRadius: 20,
          spreadRadius: 2,
          offset: Offset(0, 0),
        ),
        BoxShadow(
          color: Color(0xFFFFD700).withOpacity(0.4),
          blurRadius: 30,
          spreadRadius: 4,
          offset: Offset(0, 0),
        ),
      ]);
    }
    
    return GestureDetector(
      onTap: isPlanLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: widget.isHighlighted ? _glowAnimation : const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: widget.isHighlighted
                  ? Border.all(
                      color: Color(0xFFFFD700).withOpacity(_glowAnimation.value),
                      width: 3,
                    )
                  : (widget.plan.hasDiscount
                      ? Border.all(color: cardColor, width: 2)
                      : null),
              boxShadow: widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: Color(0xFFFFD700).withOpacity(_glowAnimation.value * 0.8),
                        blurRadius: 25,
                        spreadRadius: 3,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Color(0xFFFFD700).withOpacity(_glowAnimation.value * 0.4),
                        blurRadius: 40,
                        spreadRadius: 6,
                        offset: Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ]
                  : [
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
                      // Highlighted badge for gym membership
                      if (widget.isHighlighted)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFD700).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.black, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'RECOMMENDED',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Lock status badge
                      if (isPlanLocked)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.plan.lockIcon ?? '🔒',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LOCKED',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.plan.hasDiscount)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            widget.plan.getFormattedDiscountPercentage()!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (widget.plan.isMemberOnly)
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
                  if (widget.plan.hasDiscount || widget.plan.isMemberOnly || widget.isHighlighted) SizedBox(height: 12),
                  
                  // Plan Name
                  Text(
                    widget.plan.getDisplayName(),
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
                      if (widget.plan.hasDiscount) ...[
                        Text(
                          widget.plan.getFormattedDiscountedPrice()!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.plan.getFormattedPrice(),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else ...[
                        Text(
                          widget.plan.getFormattedPrice(),
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
                          widget.plan.getPlanTypeText(),
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
                          widget.plan.getDurationText(),
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
            
            // Lock messages (outside features section)
            if (isPlanLocked || !isAccessible)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    if (isPlanLocked) ...[
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
                                widget.plan.lockMessage ?? 'This plan is currently unavailable',
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
                    ] else if (!isAccessible) ...[
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
                  ],
                ),
              ),
            
            // Features section (always show if there are features)
            if (widget.plan.features.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 
                  (isPlanLocked || !isAccessible) ? 0 : 20, 
                  20, 
                  0
                ),
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
                    
                    // Features list
                    ...widget.plan.features.map((feature) => Padding(
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
                  ],
                ),
              ),
            
            // Action Button (always shown with proper spacing)
            Padding(
              padding: EdgeInsets.fromLTRB(
                20, 
                (widget.plan.features.isNotEmpty || isPlanLocked || !isAccessible) ? 20 : 20, 
                20, 
                20
              ),
              child: ElevatedButton(
                onPressed: isPlanLocked ? null : widget.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAccessible 
                      ? (widget.isHighlighted ? Color(0xFFFFD700) : cardColor)
                      : Colors.grey[800],
                  foregroundColor: widget.isHighlighted && isAccessible ? Colors.black : Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: widget.isHighlighted ? 8 : 0,
                ),
                child: Text(
                  isPlanLocked 
                      ? 'Unlock Requirements' 
                      : (isAccessible ? 'Select Plan' : 'Members Only'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
          );
        },
      ),
    );
  }
}

