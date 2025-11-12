import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/support_ticket_model.dart';
import 'services/support_ticket_service.dart';
import 'support_ticket_detail_page.dart';
import 'create_support_ticket_page.dart';

class SupportTicketsPage extends StatefulWidget {
  final int currentUserId;
  
  const SupportTicketsPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _SupportTicketsPageState createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> with TickerProviderStateMixin {
  List<SupportTicket> tickets = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    // Refresh tickets every 5 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadTickets(isPolling: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTickets({bool isPolling = false}) async {
    try {
      if (!isPolling) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      final loadedTickets = await SupportTicketService.getUserTickets(widget.currentUserId);
      
      if (mounted) {
        setState(() {
          tickets = loadedTickets;
          isLoading = false;
          errorMessage = '';
        });
      }
    } catch (e) {
      print('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToCreateTicket() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSupportTicketPage(userId: widget.currentUserId),
      ),
    );
    
    // Refresh tickets when returning from create page
    if (result == true && mounted) {
      // Add a small delay to ensure database transaction is committed
      await Future.delayed(Duration(milliseconds: 500));
      _loadTickets();
    }
  }

  void _navigateToTicketDetail(SupportTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportTicketDetailPage(
          ticket: ticket,
          currentUserId: widget.currentUserId,
        ),
      ),
    ).then((_) {
      _loadTickets();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Color(0xFFFF9500);
      case 'in_progress':
        return Color(0xFF007AFF);
      case 'resolved':
        return Color(0xFF34C759);
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
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
        title: Text(
          'Support Tickets',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Create Ticket Button
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToCreateTicket,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Create Support Ticket',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          // Tickets List
          Expanded(
            child: isLoading && tickets.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: isSmallScreen ? 64 : 80,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error loading tickets',
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadTickets(),
                              child: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4ECDC4),
                              ),
                            ),
                          ],
                        ),
                      )
                : tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent_outlined,
                              color: Colors.grey[600],
                              size: isSmallScreen ? 64 : 80,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Support Tickets',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a ticket to get help from our support team',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        color: Color(0xFF4ECDC4),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _buildTicketCard(ticket, isSmallScreen);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTicketDetail(ticket),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ticket Number
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ticket.ticketNumber,
                        style: GoogleFonts.poppins(
                          color: Color(0xFF4ECDC4),
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ticket.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getStatusColor(ticket.status).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        ticket.statusLabel,
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(ticket.status),
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: 12),
                // Subject
                Text(
                  ticket.subject,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Description Preview
                Text(
                  ticket.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${ticket.messageCount} message${ticket.messageCount != 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                    Spacer(),
                    Text(
                      _formatDate(ticket.createdAt),
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: isSmallScreen ? 12 : 13,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

