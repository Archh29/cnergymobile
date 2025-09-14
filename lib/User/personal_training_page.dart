import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/user_model.dart';
import './models/coach_model.dart';
import './services/coach_service.dart';
import 'manage_subscriptions_page.dart';

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
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetchedCoaches = await CoachService.fetchCoaches();
      setState(() {
        coaches = fetchedCoaches;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load coaches: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      coachRequestStatus = prefs.getString('coach_request_status') ?? 'none';
      selectedCoachId = prefs.getInt('selected_coach_id');
      selectedCoachName = prefs.getString('selected_coach_name');
      requestDate = prefs.getString('request_date');
    });
  }

  Future<void> _loadCoachRequestStatus() async {
    try {
      setState(() { _loadingCoachRequest = true; });
      int? userId = widget.currentUser?.id;
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = int.tryParse(prefs.getString('user_id') ?? '');
      }
      if (userId == null) {
        setState(() { _loadingCoachRequest = false; });
        return;
      }
      final data = await CoachService.getUserCoachRequest(userId);
      setState(() {
        _remoteCoachRequest = data?['request'];
        if (_remoteCoachRequest != null) {
          selectedCoachId = _remoteCoachRequest!['coach_id'];
          selectedCoachName = _remoteCoachRequest!['coach_name'];
          coachRequestStatus = (_remoteCoachRequest!['status'] ?? 'pending').toString();
          requestDate = _remoteCoachRequest!['requested_at']?.toString();
        }
        _loadingCoachRequest = false;
      });
    } catch (e) {
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
    if (selectedFilter == 'All') return coaches;
    if (selectedFilter == 'Available') return coaches.where((c) => c.isAvailable).toList();
    return coaches.where((c) => c.specialty == selectedFilter).toList();
  }

  List<String> get filterOptions {
    final specialties = coaches.map((c) => c.specialty).toSet().toList();
    return ['All', 'Available', ...specialties];
  }

  bool _hasActiveCoach() {
    if (_remoteCoachRequest == null) return false;
    
    final coachApproval = (_remoteCoachRequest!['coach_approval'] ?? '').toString();
    final staffApproval = (_remoteCoachRequest!['staff_approval'] ?? '').toString();
    final status = (_remoteCoachRequest!['status'] ?? '').toString();
    
    // Check if user has an active coach (both coach and staff approved)
    return coachApproval == 'approved' && staffApproval == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                _buildCoachStatusSection(),
                if (widget.currentUser != null && !widget.currentUser!.isPremium) _buildUpgradeSection(),
                _buildAboutSection(),
                if (widget.currentUser != null && widget.currentUser!.isPremium && !_hasActiveCoach()) _buildFilterSection(),
                if (widget.currentUser != null && widget.currentUser!.isPremium && !_hasActiveCoach()) _buildCoachesSection(),
                if (widget.currentUser != null && widget.currentUser!.isPremium && _hasActiveCoach()) _buildActiveCoachSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCoachStatusSection() {
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

    if (_remoteCoachRequest == null) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final coachApproval = (_remoteCoachRequest!['coach_approval'] ?? '').toString();
    final staffApproval = (_remoteCoachRequest!['staff_approval'] ?? '').toString();
    final status = (_remoteCoachRequest!['status'] ?? '').toString();
    final coachName = (_remoteCoachRequest!['coach_name'] ?? 'Coach').toString();
    final requestedAt = (_remoteCoachRequest!['requested_at'] ?? '').toString();
    final rateType = (_remoteCoachRequest!['rate_type'] ?? 'hourly').toString();
    final remainingSessions = _remoteCoachRequest!['remaining_sessions'];
    final expiresAt = _remoteCoachRequest!['expires_at'];

    String title;
    String subtitle;
    Color color;
    IconData icon;

    if (status == 'rejected' || coachApproval == 'rejected') {
      title = 'Request Rejected';
      subtitle = 'Your request with $coachName was rejected.';
      color = Colors.red;
      icon = Icons.cancel;
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
    } else {
      title = 'Awaiting Coach Approval';
      subtitle = 'Request sent to $coachName on ${requestedAt.isNotEmpty ? requestedAt : '—'}';
      color = Color(0xFFFFD700);
      icon = Icons.hourglass_top;
    }

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
            IconButton(
              onPressed: _loadCoachRequestStatus,
              icon: Icon(Icons.refresh, color: color, size: 18),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
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
        title: Text(
          'Personal Training',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
              'Unlock access to our expert personal trainers and get personalized guidance for your fitness journey.',
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
                Text(
                  'About Personal Training',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
    
    // Hourly rate (always available)
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
              '₱${coach.hourlyRate.toInt()}/hr',
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

    // Hourly rate option
    rateOptions.add(
      _buildRateOption(
        title: 'Hourly Rate',
        subtitle: 'Pay per session',
        price: '₱${coach.hourlyRate.toInt()}/hr',
        icon: Icons.access_time,
        isSelected: selectedRateType == 'hourly',
        onTap: () => onRateChanged('hourly', coach.hourlyRate, null),
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

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Your Coach',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Busy',
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
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
                          Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${coach.rating}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
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
                onPressed: (coach.isAvailable && !_hasActiveCoach()) ? () => _showHireDialog(coach) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (coach.isAvailable && !_hasActiveCoach()) ? Color(0xFF4ECDC4) : Colors.grey[700],
                  foregroundColor: (coach.isAvailable && !_hasActiveCoach()) ? Colors.white : Colors.grey[400],
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _hasActiveCoach() ? 'Already Have Coach' : (coach.isAvailable ? 'Hire Coach' : 'Currently Unavailable'),
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

  void _showHireDialog(CoachModel coach) {
    String selectedRateType = 'hourly';
    double selectedRate = coach.hourlyRate;
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
                  'Choose Training Package',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select your preferred training package with ${coach.name}',
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
            packageText = 'Hourly rate (₱${rate.toInt()}/hr)';
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

  Widget _buildActiveCoachSection() {
    if (_remoteCoachRequest == null) return SizedBox.shrink();
    
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
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to coach chat or profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coach communication feature coming soon!'),
                          backgroundColor: Color(0xFF4ECDC4),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF4ECDC4),
                      side: BorderSide(color: Color(0xFF4ECDC4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Message Coach',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to workout routines assigned by coach
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Coach routines feature coming soon!'),
                          backgroundColor: Color(0xFF4ECDC4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Routines',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
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
                'Personal training with coaches is a premium feature. Upgrade your membership to access this service.',
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
}
