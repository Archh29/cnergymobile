import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'services/achievements_service.dart';

class AchievementsPage extends StatefulWidget {
  @override
  _AchievementsPageState createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  AchievementsData? _achievementsData;
  bool _isLoading = true;
  String? _error;

  final List<String> _filters = ['All', 'Unlocked', 'Locked', 'Gold', 'Silver', 'Bronze'];

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

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
    _loadAchievements();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final achievementsData = await AchievementsService.getAchievements();
      
      setState(() {
        _achievementsData = achievementsData;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _forceCheckAchievements() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await AchievementsService.forceCheckAchievements();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Force check completed. ${result['count']} new achievements awarded.'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload achievements after force check
      await _loadAchievements();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error force checking achievements: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Achievement> get _filteredAchievements {
    if (_achievementsData == null) return [];
    
    final achievements = _achievementsData!.achievements;
    
    if (_selectedFilter == 'Unlocked') {
      return achievements.where((a) => a.unlocked).toList();
    } else if (_selectedFilter == 'Locked') {
      return achievements.where((a) => !a.unlocked).toList();
    } else if (_selectedFilter == 'Gold' || _selectedFilter == 'Silver' || _selectedFilter == 'Bronze') {
      return achievements.where((a) => a.level == _selectedFilter).toList();
    }
    return achievements;
  }

  int get _totalPoints {
    return _achievementsData?.totalPoints ?? 0;
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'log-in':
        return Icons.login;
      case 'calendar':
        return Icons.event;
      case 'dumbbell':
        return Icons.fitness_center;
      case 'star':
        return Icons.star;
      case 'medal':
        return Icons.emoji_events;
      case 'award':
        return Icons.military_tech;
      case 'clipboard':
        return Icons.assignment;
      case 'barbell':
        return Icons.sports_gymnastics;
      case 'trophy':
        return Icons.emoji_events;
      case 'flag':
        return Icons.flag;
      case 'handshake':
        return Icons.handshake;
      case 'message-circle':
        return Icons.message;
      default:
        return Icons.emoji_events;
    }
  }

  void _showAchievementDetails(Achievement achievement) {
    if (achievement.unlocked) {
      _confettiController.play();
    }
    
    showDialog(
      context: context,
      builder: (_) => Stack(
        alignment: Alignment.center,
        children: [
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(achievement.color).withOpacity(0.8),
                          Color(achievement.color).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      achievement.unlocked 
                          ? _getIconData(achievement.icon)
                          : Icons.lock,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    achievement.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(achievement.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${achievement.level} • ${achievement.points} pts',
                      style: GoogleFonts.poppins(
                        color: Color(achievement.color),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    achievement.description,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!achievement.unlocked) ...[
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: Column(
                        children: [
                          Text(
                            'Progress',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: achievement.progress,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(Color(achievement.color)),
                            minHeight: 6,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${(achievement.progress * 100).toInt()}% Complete',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(achievement.color),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (achievement.unlocked)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [Color(achievement.color), Colors.white, Colors.amber],
              numberOfParticles: 30,
              emissionFrequency: 0.05,
              gravity: 0.1,
              blastDirection: -pi / 2,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
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
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAchievements,
          ),
          IconButton(
            icon: Icon(Icons.auto_fix_high, color: Colors.white),
            onPressed: _forceCheckAchievements,
            tooltip: 'Force Check Achievements',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error loading achievements',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAchievements,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF6B35),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
              // Header with stats
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B35).withOpacity(0.8), Color(0xFFFF8E53).withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B35).withOpacity(0.3),
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
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Achievements',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$_totalPoints total points earned',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${_achievementsData?.unlockedCount ?? 0}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Unlocked',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Filter chips
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return Container(
                      margin: EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        selectedColor: Color(0xFFFF6B35).withOpacity(0.2),
                        backgroundColor: Color(0xFF1A1A1A),
                        side: BorderSide(
                          color: isSelected ? Color(0xFFFF6B35) : Colors.transparent,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // Achievements grid
              Expanded(
                child: GridView.builder(
                  itemCount: _filteredAchievements.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final achievement = _filteredAchievements[index];
                    return GestureDetector(
                      onTap: () => _showAchievementDetails(achievement),
                      child: Hero(
                        tag: achievement.title,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: achievement.unlocked
                                ? Border.all(color: Color(achievement.color), width: 1)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with icon and level
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: achievement.unlocked
                                        ? [
                                            Color(achievement.color).withOpacity(0.8),
                                            Color(achievement.color).withOpacity(0.6),
                                          ]
                                        : [
                                            Colors.grey[800]!,
                                            Colors.grey[900]!,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        achievement.unlocked 
                                            ? _getIconData(achievement.icon)
                                            : Icons.lock,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          achievement.level,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        achievement.title,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        achievement.category,
                                        style: GoogleFonts.poppins(
                                          color: Color(achievement.color),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Spacer(),
                                      if (!achievement.unlocked) ...[
                                        LinearProgressIndicator(
                                          value: achievement.progress,
                                          backgroundColor: Colors.grey[800],
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(achievement.color)),
                                          minHeight: 4,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${(achievement.progress * 100).toInt()}%',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ] else ...[
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Color(achievement.color),
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${achievement.points} pts',
                                              style: GoogleFonts.poppins(
                                                color: Color(achievement.color),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}