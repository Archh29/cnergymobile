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
                if (widget.currentUser != null && widget.currentUser!.isPremium) _buildFilterSection(),
                if (widget.currentUser != null && widget.currentUser!.isPremium) _buildCoachesSection(),
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
      subtitle = 'You are assigned to $coachName.';
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
                Spacer(),
                Text(
                  '\$${coach.hourlyRate.toInt()}/hr',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
                onPressed: coach.isAvailable ? () => _showHireDialog(coach) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: coach.isAvailable ? Color(0xFF4ECDC4) : Colors.grey[700],
                  foregroundColor: coach.isAvailable ? Colors.white : Colors.grey[400],
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  coach.isAvailable ? 'Hire Coach' : 'Currently Unavailable',
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
    final messageController = TextEditingController();
    
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
                  color: Color(0xFF4ECDC4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Color(0xFF4ECDC4), size: 32),
              ),
              SizedBox(height: 16),
              Text(
                'Hire ${coach.name}?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Send a request to hire this coach as your personal trainer.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              TextField(
                controller: messageController,
                style: GoogleFonts.poppins(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a message (optional)',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[700]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4ECDC4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                      onPressed: () => _sendCoachRequest(coach, messageController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4ECDC4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Send Request',
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

  Future<void> _sendCoachRequest(CoachModel coach, String message) async {
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
      final success = await CoachService.sendCoachRequest(
        userId: widget.currentUser!.id,
        coachId: coach.id,
        message: message,
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        setState(() {
          coachRequestStatus = 'pending';
          selectedCoachId = coach.id;
          selectedCoachName = coach.name;
          requestDate = DateTime.now().toString().split(' ')[0];
        });
        await _saveCoachRequestStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coach request sent successfully! Visit the front desk to complete payment.',
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
              'Failed to send coach request. Please try again.',
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
}
