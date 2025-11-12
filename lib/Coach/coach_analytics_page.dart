import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../User/services/auth_service.dart';

class CoachAnalyticsPage extends StatefulWidget {
  const CoachAnalyticsPage({Key? key}) : super(key: key);

  @override
  _CoachAnalyticsPageState createState() => _CoachAnalyticsPageState();
}

class _CoachAnalyticsPageState extends State<CoachAnalyticsPage> {
  bool isLoading = true;
  Map<String, dynamic>? revenueData;
  List<Map<String, dynamic>> transactions = [];
  String? errorMessage;
  String selectedPeriod = 'month'; // month, week, year
  
  // Coach statistics
  int assignedMembers = 0;
  int activePrograms = 0;
  double averageRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> recentReviews = [];
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    final coachId = AuthService.getCurrentUserId();
    if (coachId == null) {
      setState(() {
        errorMessage = 'Unable to get coach ID';
        isLoading = false;
      });
      return;
    }
    
    await Future.wait([
      _loadRevenueData(),
      _loadTransactions(),
      _loadCoachStatistics(coachId),
      _loadCoachRatings(coachId),
      _loadCoachAvailability(coachId),
    ]);
    
    setState(() {
      isLoading = false;
    });
  }
  
  Future<void> _loadCoachStatistics(int coachId) async {
    try {
      // Load assigned members count
      final membersResponse = await http.get(
        Uri.parse('https://api.cnergy.site/coach_api.php?action=coach-assigned-members&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (membersResponse.statusCode == 200) {
        final membersData = json.decode(membersResponse.body);
        if (membersData['success'] == true) {
          final members = membersData['members'] ?? [];
          setState(() {
            assignedMembers = (members as List).length;
          });
        }
      }
    } catch (e) {
      print('Error loading coach statistics: $e');
    }
  }
  
  Future<void> _loadCoachRatings(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_rating.php?action=get_coach_ratings&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            averageRating = (data['average_rating'] ?? 0.0).toDouble();
            totalReviews = (data['total_reviews'] ?? 0);
            recentReviews = List<Map<String, dynamic>>.from(data['reviews'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading coach ratings: $e');
    }
  }
  
  Future<void> _loadCoachAvailability(int coachId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_api.php?action=get-coach-availability&coach_id=$coachId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            isAvailable = data['is_available'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Error loading coach availability: $e');
    }
  }

  Future<void> _loadRevenueData() async {
    try {
      final coachId = AuthService.getCurrentUserId();
      if (coachId == null) {
        setState(() {
          errorMessage = 'Unable to get coach ID';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_revenue.php?action=get-revenue&coach_id=$coachId&period=$selectedPeriod'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            revenueData = data['data'];
          });
        }
      }
    } catch (e) {
      print('Error loading revenue data: $e');
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final coachId = AuthService.getCurrentUserId();
      if (coachId == null) return;

      final response = await http.get(
        Uri.parse('https://api.cnergy.site/coach_revenue.php?action=get-transactions&coach_id=$coachId&limit=10'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            transactions = List<Map<String, dynamic>>.from(data['data']['transactions'] ?? []);
          });
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }

  Future<void> _onPeriodChanged(String period) async {
    setState(() {
      selectedPeriod = period;
      isLoading = true;
    });
    await _loadRevenueData();
  }

  double _getRevenueForPeriod() {
    if (revenueData == null) return 0.0;
    switch (selectedPeriod) {
      case 'week':
        return (revenueData!['weekly_revenue'] ?? 0.0).toDouble();
      case 'month':
        return (revenueData!['monthly_revenue'] ?? 0.0).toDouble();
      case 'year':
        return (revenueData!['yearly_revenue'] ?? 0.0).toDouble();
      default:
        return (revenueData!['total_revenue'] ?? 0.0).toDouble();
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Analytics',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 64),
          SizedBox(height: 16),
          Text(
            errorMessage!,
            style: GoogleFonts.poppins(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: Color(0xFF4ECDC4),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Stats Section
            _buildOverviewSection(),
            SizedBox(height: 24),
            
            // Revenue Section
            _buildRevenueSection(),
            SizedBox(height: 24),
            
            // Ratings Section
            _buildRatingsSection(),
            SizedBox(height: 24),
            
            // Recent Transactions
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String period) {
    final isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _onPeriodChanged(period);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF4ECDC4) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final revenue = _getRevenueForPeriod();
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF4ECDC4).withOpacity(0.9),
            Color(0xFF45B7D1).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Revenue',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₱${revenue.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This ${selectedPeriod}',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Members',
                '$assignedMembers',
                Icons.people,
                Color(0xFF45B7D1),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sessions',
                '${revenueData?['total_sessions'] ?? 0}',
                Icons.fitness_center,
                Color(0xFFFF6B35),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Rating',
                averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
                Icons.star,
                Color(0xFFFFD700),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRevenueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        // Period Selector
        _buildPeriodSelector(),
        SizedBox(height: 16),
        // Revenue Card
        _buildRevenueCard(),
        SizedBox(height: 16),
        // Revenue Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg/Session',
                '₱${((revenueData?['average_per_session'] ?? 0.0) as num).toStringAsFixed(0)}',
                Icons.analytics,
                Color(0xFF4ECDC4),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Active Members',
                '${revenueData?['active_members'] ?? 0}',
                Icons.people,
                Color(0xFF45B7D1),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ratings & Reviews',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalReviews > 0)
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full reviews page
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4ECDC4),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFFD700).withOpacity(0.1),
                Color(0xFFFFA500).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFFFD700).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coach Rating',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[300],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      index < averageRating.floor() 
                          ? Icons.star_rounded 
                          : index < averageRating 
                              ? Icons.star_half_rounded 
                              : Icons.star_border_rounded,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  );
                }),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$totalReviews ${totalReviews == 1 ? 'Review' : 'Reviews'}',
                  style: GoogleFonts.poppins(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (recentReviews.isNotEmpty) ...[
                SizedBox(height: 20),
                Divider(color: Colors.grey[800]),
                SizedBox(height: 16),
                ...recentReviews.take(2).map((review) => _buildReviewCard(review)),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0).toDouble();
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review['member_name'] ?? 'Anonymous',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor()
                        ? Icons.star
                        : index < rating
                            ? Icons.star_half
                            : Icons.star_border,
                    color: Color(0xFFFFD700),
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (review['comment'] != null && review['comment'].toString().isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              review['comment'],
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full transactions list
              },
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        transactions.isEmpty
            ? Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.grey[600], size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No transactions yet',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: transactions.map((transaction) => _buildTransactionCard(transaction)).toList(),
              ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF4ECDC4).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4ECDC4).withOpacity(0.2),
                  Color(0xFF45B7D1).withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Color(0xFF4ECDC4),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['member_name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF4ECDC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction['type'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF4ECDC4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      transaction['date'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${(transaction['amount'] ?? 0.0).toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4ECDC4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction['status'] == 'completed' 
                      ? Color(0xFF4ECDC4).withOpacity(0.1)
                      : transaction['status'] == 'pending'
                          ? Color(0xFFFF6B35).withOpacity(0.1)
                          : Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  transaction['status'] ?? 'pending',
                  style: GoogleFonts.poppins(
                    color: transaction['status'] == 'completed' 
                        ? Color(0xFF4ECDC4)
                        : transaction['status'] == 'pending'
                            ? Color(0xFFFF6B35)
                            : Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

