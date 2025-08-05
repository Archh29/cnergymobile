import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import './services/coach_service.dart';

class CoachMemberSelector extends StatefulWidget {
  final List<MemberModel> assignedMembers;
  final MemberModel? selectedMember;
  final Function(MemberModel) onMemberSelected;
  final bool isLoading;

  const CoachMemberSelector({
    Key? key,
    required this.assignedMembers,
    required this.selectedMember,
    required this.onMemberSelected,
    required this.isLoading,
  }) : super(key: key);

  @override
  _CoachMemberSelectorState createState() => _CoachMemberSelectorState();
}

class _CoachMemberSelectorState extends State<CoachMemberSelector>
    with TickerProviderStateMixin {
  String searchQuery = '';
  String selectedFilter = 'All';
  List<MemberModel> pendingRequests = [];
  bool isLoadingRequests = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _tabController = TabController(length: 2, vsync: this);
    _animationController.forward();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() => isLoadingRequests = true);
    try {
      final requests = await CoachService.getPendingRequests();
      setState(() => pendingRequests = requests);
    } catch (e) {
      print('Error loading pending requests: $e');
    } finally {
      setState(() => isLoadingRequests = false);
    }
  }

  Future<void> _approveMemberRequest(MemberModel member) async {
    try {
      int? requestId = member.requestId;
      
      if (requestId == null) {
        _showErrorSnackBar('Request ID not found. Please refresh and try again.');
        return;
      }

      final success = await CoachService.approveMemberRequest(requestId);
      if (success) {
        _showSuccessSnackBar('${member.fullName} approved successfully');
        _loadPendingRequests();
      } else {
        throw Exception('Failed to approve member');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to approve member: $e');
    }
  }

  Future<void> _rejectMemberRequest(MemberModel member) async {
    try {
      int? requestId = member.requestId;
      
      if (requestId == null) {
        _showErrorSnackBar('Request ID not found. Please refresh and try again.');
        return;
      }

      final success = await CoachService.rejectMemberRequest(requestId, reason: 'Not available');
      if (success) {
        _showSuccessSnackBar('${member.fullName} request rejected');
        _loadPendingRequests();
      } else {
        throw Exception('Failed to reject member');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to reject member: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<MemberModel> get filteredMembers {
    List<MemberModel> filtered = widget.assignedMembers;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((member) =>
          member.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          member.email.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (selectedFilter != 'All') {
      filtered = filtered.where((member) {
        switch (selectedFilter) {
          case 'Active Subscription':
            return member.hasActiveSubscription;
          case 'Paid Plan':
            return member.hasPaidPlan;
          case 'New Members':
            return member.isNewMember;
          case 'Fully Approved':
            return member.isFullyApproved;
          case 'Pending Approval':
            return member.isPendingCoachApproval || member.isPendingStaffApproval;
          case 'Male':
            return member.genderName?.toLowerCase() == 'male';
          case 'Female':
            return member.genderName?.toLowerCase() == 'female';
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  List<MemberModel> get filteredPendingRequests {
    if (searchQuery.isEmpty) return pendingRequests;

    return pendingRequests.where((member) =>
        member.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        member.email.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 768;
              final isMobile = constraints.maxWidth < 480;

              return Column(
                children: [
                  _buildHeader(isTablet, isMobile),
                  _buildTabBar(isTablet),
                  _buildSearchSection(isTablet, isMobile),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAssignedMembersTab(isTablet, isMobile),
                        _buildPendingRequestsTab(isTablet, isMobile),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 20,
        isMobile ? 16 : 24,
        isMobile ? 12 : 16,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.people_rounded,
              color: Colors.white,
              size: isMobile ? 24 : 28,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '${widget.assignedMembers.length} assigned${pendingRequests.isNotEmpty ? ' • ${pendingRequests.length} pending' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.selectedMember != null)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Selected',
                    style: GoogleFonts.inter(
                      color: Color(0xFF10B981),
                      fontSize: isMobile ? 10 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF374151), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFF9CA3AF),
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 14 : 13,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: isTablet ? 14 : 13,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded, size: 18),
                SizedBox(width: 8),
                Text('Assigned'),
                if (widget.assignedMembers.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.assignedMembers.length}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 18),
                SizedBox(width: 8),
                Text('Pending'),
                if (pendingRequests.isNotEmpty) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pendingRequests.length}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildSearchSection(bool isTablet, bool isMobile) {
    // Database-aligned filter options
    final filterOptions = [
      'All',
      'Active Subscription',
      'Paid Plan',
      'New Members',
      'Fully Approved',
      'Pending Approval',
      'Male',
      'Female',
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        16,
        isTablet ? 24 : 16,
        8,
      ),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF374151)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search members by name or email...',
                hintStyle: GoogleFonts.inter(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Color(0xFF9CA3AF),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedFilter = filter);
                    },
                    backgroundColor: Color(0xFF1F2937),
                    selectedColor: Color(0xFF3B82F6),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Color(0xFF3B82F6) : Color(0xFF374151),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedMembersTab(bool isTablet, bool isMobile) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }
    if (widget.assignedMembers.isEmpty) {
      return _buildEmptyState('No Members Assigned',
          'Contact your gym administrator to get members assigned to you.',
          Icons.people_outline);
    }

    final members = filteredMembers;

    if (members.isEmpty) {
      return _buildEmptyState('No Results Found',
          'Try adjusting your search or filter criteria.',
          Icons.search_off);
    }

    return _buildMembersList(members, isTablet, isMobile, isAssigned: true);
  }

  Widget _buildPendingRequestsTab(bool isTablet, bool isMobile) {
    if (isLoadingRequests) {
      return _buildLoadingState();
    }
    if (pendingRequests.isEmpty) {
      return _buildEmptyState('No Pending Requests',
          'All member requests have been processed.',
          Icons.inbox_outlined);
    }

    final requests = filteredPendingRequests;

    if (requests.isEmpty) {
      return _buildEmptyState('No Results Found',
          'Try adjusting your search criteria.',
          Icons.search_off);
    }

    return _buildMembersList(requests, isTablet, isMobile, isPending: true);
  }

  Widget _buildMembersList(List<MemberModel> members, bool isTablet, bool isMobile,
      {bool isAssigned = false, bool isPending = false}) {

    final crossAxisCount = isTablet ? 2 : 1;
    final childAspectRatio = isTablet ? 2.8 : (isMobile ? 2.2 : 2.5);

    if (isTablet && members.length > 1) {
      return GridView.builder(
        padding: EdgeInsets.all(24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: members.length,
        itemBuilder: (context, index) {
          return _buildMemberCard(members[index], isTablet, isMobile,
              isAssigned: isAssigned, isPending: isPending);
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24 : 16,
        16,
        isTablet ? 24 : 16,
        24,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _buildMemberCard(members[index], isTablet, isMobile,
              isAssigned: isAssigned, isPending: isPending),
        );
      },
    );
  }

  Widget _buildMemberCard(MemberModel member, bool isTablet, bool isMobile,
      {bool isAssigned = false, bool isPending = false}) {
    final isSelected = widget.selectedMember?.id == member.id;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF10B981) : Color(0xFF374151),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAssigned ? () => widget.onMemberSelected(member) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar (no profile image in database)
                    Container(
                      width: isMobile ? 48 : 56,
                      height: isMobile ? 48 : 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Member info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member.fullName,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (member.hasPaidPlan)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PAID',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            member.email,
                            style: GoogleFonts.inter(
                              color: Color(0xFF9CA3AF),
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    if (isPending) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _rejectMemberRequest(member),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                                vertical: isMobile ? 6 : 8,
                              ),
                              minimumSize: Size(0, 0),
                            ),
                            child: Icon(Icons.close, size: 16),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approveMemberRequest(member),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 8 : 12,
                                vertical: isMobile ? 6 : 8,
                              ),
                            ),
                            child: Icon(Icons.check, size: 16),
                          ),
                        ],
                      ),
                    ] else if (isSelected)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      )
                    else if (isAssigned)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                  ],
                ),
                SizedBox(height: 16),
                // Status badges based on database fields
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatusBadge(
                      'Age ${member.age}',
                      Icons.cake_rounded,
                      Color(0xFF8B5CF6),
                      isMobile,
                    ),
                    if (member.genderName != null)
                      _buildStatusBadge(
                        member.genderName!,
                        member.genderName?.toLowerCase() == 'male' 
                            ? Icons.male_rounded 
                            : Icons.female_rounded,
                        Color(0xFF06B6D4),
                        isMobile,
                      ),
                    if (member.planName != null)
                      _buildStatusBadge(
                        member.planName!,
                        Icons.card_membership_rounded,
                        Color(0xFF3B82F6),
                        isMobile,
                      ),
                    _buildApprovalStatusBadge(member, isMobile),
                  ],
                ),
                // Additional info for pending requests
                if (isPending && member.requestedAt != null) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF374151),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Requested ${_formatDate(member.requestedAt!)}',
                          style: GoogleFonts.inter(
                            color: Color(0xFFD1D5DB),
                            fontSize: isMobile ? 11 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalStatusBadge(MemberModel member, bool isMobile) {
    String text;
    Color color;
    IconData icon;

    if (member.isFullyApproved) {
      text = 'Fully Approved';
      color = Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (member.isPendingStaffApproval) {
      text = 'Staff Review';
      color = Color(0xFFF59E0B);
      icon = Icons.pending_rounded;
    } else if (member.isPendingCoachApproval) {
      text = 'Coach Review';
      color = Color(0xFFEF4444);
      icon = Icons.schedule_rounded;
    } else if (member.isRejected) {
      text = 'Rejected';
      color = Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
    } else {
      text = member.hasActiveSubscription ? 'Active' : 'Inactive';
      color = member.hasActiveSubscription ? Color(0xFF10B981) : Color(0xFF6B7280);
      icon = Icons.circle;
    }

    return _buildStatusBadge(text, icon, color, isMobile);
  }

  Widget _buildStatusBadge(String text, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 10,
        vertical: isMobile ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 12 : 14),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading members...',
            style: GoogleFonts.inter(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF374151)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF374151),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Color(0xFF9CA3AF),
                size: 32,
              ),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
