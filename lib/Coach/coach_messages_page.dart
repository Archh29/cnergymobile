import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/member_model.dart';
import 'models/message_model.dart';
import 'services/message_service.dart';

class CoachMessagesPage extends StatefulWidget {
  final MemberModel? selectedMember;

  const CoachMessagesPage({Key? key, this.selectedMember}) : super(key: key);

  @override
  _CoachMessagesPageState createState() => _CoachMessagesPageState();
}

class _CoachMessagesPageState extends State<CoachMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    if (widget.selectedMember != null) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id');
    });
  }

  Future<void> _loadMessages() async {
    if (currentUserId == null || widget.selectedMember == null) return;

    setState(() => isLoading = true);

    try {
      final loadedMessages = await MessageService.getMessages(
        conversationId: 0, // Virtual conversation
        userId: currentUserId!,
        otherUserId: widget.selectedMember!.id,
      );

      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load messages');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || 
        currentUserId == null || 
        widget.selectedMember == null ||
        isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => isSending = true);

    try {
      final newMessage = await MessageService.sendMessage(
        senderId: currentUserId!,
        receiverId: widget.selectedMember!.id,
        message: messageText,
      );

      setState(() {
        messages.add(newMessage);
        isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      setState(() => isSending = false);
      _showErrorSnackBar('Failed to send message');
      
      // Restore the message text
      _messageController.text = messageText;
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMember == null) {
      return Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        appBar: _buildAppBar(),
        body: _buildNoMemberSelected(),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: isLoading ? _buildLoadingIndicator() : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: widget.selectedMember != null
          ? Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
                  child: Text(
                    widget.selectedMember!.initials,
                    style: GoogleFonts.poppins(
                      color: Color(0xFF4ECDC4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedMember!.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.selectedMember!.approvalStatusMessage,
                        style: GoogleFonts.poppins(
                          color: widget.selectedMember!.isFullyApproved 
                              ? Colors.green[400] 
                              : Colors.orange[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              'Messages',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
      actions: [
        if (widget.selectedMember != null)
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMessages,
          ),
      ],
    );
  }

  Widget _buildNoMemberSelected() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF4ECDC4),
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No Member Selected',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please select a member to start messaging.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF4ECDC4),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'No Messages Yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start the conversation with ${widget.selectedMember!.fullName}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
              child: Text(
                widget.selectedMember!.initials,
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Color(0xFF4ECDC4) : Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: GoogleFonts.poppins(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (message.timestamp != null) ...[
                    SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp!),
                      style: GoogleFonts.poppins(
                        color: isMe ? Colors.white70 : Colors.grey[400],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF4ECDC4).withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: Color(0xFF4ECDC4),
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: isSending ? null : _sendMessage,
                icon: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
