import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/member_model.dart';
import '../User/models/messages_model.dart';
import '../User/services/messages_service.dart';
import '../User/chat_page.dart';
import 'coach_messages_page.dart';

class CoachMessagesDashboard extends StatefulWidget {
  final int currentUserId;
  
  const CoachMessagesDashboard({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _CoachMessagesDashboardState createState() => _CoachMessagesDashboardState();
}

class _CoachMessagesDashboardState extends State<CoachMessagesDashboard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Conversation> conversations = [];
  bool isLoading = true;
  String errorMessage = '';
  Timer? _messageTimer;

  // Color palette for avatars
  final List<Color> avatarColors = [
    Color(0xFF4ECDC4),
    Color(0xFFFF6B35),
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
    // Start automatic message polling every 1 second
    _startMessagePolling();
  }

  void _startMessagePolling() {
    _messageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        print('🔄 Auto-polling for new conversations');
        _loadConversations(isPolling: true);
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
    print('🗑️ Disposing CoachMessagesDashboard...');
    _stopMessagePolling();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations({bool isPolling = false}) async {
    try {
      if (!isPolling) {
        setState(() {
          isLoading = true;
          errorMessage = '';
        });
      }

      final loadedConversations = await MessageService.getConversations(widget.currentUserId);
      
      if (mounted) {
        // Only update UI if conversations have changed
        bool hasChanged = conversations.length != loadedConversations.length ||
            conversations.any((conv) => 
              loadedConversations.any((newConv) => 
                newConv.id == conv.id && 
                (newConv.unreadCount != conv.unreadCount || 
                 newConv.lastMessage != conv.lastMessage ||
                 newConv.lastMessageTime != conv.lastMessageTime)
              )
            );
        
        if (hasChanged || !isPolling) {
          setState(() {
            conversations = loadedConversations;
            isLoading = false;
          });
          
          if (!isPolling) {
            _animationController.forward();
          }
          print('✅ Loaded ${loadedConversations.length} conversations${isPolling ? ' (polling)' : ''}');
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

  int get totalUnread => conversations.fold(0, (sum, conv) => sum + conv.unreadCount);

  Color _getAvatarColor(int userId) {
    return avatarColors[userId % avatarColors.length];
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
        leading: GestureDetector(
          onTap: () {
            print('🔙 Back button TAPPED - returning to dashboard');
            Navigator.pop(context);
          },
          child: Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        actions: [],
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
                        padding: EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4ECDC4), Color(0xFF45B7D1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF4ECDC4).withOpacity(0.4),
                              blurRadius: 25,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Conversations',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    totalUnread > 0
                                        ? '$totalUnread unread messages'
                                        : conversations.isEmpty
                                            ? 'No conversations yet'
                                            : 'All caught up!',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (totalUnread > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
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
                      // Special Action Cards
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Need Help? Chat with Admin Card
                            _buildSpecialCard(
                              title: 'Need Help?',
                              subtitle: 'Chat with Admin',
                              icon: Icons.support_agent,
                              iconColor: Color(0xFFFF6B35),
                              gradientColors: [Color(0xFFFF6B35), Color(0xFFFF8C5A)],
                              onTap: () => _openAdminChat(),
                            ),
                            SizedBox(height: 20),
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
                                    Icon(Icons.message_rounded, color: Colors.grey[700], size: 80),
                                    SizedBox(height: 8),
                                    Text(
                                      'No conversations yet!',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Start chatting with your clients!',
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
                                    margin: EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: conversation.unreadCount > 0
                                            ? [Color(0xFF2A2A2A), Color(0xFF1F1F1F)]
                                            : [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: conversation.unreadCount > 0
                                          ? Border.all(color: avatarColor.withOpacity(0.6), width: 2)
                                          : Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: conversation.unreadCount > 0
                                              ? avatarColor.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.3),
                                          blurRadius: conversation.unreadCount > 0 ? 15 : 8,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(20),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  avatarColor,
                                                  avatarColor.withOpacity(0.7),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: avatarColor.withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                conversation.otherUser.initials,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (conversation.otherUser.isOnline)
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF4ECDC4),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Color(0xFF1A1A1A), width: 3),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color(0xFF4ECDC4).withOpacity(0.5),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
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
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          if (conversation.lastMessageTime != null)
                                            Text(
                                              _formatTime(conversation.lastMessageTime!),
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Text(
                                            conversation.lastMessage ?? 'No messages yet',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: conversation.unreadCount > 0
                                                  ? Colors.white
                                                  : Colors.grey[500],
                                              fontSize: 14,
                                              fontWeight: conversation.unreadCount > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Create a MemberModel from the conversation data
                                        final member = MemberModel(
                                          id: conversation.otherUser.id,
                                          firstName: conversation.otherUser.firstName,
                                          lastName: conversation.otherUser.lastName,
                                          email: conversation.otherUser.email,
                                        );
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CoachMessagesPage(selectedMember: member),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (time.year == now.year) {
      return DateFormat('MMM d').format(time);
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }

  Widget _buildSpecialCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdminChat() async {
    try {
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

      // Get or create conversation with admin
      final response = await MessageService.getOrCreateAdminConversation(widget.currentUserId);
      final adminConversationId = response['conversation_id'];
      final adminUserData = response['admin_user'];
      
      // Get admin user info from API response
      // Use user_type_id from API to ensure it's always an admin (user_type_id = 1)
      final adminUser = UserInfo(
        id: adminUserData['id'] ?? 0,
        firstName: adminUserData['fname'] ?? 'Admin',
        lastName: adminUserData['lname'] ?? 'Support',
        email: adminUserData['email'] ?? 'admin@cnergy.site',
        userTypeId: adminUserData['user_type_id'] ?? 1, // Get from API, default to 1 (Admin)
        isOnline: false,
      );

      Navigator.pop(context); // Close loading

      // Navigate to chat
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
            conversationId: adminConversationId,
            currentUserId: widget.currentUserId,
            otherUser: adminUser,
            avatarColor: Color(0xFFFF6B35),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.1, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(animation);
            
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            );
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      ).then((_) {
        if (mounted) {
          _loadConversations();
        }
      });
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening admin chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
