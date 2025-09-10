import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/member_model.dart';
import './services/coach_service.dart';
import 'coach_create_routine_page.dart';

class CoachClientSelectionPage extends StatefulWidget {
  final Color selectedColor;

  const CoachClientSelectionPage({
    Key? key,
    this.selectedColor = const Color(0xFF4ECDC4),
  }) : super(key: key);

  @override
  _CoachClientSelectionPageState createState() => _CoachClientSelectionPageState();
}

class _CoachClientSelectionPageState extends State<CoachClientSelectionPage> {
  List<MemberModel> assignedMembers = [];
  List<MemberModel> filteredMembers = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssignedMembers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignedMembers() async {
    try {
      setState(() => isLoading = true);
      
      final members = await CoachService.getAssignedMembers();
      
      setState(() {
        assignedMembers = members;
        filteredMembers = members;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Failed to load clients: ${e.toString()}');
    }
  }

  void _filterMembers(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredMembers = assignedMembers;
      } else {
        filteredMembers = assignedMembers.where((member) {
          return member.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 member.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Client',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Choose who to create routine for',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: searchController,
              onChanged: _filterMembers,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: widget.selectedColor),
                filled: true,
                fillColor: Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Client Count Header
          if (!isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${filteredMembers.length} client${filteredMembers.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (searchQuery.isNotEmpty) ...[
                    Text(
                      ' found for "$searchQuery"',
                      style: GoogleFonts.poppins(
                        color: widget.selectedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          SizedBox(height: 16),

          // Client List
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
                    ),
                  )
                : filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          return _buildClientCard(member);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
            color: Colors.grey[600],
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty 
                ? 'No clients assigned yet'
                : 'No clients found',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Clients will appear here once they request you as their coach'
                : 'Try adjusting your search terms',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty) ...[
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                searchController.clear();
                _filterMembers('');
              },
              child: Text(
                'Clear Search',
                style: GoogleFonts.poppins(
                  color: widget.selectedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(MemberModel member) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToCreateRoutine(member),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Picture/Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.selectedColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: widget.selectedColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: member.profileImage != null && member.profileImage!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.network(
                            member.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  member.initials,
                                  style: GoogleFonts.poppins(
                                    color: widget.selectedColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            member.initials,
                            style: GoogleFonts.poppins(
                              color: widget.selectedColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                
                SizedBox(width: 16),
                
                // Client Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        member.email,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  member.statusIcon,
                                  color: member.statusColor,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  member.status.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: member.statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          // Join Date
                          Text(
                            'Joined ${member.formattedJoinDate}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCreateRoutine(MemberModel selectedMember) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoachCreateRoutinePage(
          selectedClient: selectedMember,
          selectedColor: widget.selectedColor,
        ),
      ),
    );
  }
}
