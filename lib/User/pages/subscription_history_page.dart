import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/subscription_service.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionHistoryPage> createState() => _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionData;
  Map<String, dynamic>? _currentSubscription;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Debug: Starting to load subscription data...');
      _userId = await SubscriptionService.getUserId();
      print('Debug: Retrieved user ID: $_userId');
      
      if (_userId > 0) {
        print('Debug: User ID is valid, fetching subscription history...');
        final historyData = await SubscriptionService.getSubscriptionHistory(_userId);
        print('Debug: Retrieved subscription history: $historyData');
        
        print('Debug: Fetching current subscription...');
        final currentData = await SubscriptionService.getCurrentSubscription(_userId);
        print('Debug: Retrieved current subscription: $currentData');
        
        setState(() {
          _subscriptionData = historyData;
          _currentSubscription = currentData;
          _isLoading = false;
        });
      } else {
        print('Debug: User ID is 0 or invalid, skipping data fetch');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading subscription data: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        title: Text(
          'My Requests & Subscription',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSubscriptionData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_subscriptionData == null) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptionData,
      color: const Color(0xFF4CAF50),
      backgroundColor: const Color(0xFF2D2D2D),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 20),
            _buildSectionTitle('Request History'),
            const SizedBox(height: 12),
            _buildRequestsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    if (_currentSubscription == null) {
      return _buildNoActiveSubscriptionCard();
    }

    final activeCoachData = _currentSubscription!['active_coach'];
    final activeCoach = (activeCoachData is Map<String, dynamic>) ? activeCoachData : null;
    final subscription = _currentSubscription!['subscription'];
    final subscriptionStatus = _currentSubscription!['subscription_status'] ?? 'Inactive';
    final daysRemaining = _currentSubscription!['days_remaining'] ?? 0;
    final isPremium = _currentSubscription!['is_premium'] ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1),
            const Color(0xFF2E7D32).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subscriptionStatus,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPremium ? const Color(0xFF4CAF50) : const Color(0xFF757575),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : 'BASIC',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (activeCoach != null) ...[
            const SizedBox(height: 16),
            _buildActiveCoachInfo(activeCoach),
          ],
          if (subscription != null) ...[
            const SizedBox(height: 16),
            _buildSubscriptionInfo(subscription, daysRemaining),
          ],
        ],
      ),
    );
  }

  Widget _buildNoActiveSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF757575).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF757575),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Subscription',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have an active coach connection or subscription at the moment.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCoachInfo(Map<String, dynamic> coach) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Coach',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  (coach['coach_name'] ?? 'C').substring(0, 1).toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach['coach_name'] ?? 'Unknown Coach',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      coach['coach_email'] ?? '',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB0B0B0),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (coach['expires_at'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: const Color(0xFF4CAF50),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expires: ${SubscriptionService.formatDate(coach['expires_at'])}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB0B0B0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (coach['remaining_sessions'] != null && coach['rate_type'] == 'package') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: const Color(0xFF4CAF50),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sessions: ${coach['remaining_sessions']}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFB0B0B0),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(Map<String, dynamic> subscription, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Details',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Plan',
                  subscription['plan_name'] ?? 'Unknown',
                  Icons.card_membership,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Price',
                  '\$${subscription['price'] ?? '0'}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Start Date',
                  SubscriptionService.formatDate(subscription['start_date']),
                  Icons.calendar_today,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'End Date',
                  SubscriptionService.formatDate(subscription['end_date']),
                  Icons.event,
                ),
              ),
            ],
          ),
          if (daysRemaining > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$daysRemaining days remaining',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4CAF50),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF4CAF50),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRequestsList() {
    final requests = _subscriptionData!['requests'] as List<dynamic>? ?? [];
    
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status_display'] ?? 'Unknown';
    final statusColor = SubscriptionService.getStatusColor(status);
    final statusIcon = SubscriptionService.getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusIcon,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['coach_name'] ?? 'Unknown Coach',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        color: Color(int.parse(statusColor.replaceFirst('#', '0xFF'))),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                SubscriptionService.formatDate(request['requested_at']),
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB0B0B0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRequestDetails(request),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(Map<String, dynamic> request) {
    return Column(
      children: [
        _buildDetailRow('Coach Approval', request['coach_approval']),
        _buildDetailRow('Staff Approval', request['staff_approval']),
        if (request['expires_at'] != null)
          _buildDetailRow('Expires', SubscriptionService.formatDate(request['expires_at'])),
        if (request['remaining_sessions'] != null && request['rate_type'] == 'package')
          _buildDetailRow('Sessions', '${request['remaining_sessions']} remaining'),
        if (request['rate_type'] != null)
          _buildDetailRow('Rate Type', request['rate_type'].toString().toUpperCase()),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: const Color(0xFFB0B0B0),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.history,
            color: const Color(0xFF757575),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No Requests Found',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any coach requests yet.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFF44336),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load subscription data. Please try again.',
            style: GoogleFonts.poppins(
              color: const Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptionData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
