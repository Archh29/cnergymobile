import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import './models/messages_model.dart';
import './services/messages_service.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final int currentUserId;
  final UserInfo otherUser;
  final Color avatarColor;

  const ChatPage({
    Key? key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUser,
    required this.avatarColor,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  
  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  String errorMessage = '';
  Timer? _messageTimer;
  UserInfo? _actualOtherUser; // Store the actual other user from API

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadMessages();
    // Start automatic message polling every 1 second
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _messageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _loadMessages(isPolling: true);
      } else {
        // Stop polling if widget is not mounted
        timer.cancel();
      }
    });
  }

  void _stopMessagePolling() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  @override
  void dispose() {
    _stopMessagePolling();
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    try {
      if (!isPolling) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      final response = await MessageService.getMessages(
        widget.conversationId, 
        widget.currentUserId
      );
      
      final loadedMessages = response['messages'] as List<Message>;
      
      // Update other user info if provided by API (fixes admin name display)
      if (response.containsKey('other_user') && mounted) {
        final otherUserData = response['other_user'] as Map<String, dynamic>;
        setState(() {
          _actualOtherUser = UserInfo(
            id: (otherUserData['id'] as int?) ?? widget.otherUser.id,
            firstName: (otherUserData['fname'] as String?) ?? widget.otherUser.firstName,
            lastName: (otherUserData['lname'] as String?) ?? widget.otherUser.lastName,
            email: (otherUserData['email'] as String?) ?? widget.otherUser.email,
            userTypeId: (otherUserData['user_type_id'] as int?) ?? widget.otherUser.userTypeId,
            isOnline: widget.otherUser.isOnline,
          );
        });
      }
      
      if (mounted) {
        // Only update UI if messages have changed
        bool hasChanged = messages.length != loadedMessages.length ||
            messages.any((msg) => 
              loadedMessages.any((newMsg) => 
                newMsg.id == msg.id && 
                (newMsg.message != msg.message || 
                 newMsg.timestamp != msg.timestamp)
              )
            );
        
        if (hasChanged || !isPolling) {
          setState(() {
            messages = loadedMessages;
            isLoading = false;
          });
          
          if (!isPolling) {
            _animationController.forward();
          }
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted && !isPolling) {
        setState(() {
          errorMessage = e.toString();
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

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    try {
      // Use conversation_id to determine receiver automatically
      // This ensures we always use the correct receiver from the database
      final otherUser = _actualOtherUser ?? widget.otherUser;
      final newMessage = await MessageService.sendMessage(
        widget.currentUserId,
        otherUser.id,
        messageText,
        conversationId: widget.conversationId,
      );

      setState(() {
        messages.add(newMessage);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        isSending = false;
      });
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Restore message text
      _messageController.text = messageText;
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
          onPressed: () {
            print('🔙 Chat back button pressed - returning to messages');
            // Navigate back to messages page
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.avatarColor.withOpacity(0.8),
                    widget.avatarColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (_actualOtherUser ?? widget.otherUser).userTypeId == 1 
                      ? 'A' 
                      : (_actualOtherUser ?? widget.otherUser).initials,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_actualOtherUser ?? widget.otherUser).userTypeId == 1 
                        ? 'Admin' 
                        : (_actualOtherUser ?? widget.otherUser).fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    (_actualOtherUser ?? widget.otherUser).userTypeId == 1 
                        ? 'Admin' 
                        : (_actualOtherUser ?? widget.otherUser).isCoach 
                            ? 'Coach' 
                            : 'Member',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Show submit request button only for admin conversations
          if ((_actualOtherUser ?? widget.otherUser).userTypeId == 1)
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.report_problem, color: Color(0xFF4ECDC4), size: 20),
              ),
              onPressed: () => _showSupportRequestForm(),
              tooltip: 'Submit Support Request',
            ),
        ],
      ),
      body: isLoading
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
                      Icon(Icons.error_outline, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Error loading messages',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadMessages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Messages List
                      Expanded(
                        child: messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.grey[600],
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No messages yet',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Start the conversation!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(20),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isCurrentUser = message.senderId == widget.currentUserId;
                                  return _buildMessage(
                                    message,
                                    _formatMessageTime(message.timestamp),
                                    !isCurrentUser,
                                    message.isRead,
                                  );
                                },
                              ),
                      ),
                      // Message Input
                      Container(
                        color: Color(0xFF0F0F0F),
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Type a message...",
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                  maxLines: null,
                                  cursorColor: Color(0xFF4ECDC4),
                                ),
                              ),
                              SizedBox(width: 12),
                              GestureDetector(
                                onTap: isSending ? null : _sendMessage,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4ECDC4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: isSending 
                                      ? Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMessage(Message message, String time, bool isOtherUser, bool isRead) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isOtherUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOtherUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.avatarColor.withOpacity(0.8),
                    widget.avatarColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (_actualOtherUser ?? widget.otherUser).userTypeId == 1 
                      ? 'A' 
                      : (_actualOtherUser ?? widget.otherUser).initials,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOtherUser ? Color(0xFF1A1A1A) : widget.avatarColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isOtherUser ? 4 : 20),
                  topRight: Radius.circular(isOtherUser ? 20 : 4),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: isOtherUser ? Border.all(color: widget.avatarColor.withOpacity(0.3)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOtherUser) ...[
                    // Show sender name and user type for other users
                    Row(
                      children: [
                        Text(
                          message.senderFullName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.senderUserType != null) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(message.senderUserType).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getUserTypeColor(message.senderUserType).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              message.senderUserType ?? 'User',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: _getUserTypeColor(message.senderUserType),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                  ] else ...[
                    Text(
                      'You:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                  ],
                  Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (!isOtherUser) ...[
                        SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? Color(0xFF4ECDC4) : Colors.grey[500],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isOtherUser) ...[
            SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Color _getUserTypeColor(String? userType) {
    switch (userType?.toLowerCase()) {
      case 'admin':
        return Color(0xFFFF6B35); // Orange/Red
      case 'staff':
        return Color(0xFF4ECDC4); // Teal
      case 'coach':
        return Color(0xFF9B59B6); // Purple
      case 'user':
      default:
        return Color(0xFF4ECDC4); // Teal (default)
    }
  }

  void _showSupportRequestForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFF4ECDC4).withOpacity(0.3), width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF4ECDC4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.report_problem,
                          color: Color(0xFF4ECDC4),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submit Support Request',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Report your concern to admin',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[400]),
                        onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Subject',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: subjectController,
                    enabled: !isSubmitting,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0F0F0F),
                      hintText: 'e.g., Equipment issue, Membership question...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Message',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    enabled: !isSubmitting,
                    maxLines: 5,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0xFF0F0F0F),
                      hintText: 'Describe your concern in detail...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFF4ECDC4), width: 2),
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[700]!),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            if (subjectController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a subject'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (messageController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a message'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              await MessageService.submitSupportRequest(
                                widget.currentUserId,
                                subjectController.text.trim(),
                                messageController.text.trim(),
                              );

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Support request submitted successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error submitting request: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4ECDC4),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Submit',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
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
      ),
    );
  }
}