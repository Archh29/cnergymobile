import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/messages_model.dart';
import './services/messages_service.dart';
import 'chat_page.dart';

class MessagesPage extends StatefulWidget {
  final int currentUserId;
  
  const MessagesPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Conversation> conversations = [];
  bool isLoading = true;
  String errorMessage = '';

  // Color palette for avatars
  final List<Color> avatarColors = [
    Color(0xFFFF6B35),
    Color(0xFF4ECDC4),
    Color(0xFF96CEB4),
    Color(0xFFE74C3C),
    Color(0xFF45B7D1),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
    Color(0xFF2ECC71),
  ];

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
    _loadConversations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final loadedConversations = await MessageService.getConversations(widget.currentUserId);
      
      setState(() {
        conversations = loadedConversations;
        isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  int get totalUnread => conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  Color _getAvatarColor(int userId) {
    return avatarColors[userId % avatarColors.length];
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${difference.inDays} days ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
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
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: _loadConversations,
          ),
          SizedBox(width: 16),
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
                        onPressed: _loadConversations,
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
                      // Header
                      Container(
                        margin: EdgeInsets.all(20),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4ECDC4).withOpacity(0.8), Color(0xFF44A08D).withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4ECDC4).withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Conversations',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    totalUnread > 0
                                        ? '$totalUnread unread messages'
                                        : conversations.isEmpty
                                            ? 'No conversations yet'
                                            : 'All caught up!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (totalUnread > 0)
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  totalUnread.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Messages List
                      Expanded(
                        child: conversations.isEmpty
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
                                      'No conversations yet',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[400],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Start chatting with your coach!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                itemCount: conversations.length,
                                itemBuilder: (context, index) {
                                  final conversation = conversations[index];
                                  final avatarColor = _getAvatarColor(conversation.otherUser.id);
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(20),
                                      border: conversation.unreadCount > 0
                                          ? Border.all(color: avatarColor, width: 1)
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(20),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  avatarColor.withOpacity(0.8),
                                                  avatarColor.withOpacity(0.6),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                conversation.otherUser.initials,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (conversation.otherUser.isOnline)
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF4ECDC4),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Color(0xFF1A1A1A), width: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conversation.otherUser.fullName,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (conversation.unreadCount > 0)
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: avatarColor,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                conversation.unreadCount.toString(),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 8),
                                          Text(
                                            conversation.lastMessage ?? 'No messages yet',
                                            style: GoogleFonts.poppins(
                                              color: conversation.unreadCount > 0 ? Colors.white : Colors.grey[400],
                                              fontSize: 14,
                                              fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                color: Colors.grey[500],
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                _formatTime(conversation.lastMessageTime),
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (conversation.otherUser.isOnline) ...[
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.circle,
                                                  color: Color(0xFF4ECDC4),
                                                  size: 8,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Online',
                                                  style: GoogleFonts.poppins(
                                                    color: Color(0xFF4ECDC4),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        // Mark messages as read when opening chat
                                        await MessageService.markMessagesAsRead(conversation.id, widget.currentUserId);
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                              conversationId: conversation.id,
                                              currentUserId: widget.currentUserId,
                                              otherUser: conversation.otherUser,
                                              avatarColor: avatarColor,
                                            ),
                                          ),
                                        ).then((_) {
                                          // Refresh conversations when returning from chat
                                          _loadConversations();
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}