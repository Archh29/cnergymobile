import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionHistoryPage> createState() => _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? _currentSubscription;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Debug: Starting to load subscription data...');
      _userId = await SubscriptionService.getUserId();
      print('Debug: Retrieved user ID: $_userId');
      
      if (_userId > 0) {
        print('Debug: User ID is valid, fetching subscription history...');
        final historyData = await SubscriptionService.getSubscriptionHistory(_userId);
        print('Debug: Retrieved subscription history: $historyData');
        
        print('Debug: Fetching current subscription...');
        final currentData = await SubscriptionService.getCurrentSubscription(_userId);
        print('Debug: Retrieved current subscription: $currentData');
        
         setState(() {
           // Parse membership_info.php response format
           if (historyData != null && historyData['success'] == true && historyData['data'] != null) {
             final membershipData = historyData['data'];
             _subscriptionData = {
               'subscription_history': [membershipData], // Convert single membership to list
               'success': true
             };
             _currentSubscription = {
               'subscription': membershipData,
               'subscription_status': membershipData['status'],
               'days_remaining': membershipData['days_remaining'],
               'is_premium': membershipData['has_membership']
             };
           } else {
             _subscriptionData = historyData;
             _currentSubscription = currentData;
           }
           _isLoading = false;
         });
      } else {
        print('Debug: User ID is 0 or invalid, skipping data fetch');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
         title: Text(
           'My Subscriptions',
           style: GoogleFonts.poppins(
             color: Colors.white,
             fontSize: 18,
             fontWeight: FontWeight.w600,
           ),
         ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSubscriptionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_subscriptionData == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptionData,
      color: const Color(0xFF4CAF50),
      backgroundColor: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Request History'),
            const SizedBox(height: 12),
            _buildRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_currentSubscription == null) {
      return _buildNoActiveSubscriptionCard();
    }

     final activeCoachData = _currentSubscription!['active_coach'];
     final activeCoach = (activeCoachData is Map<String, dynamic>) ? activeCoachData : null;
     final subscription = _currentSubscription!['subscription'];
     final subscriptionStatus = _currentSubscription!['subscription_status'] ?? 'Inactive';
     final daysRemaining = _currentSubscription!['days_remaining'] ?? 0;
     final isPremium = _currentSubscription!['is_premium'] ?? false;
     final hasActiveSubscription = subscription != null && daysRemaining > 0;
     final membershipStatus = hasActiveSubscription ? 'PREMIUM' : 'STANDARD';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF2E7D32).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                     Text(
                       subscriptionStatus,
                       style: GoogleFonts.poppins(
                         color: const Color(0xFF4CAF50),
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                  ],
                ),
              ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: hasActiveSubscription 
                         ? const Color(0xFFFFD700) 
                         : const Color(0xFF757575),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     membershipStatus,
                     style: GoogleFonts.poppins(
                       color: Colors.white,
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ),
            ],
          ),
          // Show membership card if user has member benefits
          if (_currentSubscription != null) ...[
            const SizedBox(height: 16),
            _buildMembershipCard(),
          ],
          // Show subscription info (membership or monthly access)
          if (subscription != null) ...[
            const SizedBox(height: 16),
            _buildSubscriptionInfo(subscription, daysRemaining),
          ],
          // Show coach package info if available
          if (activeCoach != null) ...[
            const SizedBox(height: 16),
            _buildCoachSubscriptionInfo(activeCoach),
          ],
        ],
      ),
    );
  }

   Widget _buildNoActiveSubscriptionCard() {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: const Color(0xFF2D2D2D),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: const Color(0xFF757575).withOpacity(0.3),
           width: 1,
         ),
       ),
       child: Column(
         children: [
           Icon(
             Icons.info_outline,
             color: const Color(0xFF757575),
             size: 48,
           ),
           const SizedBox(height: 12),
           Text(
             'No Active Subscription',
             style: GoogleFonts.poppins(
               color: Colors.white,
               fontSize: 18,
               fontWeight: FontWeight.w600,
             ),
           ),
           const SizedBox(height: 8),
           Text(
             'You don\'t have an active coach connection or subscription at the moment.',
             style: GoogleFonts.poppins(
               color: const Color(0xFFB0B0B0),
               fontSize: 14,
             ),
             textAlign: TextAlign.center,
           ),
         ],
       ),
     );
   }


  // Helper method to calculate days remaining
  int _calculateDaysRemaining(String? endDate) {
    if (endDate == null) return 0;
    
    try {
      final end = DateTime.parse(endDate);
      final now = DateTime.now();
      final difference = end.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to calculate membership duration
  String _calculateMembershipDuration(String? startDate, String? endDate) {
    if (startDate == null || endDate == null) return 'Unknown';
    
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final difference = end.difference(start).inDays;
      
      if (difference >= 365) {
        final years = (difference / 365).floor();
        final remainingDays = difference % 365;
        if (remainingDays > 0) {
          return '$years year${years > 1 ? 's' : ''} $remainingDays day${remainingDays > 1 ? 's' : ''}';
        }
        return '$years year${years > 1 ? 's' : ''}';
      } else if (difference >= 30) {
        final months = (difference / 30).floor();
        final remainingDays = difference % 30;
        if (remainingDays > 0) {
          return '$months month${months > 1 ? 's' : ''} $remainingDays day${remainingDays > 1 ? 's' : ''}';
        }
        return '$months month${months > 1 ? 's' : ''}';
      } else {
        return '$difference day${difference > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Invalid dates';
    }
  }


  Widget _buildSubscriptionInfo(Map<String, dynamic> subscription, int daysRemaining) {
    // Handle both membership and coach subscription data
    final planName = subscription['plan_name'] ?? subscription['membership_type'] ?? 'Unknown Plan';
    final price = subscription['price'] ?? subscription['discounted_price'] ?? '0';
    final startDate = subscription['start_date'];
    final endDate = subscription['end_date'];
    final status = subscription['display_status'] ?? subscription['status'] ?? subscription['status_name'] ?? 'Unknown';
    final isExpired = subscription['is_expired'] ?? false;
    final isExpiringSoon = subscription['is_expiring_soon'] ?? false;
    
    // Determine if this is a membership or coach subscription
    final isMembership = planName.toLowerCase().contains('member') || 
                        planName.toLowerCase().contains('monthly') ||
                        planName.toLowerCase().contains('access');
    final isCoachSubscription = subscription['coach_name'] != null;
    final isMemberRate = planName.toLowerCase().contains('member rate');
    
    String subscriptionType = 'Subscription';
    Color typeColor = const Color(0xFF2196F3);
    String typeLabel = 'SUBSCRIPTION';
    
    if (isMembership) {
      if (isMemberRate) {
        subscriptionType = 'Monthly Premium Access';
        typeColor = const Color(0xFF4CAF50);
        typeLabel = 'PREMIUM';
      } else {
        subscriptionType = 'Monthly Standard Access';
        typeColor = const Color(0xFF757575);
        typeLabel = 'STANDARD';
      }
    } else if (isCoachSubscription) {
      subscriptionType = 'Coach Package';
      typeColor = const Color(0xFFFF9800);
      typeLabel = 'COACH';
    }

     return Container(
       padding: const EdgeInsets.all(16),
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
           color: typeColor.withOpacity(0.3),
           width: 1.5,
         ),
         boxShadow: [
           BoxShadow(
             color: typeColor.withOpacity(0.1),
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
               Icon(
                 isMembership ? Icons.card_membership : 
                 isCoachSubscription ? Icons.fitness_center : Icons.subscriptions,
                 color: typeColor,
                 size: 20,
               ),
               const SizedBox(width: 8),
               Text(
                 subscriptionType,
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: typeColor,
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text(
                   typeLabel,
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 10,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           // Plan info with better design
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: typeColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: typeColor.withOpacity(0.2),
                 width: 1,
               ),
             ),
             child: Row(
               children: [
                 Icon(
                   Icons.star,
                   color: typeColor,
                   size: 20,
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         isMembership ? (isMemberRate ? 'Monthly (Member Rate)' : 'Monthly (Standard Rate)') : planName,
                         style: GoogleFonts.poppins(
                           color: Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       Text(
                         '₱$price',
                         style: GoogleFonts.poppins(
                           color: typeColor,
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
           const SizedBox(height: 16),
           // Enhanced Date Display Section
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: typeColor.withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: typeColor.withOpacity(0.2),
                 width: 1,
               ),
             ),
             child: Column(
               children: [
                 Row(
                   children: [
                     Icon(
                       Icons.schedule,
                       color: typeColor,
                       size: 16,
                     ),
                     const SizedBox(width: 8),
                     Text(
                       'Subscription Period',
                       style: GoogleFonts.poppins(
                         color: typeColor,
                         fontSize: 14,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: _buildDateItem(
                         'Start Date',
                         SubscriptionService.formatDate(startDate),
                         Icons.play_circle_outline,
                         typeColor,
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildDateItem(
                         'End Date',
                         SubscriptionService.formatDate(endDate),
                         Icons.event_available,
                         typeColor,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     Expanded(
                       child: _buildDateItem(
                         'Duration',
                         _calculateMembershipDuration(startDate, endDate),
                         Icons.timer,
                         typeColor,
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildDateItem(
                         'Days Remaining',
                         '$daysRemaining days',
                         Icons.hourglass_empty,
                         daysRemaining > 7 ? typeColor : 
                         daysRemaining > 0 ? typeColor : const Color(0xFFF44336),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

   String _getStatusDisplay(int daysRemaining, bool isExpired, bool isExpiringSoon, String status) {
     if (isExpired) {
       return 'Expired';
     } else if (isExpiringSoon) {
       return 'Expires Soon ($daysRemaining days left)';
     } else if (daysRemaining > 0) {
       return 'Active ($daysRemaining days left)';
     } else {
       return status;
     }
   }

   IconData _getStatusIcon(int daysRemaining, bool isExpired, bool isExpiringSoon) {
     if (isExpired) {
       return Icons.cancel;
     } else if (isExpiringSoon) {
       return Icons.warning;
     } else if (daysRemaining > 0) {
       return Icons.check_circle;
     } else {
       return Icons.help_outline;
     }
   }


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

   Widget _buildCoachSubscriptionInfo(Map<String, dynamic> coach) {
     final coachName = coach['coach_name'] ?? 'Unknown Coach';
     final rate = coach['monthly_rate'] ?? coach['session_package_rate'] ?? '0';
     final sessions = coach['remaining_sessions'] ?? '0';
     final expiresAt = coach['expires_at'];
     final requestedAt = coach['requested_at'];
     final coachApprovedAt = coach['coach_approved_at'];
     final staffApprovedAt = coach['staff_approved_at'];
     final rateType = coach['rate_type'] ?? 'package';
     const Color coachColor = Color(0xFFFF9800);
     
     // Use the latest approval date as start date (when both coach and staff approved)
     String? startDate;
     if (staffApprovedAt != null) {
       startDate = staffApprovedAt;
     } else if (coachApprovedAt != null) {
       startDate = coachApprovedAt;
     } else {
       startDate = requestedAt; // Fallback to request date
     }
     
     final endDate = expiresAt;
     
     // Calculate days remaining from expires_at
     int daysRemaining = 0;
     if (expiresAt != null) {
       try {
         final endDateTime = DateTime.parse(expiresAt);
         final now = DateTime.now();
         daysRemaining = endDateTime.difference(now).inDays;
       } catch (e) {
         print('Error parsing coach end date: $e');
       }
     }
     
     print('Debug: Coach data - Name: $coachName, Requested: $requestedAt, Coach Approved: $coachApprovedAt, Staff Approved: $staffApprovedAt, Start: $startDate, End: $endDate, Sessions: $sessions, Days Remaining: $daysRemaining');
     
     return Container(
       padding: const EdgeInsets.all(16),
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
           color: const Color(0xFFFF9800).withOpacity(0.3),
           width: 1.5,
         ),
         boxShadow: [
           BoxShadow(
             color: const Color(0xFFFF9800).withOpacity(0.1),
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
               Icon(
                 Icons.fitness_center,
                 color: const Color(0xFFFF9800),
                 size: 20,
               ),
               const SizedBox(width: 8),
               Text(
                 'Active Coach',
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
               ),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: const Color(0xFFFF9800),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Text(
                   'COACH',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 10,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           // Coach info with avatar
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFFFF9800).withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: const Color(0xFFFF9800).withOpacity(0.2),
                 width: 1,
               ),
             ),
             child: Row(
               children: [
                 CircleAvatar(
                   radius: 20,
                   backgroundColor: const Color(0xFFFF9800),
                   child: Text(
                     coachName.substring(0, 1).toUpperCase(),
                     style: GoogleFonts.poppins(
                       color: Colors.white,
                       fontSize: 16,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         coachName,
                         style: GoogleFonts.poppins(
                           color: Colors.white,
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                       Text(
                         '₱$rate/month',
                         style: GoogleFonts.poppins(
                           color: const Color(0xFFFF9800),
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
           const SizedBox(height: 16),
           // Enhanced Date Display for Coach Package
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFFFF9800).withOpacity(0.1),
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: const Color(0xFFFF9800).withOpacity(0.2),
                 width: 1,
               ),
             ),
             child: Column(
               children: [
                 Row(
                   children: [
                     Icon(
                       Icons.schedule,
                       color: const Color(0xFFFF9800),
                       size: 16,
                     ),
                     const SizedBox(width: 8),
                     Text(
                       'Coaching Period',
                       style: GoogleFonts.poppins(
                         color: const Color(0xFFFF9800),
                         fontSize: 14,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: _buildDateItem(
                         'Start Date',
                         SubscriptionService.formatDate(startDate),
                         Icons.play_circle_outline,
                         const Color(0xFFFF9800),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildDateItem(
                         'End Date',
                         SubscriptionService.formatDate(endDate),
                         Icons.event_available,
                         const Color(0xFFFF9800),
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 8),
                 Row(
                   children: [
                     Expanded(
                       child: _buildDateItem(
                         'Duration',
                         _calculateMembershipDuration(startDate, endDate),
                         Icons.timer,
                         const Color(0xFFFF9800),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildDateItem(
                         'Days Remaining',
                         '$daysRemaining days',
                         Icons.hourglass_empty,
                         daysRemaining > 7 ? const Color(0xFFFF9800) : 
                         daysRemaining > 0 ? const Color(0xFFFF9800) : const Color(0xFFF44336),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ],
       ),
     );
   }

  Widget _buildMembershipCard() {
    // Since you have member benefits, show membership card based on current subscription
    final currentSub = _currentSubscription?['subscription'];
    final isPremium = _currentSubscription?['is_premium'] ?? false;
    
    // Show membership card if user has any subscription (since you have member benefits)
    if (currentSub == null) {
      return const SizedBox.shrink(); // Don't show card if no subscription
    }
    
    // Use current subscription data for membership card
    final startDate = currentSub?['start_date'];
    // Calculate end date for annual membership (1 year from start)
    String? endDate;
    if (startDate != null) {
      try {
        final start = DateTime.parse(startDate);
        final end = DateTime(start.year + 1, start.month, start.day);
        endDate = end.toIso8601String().split('T')[0];
      } catch (e) {
        endDate = currentSub?['end_date'];
      }
    } else {
      endDate = currentSub?['end_date'];
    }
    
    final membershipType = 'Annual';
    final isExpired = currentSub?['is_expired'] ?? false;
    final isExpiringSoon = currentSub?['is_expiring_soon'] ?? false;
    final daysRemaining = _currentSubscription?['days_remaining'] ?? 0;
    final price = '500'; // Annual membership fee
    final planName = 'Membership';
    
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(
                Icons.card_membership,
                color: const Color(0xFF9C27B0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Membership',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'MEMBER',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Membership info with better design
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: const Color(0xFF9C27B0),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium Access',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₱$price',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9C27B0),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Enhanced Date Display Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: const Color(0xFF9C27B0),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subscription Period',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9C27B0),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        'Start Date',
                        SubscriptionService.formatDate(startDate),
                        Icons.play_circle_outline,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateItem(
                        'End Date',
                        SubscriptionService.formatDate(endDate),
                        Icons.event_available,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        'Duration',
                        '1 year',
                        Icons.timer,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateItem(
                        'Days Remaining',
                        '$daysRemaining days',
                        Icons.hourglass_empty,
                        daysRemaining > 7 ? const Color(0xFF9C27B0) : 
                        daysRemaining > 0 ? const Color(0xFFFF9800) : const Color(0xFFF44336),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
              color: const Color(0xFF4CAF50),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color.withOpacity(0.8),
                fontSize: 11,
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    final requests = _subscriptionData!['requests'] as List<dynamic>? ?? [];
    
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

   Widget _buildRequestCard(Map<String, dynamic> request) {
     final status = request['status_display'] ?? 'Unknown';
     final statusColor = SubscriptionService.getStatusColor(status);
     final statusIcon = SubscriptionService.getStatusIcon(status);

     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: const Color(0xFF2D2D2D),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(
           color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))).withOpacity(0.3),
           width: 1,
         ),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(
                   statusIcon,
                   style: const TextStyle(
                     color: Colors.white,
                     fontSize: 16,
                   ),
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       request['coach_name'] ?? 'Unknown Coach',
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                     Text(
                       status,
                       style: GoogleFonts.poppins(
                         color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ],
                 ),
               ),
               Text(
                 SubscriptionService.formatDate(request['requested_at']),
                 style: GoogleFonts.poppins(
                   color: const Color(0xFFB0B0B0),
                   fontSize: 12,
                 ),
               ),
             ],
           ),
           const SizedBox(height: 12),
           _buildRequestDetails(request),
         ],
       ),
     );
   }

  Widget _buildRequestDetails(Map<String, dynamic> request) {
    return Column(
      children: [
        _buildDetailRow('Coach Approval', request['coach_approval']),
        _buildDetailRow('Staff Approval', request['staff_approval']),
        if (request['expires_at'] != null)
          _buildDetailRow('Expires', SubscriptionService.formatDate(request['expires_at'])),
        if (request['remaining_sessions'] != null && request['rate_type'] == 'package')
          _buildDetailRow('Sessions', '${request['remaining_sessions']} remaining'),
        if (request['rate_type'] != null)
          _buildDetailRow('Rate Type', request['rate_type'].toString().toUpperCase()),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history,
            color: const Color(0xFF757575),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Requests Found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any coach requests yet.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            color: const Color(0xFFF44336),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load subscription data. Please try again.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptionData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
