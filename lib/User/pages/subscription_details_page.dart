import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import '../models/subscription_model.dart';

class SubscriptionDetailsPage extends StatefulWidget {
  const SubscriptionDetailsPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionDetailsPage> createState() => _SubscriptionDetailsPageState();
}

class _SubscriptionDetailsPageState extends State<SubscriptionDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Current subscription data
  Map<String, dynamic>? _currentSubscription;
  bool _isLoadingCurrent = false;
  
  // Subscription history data
  List<SubscriptionPlan> _availedPlans = [];
  Map<int, String> _subscriptionStatusMap = {}; // Map subscription ID to status
  Map<int, Map<String, dynamic>> _subscriptionDurationMap = {}; // Map subscription ID to duration info (periods, total_duration_months, etc.)
  Map<int, DateTime?> _subscriptionDateMap = {}; // Map subscription ID to start_date for sorting
  bool _isLoadingHistory = false;
  
  // Filter state
  String _selectedFilter = 'All'; // All, Paid, Cancelled, Unpaid
  
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = AuthService.getCurrentUserId();
    if (uid == null) return;
    
    setState(() {
      _userId = uid;
      _isLoadingCurrent = true;
      _isLoadingHistory = true;
    });
    
    // Load both in parallel
    await Future.wait([
      _loadCurrentSubscription(),
      _loadSubscriptionHistory(),
    ]);
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final currentData = await SubscriptionService.getCurrentSubscription(_userId);
      if (mounted) {
        setState(() {
          _currentSubscription = currentData;
          _isLoadingCurrent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCurrent = false;
        });
      }
      print('Error loading current subscription: $e');
    }
  }

  Future<void> _loadSubscriptionHistory() async {
    try {
      final result = await _getUserAvailedPlans(_userId);
      final availedPlans = result['plans'] as List<SubscriptionPlan>? ?? [];
      final statusMap = result['statusMap'] as Map<int, String>? ?? <int, String>{};
      final durationMap = result['durationMap'] as Map<int, Map<String, dynamic>>? ?? <int, Map<String, dynamic>>{};
      final dateMap = result['dateMap'] as Map<int, DateTime?>? ?? <int, DateTime?>{};
      
      if (mounted) {
        setState(() {
          _availedPlans = availedPlans;
          _subscriptionStatusMap = statusMap;
          _subscriptionDurationMap = durationMap;
          _subscriptionDateMap = dateMap;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
      print('Error loading subscription history: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserAvailedPlans(int userId) async {
    try {
      final historyData = await SubscriptionService.getSubscriptionHistory(userId);
      final currentSubscriptionData = await SubscriptionService.getCurrentSubscription(userId);
      
      if (historyData == null && currentSubscriptionData == null) {
        return {
          'plans': <SubscriptionPlan>[], 
          'statusMap': <int, String>{},
          'durationMap': <int, Map<String, dynamic>>{},
          'dateMap': <int, DateTime?>{}
        };
      }

      List<SubscriptionPlan> availedPlans = [];
      Map<int, String> subscriptionStatusMap = {};
      Map<int, Map<String, dynamic>> subscriptionDurationMap = {};
      Map<int, DateTime?> subscriptionDateMap = {};

      // Check for current subscription - try both sources
      Map<String, dynamic>? currentSub;
      if (currentSubscriptionData != null && currentSubscriptionData['subscription'] != null) {
        currentSub = currentSubscriptionData['subscription'];
      } else if (historyData != null && historyData['current_subscription'] != null) {
        currentSub = historyData['current_subscription'];
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
        
        final priceStr = currentSub['original_price']?.toString() ?? 
                        currentSub['price']?.toString() ?? 
                        currentSub['discounted_price']?.toString() ?? '0';
        final price = double.tryParse(priceStr) ?? 0.0;
        
        final discountedPriceStr = currentSub['discounted_price']?.toString();
        final discountedPrice = discountedPriceStr != null ? double.tryParse(discountedPriceStr) : null;
        
        final planId = currentSub['plan_id'] ?? currentSub['id'] ?? 0;
        
        // Store status for current subscription
        final currentStatus = currentSub['status_name']?.toString() ?? 
                             currentSub['display_status']?.toString() ?? 
                             'approved'; // Default to approved for current subscription
        subscriptionStatusMap[planId] = currentStatus;
        
        // Get periods and total duration
        final periods = int.tryParse(currentSub['periods']?.toString() ?? '1') ?? 1;
        final totalDurationMonths = currentSub['total_duration_months'] != null 
            ? int.tryParse(currentSub['total_duration_months'].toString()) 
            : null;
        final totalDurationDays = currentSub['total_duration_days'] != null 
            ? int.tryParse(currentSub['total_duration_days'].toString()) 
            : null;
        
        // Store duration info for this subscription
        subscriptionDurationMap[planId] = {
          'periods': periods,
          'total_duration_months': totalDurationMonths,
          'total_duration_days': totalDurationDays,
          'base_duration_months': int.tryParse(currentSub['duration_months']?.toString() ?? '1') ?? 1,
          'base_duration_days': currentSub['duration_days'] != null ? int.tryParse(currentSub['duration_days'].toString()) : null,
        };
        
        // Store date for sorting (use start_date, fallback to requested_at or current date)
        DateTime? subscriptionDate;
        if (currentSub['start_date'] != null) {
          try {
            subscriptionDate = DateTime.parse(currentSub['start_date'].toString());
          } catch (e) {
            print('Error parsing start_date: $e');
          }
        }
        if (subscriptionDate == null && currentSub['requested_at'] != null) {
          try {
            subscriptionDate = DateTime.parse(currentSub['requested_at'].toString());
          } catch (e) {
            print('Error parsing requested_at: $e');
          }
        }
        subscriptionDateMap[planId] = subscriptionDate;
        
        final plan = SubscriptionPlan(
          id: planId,
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
        
        availedPlans.add(plan);
      }

      // Add coach packages from requests array
      if (historyData != null && historyData['requests'] != null) {
        final requests = historyData['requests'] as List<dynamic>;
        
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
          }
        }
      }

      // Add gym membership and other subscriptions from the subscriptions array
      try {
        final userSubs = await SubscriptionService.getUserSubscriptions(userId);
        
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
            continue;
          }
          
          // Store status for this subscription (if not already stored)
          if (!subscriptionStatusMap.containsKey(sub.id)) {
            subscriptionStatusMap[sub.id] = sub.statusName;
          }
          
          // Calculate total duration based on periods
          final periods = sub.periods;
          final baseDurationMonths = sub.durationMonths;
          final baseDurationDays = sub.durationDays;
          final totalDurationMonths = baseDurationMonths * periods;
          final totalDurationDays = baseDurationDays != null ? baseDurationDays * periods : null;
          
          // Store duration info for this subscription
          subscriptionDurationMap[sub.id] = {
            'periods': periods,
            'total_duration_months': totalDurationMonths,
            'total_duration_days': totalDurationDays,
            'base_duration_months': baseDurationMonths,
            'base_duration_days': baseDurationDays,
          };
          
          // Store date for sorting (from UserSubscription model if available)
          // Note: UserSubscription might not have date info, so we'll get it from historyData later
          
          // Create a plan with status information stored in description or create extended plan
          final plan = SubscriptionPlan(
            id: sub.id,
            planName: planName,
            price: sub.price,
            discountedPrice: sub.discountedPrice,
            durationMonths: baseDurationMonths,
            durationDays: baseDurationDays,
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
        }
      } catch (e) {
        print('Error getting user subscriptions: $e');
      }
      
      // Store subscription status and duration mapping from history data
      // This includes ALL subscriptions including pending ones
      if (historyData != null && historyData['subscriptions'] != null) {
        final subscriptions = historyData['subscriptions'] as List<dynamic>;
        for (var sub in subscriptions) {
          final subId = int.tryParse(sub['id'].toString()) ?? 0;
          final status = sub['status_name']?.toString() ?? sub['display_status']?.toString() ?? 'Unknown';
          subscriptionStatusMap[subId] = status;
          
          // Check if this subscription is already in availedPlans
          bool alreadyAdded = availedPlans.any((plan) => plan.id == subId);
          
          // If not already added (e.g., pending requests), add it
          if (!alreadyAdded) {
            final planName = sub['plan_name']?.toString() ?? 'Unknown Plan';
            final isMembership = planName.toLowerCase().contains('gym membership fee') || 
                                planName.toLowerCase().contains('membership');
            final isMemberRate = planName.toLowerCase().contains('member rate') || 
                              planName.toLowerCase().contains('member monthly') ||
                              (planName.toLowerCase().contains('member') && 
                               !planName.toLowerCase().contains('non-member') && 
                               !planName.toLowerCase().contains('non member'));
            final isDayPass = planName.toLowerCase().contains('day pass');
            
            final priceStr = sub['original_price']?.toString() ?? 
                            sub['price']?.toString() ?? 
                            sub['discounted_price']?.toString() ?? '0';
            final price = double.tryParse(priceStr) ?? 0.0;
            
            final discountedPriceStr = sub['discounted_price']?.toString();
            final discountedPrice = discountedPriceStr != null ? double.tryParse(discountedPriceStr) : null;
            
            final periods = int.tryParse(sub['periods']?.toString() ?? '1') ?? 1;
            final totalDurationMonths = sub['total_duration_months'] != null 
                ? int.tryParse(sub['total_duration_months'].toString()) 
                : null;
            final totalDurationDays = sub['total_duration_days'] != null 
                ? int.tryParse(sub['total_duration_days'].toString()) 
                : null;
            final baseDurationMonths = int.tryParse(sub['duration_months']?.toString() ?? '1') ?? 1;
            final baseDurationDays = sub['duration_days'] != null 
                ? int.tryParse(sub['duration_days'].toString()) 
                : null;
            
            // Store duration info
            subscriptionDurationMap[subId] = {
              'periods': periods,
              'total_duration_months': totalDurationMonths,
              'total_duration_days': totalDurationDays,
              'base_duration_months': baseDurationMonths,
              'base_duration_days': baseDurationDays,
            };
            
            // Store date for sorting (use start_date, fallback to requested_at)
            DateTime? subscriptionDate;
            if (sub['start_date'] != null) {
              try {
                subscriptionDate = DateTime.parse(sub['start_date'].toString());
              } catch (e) {
                print('Error parsing start_date: $e');
              }
            }
            if (subscriptionDate == null && sub['requested_at'] != null) {
              try {
                subscriptionDate = DateTime.parse(sub['requested_at'].toString());
              } catch (e) {
                print('Error parsing requested_at: $e');
              }
            }
            subscriptionDateMap[subId] = subscriptionDate;
            
            final plan = SubscriptionPlan(
              id: subId,
              planName: planName,
              price: price,
              discountedPrice: discountedPrice,
              durationMonths: baseDurationMonths,
              durationDays: baseDurationDays,
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
          } else {
            // Store duration info if not already stored
            if (!subscriptionDurationMap.containsKey(subId)) {
              final periods = int.tryParse(sub['periods']?.toString() ?? '1') ?? 1;
              final totalDurationMonths = sub['total_duration_months'] != null 
                  ? int.tryParse(sub['total_duration_months'].toString()) 
                  : null;
              final totalDurationDays = sub['total_duration_days'] != null 
                  ? int.tryParse(sub['total_duration_days'].toString()) 
                  : null;
              final baseDurationMonths = int.tryParse(sub['duration_months']?.toString() ?? '1') ?? 1;
              final baseDurationDays = sub['duration_days'] != null 
                  ? int.tryParse(sub['duration_days'].toString()) 
                  : null;
              
              subscriptionDurationMap[subId] = {
                'periods': periods,
                'total_duration_months': totalDurationMonths,
                'total_duration_days': totalDurationDays,
                'base_duration_months': baseDurationMonths,
                'base_duration_days': baseDurationDays,
              };
            }
            
            // Store date for sorting if not already stored
            if (!subscriptionDateMap.containsKey(subId)) {
              DateTime? subscriptionDate;
              if (sub['start_date'] != null) {
                try {
                  subscriptionDate = DateTime.parse(sub['start_date'].toString());
                } catch (e) {
                  print('Error parsing start_date: $e');
                }
              }
              if (subscriptionDate == null && sub['requested_at'] != null) {
                try {
                  subscriptionDate = DateTime.parse(sub['requested_at'].toString());
                } catch (e) {
                  print('Error parsing requested_at: $e');
                }
              }
              subscriptionDateMap[subId] = subscriptionDate;
            }
          }
        }
      }
      
      // Also get status from getUserSubscriptions
      try {
        final userSubs = await SubscriptionService.getUserSubscriptions(userId);
        for (var sub in userSubs) {
          subscriptionStatusMap[sub.id] = sub.statusName;
          
          // Store duration info if not already stored
          if (!subscriptionDurationMap.containsKey(sub.id)) {
            final periods = sub.periods;
            final baseDurationMonths = sub.durationMonths;
            final baseDurationDays = sub.durationDays;
            final totalDurationMonths = baseDurationMonths * periods;
            final totalDurationDays = baseDurationDays != null ? baseDurationDays * periods : null;
            
            subscriptionDurationMap[sub.id] = {
              'periods': periods,
              'total_duration_months': totalDurationMonths,
              'total_duration_days': totalDurationDays,
              'base_duration_months': baseDurationMonths,
              'base_duration_days': baseDurationDays,
            };
          }
          
          // Store date for sorting if not already stored
          if (!subscriptionDateMap.containsKey(sub.id) && sub.startDate.isNotEmpty) {
            try {
              subscriptionDateMap[sub.id] = DateTime.parse(sub.startDate);
            } catch (e) {
              print('Error parsing startDate from UserSubscription: $e');
            }
          }
        }
      } catch (e) {
        print('Error getting subscription status: $e');
      }

      // Filter out individual Monthly Access plan if user has combination package
      bool hasCombinationPackage = availedPlans.any((plan) => 
          plan.planName.toLowerCase().contains('membership + 1 month access'));
      
      if (hasCombinationPackage) {
        availedPlans.removeWhere((plan) => 
            (plan.planName.toLowerCase().contains('monthly access (member rate)') && 
             plan.price == 0.0) ||
            (plan.planName.toLowerCase().contains('gym membership fee') && 
             plan.price == 0.0));
      }

      return {
        'plans': availedPlans, 
        'statusMap': subscriptionStatusMap,
        'durationMap': subscriptionDurationMap,
        'dateMap': subscriptionDateMap
      };
    } catch (e) {
      print('Error getting user availed plans: $e');
      return {
        'plans': <SubscriptionPlan>[], 
        'statusMap': <int, String>{},
        'durationMap': <int, Map<String, dynamic>>{},
        'dateMap': <int, DateTime?>{}
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'My Subscriptions',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFF4ECDC4),
          indicatorWeight: 3,
          labelColor: Color(0xFF4ECDC4),
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Current Subscription'),
            Tab(text: 'Subscription History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentSubscriptionTab(),
          _buildSubscriptionHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionTab() {
    if (_isLoadingCurrent) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (_currentSubscription == null || _currentSubscription!['subscription'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No Active Subscription',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You don\'t have any active subscriptions',
              style: GoogleFonts.poppins(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final subscription = _currentSubscription!['subscription'];
    final subscriptionStatus = _currentSubscription!['subscription_status'] ?? 'Inactive';
    final daysRemaining = _currentSubscription!['days_remaining'] ?? 0;
    final activeMembership = _currentSubscription!['active_membership'];
    // Handle both null and false cases from API (PHP returns false, but we want to treat it as null)
    final activeCoachRaw = _currentSubscription!['active_coach'];
    final activeCoach = (activeCoachRaw != null && activeCoachRaw is Map) ? activeCoachRaw : null;
    
    final planName = subscription['plan_name']?.toString() ?? 'Unknown Plan';
    final planId = subscription['plan_id'] ?? 0;
    
    // Determine plan type and color
    final isDayPass = planId == 6;
    final isMembership = planId == 1;
    
    Color cardColor;
    IconData planIcon;
    if (isDayPass) {
      cardColor = Color(0xFFFF9800); // Orange
      planIcon = Icons.event_available;
    } else if (isMembership) {
      cardColor = Color(0xFFFFD700); // Gold
      planIcon = Icons.card_membership;
    } else {
      cardColor = Color(0xFF4ECDC4); // Teal
      planIcon = Icons.subscriptions;
    }
    
    final startDate = subscription['start_date']?.toString() ?? 'N/A';
    final endDate = subscription['end_date']?.toString() ?? 'N/A';
    
    final priceStr = subscription['original_price']?.toString() ?? 
                    subscription['amount_paid']?.toString() ?? '0';
    final price = double.tryParse(priceStr) ?? 0.0;
    final formattedPrice = '₱${price.toStringAsFixed(2)}';

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Container wrapping all subscriptions
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(0xFF2D2D2D),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Text(
                  'My Subscriptions',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20),
                
                // Gym Membership Card (Always at top if exists)
                if (activeMembership != null) ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 16),
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
                        color: const Color(0xFF9C27B0).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withOpacity(0.1),
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
                                color: const Color(0xFF9C27B0).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.card_membership,
                                color: const Color(0xFF9C27B0),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activeMembership['plan_name']?.toString() ?? 'Gym Membership',
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
                                color: const Color(0xFF9C27B0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'MEMBERSHIP',
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
                                    'End Date',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(activeMembership['end_date']?.toString()),
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
                                    'Days Remaining',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (activeMembership['days_remaining'] ?? 0) > 0 
                                        ? '${activeMembership['days_remaining']} day${activeMembership['days_remaining'] == 1 ? '' : 's'}' 
                                        : 'Expired',
                                    style: GoogleFonts.poppins(
                                      color: (activeMembership['days_remaining'] ?? 0) > 0 ? Colors.green : Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Notice if no gym membership
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No gym membership plan availed',
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
                ],
                
                // Current Subscription Card (if exists and not the same as membership)
                if (subscription != null && (activeMembership == null || activeMembership['plan_id'] != planId)) ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.only(bottom: 16),
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
                        color: cardColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.1),
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
                                color: cardColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                planIcon,
                                color: cardColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                planName,
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
                                color: isDayPass 
                                    ? const Color(0xFFFF9800)
                                    : isMembership
                                        ? const Color(0xFF9C27B0)
                                        : const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDayPass 
                                    ? 'DAY PASS'
                                    : isMembership
                                        ? 'MEMBERSHIP'
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
                                    formattedPrice,
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
                                    isDayPass 
                                        ? '1 Session'
                                        : isMembership
                                            ? '12 Months'
                                            : '1 Month',
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
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDayPass 
                                ? 'Day pass - 1 day access, standard rate, limited access'
                                : isMembership
                                    ? 'Annual membership - Can access everything, unlimited access'
                                    : 'Monthly access - 1 month access, standard rate, limited access',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Other Subscriptions Section (Only for coach)
                if (activeCoach != null) ...[
                  SizedBox(height: 24),
                  Text(
                    'Other Subscriptions',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                
                // Active Coach Card (Small Card)
                if (activeCoach != null) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFFF9800).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF9800).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                color: Color(0xFFFF9800),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personal Coach',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    activeCoach['coach_name']?.toString() ?? 'Unknown Coach',
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFFFF9800),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: activeCoach['status'] == 'active' 
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: activeCoach['status'] == 'active' 
                                      ? Colors.green
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                activeCoach['status'] == 'active' ? 'Active' : 'Inactive',
                                style: GoogleFonts.poppins(
                                  color: activeCoach['status'] == 'active' 
                                      ? Colors.green
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            if (activeCoach['remaining_sessions'] != null) ...[
                              Expanded(
                                child: _buildSmallDetailItem(
                                  'Sessions',
                                  activeCoach['remaining_sessions'].toString(),
                                  Icons.event_available,
                                  Color(0xFFFF9800),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            if (activeCoach['expires_at'] != null) ...[
                              Expanded(
                                child: _buildSmallDetailItem(
                                  'Expires',
                                  _formatDate(activeCoach['expires_at']?.toString()),
                                  Icons.event,
                                  Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (activeCoach['coach_specialty'] != null && activeCoach['coach_specialty'].toString().isNotEmpty) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFFF9800), size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${activeCoach['coach_specialty']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistoryTab() {
    if (_isLoadingHistory) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    // Filter subscriptions based on selected filter
    List<SubscriptionPlan> filteredPlans = _availedPlans.where((plan) {
      final status = _subscriptionStatusMap[plan.id] ?? 'Unknown';
      final statusLower = status.toLowerCase();
      
      switch (_selectedFilter) {
        case 'Paid':
          return statusLower == 'approved' || statusLower == 'active';
        case 'Cancelled':
          return statusLower == 'cancelled' || statusLower == 'rejected';
        case 'Unpaid':
          return statusLower == 'pending_approval' || statusLower.contains('pending');
        default:
          return true; // Show all
      }
    }).toList();
    
    // Sort by date (most recent first), with ID as fallback
    filteredPlans.sort((a, b) {
      final statusA = _subscriptionStatusMap[a.id] ?? '';
      final statusB = _subscriptionStatusMap[b.id] ?? '';
      final isPendingA = statusA.toLowerCase().contains('pending');
      final isPendingB = statusB.toLowerCase().contains('pending');
      
      // Prioritize pending subscriptions (they should appear at top)
      if (isPendingA && !isPendingB) return -1;
      if (!isPendingA && isPendingB) return 1;
      
      final dateA = _subscriptionDateMap[a.id];
      final dateB = _subscriptionDateMap[b.id];
      
      // If both have dates, compare them (most recent first)
      if (dateA != null && dateB != null) {
        final dateCompare = dateB.compareTo(dateA); // Descending order (newest first)
        // If dates are equal, use ID as tiebreaker
        if (dateCompare != 0) return dateCompare;
        return b.id.compareTo(a.id);
      }
      // If only one has a date, prioritize it
      if (dateA != null) return -1;
      if (dateB != null) return 1;
      // If neither has a date, use ID as fallback (higher ID = more recent)
      return b.id.compareTo(a.id); // Descending order by ID (newest first)
    });

    if (filteredPlans.isEmpty) {
      return Column(
        children: [
          // Filter chips
          _buildFilterChips(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_outlined,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All' 
                        ? 'No Subscription History'
                        : 'No ${_selectedFilter} Subscriptions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'All'
                        ? 'You haven\'t subscribed to any plans yet'
                        : 'You don\'t have any ${_selectedFilter.toLowerCase()} subscriptions',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),
        // Subscription list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: filteredPlans.length,
            itemBuilder: (context, index) {
              final plan = filteredPlans[index];
              return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(20),
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
                  Builder(
                    builder: (context) {
                      // Get status for this subscription
                      final status = _subscriptionStatusMap[plan.id] ?? 'Unknown';
                      final statusDisplay = _getStatusDisplayText(status);
                      final statusColor = _getStatusColor(status);
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusDisplay,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
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
                        Builder(
                          builder: (context) {
                            // Get duration info to calculate total price
                            final durationInfo = _subscriptionDurationMap[plan.id];
                            final periods = durationInfo?['periods'] as int? ?? 1;
                            final basePrice = plan.price;
                            final totalPrice = basePrice * periods;
                            
                            // Show total price (base price × periods)
                            String priceText = '₱${totalPrice.toStringAsFixed(2)}';
                            
                            return Text(
                              priceText,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
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
                        Builder(
                          builder: (context) {
                            // Get duration info for this subscription
                            final durationInfo = _subscriptionDurationMap[plan.id];
                            final durationText = _getSubscriptionDurationText(plan, durationInfo);
                            
                            return Text(
                              durationText,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
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
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', _selectedFilter == 'All'),
            SizedBox(width: 8),
            _buildFilterChip('Paid', _selectedFilter == 'Paid'),
            SizedBox(width: 8),
            _buildFilterChip('Unpaid', _selectedFilter == 'Unpaid'),
            SizedBox(width: 8),
            _buildFilterChip('Cancelled', _selectedFilter == 'Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(0xFF4ECDC4) 
              : Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Color(0xFF4ECDC4) 
                : Color(0xFF2D2D2D),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'PAID';
      case 'pending_approval':
      case 'pending':
        return 'UNPAID';
      case 'cancelled':
        return 'CANCELLED';
      case 'expired':
        return 'EXPIRED';
      case 'rejected':
        return 'REJECTED';
      case 'active':
        return 'ACTIVE';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return const Color(0xFF4CAF50); // Green
      case 'pending_approval':
      case 'pending':
        return const Color(0xFFFF9800); // Orange for unpaid/pending
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'expired':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  String _getSubscriptionDurationText(SubscriptionPlan plan, Map<String, dynamic>? durationInfo) {
    // Day Pass is always 1 session
    if (plan.id == 6 || plan.planName.toLowerCase().contains('day pass')) {
      return '1 Session';
    }
    
    // If we have duration info with periods, use it
    if (durationInfo != null) {
      final totalDurationMonths = durationInfo['total_duration_months'] as int?;
      final totalDurationDays = durationInfo['total_duration_days'] as int?;
      final periods = durationInfo['periods'] as int? ?? 1;
      
      // Use total_duration_days if available
      if (totalDurationDays != null && totalDurationDays > 0) {
        if (totalDurationDays == 1) {
          return '1 Day';
        } else {
          return '$totalDurationDays Days';
        }
      }
      
      // Use total_duration_months if available
      if (totalDurationMonths != null && totalDurationMonths > 0) {
        if (totalDurationMonths == 1) {
          return '1 Month';
        } else if (totalDurationMonths == 12) {
          return '1 Year';
        } else if (totalDurationMonths > 12 && totalDurationMonths % 12 == 0) {
          final years = totalDurationMonths ~/ 12;
          return '$years Year${years > 1 ? 's' : ''}';
        } else if (totalDurationMonths > 12) {
          final years = totalDurationMonths ~/ 12;
          final remainingMonths = totalDurationMonths % 12;
          if (remainingMonths > 0) {
            return '$years Year${years > 1 ? 's' : ''} $remainingMonths Month${remainingMonths > 1 ? 's' : ''}';
          }
          return '$years Year${years > 1 ? 's' : ''}';
        } else {
          return '$totalDurationMonths Month${totalDurationMonths > 1 ? 's' : ''}';
        }
      }
      
      // Fallback: calculate from base duration and periods
      final baseDurationMonths = durationInfo['base_duration_months'] as int? ?? plan.durationMonths;
      final baseDurationDays = durationInfo['base_duration_days'] as int? ?? plan.durationDays;
      
      if (baseDurationDays != null && baseDurationDays > 0) {
        final totalDays = baseDurationDays * periods;
        return totalDays == 1 ? '1 Day' : '$totalDays Days';
      } else {
        final totalMonths = baseDurationMonths * periods;
        if (totalMonths == 1) {
          return '1 Month';
        } else if (totalMonths == 12) {
          return '1 Year';
        } else if (totalMonths > 12 && totalMonths % 12 == 0) {
          final years = totalMonths ~/ 12;
          return '$years Year${years > 1 ? 's' : ''}';
        } else if (totalMonths > 12) {
          final years = totalMonths ~/ 12;
          final remainingMonths = totalMonths % 12;
          if (remainingMonths > 0) {
            return '$years Year${years > 1 ? 's' : ''} $remainingMonths Month${remainingMonths > 1 ? 's' : ''}';
          }
          return '$years Year${years > 1 ? 's' : ''}';
        } else {
          return '$totalMonths Month${totalMonths > 1 ? 's' : ''}';
        }
      }
    }
    
    // Fallback to plan's default duration text
    return plan.getDurationText();
  }
}

