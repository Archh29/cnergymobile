import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    print('🔄 CoachMessagesPage initState called - Loading messages automatically');
    _initializeMessages();
  }

  Future<void> _initializeMessages() async {
    await _loadCurrentUser();
    if (widget.selectedMember != null) {
      // Automatically trigger refresh when opening messages
      print('🔄 Auto-refreshing messages on open');
      await _loadMessages();
      
      // Start automatic message polling every 3 seconds
      _startMessagePolling();
    }
  }

  void _startMessagePolling() {
    _messageTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && widget.selectedMember != null) {
        print('🔄 Auto-polling for new messages');
        _loadMessages(isPolling: true);
      }
    });
  }

  void _stopMessagePolling() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  @override
  void didUpdateWidget(CoachMessagesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload messages if the selected member changed
    if (oldWidget.selectedMember?.id != widget.selectedMember?.id) {
      print('🔄 Selected member changed, restarting message polling');
      _stopMessagePolling();
      if (widget.selectedMember != null) {
        _loadMessages();
        _startMessagePolling();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh when the page becomes visible
    if (widget.selectedMember != null) {
      print('🔄 Page became visible, force refreshing messages');
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _stopMessagePolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? userId;
    
    // Try to get as int first - wrapped in try-catch because getInt throws if value is string
    try {
      userId = prefs.getInt('user_id');
    } catch (e) {
      print('⚠️ user_id is not stored as int, trying as string: $e');
      userId = null; // Ensure it's null to trigger string fallback
    }
    
    // If not found or null, try to get as string and convert
    if (userId == null) {
      final userIdString = prefs.getString('user_id');
      if (userIdString != null) {
        userId = int.tryParse(userIdString);
        // Convert back to int for future consistency
        if (userId != null) {
          await prefs.setInt('user_id', userId);
        }
      }
    }
    
    setState(() {
      currentUserId = userId;
    });
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    if (widget.selectedMember == null) {
      print('❌ No selected member, cannot load messages');
      setState(() => isLoading = false);
      return;
    }

    // If currentUserId is null, try to load it first
    if (currentUserId == null) {
      print('🔍 Loading current user ID...');
      await _loadCurrentUser();
      if (currentUserId == null) {
        print('❌ No current user ID, cannot load messages');
        setState(() => isLoading = false);
        return;
      }
      print('✅ Current user ID loaded: $currentUserId');
    }

    if (!isPolling) {
      print('🔄 Loading messages for member: ${widget.selectedMember!.fullName} (ID: ${widget.selectedMember!.id})');
      print('🔑 Current user ID: $currentUserId');
      setState(() => isLoading = true);
    }

    try {
      print('📡 Calling MessageService.getMessages with:');
      print('   - conversationId: 0');
      print('   - userId: $currentUserId');
      print('   - otherUserId: ${widget.selectedMember!.id}');
      
      // Add timeout to prevent infinite loading
      final loadedMessages = await MessageService.getMessages(
        conversationId: 0, // Virtual conversation
        userId: currentUserId!,
        otherUserId: widget.selectedMember!.id,
      ).timeout(
        Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          print('⏰ Message loading timed out, returning empty list');
          return <Message>[];
        },
      );

      print('📨 Received ${loadedMessages.length} messages from server');

      // Always update messages to ensure real-time updates
      bool hasChanges = loadedMessages.length != messages.length;
      
      if (!hasChanges && loadedMessages.isNotEmpty && messages.isNotEmpty) {
        // Check if any message content changed
        for (int i = 0; i < loadedMessages.length && i < messages.length; i++) {
          if (loadedMessages[i].id != messages[i].id || 
              loadedMessages[i].message != messages[i].message) {
            hasChanges = true;
            break;
          }
        }
      }

      if (hasChanges || !isPolling) {
        print('✅ Loaded ${loadedMessages.length} messages (${isPolling ? 'polling' : 'initial'}) - ${hasChanges ? 'Changes detected' : 'No changes'}');
        setState(() {
          messages = loadedMessages;
          isLoading = false;
        });

        // Always scroll to bottom when messages change (both initial and polling)
        _scrollToBottom();
      } else if (isPolling) {
        print('🔄 No message changes detected during polling');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading messages: $e');
      print('Stack trace: $stackTrace');
      if (!isPolling) {
        setState(() {
          messages = []; // Set empty messages instead of staying in loading state
          isLoading = false;
        });
        print('📭 Showing empty messages state due to error');
      }
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

    // Create a temporary message immediately for instant UI update
    final tempMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      senderId: currentUserId!,
      receiverId: widget.selectedMember!.id,
      message: messageText,
      timestamp: DateTime.now(),
      isRead: false, // Add required isRead parameter
    );

    // Add message immediately to UI
    setState(() {
      messages.add(tempMessage);
    });

    _scrollToBottom();

    try {
      // Send to server in background
      final newMessage = await MessageService.sendMessage(
        senderId: currentUserId!,
        receiverId: widget.selectedMember!.id,
        message: messageText,
      );

      // Update with real message from server
      setState(() {
        final index = messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          messages[index] = newMessage;
        }
        isSending = false;
      });

      // Trigger immediate refresh to get any new messages
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _loadMessages(isPolling: true);
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      // Remove the temporary message if sending failed
      setState(() {
        messages.removeWhere((m) => m.id == tempMessage.id);
        isSending = false;
      });
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
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: widget.selectedMember != null
          ? Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.selectedMember!.initials,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedMember!.fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
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
      actions: [],
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra bottom padding
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
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF4ECDC4).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.selectedMember!.initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isMe 
                    ? LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Color(0xFF2A2A2A), Color(0xFF1F1F1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isMe 
                      ? Color(0xFF4ECDC4).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe 
                        ? Color(0xFF4ECDC4).withOpacity(0.2)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: isMe ? 12 : 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMe) ...[
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
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (message.timestamp != null) ...[
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp!),
                          style: GoogleFonts.poppins(
                            color: isMe ? Colors.white70 : Colors.grey[400],
                            fontSize: 10,
                          ),
                        ),
                        if (isMe) ...[
                          SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead ? Colors.white70 : Colors.grey[400],
                          ),
                        ],
                      ],
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
        color: Color(0xFF0F0F0F),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
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
}
