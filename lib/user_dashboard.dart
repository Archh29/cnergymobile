import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'User/qr_page.dart';
import 'User/progress_page.dart';
import 'User/profile_page.dart';
import 'User/messages_page.dart';
import 'User/routine_page.dart';
import 'User/home_page.dart';
import 'User/schedule_page.dart';
import './User/services/auth_service.dart';
import './User/services/notification_service.dart';
import './User/services/messages_service.dart';
import './User/models/notification_model.dart';
import './User/manage_subscriptions_page.dart';
import './User/pages/subscription_history_page.dart';
import './account_verification_page.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  // Notification state
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;
  int _currentPage = 1;
  bool _hasMoreNotifications = true;
  
  // Message state
  int _messageUnreadCount = 0;
  
  List<Widget> get _pages => [
     HomePage(onNavigateToQR: () {
       setState(() {
         _selectedIndex = 4; // QR tab index (updated due to new Schedule tab)
       });
     }),
     RoutinePage(),
     SchedulePage(),
     ComprehensiveDashboard(),
     QRPage(),
     ProfilePage(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      color: const Color(0xFF4ECDC4),
    ),
    NavigationItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Programs',
      color: const Color(0xFFFF6B35),
    ),
    NavigationItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Schedule',
      color: const Color(0xFF9B59B6),
    ),
    NavigationItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Progress',
      color: const Color(0xFF96CEB4),
    ),
    NavigationItem(
      icon: Icons.qr_code_scanner_outlined,
      activeIcon: Icons.qr_code_scanner,
      label: 'QR',
      color: const Color(0xFF45B7D1),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      color: const Color(0xFFE74C3C),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadSelectedIndex();
    _loadNotifications();
    _loadMessageUnreadCount();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  Future<void> _initializeAuth() async {
    await AuthService.initialize();
        
    if (!AuthService.isLoggedIn()) {
      print('User not logged in - consider redirecting to login page');
    } else {
      print('User logged in: ${AuthService.getUserFullName()}');
      print('User ID: ${AuthService.getCurrentUserId()}');
      print('Is Member: ${AuthService.isUserMember()}');
      
      // SECURITY FIX: Check if user needs account verification
      if (AuthService.needsAccountVerification()) {
        print('🔐 User needs account verification, redirecting to AccountVerificationScreen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AccountVerificationScreen()),
          );
        }
        return;
      }
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedIndex', index);
  }

  Future<void> _loadNotifications() async {
    if (_isLoadingNotifications) return;
    
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final data = await NotificationService.getNotifications(page: _currentPage);
      final notifications = (data['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      setState(() {
        if (_currentPage == 1) {
          _notifications = notifications;
        } else {
          _notifications.addAll(notifications);
        }
        _unreadCount = data['unread_count'];
        _hasMoreNotifications = data['pagination']['has_more'];
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (!_hasMoreNotifications || _isLoadingNotifications) return;
    
    setState(() {
      _currentPage++;
    });
    
    await _loadNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _currentPage = 1;
      _hasMoreNotifications = true;
    });
    await _loadNotifications();
  }

  // Real-time state update methods
  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      // Update state immediately for better UX
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: _notifications[index].id,
            message: _notifications[index].message,
            timestamp: _notifications[index].timestamp,
            statusName: 'Read',
            typeName: _notifications[index].typeName,
            isUnread: false,
          );
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }
      });

      // Call API in background
      await NotificationService.markAsRead(notificationId);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification marked as read'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // If API fails, revert the state
      await _refreshNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark notification as read'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      // Update state immediately for better UX
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          if (_notifications[index].isUnread) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }
          _notifications.removeAt(index);
        }
      });

      // Call API in background
      await NotificationService.deleteNotification(notificationId);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // If API fails, revert the state
      await _refreshNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      // Update state immediately for better UX
      setState(() {
        _notifications = _notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            message: notification.message,
            timestamp: notification.timestamp,
            statusName: 'Read',
            typeName: notification.typeName,
            isUnread: false,
          );
        }).toList();
        _unreadCount = 0;
      });

      // Call API in background
      await NotificationService.markAllAsRead();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // If API fails, revert the state
      await _refreshNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all notifications as read'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      // Update state immediately for better UX
      setState(() {
        _notifications.clear();
        _unreadCount = 0;
      });

      // Call API in background
      await NotificationService.clearAllNotifications();
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications cleared'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      // If API fails, revert the state
      await _refreshNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear all notifications'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNotificationsDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35).withOpacity(0.15),
                      const Color(0xFF4ECDC4).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // Notification Icon with Badge
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFFF8A65)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFF6B35).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF1A1A1A), width: 2),
                              ),
                              constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                              child: Text(
                                '$_unreadCount',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 16),
                    // Title and Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _notifications.isEmpty 
                                ? 'No notifications yet'
                                : '$_unreadCount unread • ${_notifications.length} total',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Menu
                    if (_notifications.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800]!.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'mark_all_read') {
                            await _markAllNotificationsAsRead();
                          } else if (value == 'clear_all') {
                            await _clearAllNotifications();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'mark_all_read',
                            child: Row(
                              children: [
                                Icon(Icons.done_all_rounded, color: Color(0xFF4ECDC4), size: 18),
                                SizedBox(width: 12),
                                Text('Mark all as read', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'clear_all',
                            child: Row(
                              children: [
                                Icon(Icons.clear_all_rounded, color: Colors.red, size: 18),
                                SizedBox(width: 12),
                                Text('Clear all', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    // Close Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications List
              Expanded(
                child: _notifications.isEmpty
                    ? _buildEmptyNotifications(isSmallScreen)
                    : _buildNotificationsList(isSmallScreen),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyNotifications(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Modern Empty State Icon
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35).withOpacity(0.1),
                  Color(0xFF4ECDC4).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFFFF6B35).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              color: Color(0xFFFF6B35),
              size: 56,
            ),
          ),
          SizedBox(height: 24),
          // Title
          Text(
            'All caught up!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          // Subtitle
          Text(
            'You have no new notifications.\nWe\'ll notify you when something important happens.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.grey[400],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          // Decorative Elements
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(bool isSmallScreen) {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFFFF6B35),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _notifications.length + (_hasMoreNotifications ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _buildLoadMoreButton(isSmallScreen);
          }
          
          final notification = _notifications[index];
          return _buildNotificationItem(notification, isSmallScreen);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isUnread 
            ? Color(0xFF2A2A2A)
            : Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
        border: notification.isUnread 
            ? Border.all(color: Color(0xFFFF6B35).withOpacity(0.3), width: 1)
            : Border.all(color: Colors.grey[800]!.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (notification.isUnread) {
              await _markNotificationAsRead(notification.id);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with modern styling
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getNotificationColor(notification.typeName).withOpacity(0.2),
                        _getNotificationColor(notification.typeName).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getNotificationColor(notification.typeName).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.typeName),
                    color: _getNotificationColor(notification.typeName),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message (using display message to hide question marks)
                      Text(
                        notification.getDisplayMessage(),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      // Time and Type
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification.typeName).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notification.typeName.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getNotificationColor(notification.typeName),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            notification.getFormattedTime(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  children: [
                    if (notification.isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 8),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[800]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'mark_read' && notification.isUnread) {
                          await _markNotificationAsRead(notification.id);
                        } else if (value == 'delete') {
                          await _deleteNotification(notification.id);
                        }
                      },
                      itemBuilder: (context) => [
                        if (notification.isUnread)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.done_rounded, color: Color(0xFF4ECDC4), size: 18),
                                SizedBox(width: 12),
                                Text('Mark as read', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 12),
                              Text('Delete', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildLoadMoreButton(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
      child: _isLoadingNotifications
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFF6B35)),
                ),
              ),
            )
          : ElevatedButton(
              onPressed: _loadMoreNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
              child: Text(
                'Load More',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'info':
        return const Color(0xFF4ECDC4);
      case 'warning':
        return const Color(0xFFFFB74D);
      case 'success':
        return const Color(0xFF96CEB4);
      case 'error':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  void _showSubscriptionsMenu() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
        
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Subscription Options',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 16,
                  vertical: isSmallScreen ? 4 : 8,
                ),
                leading: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.subscriptions,
                    color: const Color(0xFF4ECDC4),
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                title: Text(
                  'View Plans',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                subtitle: Text(
                  'Browse available subscription plans',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageSubscriptionsPage(),
                    ),
                  );
                },
              ),
              if (AuthService.isLoggedIn()) ...[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 16,
                    vertical: isSmallScreen ? 4 : 8,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF45B7D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: const Color(0xFF45B7D1),
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  title: Text(
                    'My Subscriptions',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  subtitle: Text(
                    'View your subscription history and status',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionHistoryPage(),
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: isSmallScreen ? 16 : 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMessages() {
    // Check if user is logged in and get current user ID
    if (!AuthService.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to access messages'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to get user information'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Navigate to messages and refresh dashboard when returning
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagesPage(currentUserId: currentUserId),
      ),
    ).then((_) {
      // Refresh notifications and message count when returning from messages
      print('🔄 Returning from messages - refreshing counts...');
      // Add a small delay to ensure server has processed the read status
      Future.delayed(Duration(milliseconds: 500), () {
        _loadNotifications();
        _loadMessageUnreadCount();
      });
    });
  }

  Future<void> _loadMessageUnreadCount() async {
    print('🔄 Loading message unread count...');
    if (!AuthService.isLoggedIn()) {
      print('❌ User not logged in, skipping message unread count');
      return;
    }
    
    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId == null) {
      print('❌ No current user ID, skipping message unread count');
      return;
    }

    print('📱 Getting conversations for user ID: $currentUserId');
    try {
      // Get conversations and calculate unread count from them
      final conversations = await MessageService.getConversations(currentUserId);
      final unreadCount = conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
      print('✅ Message unread count calculated from conversations: $unreadCount');
      if (mounted) {
        setState(() {
          _messageUnreadCount = unreadCount;
        });
        print('✅ Message unread count updated in UI: $_messageUnreadCount');
      }
    } catch (e) {
      print('❌ Error loading message unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 375 || screenHeight < 667;
    final isThinScreen = screenWidth < 350;
        
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(isSmallScreen, isThinScreen),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildModernBottomNav(isSmallScreen, isThinScreen),
      floatingActionButton: _buildModernFAB(isSmallScreen),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmallScreen, bool isThinScreen) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F0F),
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: isSmallScreen ? 70 : 80,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: isSmallScreen ? 16 : 20,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              "CNERGY",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : (isThinScreen ? 16 : 22),
                letterSpacing: isThinScreen ? 1.0 : 1.5,
                color: Colors.white,
              ),
              overflow: TextOverflow.visible,
              softWrap: false,
              maxLines: 1,
              textAlign: TextAlign.start,
            ),
          ),
          const Spacer(),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: isSmallScreen ? 4 : 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.subscriptions,
                color: const Color(0xFF4ECDC4),
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            onPressed: _showSubscriptionsMenu,
            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 32 : 40,
              minHeight: isSmallScreen ? 32 : 40,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: isSmallScreen ? 12 : 16),
          child: IconButton(
            icon: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1A1A1A), width: 1),
                      ),
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 12 : 16,
                        minHeight: isSmallScreen ? 12 : 16,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 8 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showNotificationsDialog,
            padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
            constraints: BoxConstraints(
              minWidth: isSmallScreen ? 32 : 40,
              minHeight: isSmallScreen ? 32 : 40,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernBottomNav(bool isSmallScreen, bool isThinScreen) {
    return Container(
      height: isSmallScreen ? 75 : 90,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navigationItems.length, (index) {
            final item = _navigationItems[index];
            final isSelected = _selectedIndex == index;
                        
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  await _saveSelectedIndex(index);
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isThinScreen ? 4 : (isSmallScreen ? 8 : 12),
                     vertical: isSmallScreen ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: isSelected ? item.color.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? item.color : Colors.grey[400],
                          size: isSmallScreen ? 18 : 22,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Flexible(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: isThinScreen ? 8 : (isSmallScreen ? 9 : 10),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? item.color : Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildModernFAB(bool isSmallScreen) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        width: isSmallScreen ? 48 : 56,
        height: isSmallScreen ? 48 : 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _navigateToMessages, // Updated to use the new method
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: isSmallScreen ? 20 : 24,
              ),
              if (_messageUnreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _messageUnreadCount > 99 ? '99+' : _messageUnreadCount.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}