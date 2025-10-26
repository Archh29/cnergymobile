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
    
    // Add listener to refresh pending requests when switching to pending tab
    _tabController.addListener(() {
      if (_tabController.index == 1) { // Pending requests tab
        _loadPendingRequests();
      }
    });
    
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
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
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
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
          case 'New Members':
            return member.isNewMember;
          case 'Fully Approved':
            return member.isFullyApproved;
          case 'Pending Approval':
            return member.isPendingCoachApproval || member.isPendingStaffApproval;
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
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Color(0xFF0F0F0F),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[900]!,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Color(0xFFFF6B35),
              unselectedLabelColor: Colors.grey[400],
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: Color(0xFFFF6B35),
                  width: 3,
                ),
                insets: EdgeInsets.symmetric(horizontal: 20),
              ),
              tabs: [
                Tab(
                  child: Text(
                    "ASSIGNED MEMBERS",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    "PENDING REQUESTS${pendingRequests.isNotEmpty ? ' (${pendingRequests.length})' : ''}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSearchSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignedMembersTab(),
                _buildPendingRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchSection() {
    // Updated filter options as requested
    final filterOptions = [
      'All',
      'Active Subscription',
      'New Members',
      'Fully Approved',
      'Pending Approval',
    ];

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search members by name or email...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: Colors.grey[500],
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
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedFilter = filter);
                    },
                    backgroundColor: Color(0xFF1A1A1A),
                    selectedColor: Color(0xFFFF6B35),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? Color(0xFFFF6B35) : Colors.grey[800]!,
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

  Widget _buildAssignedMembersTab() {
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

    return _buildMembersList(members, isAssigned: true);
  }

  Widget _buildPendingRequestsTab() {
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

    return _buildMembersList(requests, isPending: true);
  }

  Widget _buildMembersList(List<MemberModel> members,
      {bool isAssigned = false, bool isPending = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        return _buildMemberCard(members[index], isAssigned: isAssigned, isPending: isPending);
      },
    );
  }

  Widget _buildMemberCard(MemberModel member,
      {bool isAssigned = false, bool isPending = false}) {
    final isSelected = widget.selectedMember?.id == member.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFFFF6B35) : Colors.grey[800]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAssigned ? () => widget.onMemberSelected(member) : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: Color(0xFFFF6B35).withOpacity(0.1),
          highlightColor: Color(0xFFFF6B35).withOpacity(0.05),
          child: Column(
            children: [
          // Member Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Member Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Color(0xFFFF6B35).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: GoogleFonts.poppins(
                        color: Color(0xFFFF6B35),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Member Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.fullName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (member.hasPaidPlan)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Color(0xFF4ECDC4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PAID',
                                style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
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
                  GestureDetector(
                    onTap: () {}, // Prevent event bubbling
                    child: Row(
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Icon(Icons.check, size: 16),
                        ),
                      ],
                    ),
                  ),
                ] else if (isSelected)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B35).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFFFF6B35),
                      size: 16,
                    ),
                  )
                else if (isAssigned)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[500],
                    size: 16,
                  ),
              ],
            ),
          ),
          // Status badges (removed age)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (member.genderName != null)
                  _buildStatusBadge(
                    member.genderName!,
                    member.genderName?.toLowerCase() == 'male' 
                        ? Icons.male_rounded 
                        : Icons.female_rounded,
                    Color(0xFF4ECDC4),
                  ),
                if (member.planName != null)
                  _buildStatusBadge(
                    member.planName!,
                    Icons.card_membership_rounded,
                    Color(0xFF3B82F6),
                  ),
                _buildApprovalStatusBadge(member),
              ],
            ),
          ),
          // Additional info for pending requests
          if (isPending && member.requestedAt != null) ...[
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: Color(0xFFFF6B35), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Requested ${_formatDate(member.requestedAt!)}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[300],
                      fontSize: 12,
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
    );
  }

  Widget _buildApprovalStatusBadge(MemberModel member) {
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

    return _buildStatusBadge(text, icon, color);
  }

  Widget _buildStatusBadge(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
