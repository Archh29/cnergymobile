import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/support_ticket_model.dart';
import 'services/support_ticket_service.dart';

class SupportTicketDetailPage extends StatefulWidget {
  final SupportTicket ticket;
  final int currentUserId;

  const SupportTicketDetailPage({
    Key? key,
    required this.ticket,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _SupportTicketDetailPageState createState() => _SupportTicketDetailPageState();
}

class _SupportTicketDetailPageState extends State<SupportTicketDetailPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  SupportTicket? _currentTicket;
  List<SupportTicketMessage> messages = [];
  bool isLoading = true;
  bool isSending = false;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _loadTicketData();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startMessagePolling() {
    _messageTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadMessages(isPolling: true);
        _refreshTicket();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshTicket() async {
    try {
      final ticket = await SupportTicketService.getTicket(
        _currentTicket!.id,
        widget.currentUserId,
      );
      if (ticket != null && mounted) {
        setState(() {
          _currentTicket = ticket;
        });
      }
    } catch (e) {
      // Silently fail for polling
    }
  }

  Future<void> _loadTicketData() async {
    await Future.wait([
      _refreshTicket(),
      _loadMessages(),
    ]);
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    try {
      if (!isPolling) {
        setState(() {
          isLoading = true;
        });
      }

      final loadedMessages = await SupportTicketService.getTicketMessages(
        _currentTicket!.id,
        widget.currentUserId,
      );
      
      if (mounted) {
        setState(() {
          messages = loadedMessages;
          isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !isPolling) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || isSending) return;
    if (_currentTicket == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      final response = await SupportTicketService.sendMessage(
        ticketId: _currentTicket!.id,
        senderId: widget.currentUserId,
        message: messageText,
      );

      if (response['success'] == true && response['data'] != null) {
        final newMessage = SupportTicketMessage.fromJson(response['data']);
        setState(() {
          messages.add(newMessage);
          isSending = false;
        });
        _scrollToBottom();
        _refreshTicket();
      } else {
        setState(() {
          isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
        _messageController.text = messageText;
      }
    } catch (e) {
      setState(() {
        isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      _messageController.text = messageText;
    }
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

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final ticket = _currentTicket ?? widget.ticket;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.ticketNumber,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ticket.statusLabel,
              style: GoogleFonts.poppins(
                color: _getStatusColor(ticket.status),
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Ticket Info Card
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            color: Color(0xFF1A1A1A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.subject,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: isSmallScreen ? 14 : 15,
                  ),
                ),
                if (ticket.resolutionNotes != null && ticket.resolutionNotes!.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xFF34C759).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF34C759),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resolution Notes',
                                style: GoogleFonts.poppins(
                                  color: Color(0xFF34C759),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                ticket.resolutionNotes!,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: isLoading && messages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                    ),
                  )
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              color: Colors.grey[600],
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the conversation by sending a message',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser = message.senderId == widget.currentUserId;
                          return _buildMessageBubble(message, isCurrentUser, isSmallScreen);
                        },
                      ),
          ),
          // Message Input (only show if ticket is not resolved)
          if (ticket.status != 'resolved')
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.poppins(color: Colors.white),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        onPressed: isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This ticket has been resolved. You can view the conversation above.',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportTicketMessage message, bool isCurrentUser, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isFromAdmin 
                  ? Color(0xFFFF6B35).withOpacity(0.2)
                  : Color(0xFF4ECDC4).withOpacity(0.2),
              child: Icon(
                message.isFromAdmin ? Icons.support_agent : Icons.person,
                size: 16,
                color: message.isFromAdmin ? Color(0xFFFF6B35) : Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Color(0xFFFF6B35)
                    : Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Text(
                      message.senderFullName,
                      style: GoogleFonts.poppins(
                        color: isCurrentUser ? Colors.white : Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!isCurrentUser) SizedBox(height: 4),
                  Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      color: isCurrentUser ? Colors.white : Colors.white,
                      fontSize: isSmallScreen ? 14 : 15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: GoogleFonts.poppins(
                      color: isCurrentUser 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 16,
                color: Color(0xFF4ECDC4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


