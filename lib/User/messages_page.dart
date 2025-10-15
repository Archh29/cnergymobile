import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models/messages_model.dart';
import 'services/messages_service.dart';
import 'chat_page.dart';
import '../user_dashboard.dart';

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
  Timer? _messageTimer;

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
    // Start automatic message polling every 1 second
    _startMessagePolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh conversations when page becomes visible (e.g., returning from chat)
    _loadConversations();
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
    print('🗑️ Disposing MessagesPage...');
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
            // If this is polling and we have a conversation with unreadCount 0 locally,
            // don't let server data overwrite it unless the server also shows 0
            if (isPolling) {
              for (int i = 0; i < conversations.length; i++) {
                final localConv = conversations[i];
                final serverConv = loadedConversations.firstWhere(
                  (c) => c.id == localConv.id, 
                  orElse: () => localConv
                );
                
                // If local shows as read (0) but server still shows unread, keep local
                if (localConv.unreadCount == 0 && serverConv.unreadCount > 0) {
                  print('🔒 Keeping local read status for conversation ${localConv.id}');
                  loadedConversations[loadedConversations.indexWhere((c) => c.id == localConv.id)] = localConv;
                }
              }
            }
            
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

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('MMM d, y').format(dateTime);
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
        leading: GestureDetector(
          onTap: () {
            print('🔙 Back button TAPPED - returning to dashboard');
            // Use Navigator.pop() to trigger the .then() callback in dashboard
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
                      SizedBox(height: 24),
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
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF6B35).withOpacity(0.4),
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
                                    key: ValueKey('conversation_${conversation.id}_${conversation.unreadCount}'),
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
                                          Builder(
                                            builder: (context) {
                                              final isUnread = conversation.unreadCount > 0;
                                              print('🎨 Rendering message text - unreadCount: ${conversation.unreadCount}, isUnread: $isUnread');
                                              return Text(
                                                conversation.lastMessage ?? 'No messages yet',
                                                style: GoogleFonts.poppins(
                                                  color: isUnread ? Colors.white : Colors.grey[500],
                                                  fontSize: 14,
                                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
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
                                      onTap: () {
                                        // Mark messages as read in background (don't wait)
                                        MessageService.markMessagesAsRead(conversation.id, widget.currentUserId);
                                        
                                        // Immediately update local conversation to show as read
                                        print('🔄 Before update - unreadCount: ${conversation.unreadCount}');
                                        setState(() {
                                          final index = conversations.indexWhere((c) => c.id == conversation.id);
                                          if (index != -1) {
                                            conversations[index] = conversation.copyWith(unreadCount: 0);
                                            print('✅ After update - unreadCount: ${conversations[index].unreadCount}');
                                            // Force a complete rebuild
                                            conversations = List.from(conversations);
                                          }
                                        });
                                        
                                        // Navigate with ultra-smooth animation
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => ChatPage(
                                              conversationId: conversation.id,
                                              currentUserId: widget.currentUserId,
                                              otherUser: conversation.otherUser,
                                              avatarColor: avatarColor,
                                            ),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              // Very gentle slide from right
                                              const begin = Offset(0.1, 0.0);
                                              const end = Offset.zero;
                                              const curve = Curves.easeOutCubic;
                                              
                                              var tween = Tween(begin: begin, end: end).chain(
                                                CurveTween(curve: curve),
                                              );
                                              
                                              var offsetAnimation = animation.drive(tween);
                                              
                                              // Very smooth fade
                                              var fadeAnimation = Tween<double>(
                                                begin: 0.0,
                                                end: 1.0,
                                              ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
                                              
                                              return SlideTransition(
                                                position: offsetAnimation,
                                                child: FadeTransition(
                                                  opacity: fadeAnimation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            transitionDuration: Duration(milliseconds: 500),
                                            reverseTransitionDuration: Duration(milliseconds: 400),
                                          ),
                                        ).then((_) {
                                          // Refresh conversations when returning from chat
                                          if (mounted) {
                                            _loadConversations();
                                          }
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