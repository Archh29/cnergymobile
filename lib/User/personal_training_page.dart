import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/user_model.dart';
import './models/coach_model.dart';
import './services/coach_service.dart';
import './services/auth_service.dart';
import './services/coach_rating_service.dart';
import 'manage_subscriptions_page.dart';
import 'rate_coach_page.dart';
import 'coach_feedback_viewer.dart';

class PersonalTrainingPage extends StatefulWidget {
  final UserModel? currentUser;

  const PersonalTrainingPage({Key? key, this.currentUser}) : super(key: key);

  @override
  _PersonalTrainingPageState createState() => _PersonalTrainingPageState();
}

class _PersonalTrainingPageState extends State<PersonalTrainingPage>
    with TickerProviderStateMixin {
  List<CoachModel> coaches = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'All';
  
  // Coach request status (stored locally for now)
  String coachRequestStatus = "none";
  int? selectedCoachId;
  String? selectedCoachName;
  String? requestDate;
  Map<String, dynamic>? _remoteCoachRequest; // latest from API
  bool _loadingCoachRequest = false;
  bool _isCoachRelationshipExpired = false;
  bool _paymentModalShown = false;
  
  // Track previous coach approval status to detect approval
  String? _previousCoachApproval;
  String? _previousStaffApproval;
  
  // Timer for auto-refresh
  Timer? _statusPollingTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCoaches();
    _loadLocalData();
    _loadCoachRequestStatus();
    // Refresh ratings after a short delay to ensure coaches are loaded
    Future.delayed(Duration(seconds: 2), () {
      _refreshCoachRatings();
    });
    // Start auto-refresh polling for status updates
    _startStatusPolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh coach status when page becomes visible
    _loadCoachRequestStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusPollingTimer?.cancel();
    super.dispose();
  }
  
  void _startStatusPolling() {
    // Poll every 5 seconds for status updates
    _statusPollingTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Only poll if there's a pending request
      final coachApproval = _remoteCoachRequest?['coach_approval']?.toString() ?? 'none';
      final staffApproval = _remoteCoachRequest?['staff_approval']?.toString() ?? 'none';
      final status = _remoteCoachRequest?['status']?.toString() ?? 'none';
      
      // Continue polling if:
      // 1. There's a request and it's not fully approved yet
      // 2. Or if there's no request (might have just been made)
      final shouldPoll = _remoteCoachRequest != null && 
                        (coachApproval != 'approved' || staffApproval != 'approved' || status == 'pending');
      
      if (shouldPoll || _remoteCoachRequest == null) {
        _loadCoachRequestStatus();
      } else {
        // Stop polling if fully approved
        timer.cancel();
      }
    });
  }

  Future<void> _loadCoaches() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedCoaches = await CoachService.fetchCoaches();
      if (!mounted) return;
      setState(() {
        coaches = fetchedCoaches;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load coaches: $e';
        isLoading = false;
      });
    }
  }

  // Refresh coach ratings in real-time
  Future<void> _refreshCoachRatings() async {
    if (coaches.isEmpty) return;
    
    try {
      // Update ratings for all coaches
      for (int i = 0; i < coaches.length; i++) {
        final coach = coaches[i];
        final ratingData = await CoachRatingService.getCoachRatings(coach.id);
        
        if (ratingData['success'] == true) {
          final updatedCoach = CoachModel(
            id: coach.id,
            name: coach.name,
            specialty: coach.specialty,
            bio: coach.bio,
            experience: coach.experience,
            rating: _safeParseDouble(ratingData['average_rating']) ?? 0.0,
            totalClients: _safeParseInt(ratingData['total_reviews']) ?? 0,
            imageUrl: coach.imageUrl,
            isAvailable: coach.isAvailable,
            sessionRate: coach.sessionRate,
            monthlyRate: coach.monthlyRate,
            sessionPackageRate: coach.sessionPackageRate,
            sessionPackageCount: coach.sessionPackageCount,
            certifications: coach.certifications,
          );
          
          if (mounted) {
            setState(() {
              coaches[i] = updatedCoach;
            });
          }
        }
      }
    } catch (e) {
      print('Error refreshing coach ratings: $e');
    }
  }

  // Helper method to safely parse double values from API responses
  double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value');
        return null;
      }
    }
    return null;
  }

  // Helper method to safely parse int values from API responses
  int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $value');
        return null;
      }
    }
    return null;
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        coachRequestStatus = prefs.getString('coach_request_status') ?? 'none';
        selectedCoachId = prefs.getInt('selected_coach_id');
        selectedCoachName = prefs.getString('selected_coach_name');
        requestDate = prefs.getString('request_date');
      });
    } catch (e) {
      print('❌ Error loading local data: $e');
    }
  }

  Future<void> _loadCoachRequestStatus() async {
    try {
      if (!mounted) return;
      setState(() { _loadingCoachRequest = true; });
      int? userId = widget.currentUser?.id;
      if (userId == null) {
        userId = AuthService.getCurrentUserId();
      }
      if (userId == null) {
        if (!mounted) return;
        setState(() { _loadingCoachRequest = false; });
        return;
      }
      final data = await CoachService.getUserCoachRequest(userId);
      if (!mounted) return;
      
      print('🔍 API Response data: $data');
      print('🔍 API Response request: ${data?['request']}');
      
      final newRequest = data?['request'];
      final newStatus = (newRequest?['status']?.toString() ?? '').toLowerCase().trim();
      final newCoachApproval = (newRequest?['coach_approval']?.toString() ?? '').toLowerCase().trim();
      final newStaffApproval = (newRequest?['staff_approval']?.toString() ?? '').toLowerCase().trim();
      
      // Check if request is rejected/disconnected - clear state so user can select another coach
      final isRejected = newStatus == 'rejected' || newStatus == 'disconnected' || 
                        newCoachApproval == 'rejected' || newStaffApproval == 'rejected';
      
      // Check if data actually changed to prevent unnecessary rebuilds (blinking)
      final currentStatus = (_remoteCoachRequest?['status']?.toString() ?? '').toLowerCase().trim();
      final currentCoachApproval = (_remoteCoachRequest?['coach_approval']?.toString() ?? '').toLowerCase().trim();
      final currentStaffApproval = (_remoteCoachRequest?['staff_approval']?.toString() ?? '').toLowerCase().trim();
      
      final statusChanged = currentStatus != newStatus || 
                           currentCoachApproval != newCoachApproval || 
                           currentStaffApproval != newStaffApproval;
      
      // If rejected/disconnected and not fully approved before, clear state
      // Check if it was fully approved by looking at the new request data
      final wasFullyApproved = newCoachApproval == 'approved' && newStaffApproval == 'approved';
      if (isRejected && !wasFullyApproved) {
        if (!mounted) return;
        setState(() {
          _remoteCoachRequest = {
            'coach_approval': 'none',
            'staff_approval': 'none', 
            'status': 'none',
            'coach_name': null,
            'coach_id': null,
            'requested_at': null,
            'expires_at': null,
            'remaining_sessions': null,
            'rate_type': null
          };
          selectedCoachId = null;
          selectedCoachName = null;
          coachRequestStatus = 'none';
          requestDate = null;
          _previousCoachApproval = null;
          _previousStaffApproval = null;
          _paymentModalShown = false;
          _loadingCoachRequest = false;
        });
        // Stop polling since request is rejected/cancelled
        _statusPollingTimer?.cancel();
        _statusPollingTimer = null;
        return;
      }
      
      // Only update state if data actually changed (prevents blinking)
      if (!statusChanged && _remoteCoachRequest != null) {
        if (!mounted) return;
        setState(() {
          _loadingCoachRequest = false;
        });
        return;
      }
      
      setState(() {
        _remoteCoachRequest = newRequest;
        print('🔍 Set _remoteCoachRequest to: $_remoteCoachRequest');
        
        if (_remoteCoachRequest != null) {
          // Real coach data exists
          final coachIdValue = _remoteCoachRequest?['coach_id'];
          selectedCoachId = coachIdValue is int 
              ? coachIdValue 
              : int.tryParse(coachIdValue?.toString() ?? '0');
          selectedCoachName = _remoteCoachRequest?['coach_name']?.toString();
          coachRequestStatus = (_remoteCoachRequest?['status'] ?? 'pending').toString();
          requestDate = _remoteCoachRequest?['requested_at']?.toString();
          
          // Check for newly approved coach subscription
          final currentCoachApproval = _remoteCoachRequest?['coach_approval']?.toString() ?? 'none';
          final currentStaffApproval = _remoteCoachRequest?['staff_approval']?.toString() ?? 'none';
          
          // If both approvals changed from non-approved to approved
          if (_previousCoachApproval != null && _previousStaffApproval != null) {
            final wasPending = (_previousCoachApproval != 'approved' || _previousStaffApproval != 'approved');
            final isNowApproved = (currentCoachApproval == 'approved' && currentStaffApproval == 'approved');
            
            if (wasPending && isNowApproved) {
              // Show success modal
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showCoachSubscriptionSuccessModal();
              });
            }
          }
          
          // Check for status changes that require showing modals
          // Check if coach just got approved (coach approved but staff not yet)
          // Only show modal if:
          // 1. Coach is approved but staff is not
          // 2. Coach was NOT approved before (this is a new approval)
          // 3. Modal hasn't been shown yet for this approval state
          if (currentCoachApproval == 'approved' && 
              currentStaffApproval != 'approved' && 
              currentStaffApproval != 'rejected') {
            // Check if this is a new approval (coach was not approved before)
            // OR if this is the first time loading (previous approval is null)
            final wasCoachNotApproved = _previousCoachApproval == null || _previousCoachApproval != 'approved';
            
            if (wasCoachNotApproved && !_paymentModalShown) {
              // Coach just got approved - show payment modal only once
              _paymentModalShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showPaymentRequiredModal();
              });
            }
          } else {
            // If status changed away from "coach approved, staff pending", reset modal flag
            // This allows modal to show again if status goes back to that state
            if (_previousCoachApproval == 'approved' && 
                _previousStaffApproval != 'approved' &&
                currentCoachApproval != 'approved') {
              _paymentModalShown = false;
            }
          }
          
          // Update previous approval statuses
          _previousCoachApproval = currentCoachApproval;
          _previousStaffApproval = currentStaffApproval;
          
          // Check if coach relationship has expired
          _checkCoachRelationshipExpiration();
          
          // Restart polling if needed (in case it was stopped) and there's a pending request
          if (_hasPendingRequest() && (_statusPollingTimer == null || !_statusPollingTimer!.isActive)) {
            _startStatusPolling();
          }
          
          print('🔍 Parsed data - Coach ID: $selectedCoachId, Name: $selectedCoachName, Status: $coachRequestStatus');
        } else {
          // No coach assigned - clear state
          print('🔍 No coach assigned - clearing state');
          final wasNull = _remoteCoachRequest == null;
          
          // Only update if state actually changed (prevents blinking)
          if (!wasNull) {
            _remoteCoachRequest = {
              'coach_approval': 'none',
              'staff_approval': 'none', 
              'status': 'none',
              'coach_name': null,
              'coach_id': null,
              'requested_at': null,
              'expires_at': null,
              'remaining_sessions': null,
              'rate_type': null
            };
            selectedCoachId = null;
            selectedCoachName = null;
            coachRequestStatus = 'none';
            requestDate = null;
            
            // Reset previous approval statuses
            _previousCoachApproval = null;
            _previousStaffApproval = null;
            
            print('🔍 Set fallback data - Status: $coachRequestStatus');
          }
        }
        _loadingCoachRequest = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingCoachRequest = false; });
    }
  }

  Future<void> _saveCoachRequestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coach_request_status', coachRequestStatus);
    if (selectedCoachId != null) {
      await prefs.setInt('selected_coach_id', selectedCoachId!);
    }
    if (selectedCoachName != null) {
      await prefs.setString('selected_coach_name', selectedCoachName!);
    }
    if (requestDate != null) {
      await prefs.setString('request_date', requestDate!);
    }
  }

  List<CoachModel> get filteredCoaches {
    if (coaches.isEmpty) return [];
    
    List<CoachModel> filtered = List.from(coaches);
    
    // Apply specialty filter
    if (selectedFilter != 'All' && selectedFilter != 'Available' && 
        selectedFilter != 'Fewest Clients' && selectedFilter != 'Most Clients' &&
        selectedFilter != 'Highest Rated' && selectedFilter != 'Lowest Rated') {
      filtered = filtered.where((c) => c.specialty == selectedFilter).toList();
    }
    
    // Apply availability filter
    if (selectedFilter == 'Available') {
      filtered = filtered.where((c) => c.isAvailable).toList();
    }
    
    // Apply client count filters
    if (selectedFilter == 'Fewest Clients') {
      filtered.sort((a, b) => a.totalClients.compareTo(b.totalClients));
    } else if (selectedFilter == 'Most Clients') {
      filtered.sort((a, b) => b.totalClients.compareTo(a.totalClients));
    }
    
    // Apply rating filters
    if (selectedFilter == 'Highest Rated') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (selectedFilter == 'Lowest Rated') {
      filtered.sort((a, b) => a.rating.compareTo(b.rating));
    }
    
    return filtered;
  }

  List<String> get filterOptions {
    if (coaches.isEmpty) return ['All'];
    final specialties = coaches.map((c) => c.specialty ?? 'General').toSet().toList();
    return [
      'All', 
      'Available',
      'Fewest Clients',
      'Most Clients',
      'Highest Rated',
      'Lowest Rated',
      ...specialties
    ];
  }
  
  // Get suggested coaches (lowest client count, available, sorted by rating)
  List<CoachModel> get suggestedCoaches {
    if (coaches.isEmpty) return [];
    
    // Filter available coaches only
    List<CoachModel> available = coaches.where((c) => c.isAvailable).toList();
    
    if (available.isEmpty) return [];
    
    // Sort by client count (ascending), then by rating (descending)
    available.sort((a, b) {
      final clientCompare = a.totalClients.compareTo(b.totalClients);
      if (clientCompare != 0) return clientCompare;
      return b.rating.compareTo(a.rating);
    });
    
    // Return top 3 coaches with lowest client count
    return available.take(3).toList();
  }

  bool _hasActiveCoach() {
    try {
      if (_remoteCoachRequest == null) {
        print('🔍 _remoteCoachRequest is null - no active coach');
        return false;
      }
      
      // Safe data extraction with comprehensive null checks
      final coachApproval = _remoteCoachRequest?['coach_approval']?.toString() ?? 'none';
      final staffApproval = _remoteCoachRequest?['staff_approval']?.toString() ?? 'none';
      final status = _remoteCoachRequest?['status']?.toString() ?? 'none';
      
      print('🔍 Coach approval: $coachApproval, Staff approval: $staffApproval, Status: $status');
      
      // Check if user has an active coach (both coach and staff approved AND not expired)
      final isApproved = coachApproval == 'approved' && staffApproval == 'approved';
      final isExpired = status == 'expired' || status == 'ended' || status == 'completed';
      final isActive = isApproved && !isExpired;
      
      print('🔍 Has active coach: $isActive (approved: $isApproved, expired: $isExpired)');
      
      return isActive;
    } catch (e) {
      print('❌ Error checking active coach: $e');
      print('❌ _remoteCoachRequest data: $_remoteCoachRequest');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: SafeArea(
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                  ),
                )
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Error Loading Coaches',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadCoaches,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4ECDC4),
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMainContent(),
                      ),
                    ),
        ),
      );
    } catch (e) {
      print('❌ PersonalTrainingPage: Build error: $e');
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                SizedBox(height: 20),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please try again later',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      errorMessage = null;
                    });
                    _loadCoaches();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMainContent() {
    try {
      List<Widget> slivers = [];
      
      try {
        slivers.add(_buildSliverAppBar());
        print('✅ _buildSliverAppBar() completed');
      } catch (e) {
        print('❌ Error in _buildSliverAppBar(): $e');
        return _buildErrorContent('Error building app bar');
      }
      
      try {
        slivers.add(_buildCoachStatusSection());
        print('✅ _buildCoachStatusSection() completed');
      } catch (e) {
        print('❌ Error in _buildCoachStatusSection(): $e');
        // Don't show error for coach status - just show "no coach assigned"
        slivers.add(SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Color(0xFF4ECDC4), size: 20),
                SizedBox(width: 12),
                Text(
                  'No coach assigned yet',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ));
      }

      // Add rating section if user has an expired coach relationship AND it was fully approved
      if (selectedCoachId != null && selectedCoachName != null && _isCoachRelationshipExpired && _wasCoachConnectionApproved()) {
        try {
          slivers.add(_buildCoachRatingSection());
          print('✅ _buildCoachRatingSection() completed');
        } catch (e) {
          print('❌ Error in _buildCoachRatingSection(): $e');
        }
      }

      // Add expired coach status section if relationship is expired AND it was fully approved
      if (selectedCoachId != null && selectedCoachName != null && _isCoachRelationshipExpired && _wasCoachConnectionApproved()) {
        try {
          slivers.add(_buildExpiredCoachStatusSection());
          print('✅ _buildExpiredCoachStatusSection() completed');
        } catch (e) {
          print('❌ Error in _buildExpiredCoachStatusSection(): $e');
        }
      }

      if (widget.currentUser != null && !widget.currentUser!.isPremium) {
        try {
          slivers.add(_buildUpgradeSection());
          print('✅ _buildUpgradeSection() completed');
        } catch (e) {
          print('❌ Error in _buildUpgradeSection(): $e');
          return _buildErrorContent('Error building upgrade section');
        }
      }
      
      // Hide about section and other content when there's a pending request
      if (!_hasPendingRequest()) {
        try {
          slivers.add(_buildAboutSection());
          print('✅ _buildAboutSection() completed');
        } catch (e) {
          print('❌ Error in _buildAboutSection(): $e');
          return _buildErrorContent('Error building about section');
        }
      }
      
      // Only show coaches if:
      // 1. User is premium
      // 2. No active coach assigned
      // 3. No pending request (can be cancelled)
      if (widget.currentUser != null && widget.currentUser!.isPremium && !_hasActiveCoach() && !_hasPendingRequest()) {
        // Add suggested coaches section if available
        if (suggestedCoaches.isNotEmpty && selectedFilter == 'All') {
          try {
            slivers.add(_buildSuggestedCoachesSection());
            print('✅ _buildSuggestedCoachesSection() completed');
          } catch (e) {
            print('❌ Error in _buildSuggestedCoachesSection(): $e');
          }
        }
        
        try {
          slivers.add(_buildFilterSection());
          print('✅ _buildFilterSection() completed');
        } catch (e) {
          print('❌ Error in _buildFilterSection(): $e');
          return _buildErrorContent('Error building filter section');
        }
        
        if (coaches.isEmpty && !isLoading) {
          try {
            slivers.add(_buildEmptyCoachesSection());
            print('✅ _buildEmptyCoachesSection() completed');
          } catch (e) {
            print('❌ Error in _buildEmptyCoachesSection(): $e');
            return _buildErrorContent('Error building empty coaches section');
          }
        } else {
          try {
            slivers.add(_buildCoachesSection());
            print('✅ _buildCoachesSection() completed');
          } catch (e) {
            print('❌ Error in _buildCoachesSection(): $e');
            return _buildErrorContent('Error building coaches section');
          }
        }
      }
      
      if (widget.currentUser != null && widget.currentUser!.isPremium && _hasActiveCoach() && !_isCoachRelationshipExpired) {
        try {
          slivers.add(_buildActiveCoachSection());
          print('✅ _buildActiveCoachSection() completed');
        } catch (e) {
          print('❌ Error in _buildActiveCoachSection(): $e');
          return _buildErrorContent('Error building active coach section');
        }
      }

      return CustomScrollView(
        slivers: slivers,
      );
    } catch (e) {
      print('❌ PersonalTrainingPage: _buildMainContent general error: $e');
      return _buildErrorContent('General content building error');
    }
  }

  Widget _buildErrorContent(String errorType) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 20),
          Text(
            'Error: $errorType',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Please try refreshing the page',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _loadCoaches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCoachesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey[400],
              size: 64,
            ),
            SizedBox(height: 20),
            Text(
              'No Coaches Available',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'We couldn\'t find any coaches matching your criteria. Please try again later.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCoaches,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackContent() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.fitness_center,
              color: Color(0xFF4ECDC4),
              size: 64,
            ),
            SizedBox(height: 20),
            Text(
              'Personal Coaching',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Connect with our certified coaches to achieve your fitness goals.',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            if (widget.currentUser == null)
              Text(
                'Please log in to access personal coaching features.',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              )
            else if (!widget.currentUser!.isPremium)
              Text(
                'Upgrade to premium to access personal coaching.',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Loading your personal coaching options...',
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


  SliverToBoxAdapter _buildCoachStatusSection() {
    try {
      // Decide what to show based on remote data
      if (_loadingCoachRequest) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                ),
              ),
              SizedBox(width: 12),
              Text('Checking coach assignment...', style: GoogleFonts.poppins(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_remoteCoachRequest == null || _remoteCoachRequest?['status'] == 'none') {
      // Return empty - don't show status card
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Safe data extraction with comprehensive null checks
    final coachApproval = _remoteCoachRequest?['coach_approval']?.toString() ?? '';
    final staffApproval = _remoteCoachRequest?['staff_approval']?.toString() ?? '';
    final status = (_remoteCoachRequest?['status']?.toString() ?? '').toLowerCase().trim();
    final coachName = _remoteCoachRequest?['coach_name']?.toString() ?? 'Coach';
    final requestedAt = _remoteCoachRequest?['requested_at']?.toString() ?? '';
    final rateType = _remoteCoachRequest?['rate_type']?.toString() ?? 'hourly';
    final remainingSessions = _remoteCoachRequest?['remaining_sessions'];
    final expiresAt = _remoteCoachRequest?['expires_at']?.toString();

    // Hide card if rejected, disconnected, or cancelled (unless it was fully approved before)
    final bool wasFullyApproved = coachApproval == 'approved' && staffApproval == 'approved';
    final isRejected = status == 'rejected' || status == 'disconnected' || 
                       coachApproval.toLowerCase() == 'rejected' || 
                       staffApproval.toLowerCase() == 'rejected';
    
    // Don't show card if rejected/disconnected unless it was fully approved before (then show ended message)
    if (isRejected && !wasFullyApproved) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    String title;
    String subtitle;
    Color color;
    IconData icon;
    
    if (status == 'rejected' || coachApproval.toLowerCase() == 'rejected') {
      title = 'Request Rejected';
      subtitle = 'Your request with $coachName was rejected.';
      color = Colors.red;
      icon = Icons.cancel;
    } else if ((status == 'expired' || status == 'ended' || status == 'completed') && wasFullyApproved) {
      title = 'Coaching Session Ended';
      subtitle = 'Your coaching with $coachName has concluded.';
      color = Colors.orange;
      icon = Icons.schedule;
    } else if (coachApproval == 'approved' && staffApproval == 'approved') {
      title = 'Coach Assigned';
      String sessionInfo = '';
      if (rateType == 'package' && remainingSessions != null) {
        sessionInfo = '\nRemaining sessions: $remainingSessions';
      } else if (rateType == 'monthly' && expiresAt != null) {
        sessionInfo = '\nExpires: $expiresAt';
      } else if (rateType == 'hourly' && expiresAt != null) {
        sessionInfo = '\nExpires: $expiresAt';
      }
      subtitle = 'You are assigned to $coachName.$sessionInfo';
      color = Color(0xFF4ECDC4);
      icon = Icons.verified;
    } else if (coachApproval == 'approved' && staffApproval != 'approved') {
      title = 'Awaiting Staff Approval';
      subtitle = 'Coach approved. Please wait for staff confirmation.';
      color = Color(0xFFFFD700);
      icon = Icons.hourglass_top;
      
      // Don't show modal here - it's handled in _loadCoachRequestStatus
      // to ensure it only shows once when status changes
    } else {
      title = 'Awaiting Coach Approval';
      subtitle = 'Request sent to $coachName on ${requestedAt.isNotEmpty ? requestedAt : '—'}';
      color = Color(0xFFFFD700);
      icon = Icons.hourglass_top;
    }

    // Check if cancellation is allowed - use same logic as _hasPendingRequest
    final canCancel = _hasPendingRequest();
    final isPending = _hasPendingRequest();

    // If pending, show a better card with payment info
    if (isPending) {
      final hourlyRate = _remoteCoachRequest?['hourly_rate'] ?? 0;
      final monthlyRate = _remoteCoachRequest?['monthly_rate'] ?? 0;
      final sessionPackageRate = _remoteCoachRequest?['session_package_rate'] ?? 0;
      final sessionPackageCount = _remoteCoachRequest?['session_package_count'] ?? 0;
      
      String rateText = '';
      double amount = 0;
      if (rateType == 'monthly' && monthlyRate > 0) {
        rateText = 'Monthly Rate';
        amount = (monthlyRate is int) ? monthlyRate.toDouble() : (monthlyRate is double ? monthlyRate : 0);
      } else if (rateType == 'package' && sessionPackageRate > 0 && sessionPackageCount > 0) {
        rateText = 'Session Package';
        amount = (sessionPackageRate is int) ? sessionPackageRate.toDouble() : (sessionPackageRate is double ? sessionPackageRate : 0);
      } else if (rateType == 'hourly' && hourlyRate > 0) {
        rateText = 'Hourly Rate';
        amount = (hourlyRate is int) ? hourlyRate.toDouble() : (hourlyRate is double ? hourlyRate : 0);
      }

      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFD700).withOpacity(0.1),
                Color(0xFFFFA500).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFFFFD700), width: 2),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.hourglass_top, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canCancel)
                        IconButton(
                          onPressed: _cancelCoachRequest,
                          icon: Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                          tooltip: 'Cancel Request',
                        ),
                      IconButton(
                        onPressed: _loadCoachRequestStatus,
                        icon: Icon(Icons.refresh, color: Color(0xFFFFD700), size: 20),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ],
              ),
              if (amount > 0) ...[
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rateText,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[300],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₱${amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Color(0xFFFFD700),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (rateType == 'package' && sessionPackageCount > 0) ...[
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sessions',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$sessionPackageCount sessions',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[300],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          coachApproval == 'approved' && staffApproval != 'approved'
                              ? 'Once staff approves, please visit the front desk to complete payment.'
                              : 'Once approved, you will be notified to complete payment at the front desk.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            fontSize: 12,
                            height: 1.4,
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
      );
    }

    // For non-pending statuses, show the simple card
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show cancel button if cancellation is allowed
                if (canCancel)
                  IconButton(
                    onPressed: _cancelCoachRequest,
                    icon: Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                    tooltip: 'Cancel Request',
                  ),
                IconButton(
                  onPressed: _loadCoachRequestStatus,
                  icon: Icon(Icons.refresh, color: color, size: 18),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    } catch (e) {
      print('❌ Error in _buildCoachStatusSection details: $e');
      // Return a safe fallback widget - show "no coach assigned" instead of error
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: Color(0xFF4ECDC4), size: 20),
              SizedBox(width: 12),
              Text(
                'No coach assigned yet',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 56, right: 80, bottom: 16),
        title: Text(
          'Personal Coaching',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF4ECDC4).withOpacity(0.3),
                Color(0xFF0F0F0F),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700).withOpacity(0.1), Color(0xFFFFA500).withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFFFD700).withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFD700).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 32),
            ),
            SizedBox(height: 16),
            Text(
              'Upgrade to Premium',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unlock access to our expert personal coaches and get personalized guidance for your fitness journey.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ManageSubscriptionsPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: Color(0xFF4ECDC4), size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'About Personal Coaching',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildBenefitItem(Icons.person, 'One-on-one personalized guidance'),
            _buildBenefitItem(Icons.fitness_center, 'Customized workout plans'),
            _buildBenefitItem(Icons.trending_up, 'Progress tracking & goal setting'),
            _buildBenefitItem(Icons.schedule, 'Flexible scheduling options'),
            _buildBenefitItem(Icons.security, 'Proper form & injury prevention'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF4ECDC4), size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(CoachModel coach) {
    List<Widget> pricingOptions = [];
    
    // Session rate (always available)
    pricingOptions.add(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, color: Color(0xFF4ECDC4), size: 14),
            SizedBox(width: 4),
            Text(
              '₱${coach.sessionRate.toInt()}/session',
              style: GoogleFonts.poppins(
                color: Color(0xFF4ECDC4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    // Monthly rate (if available)
    if (coach.monthlyRate != null && coach.monthlyRate! > 0) {
      pricingOptions.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, color: Color(0xFF4ECDC4), size: 14),
              SizedBox(width: 4),
              Text(
                '₱${coach.monthlyRate!.toInt()}/mo',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Session package (if available)
    if (coach.sessionPackageRate != null && coach.sessionPackageCount != null && 
        coach.sessionPackageRate! > 0 && coach.sessionPackageCount! > 0) {
      pricingOptions.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center, color: Color(0xFF4ECDC4), size: 14),
              SizedBox(width: 4),
              Text(
                '₱${coach.sessionPackageRate!.toInt()}/${coach.sessionPackageCount} sessions',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: pricingOptions,
    );
  }

  Widget _buildRateSelection({
    required CoachModel coach,
    required String selectedRateType,
    required double selectedRate,
    required int? selectedSessionCount,
    required Function(String, double, int?) onRateChanged,
  }) {
    List<Widget> rateOptions = [];

    // Session rate option
    rateOptions.add(
      _buildRateOption(
        title: 'Session Rate',
        subtitle: 'Pay per session',
        price: '₱${coach.sessionRate.toInt()}/session',
        icon: Icons.fitness_center,
        isSelected: selectedRateType == 'hourly',
        onTap: () => onRateChanged('hourly', coach.sessionRate, null),
      ),
    );

    // Monthly rate option (if available)
    if (coach.monthlyRate != null && coach.monthlyRate! > 0) {
      rateOptions.add(
        _buildRateOption(
          title: 'Monthly Package',
          subtitle: 'Unlimited sessions for 1 month',
          price: '₱${coach.monthlyRate!.toInt()}/mo',
          icon: Icons.calendar_month,
          isSelected: selectedRateType == 'monthly',
          onTap: () => onRateChanged('monthly', coach.monthlyRate!, null),
        ),
      );
    }

    // Session package option (if available)
    if (coach.sessionPackageRate != null && coach.sessionPackageCount != null && 
        coach.sessionPackageRate! > 0 && coach.sessionPackageCount! > 0) {
      rateOptions.add(
        _buildRateOption(
          title: 'Session Package',
          subtitle: '${coach.sessionPackageCount} sessions',
          price: '₱${coach.sessionPackageRate!.toInt()}/${coach.sessionPackageCount} sessions',
          icon: Icons.fitness_center,
          isSelected: selectedRateType == 'package',
          onTap: () => onRateChanged('package', coach.sessionPackageRate!, coach.sessionPackageCount),
        ),
      );
    }

    return Column(
      children: rateOptions,
    );
  }

  Widget _buildRateOption({
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4ECDC4).withOpacity(0.1) : Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[700]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: GoogleFonts.poppins(
                  color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF4ECDC4),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedCoachesSection() {
    final suggested = suggestedCoaches;
    if (suggested.isEmpty) return SliverToBoxAdapter(child: SizedBox.shrink());
    
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb, color: Color(0xFF4ECDC4), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Suggested Coaches',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Coaches with the most availability for personalized attention',
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 12),
            ...suggested.map((coach) => Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF4ECDC4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person, color: Color(0xFF4ECDC4), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.grey[400], size: 14),
                            SizedBox(width: 4),
                            Text(
                              '${coach.totalClients} clients',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 12),
                            Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                            SizedBox(width: 4),
                            Text(
                              '${coach.rating.toStringAsFixed(1)}',
                              style: GoogleFonts.poppins(
                                color: Color(0xFF4ECDC4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showHireDialog(coach),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Hire',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Find Your Coach',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () async {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4ECDC4),
                        ),
                      ),
                    );
                    
                    await _refreshCoachRatings();
                    Navigator.pop(context); // Close loading dialog
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Coach ratings updated!'),
                        backgroundColor: Color(0xFF4ECDC4),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.refresh, color: Color(0xFF4ECDC4)),
                  tooltip: 'Refresh ratings',
                ),
              ],
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterOptions.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Container(
                    margin: EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                      backgroundColor: Color(0xFF2A2A2A),
                      selectedColor: Color(0xFF4ECDC4),
                      checkmarkColor: Colors.black,
                      side: BorderSide(
                        color: isSelected ? Color(0xFF4ECDC4) : Colors.grey[700]!,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachesSection() {
    if (isLoading) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                style: GoogleFonts.poppins(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCoaches,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                ),
                child: Text('Retry', style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      );
    }

    final displayCoaches = filteredCoaches;

    if (displayCoaches.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.search_off, color: Colors.grey[400], size: 48),
              SizedBox(height: 16),
              Text(
                'No coaches found',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your filters',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final coach = displayCoaches[index];
            return _buildCoachCard(coach);
          },
          childCount: displayCoaches.length,
        ),
      ),
    );
  }

  Widget _buildCoachCard(CoachModel coach) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF4ECDC4),
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              coach.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!coach.isAvailable)
                            GestureDetector(
                              onTap: () => _showUnavailableReasonDialog(),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Unavailable',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        coach.specialty,
                        style: GoogleFonts.poppins(
                          color: Color(0xFF4ECDC4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4ECDC4),
                                  ),
                                ),
                              );
                              
                              try {
                                final ratingData = await CoachRatingService.getCoachRatings(coach.id);
                                Navigator.pop(context); // Close loading dialog
                                
                                if (ratingData['success'] == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CoachFeedbackViewer(
                                        coachId: coach.id,
                                        coachName: coach.name,
                                        currentRating: _safeParseDouble(ratingData['average_rating']) ?? 0.0,
                                        totalReviews: _safeParseInt(ratingData['total_reviews']) ?? 0,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to load reviews'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                Navigator.pop(context); // Close loading dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error loading reviews: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '${coach.rating}',
                                  style: GoogleFonts.poppins(
                                    color: Color(0xFF4ECDC4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, color: Color(0xFF4ECDC4), size: 12),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.people, color: Colors.grey[400], size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${coach.totalClients} clients',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              coach.bio,
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 13,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                SizedBox(width: 4),
                Text(
                  '${coach.experience} experience',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildPricingSection(coach),
            if (coach.certifications.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: coach.certifications.map((cert) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cert,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[300],
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_hasPendingRequest())
                    ? null
                    : (coach.isAvailable && !_hasActiveCoach()) 
                        ? () => _showHireDialog(coach) 
                        : (!coach.isAvailable ? () => _showUnavailableReasonDialog() : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_hasPendingRequest() || !coach.isAvailable || _hasActiveCoach()) 
                      ? Colors.grey[700] 
                      : Color(0xFF4ECDC4),
                  foregroundColor: (_hasPendingRequest() || !coach.isAvailable || _hasActiveCoach()) 
                      ? Colors.grey[400] 
                      : Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _hasPendingRequest() 
                      ? 'Pending Request - Cancel First'
                      : (_hasActiveCoach() 
                          ? 'Already Have Coach' 
                          : (coach.isAvailable ? 'Hire Coach' : 'Currently Unavailable')),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnavailableReasonDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: Offset(0, 15),
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
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Coach Unavailable',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
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
                child: Text(
                  'This coach is currently not accepting new clients',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[200],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  bool _hasPendingRequest() {
    if (_remoteCoachRequest == null) {
      print('🔍 _hasPendingRequest: _remoteCoachRequest is null, returning false');
      return false;
    }
    
    final coachApproval = (_remoteCoachRequest?['coach_approval']?.toString() ?? '').toLowerCase().trim();
    final staffApproval = (_remoteCoachRequest?['staff_approval']?.toString() ?? '').toLowerCase().trim();
    final status = (_remoteCoachRequest?['status']?.toString() ?? '').toLowerCase().trim();
    
    print('🔍 _hasPendingRequest: coachApproval="$coachApproval", staffApproval="$staffApproval", status="$status"');
    
    // If status is 'none', 'disconnected', 'rejected', or 'completed', it's not pending
    if (status == 'none' || status == 'disconnected' || status == 'rejected' || status == 'completed') {
      print('🔍 _hasPendingRequest: Status is $status, returning false');
      return false;
    }
    
    // If approval statuses are 'none', it's not pending
    if (coachApproval == 'none' && staffApproval == 'none') {
      print('🔍 _hasPendingRequest: Both approvals are none, returning false');
      return false;
    }
    
    // If both are fully approved, it's not pending (can't cancel)
    if (coachApproval == 'approved' && staffApproval == 'approved') {
      print('🔍 _hasPendingRequest: Both approved, returning false');
      return false;
    }
    
    // If there's a request object, it means there's a request
    // It's pending if coach hasn't approved OR (coach approved but staff hasn't)
    // Note: We allow cancellation even if status is "expired" as long as approvals are still pending
    final coachNotApproved = coachApproval.isEmpty || coachApproval == 'pending' || (coachApproval != 'approved' && coachApproval != 'none');
    final coachApprovedButStaffNot = coachApproval == 'approved' && 
                                     staffApproval != 'approved' && 
                                     staffApproval != 'rejected' &&
                                     staffApproval != 'none' &&
                                     (staffApproval.isEmpty || staffApproval == 'pending');
    
    final isPending = coachNotApproved || coachApprovedButStaffNot;
    
    print('🔍 _hasPendingRequest: coachNotApproved=$coachNotApproved, coachApprovedButStaffNot=$coachApprovedButStaffNot, isPending=$isPending');
    return isPending;
  }

  void _showHireDialog(CoachModel coach) {
    // Check if there's a pending request
    if (_hasPendingRequest()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You already have a pending coach request. Please cancel it first before requesting a new coach.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    String selectedRateType = 'hourly';
    double selectedRate = coach.sessionRate;
    int? selectedSessionCount;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.fitness_center, color: Color(0xFF4ECDC4), size: 32),
                ),
                SizedBox(height: 16),
                Text(
                  'Choose Coaching Package',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select your preferred coaching package with ${coach.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                _buildRateSelection(
                  coach: coach,
                  selectedRateType: selectedRateType,
                  selectedRate: selectedRate,
                  selectedSessionCount: selectedSessionCount,
                  onRateChanged: (rateType, rate, sessionCount) {
                    setState(() {
                      selectedRateType = rateType;
                      selectedRate = rate;
                      selectedSessionCount = sessionCount;
                    });
                  },
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(color: Colors.grey[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _sendCoachRequest(
                          coach, 
                          selectedRateType, 
                          selectedRate, 
                          selectedSessionCount
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Hire Coach',
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
      ),
    );
  }

  Future<void> _sendCoachRequest(
    CoachModel coach, 
    String rateType, 
    double rate, 
    int? sessionCount
  ) async {
    Navigator.pop(context);
    
    if (widget.currentUser == null) return;

    // Check if there's already a pending request using the same logic as _hasPendingRequest()
    if (_hasPendingRequest()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You already have a pending coach request. Please cancel it first before requesting a new coach.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      ),
    );

    try {
      final result = await CoachService.sendCoachRequest(
        userId: widget.currentUser!.id,
        coachId: coach.id,
        rateType: rateType,
        rate: rate,
        sessionCount: sessionCount,
      );

      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        // Reload coach request status to get the latest from API
        await _loadCoachRequestStatus();
        
        setState(() {
          coachRequestStatus = 'pending';
          selectedCoachId = coach.id;
          selectedCoachName = coach.name;
          requestDate = DateTime.now().toString().split(' ')[0];
        });
        await _saveCoachRequestStatus();

        String packageText = '';
        switch (rateType) {
          case 'hourly':
            packageText = 'Session rate (₱${rate.toInt()}/session)';
            break;
          case 'monthly':
            packageText = 'Monthly package (₱${rate.toInt()}/mo)';
            break;
          case 'package':
            packageText = 'Session package (₱${rate.toInt()}/${sessionCount} sessions)';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coach request sent successfully!\nPackage: $packageText\nVisit the front desk to complete payment.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Check if it's a premium membership error
        String errorMessage = result['message'] ?? 'Failed to send coach request. Please try again.';
        
        if (errorMessage.toLowerCase().contains('premium membership required')) {
          _showPremiumMembershipDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error sending request: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _cancelCoachRequest() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text(
          'Cancel Coach Request',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your coach request? This action cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      ),
    );

    try {
      int? userId = widget.currentUser?.id;
      if (userId == null) {
        userId = AuthService.getCurrentUserId();
      }
      if (userId == null) {
        Navigator.pop(context); // Close loading
        return;
      }

      final result = await CoachService.cancelCoachRequest(userId);
      Navigator.pop(context); // Close loading

      if (result['success'] == true) {
        // Stop polling first since request is cancelled
        _statusPollingTimer?.cancel();
        _statusPollingTimer = null;
        
        // Reset state immediately to show normal view
        setState(() {
          // Set to 'none' state explicitly so _hasPendingRequest() returns false
          _remoteCoachRequest = {
            'coach_approval': 'none',
            'staff_approval': 'none', 
            'status': 'none',
            'coach_name': null,
            'coach_id': null,
            'requested_at': null,
            'expires_at': null,
            'remaining_sessions': null,
            'rate_type': null
          };
          selectedCoachId = null;
          selectedCoachName = null;
          coachRequestStatus = 'none';
          requestDate = null;
          _previousCoachApproval = null;
          _previousStaffApproval = null;
          _paymentModalShown = false;
        });
        
        // Reload coach request status and coaches list to show selection again
        await Future.wait([
          _loadCoachRequestStatus(),
          _loadCoaches(),
        ]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coach request cancelled successfully.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to cancel request. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error cancelling request: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActiveCoachSection() {
    if (_remoteCoachRequest == null) {
      return SliverToBoxAdapter(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'No active coach session',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    final coachName = (_remoteCoachRequest!['coach_name'] ?? 'Coach').toString();
    final rateType = (_remoteCoachRequest!['rate_type'] ?? 'hourly').toString();
    final remainingSessions = _remoteCoachRequest!['remaining_sessions'];
    final expiresAt = _remoteCoachRequest!['expires_at'];
    
    String sessionInfo = '';
    if (rateType == 'package' && remainingSessions != null) {
      sessionInfo = 'Remaining sessions: $remainingSessions';
    } else if (rateType == 'monthly' && expiresAt != null) {
      sessionInfo = 'Expires: $expiresAt';
    } else if (rateType == 'hourly' && expiresAt != null) {
      sessionInfo = 'Expires: $expiresAt';
    }
    
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4ECDC4).withOpacity(0.1), Color(0xFF2A2A2A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4ECDC4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified, color: Color(0xFF4ECDC4), size: 32),
            ),
            SizedBox(height: 16),
            Text(
              'Active Coach Connection',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You are currently assigned to $coachName',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (sessionInfo.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  sessionInfo,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Color(0xFF4ECDC4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPremiumMembershipDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFD700).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, color: Color(0xFFFFD700), size: 32),
              ),
              SizedBox(height: 16),
              Text(
                'Premium Membership Required',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Personal coaching with coaches is a premium feature. Upgrade your membership to access this service.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageSubscriptionsPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Upgrade Now',
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

  bool _wasCoachConnectionApproved() {
    if (_remoteCoachRequest == null) {
      return false;
    }
    
    final coachApproval = _remoteCoachRequest?['coach_approval']?.toString() ?? 'none';
    final staffApproval = _remoteCoachRequest?['staff_approval']?.toString() ?? 'none';
    
    // Check if both coach and staff have approved the connection
    final wasApproved = coachApproval == 'approved' && staffApproval == 'approved';
    
    print('🔍 Checking if coach connection was approved - Coach: $coachApproval, Staff: $staffApproval, Was approved: $wasApproved');
    
    return wasApproved;
  }

  void _checkCoachRelationshipExpiration() {
    if (_remoteCoachRequest == null) {
      _isCoachRelationshipExpired = false;
      return;
    }

    // Check various expiration conditions
    final status = _remoteCoachRequest?['status']?.toString() ?? '';
    final expiresAt = _remoteCoachRequest?['expires_at']?.toString();
    final remainingSessions = _remoteCoachRequest?['remaining_sessions'];
    final rateType = _remoteCoachRequest?['rate_type']?.toString();

    print('🔍 Checking expiration - Status: $status, Remaining: $remainingSessions, RateType: $rateType');

    // Check if relationship is explicitly marked as expired/ended
    if (status == 'expired' || status == 'ended' || status == 'completed') {
      print('🔍 Relationship expired by status: $status');
      _isCoachRelationshipExpired = true;
      return;
    }

    // Check if package has expired based on date
    if (expiresAt != null) {
      try {
        final expiryDate = DateTime.parse(expiresAt);
        if (DateTime.now().isAfter(expiryDate)) {
          print('🔍 Relationship expired by date: $expiresAt');
          _isCoachRelationshipExpired = true;
          return;
        }
      } catch (e) {
        print('Error parsing expiry date: $e');
      }
    }

    // Check if session package has run out of sessions
    if (rateType == 'package' && remainingSessions != null) {
      final sessions = int.tryParse(remainingSessions.toString()) ?? 0;
      if (sessions <= 0) {
        print('🔍 Relationship expired by sessions: $sessions');
        _isCoachRelationshipExpired = true;
        return;
      }
    }

    // Additional check: If status is 'active' but we want to force expiration
    // This handles cases where database was manually updated
    if (status == 'active' && remainingSessions != null) {
      final sessions = int.tryParse(remainingSessions.toString()) ?? 0;
      // If sessions are 0 or negative, consider it expired
      if (sessions <= 0) {
        print('🔍 Relationship expired - active status but no sessions: $sessions');
        _isCoachRelationshipExpired = true;
        return;
      }
    }

    // If none of the above conditions are met, relationship is still active
    print('🔍 Relationship still active');
    _isCoachRelationshipExpired = false;
  }

  Widget _buildExpiredCoachStatusSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.schedule, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coaching Session Ended',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your coaching with $selectedCoachName has concluded',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Your coaching relationship has ended. You can now provide feedback about your coaching experience.',
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachRatingSection() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateCoachPage(
                coachId: selectedCoachId!,
                coachName: selectedCoachName!,
              ),
            ),
          );
          if (result == true) {
            // Optionally refresh the page or show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Thank you for your feedback!'),
                backgroundColor: Color(0xFF4ECDC4),
              ),
            );
          }
        },
        child: Container(
          margin: EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.star, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate Your Coach',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your coaching with $selectedCoachName has ended',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xFF4ECDC4), size: 20),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Now that your coaching has ended, please share your experience to help improve our coaching services.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentRequiredModal() {
    // Check if we already showed this modal to avoid multiple dialogs
    if (!_paymentModalShown) {
      _paymentModalShown = true;
      
      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(Icons.payment, color: Colors.white, size: 48),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Payment Required',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Your coach has approved your request!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'To complete your coach assignment, please visit the front desk to make your payment.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }
  }

  void _showCoachSubscriptionSuccessModal() {
    final rateType = _remoteCoachRequest?['rate_type']?.toString() ?? 'hourly';
    final expiresAt = _remoteCoachRequest?['expires_at']?.toString();
    final remainingSessions = _remoteCoachRequest?['remaining_sessions'];
    final coachName = selectedCoachName ?? 'your coach';
    
    String subscriptionDetails = '';
    if (rateType == 'package' && remainingSessions != null) {
      subscriptionDetails = 'Package: $remainingSessions sessions remaining';
    } else if (rateType == 'monthly' && expiresAt != null) {
      try {
        final expiryDate = DateTime.parse(expiresAt);
        final formatted = '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
        subscriptionDetails = 'Monthly subscription valid until $formatted';
      } catch (_) {
        subscriptionDetails = 'Monthly subscription active';
      }
    } else if (rateType == 'hourly' && expiresAt != null) {
      try {
        final expiryDate = DateTime.parse(expiresAt);
        final formatted = '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
        subscriptionDetails = 'Hourly rate valid until $formatted';
      } catch (_) {
        subscriptionDetails = 'Hourly rate active';
      }
    } else {
      subscriptionDetails = 'Personal coaching subscription active';
    }
    
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
                'Your personal coaching payment has been successfully processed and approved.',
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
                        Icon(Icons.person, color: Color(0xFF4ECDC4), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Coach: $coachName',
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
                        Icon(Icons.fitness_center, color: Colors.grey[400], size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subscriptionDetails,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
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
}
