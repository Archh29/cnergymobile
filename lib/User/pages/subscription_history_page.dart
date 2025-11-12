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
           // Use the subscription history data directly
           _subscriptionData = historyData;
           _currentSubscription = currentData;
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9800)),
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
      color: const Color(0xFFFF9800),
      backgroundColor: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Subscription History'),
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
     Map<String, dynamic>? activeCoach;
     
     // Check if coach is not expired before displaying
     if (activeCoachData is Map<String, dynamic>) {
       final expiresAt = activeCoachData['expires_at'];
       if (expiresAt != null) {
         try {
           final expireDate = DateTime.parse(expiresAt);
           final now = DateTime.now();
           if (expireDate.isAfter(now)) {
             activeCoach = activeCoachData;
           }
         } catch (e) {
           // If parsing fails, set to null
           activeCoach = null;
         }
       } else {
         // If no expiration date, show the coach
         activeCoach = activeCoachData;
       }
     }
     // Get the Gym Membership Fee subscription (plan id 1) and Monthly Access (plan id 2) from subscription history (only active ones)
     final subscriptionHistory = _subscriptionData?['subscription_history'] as List<dynamic>? ?? [];
     Map<String, dynamic>? membershipSubscription;
     Map<String, dynamic>? subscription;
     Map<String, dynamic>? combinationPackage;
     
     // Track the latest end dates to get the most recent active subscription
     DateTime? latestMembershipEndDate;
     DateTime? latestSubscriptionEndDate;
     DateTime? latestCombinationEndDate;
     
     for (final sub in subscriptionHistory) {
       final planId = sub['plan_id']?.toString() ?? '';
       final planName = sub['plan_name']?.toString().toLowerCase() ?? '';
       final endDateStr = sub['end_date'];
       
       if (endDateStr != null) {
         try {
           final endDate = DateTime.parse(endDateStr);
           final now = DateTime.now();
           if (endDate.isAfter(now)) {
             // Check for plan_id 5 (Combination Package)
             if (planId == '5' || planName.contains('combination') || planName.contains('membership + 1 month')) {
               if (latestCombinationEndDate == null || endDate.isAfter(latestCombinationEndDate)) {
                 combinationPackage = sub;
                 latestCombinationEndDate = endDate;
               }
             }
             // Check for plan_id 1 (Gym Membership) or names containing 'gym membership'
             if (planId == '1' || planName.contains('gym membership') || planName.contains('membership fee')) {
               if (latestMembershipEndDate == null || endDate.isAfter(latestMembershipEndDate)) {
                 membershipSubscription = sub;
                 latestMembershipEndDate = endDate;
               }
             }
             // Check for plan_id 2 (Member Monthly) or names containing 'member' and 'monthly' or 'monthly access'
             else if (planId == '2' || planName.contains('member monthly') || (planName.contains('member') && planName.contains('monthly')) || planName.contains('monthly access')) {
               if (latestSubscriptionEndDate == null || endDate.isAfter(latestSubscriptionEndDate)) {
                 subscription = sub;
                 latestSubscriptionEndDate = endDate;
               }
             }
           }
         } catch (e) {
           continue;
         }
       }
     }
     
     // Debug: Print selected subscription data
     if (subscription != null) {
       print('Debug: Selected subscription for current display:');
       print('  Plan: ${subscription['plan_name']}');
       print('  Periods: ${subscription['periods']}');
       print('  Total Duration Months: ${subscription['total_duration_months']}');
       print('  Total Duration Days: ${subscription['total_duration_days']}');
       print('  Duration Months (base): ${subscription['duration_months']}');
       print('  Amount Paid: ${subscription['amount_paid']}');
       print('  Original Price: ${subscription['original_price']}');
     }
     
     // If combination package exists but individual plans don't, create virtual subscriptions
     if (combinationPackage != null && (membershipSubscription == null || subscription == null)) {
       // Check if we need to create virtual membership (plan_id 1)
       if (membershipSubscription == null) {
         try {
           final startDateStr = combinationPackage['start_date'] as String;
           final startDateObj = DateTime.parse(startDateStr);
           // plan_id 1 should be 365 days (1 year)
           final newEndDateObj = startDateObj.add(Duration(days: 365)); // 1 year from start
           
           membershipSubscription = {
             'plan_id': 1,
             'plan_name': 'Gym Membership Fee',
             'start_date': startDateStr,
             'end_date': newEndDateObj.toString().split(' ')[0],
             'price': '500.00',
             'status_name': 'approved',
             'duration_months': 12,
             'duration_days': 365,
           };
         } catch (e) {
           print('Error creating virtual membership: $e');
         }
       }
       
       // Check if we need to create virtual monthly access (plan_id 2)
       if (subscription == null) {
         try {
           final startDateStr = combinationPackage['start_date'] as String;
           final startDateObj = DateTime.parse(startDateStr);
           // plan_id 2 should be 30 days (1 month), NOT using the package end_date
           final newEndDateObj = startDateObj.add(Duration(days: 30)); // 1 month from start
           
           subscription = {
             'plan_id': 2,
             'plan_name': 'Member Monthly Access',
             'start_date': startDateStr,
             'end_date': newEndDateObj.toString().split(' ')[0],
             'price': '999.00',
             'status_name': 'approved',
             'duration_months': 1,
             'duration_days': 30,
           };
         } catch (e) {
           print('Error creating virtual monthly access: $e');
         }
       }
     }
     
     final subscriptionStatus = _currentSubscription!['subscription_status'] ?? 'Inactive';
     
     // Calculate days remaining for the Monthly Access subscription
     int daysRemaining = 0;
     if (subscription != null && subscription['end_date'] != null) {
       try {
         final end = DateTime.parse(subscription['end_date']);
         final now = DateTime.now();
         daysRemaining = end.difference(now).inDays;
       } catch (e) {
         daysRemaining = 0;
       }
     }
     
     final isPremium = _currentSubscription!['is_premium'] ?? false;
     
     // Determine the correct membership status based on Gym Membership (plan id 1)
     String membershipStatus = 'STANDARD';
     if (membershipSubscription != null) {
       // User has active Gym Membership Fee subscription - they are PREMIUM
       membershipStatus = 'PREMIUM';
     } else {
       // User does not have Gym Membership - they are STANDARD
       membershipStatus = 'STANDARD';
     }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800),
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 44), // Align with the text content above
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: membershipStatus == 'PREMIUM' 
                          ? const Color(0xFFFF9800)  // Orange for premium
                          : membershipStatus == 'STANDARD'
                              ? const Color(0xFF757575)  // Gray for standard
                              : const Color(0xFF2196F3),  // Blue for access
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
            Builder(
              builder: (context) {
                // Debug: Print subscription data to verify it has periods and total_duration
                final sub = subscription!; // Non-null assertion since we're inside the if block
                print('Debug: Current subscription data: ${sub.toString()}');
                print('Debug: Subscription periods: ${sub['periods']}');
                print('Debug: Subscription total_duration_months: ${sub['total_duration_months']}');
                print('Debug: Subscription total_duration_days: ${sub['total_duration_days']}');
                print('Debug: Subscription duration_months: ${sub['duration_months']}');
                print('Debug: Subscription amount_paid: ${sub['amount_paid']}');
                print('Debug: Subscription original_price: ${sub['original_price']}');
                return _buildSubscriptionInfo(sub, daysRemaining);
              },
            ),
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

  // Helper method to format days remaining in a user-friendly way (e.g., "1 year 2 months and 5 days")
  String _formatDaysRemaining(int days) {
    if (days <= 0) {
      return 'Expired';
    }
    
    if (days < 30) {
      return '$days day${days > 1 ? 's' : ''}';
    }
    
    // Calculate total months first (using 30 days per month)
    final totalMonths = days ~/ 30;
    
    // If we have 12 or more months, convert to years
    int years = 0;
    int months = 0;
    int remainingDays = days % 30;
    
    if (totalMonths >= 12) {
      // Convert months to years
      years = totalMonths ~/ 12;
      months = totalMonths % 12;
    } else {
      // Less than 12 months, just use months
      months = totalMonths;
    }
    
    List<String> parts = [];
    
    if (years > 0) {
      parts.add('$years year${years > 1 ? 's' : ''}');
    }
    
    if (months > 0) {
      parts.add('$months month${months > 1 ? 's' : ''}');
    }
    
    if (remainingDays > 0) {
      parts.add('$remainingDays day${remainingDays > 1 ? 's' : ''}');
    }
    
    if (parts.isEmpty) {
      return '$days day${days > 1 ? 's' : ''}';
    }
    
    // Join parts with appropriate separators
    if (parts.length == 1) {
      return parts[0];
    } else if (parts.length == 2) {
      return '${parts[0]} and ${parts[1]}';
    } else {
      // For 3 parts: "1 year 2 months and 5 days"
      return '${parts[0]} ${parts[1]} and ${parts[2]}';
    }
  }

  // Helper method to get plan type label (Monthly Plan or Yearly Plan)
  String _getPlanTypeLabel(Map<String, dynamic>? subscription) {
    if (subscription == null) return 'Unknown';
    
    final planName = subscription['plan_name']?.toString().toLowerCase() ?? '';
    final durationMonths = subscription['duration_months'] ?? 0;
    final durationDays = subscription['duration_days'] ?? 0;
    
    // Check if it's a yearly/membership plan
    if (planName.contains('membership fee') || 
        planName.contains('gym membership') ||
        durationMonths >= 12 ||
        (durationDays >= 365 && durationDays <= 366)) {
      return 'Yearly Plan';
    }
    
    // Check if it's a monthly plan
    if (planName.contains('monthly') || 
        planName.contains('month access') ||
        durationMonths == 1 ||
        (durationDays >= 28 && durationDays <= 31)) {
      return 'Monthly Plan';
    }
    
    // Check if it's a day pass
    if (planName.contains('day pass') || durationDays == 1) {
      return 'Day Pass';
    }
    
    // Default to Monthly Plan for other cases
    return 'Monthly Plan';
  }

  // Helper method to format plan duration based on plan data and periods
  String _formatPlanDuration(Map<String, dynamic>? subscription) {
    if (subscription == null) return 'Unknown';
    
    // PRIORITY 1: Calculate duration from actual start_date and end_date (most accurate)
    final startDate = subscription['start_date'];
    final endDate = subscription['end_date'];
    if (startDate != null && endDate != null) {
      try {
        final start = DateTime.parse(startDate.toString());
        final end = DateTime.parse(endDate.toString());
        final difference = end.difference(start).inDays;
        
        if (difference > 0) {
          // Format the actual duration from dates (rounded to months for cleaner display)
          if (difference >= 365) {
            final years = (difference / 365).floor();
            final remainingDays = difference % 365;
            // Round to nearest month if less than 30 days remaining
            if (remainingDays < 15) {
              return '$years year${years > 1 ? 's' : ''}';
            } else if (remainingDays >= 15 && remainingDays < 365) {
              final months = (remainingDays / 30).round();
              if (months == 0) {
                return '$years year${years > 1 ? 's' : ''}';
              } else if (months >= 12) {
                return '${years + 1} year${years + 1 > 1 ? 's' : ''}';
              } else {
                return '$years year${years > 1 ? 's' : ''} $months month${months > 1 ? 's' : ''}';
              }
            }
            return '$years year${years > 1 ? 's' : ''}';
          } else if (difference >= 30) {
            // Round to nearest month (if less than 15 days extra, don't show days)
            final months = (difference / 30).round();
            final exactMonths = (difference / 30).floor();
            final remainingDays = difference % 30;
            
            // If remaining days is less than 15, round down to months
            if (remainingDays < 15) {
              if (exactMonths == 0) {
                return '$difference day${difference > 1 ? 's' : ''}';
              }
              return '$exactMonths month${exactMonths > 1 ? 's' : ''}';
            } else {
              // If 15+ days remaining, round up to next month
              return '$months month${months > 1 ? 's' : ''}';
            }
          } else {
            return '$difference day${difference > 1 ? 's' : ''}';
          }
        }
      } catch (e) {
        // If date parsing fails, fall through to other methods
        print('Error parsing dates for duration: $e');
      }
    }
    
    // PRIORITY 2: Check if API already calculated total_duration
    final totalDurationMonthsFromAPI = subscription['total_duration_months'];
    final totalDurationDaysFromAPI = subscription['total_duration_days'];
    
    if (totalDurationDaysFromAPI != null && totalDurationDaysFromAPI > 0) {
      final totalDays = int.tryParse(totalDurationDaysFromAPI.toString()) ?? 0;
      if (totalDays == 1) {
        return '1 day';
      } else {
        return '$totalDays days';
      }
    }
    
    if (totalDurationMonthsFromAPI != null && totalDurationMonthsFromAPI > 0) {
      final totalMonths = int.tryParse(totalDurationMonthsFromAPI.toString()) ?? 0;
      if (totalMonths == 1) {
        return '1 month';
      } else if (totalMonths == 12) {
        return '1 year';
      } else if (totalMonths > 12 && totalMonths % 12 == 0) {
        final years = totalMonths ~/ 12;
        return '$years year${years > 1 ? 's' : ''}';
      } else if (totalMonths > 12) {
        final years = totalMonths ~/ 12;
        final remainingMonths = totalMonths % 12;
        if (remainingMonths > 0) {
          return '$years year${years > 1 ? 's' : ''} $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
        }
        return '$years year${years > 1 ? 's' : ''}';
      } else {
        return '$totalMonths months';
      }
    }
    
    // PRIORITY 3: Fallback - Calculate periods from amount_paid and price
    int periods = 1;
    final amountPaid = subscription['amount_paid'];
    final originalPrice = subscription['original_price'] ?? subscription['price'];
    
    if (originalPrice != null && amountPaid != null) {
      final priceValue = double.tryParse(originalPrice.toString()) ?? 0.0;
      final paidValue = double.tryParse(amountPaid.toString()) ?? 0.0;
      if (priceValue > 0) {
        periods = (paidValue / priceValue).round();
        if (periods < 1) periods = 1;
      }
    }
    
    // Also check if periods is already in the subscription data
    if (subscription['periods'] != null) {
      final periodsValue = subscription['periods'];
      if (periodsValue is int) {
        periods = periodsValue;
      } else if (periodsValue is num) {
        periods = periodsValue.toInt();
      } else if (periodsValue is String) {
        periods = int.tryParse(periodsValue) ?? periods;
      }
    }
    
    final durationMonths = subscription['duration_months'] ?? 0;
    final durationDays = subscription['duration_days'] ?? 0;
    
    // Calculate total duration based on periods
    final totalDurationDays = durationDays > 0 ? durationDays * periods : 0;
    final totalDurationMonths = durationMonths > 0 ? durationMonths * periods : 0;
    
    // If duration_days is specified and > 0, use days
    if (totalDurationDays > 0) {
      if (totalDurationDays == 1) {
        return '1 day';
      } else {
        return '$totalDurationDays days';
      }
    }
    
    // Otherwise use months
    if (totalDurationMonths > 0) {
      if (totalDurationMonths == 1) {
        return '1 month';
      } else if (totalDurationMonths == 12) {
        return '1 year';
      } else if (totalDurationMonths > 12 && totalDurationMonths % 12 == 0) {
        final years = totalDurationMonths ~/ 12;
        return '$years year${years > 1 ? 's' : ''}';
      } else if (totalDurationMonths > 12) {
        final years = totalDurationMonths ~/ 12;
        final remainingMonths = totalDurationMonths % 12;
        if (remainingMonths > 0) {
          return '$years year${years > 1 ? 's' : ''} $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
        }
        return '$years year${years > 1 ? 's' : ''}';
      } else {
        return '$totalDurationMonths months';
      }
    }
    
    return 'Unknown';
  }


  Widget _buildSubscriptionInfo(Map<String, dynamic> subscription, int daysRemaining) {
    // Handle both membership and coach subscription data
    final planName = subscription['plan_name'] ?? subscription['membership_type'] ?? 'Unknown Plan';
    final endDate = subscription['end_date'];
    // final status = subscription['display_status'] ?? subscription['status'] ?? subscription['status_name'] ?? 'Unknown';
    // final isExpired = subscription['is_expired'] ?? false;
    // final isExpiringSoon = subscription['is_expiring_soon'] ?? false;
    
    // Determine if this is a membership or coach subscription
    final isMembership = planName.toLowerCase().contains('member') || 
                        planName.toLowerCase().contains('monthly') ||
                        planName.toLowerCase().contains('access');
    final isCoachSubscription = subscription['coach_name'] != null;
    
    // More specific plan type detection
    final isMemberRate = (planName.toLowerCase().contains('member rate') && 
                         !planName.toLowerCase().contains('non-member')) || 
                        (planName.toLowerCase().contains('member monthly') && 
                         !planName.toLowerCase().contains('non-member'));
    final isNonMemberPlan = planName.toLowerCase().contains('non-member') || 
                           planName.toLowerCase().contains('non member') ||
                           planName.toLowerCase().contains('standard');
    
    String subscriptionType = 'Subscription';
    Color typeColor = const Color(0xFF2196F3);
    String typeLabel = 'SUBSCRIPTION';
    
    if (isMembership) {
      if (isMemberRate) {
        subscriptionType = 'Monthly Premium Access';
        typeColor = const Color(0xFFFF9800);
        typeLabel = 'PREMIUM';
      } else if (isNonMemberPlan) {
        subscriptionType = 'Monthly Standard Access';
        typeColor = const Color(0xFF757575);
        typeLabel = 'STANDARD';
      } else {
        // Default for other membership types
        subscriptionType = 'Monthly Access';
        typeColor = const Color(0xFF2196F3);
        typeLabel = 'ACCESS';
      }
    } else if (isCoachSubscription) {
      subscriptionType = 'Coach Package';
      typeColor = const Color(0xFFFF9800);
      typeLabel = 'COACH';
    }

     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: const Color(0xFF1A1A1A),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: typeColor.withOpacity(0.3),
           width: 1.5,
         ),
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
               Expanded(
                 child: Text(
                   subscriptionType,
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                   ),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               const SizedBox(width: 8),
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
                      'Subscription Details',
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
                        'Plan Type',
                        _getPlanTypeLabel(subscription),
                        Icons.category,
                        typeColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateItem(
                        'Expiry Date',
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
                        'Time Remaining',
                        _formatDaysRemaining(daysRemaining),
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
    // final rateType = coach['rate_type'] ?? 'package';
    // const Color coachColor = Color(0xFFFF9800);
     
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
         color: const Color(0xFF1A1A1A),
         borderRadius: BorderRadius.circular(16),
         border: Border.all(
           color: const Color(0xFFFF9800).withOpacity(0.3),
           width: 1.5,
         ),
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
    // Get the Monthly Access subscription from subscription history
    final subscriptionHistory = _subscriptionData?['subscription_history'] as List<dynamic>? ?? [];
    
    // Find the Gym Membership Fee subscription (the one with 12 months duration)
    Map<String, dynamic>? membershipSub;
    for (final sub in subscriptionHistory) {
      if (sub['plan_name']?.toString().toLowerCase().contains('gym membership') == true) {
        // Check if subscription is not expired
        final endDateStr = sub['end_date'];
        if (endDateStr != null) {
          try {
            final endDate = DateTime.parse(endDateStr);
            final now = DateTime.now();
            if (endDate.isAfter(now)) {
              membershipSub = sub;
              break;
            }
          } catch (e) {
            // If parsing fails, skip this subscription
            continue;
          }
        }
      }
    }
    
    // Show membership card if user has gym membership subscription
    if (membershipSub == null) {
      return const SizedBox.shrink(); // Don't show card if no gym membership
    }
    
    // Use gym membership subscription data for membership card
    final endDate = membershipSub['end_date'];
    
    // Calculate days remaining for gym membership
    int daysRemaining = 0;
    if (endDate != null) {
      try {
        final end = DateTime.parse(endDate);
        final now = DateTime.now();
        daysRemaining = end.difference(now).inDays;
      } catch (e) {
        daysRemaining = 0;
      }
    }
    // final planName = monthlyAccessSub['plan_name'] ?? 'Membership';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_membership,
                color: const Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Membership',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
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
          const SizedBox(height: 16),
          // Enhanced Date Display Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: const Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subscription Details',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4CAF50),
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
                        'Plan Type',
                        _getPlanTypeLabel(membershipSub),
                        Icons.category,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateItem(
                        'Expiry Date',
                        SubscriptionService.formatDate(endDate),
                        Icons.event_available,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateItem(
                        'Time Remaining',
                        _formatDaysRemaining(daysRemaining),
                        Icons.hourglass_empty,
                        daysRemaining > 7 ? const Color(0xFF4CAF50) : 
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
              color: const Color(0xFFFF9800),
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
    // Get subscription history from the API response
    final subscriptionHistory = _subscriptionData!['subscription_history'] as List<dynamic>? ?? [];
    
    // Filter out individual plans if user has combination package
    List<dynamic> filteredHistory = List.from(subscriptionHistory);
    
    // Check if user has combination package (Membership + 1 Month Access)
    bool hasCombinationPackage = subscriptionHistory.any((sub) => 
        sub['plan_name']?.toString().toLowerCase().contains('membership + 1 month access') == true);
    
    if (hasCombinationPackage) {
      // Remove individual plans (Gym Membership Fee and Monthly Access) when combination package exists
      filteredHistory = subscriptionHistory.where((sub) {
        final planName = sub['plan_name']?.toString().toLowerCase() ?? '';
        return !(planName.contains('gym membership fee') || 
                 planName.contains('monthly access (member rate)'));
      }).toList();
      print('Debug: Filtered out individual plans due to combination package');
    }
    
    // Debug logging
    print('Debug: Total subscription history count: ${subscriptionHistory.length}');
    print('Debug: Has combination package: $hasCombinationPackage');
    print('Debug: Filtered history count: ${filteredHistory.length}');
    for (int i = 0; i < filteredHistory.length; i++) {
      final sub = filteredHistory[i];
      print('Debug: Filtered Subscription $i - ID: ${sub['id']}, Plan: ${sub['plan_name']}, Price: ${sub['price']}, Duration: ${sub['duration_months']} months');
    }
    
    if (filteredHistory.isEmpty) {
      return _buildEmptyState();
    }

    // Use Column instead of ListView.builder since it's inside SingleChildScrollView
    // This allows smooth scrolling for long lists
    return Column(
      children: filteredHistory.map((subscription) {
        return _buildSubscriptionHistoryCard(subscription);
      }).toList(),
    );
  }

  Widget _buildSubscriptionHistoryCard(Map<String, dynamic> subscription) {
    final planName = subscription['plan_name'] ?? 'Unknown Plan';
    final price = subscription['price']?.toString() ?? '0';
    final startDate = subscription['start_date'];
    final endDate = subscription['end_date'];
    final status = subscription['display_status'] ?? 'Unknown';
    final planDuration = _formatPlanDuration(subscription);
    
    // Debug logging
    print('Debug: Building subscription history card for plan: $planName, price: $price, duration: $planDuration');
    
    // Calculate days remaining
    int daysRemaining = 0;
    if (endDate != null) {
      try {
        final end = DateTime.parse(endDate);
        final now = DateTime.now();
        daysRemaining = end.difference(now).inDays;
      } catch (e) {
        daysRemaining = 0;
      }
    }
    
    // Determine status color
    Color statusColor = const Color(0xFFFF9800); // Orange for active
    if (status.toLowerCase().contains('expired')) {
      statusColor = const Color(0xFFF44336); // Red for expired
    } else if (status.toLowerCase().contains('pending')) {
      statusColor = const Color(0xFFFF9800); // Orange for pending
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
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
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  status.toLowerCase().contains('active') ? Icons.check_circle : 
                  status.toLowerCase().contains('expired') ? Icons.cancel :
                  Icons.schedule,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                SubscriptionService.formatDate(startDate),
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSubscriptionHistoryDetails(subscription, planDuration, daysRemaining),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistoryDetails(Map<String, dynamic> subscription, String planDuration, int daysRemaining) {
    final price = subscription['price']?.toString() ?? subscription['original_price']?.toString() ?? '0';
    
    // Calculate periods from amount_paid and price
    int periods = 1;
    final amountPaid = subscription['amount_paid'];
    final originalPrice = subscription['original_price'] ?? subscription['price'];
    
    if (originalPrice != null && amountPaid != null) {
      final priceValue = double.tryParse(originalPrice.toString()) ?? 0.0;
      final paidValue = double.tryParse(amountPaid.toString()) ?? 0.0;
      if (priceValue > 0) {
        periods = (paidValue / priceValue).round();
        if (periods < 1) periods = 1;
      }
    }
    
    // Get duration info
    final durationMonths = subscription['duration_months'] ?? 1;
    final durationDays = subscription['duration_days'];
    
    // Format quantity text
    String quantityText = '';
    if (durationDays != null && durationDays > 0) {
      quantityText = periods > 1 ? '$periods periods' : '1 period';
    } else if (durationMonths >= 12) {
      quantityText = periods > 1 ? '$periods years' : '1 year';
    } else {
      quantityText = periods > 1 ? '$periods months' : '1 month';
    }
    
    return Column(
      children: [
        _buildDetailRow('Price', '₱$price'),
        _buildDetailRow('Quantity', quantityText),
      ],
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
              backgroundColor: const Color(0xFFFF9800),
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
