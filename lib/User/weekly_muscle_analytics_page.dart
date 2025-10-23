import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/weekly_muscle_analytics_model.dart';
import './group_detail_page.dart';
import './services/weekly_muscle_analytics_service.dart';
import './training_focus_settings_page.dart';

class WeeklyMuscleAnalyticsPage extends StatefulWidget {
  const WeeklyMuscleAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<WeeklyMuscleAnalyticsPage> createState() => _WeeklyMuscleAnalyticsPageState();
}

class _WeeklyMuscleAnalyticsPageState extends State<WeeklyMuscleAnalyticsPage> {
  WeeklyMuscleAnalyticsData? _data;
  bool _loading = true;
  String? _error;
  DateTime _weekStart = _mondayOf(DateTime.now());
  String _trainingFocus = 'full_body';

  final Map<String, String> _imageByName = {
    'Chest': 'https://api.cnergy.site/image-servers.php?image=68e4bdc995d2a_1759821257.jpg',
    'Back': 'https://api.cnergy.site/image-servers.php?image=68e3601c90c68_1759731740.jpg',
    'Shoulder': 'https://api.cnergy.site/image-servers.php?image=68e35ff3c80bf_1759731699.jpg',
    'Core': 'https://api.cnergy.site/image-servers.php?image=68e4bdbf3044e_1759821247.jpg',
    'Arms': 'https://api.cnergy.site/image-servers.php?image=68e4bdaac1683_1759821226.jpg',
    'Legs': 'https://api.cnergy.site/image-servers.php?image=68e4bdb72737e_1759821239.jpg',
    'Biceps': 'https://api.cnergy.site/image-servers.php?image=68e35fc7a61a1_1759731655.jpg',
    'Triceps': 'https://api.cnergy.site/image-servers.php?image=68f64ea977586_1760972457.jpg',
    'Forearms': 'https://api.cnergy.site/image-servers.php?image=68f64eb18b226_1760972465.jpg',
    'Quads': 'https://api.cnergy.site/image-servers.php?image=68f64dad93d06_1760972205.jpg',
    'Hamstring': 'https://api.cnergy.site/image-servers.php?image=68f64db61bead_1760972214.jpg',
    'Glutes': '',
    'Calves': 'https://api.cnergy.site/image-servers.php?image=68f64d9e5c757_1760972190.jpg',
    'Upper Chest': 'https://api.cnergy.site/image-servers.php?image=68f64dd7e8266_1760972247.jpg',
    'Middle Chest': 'https://api.cnergy.site/image-servers.php?image=68f64de00c60e_1760972256.jpg',
    'Lower Chest': 'https://api.cnergy.site/image-servers.php?image=68f64dcc3d660_1760972236.jpg',
    'Upper Back': '',
    'Mid Back': '',
    'Lower Back': '',
    'Lats': 'https://api.cnergy.site/image-servers.php?image=68f64d9478f41_1760972180.jpg',
    'Front Shoulders': '',
    'Side Shoulders': '',
    'Rear Shoulders': '',
    'Brachialis': '',
    'Abs': '',
    'Obliques': 'https://api.cnergy.site/image-servers.php?image=68f64e10591ac_1760972304.jpg',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await WeeklyMuscleAnalyticsService.getWeekly(weekStart: _weekStart);
      
      // Extract training focus from data
      _trainingFocus = data.trainingFocus ?? 'full_body';
      
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static DateTime _mondayOf(DateTime d) {
    final wd = d.weekday; // 1=Mon
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: wd - 1));
  }

  void _prevWeek() { setState(() { _weekStart = _weekStart.subtract(const Duration(days: 7)); }); _load(); }
  void _nextWeek() { setState(() { _weekStart = _weekStart.add(const Duration(days: 7)); }); _load(); }
  void _thisWeek() { setState(() { _weekStart = _mondayOf(DateTime.now()); }); _load(); }

  String _formatDate(String ymd) {
    // ymd is expected as YYYY-MM-DD from backend
    try {
      final parts = ymd.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final dt = DateTime(y, m, d);
      const months = [
        'January','February','March','April','May','June','July','August','September','October','November','December'
      ];
      final month = months[dt.month - 1];
      return '$month ${dt.day}, ${dt.year}';
    } catch (_) {
      return ymd;
    }
  }

  void _openFilterSheet() async {
    DateTime tempSelected = _weekStart;
    String selectedMonth = '';
    List<Map<String, dynamic>> weeksInMonth = [];
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Week', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () { Navigator.pop(ctx); },
                          icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Select
                  Text('Quick Select', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _vibrantChip('This Week', 
                      onTap: () { 
                        tempSelected = _mondayOf(DateTime.now()); 
                        setModalState((){}); 
                      },
                      isSelected: tempSelected == _mondayOf(DateTime.now()),
                      color: const Color(0xFF00D4AA),
                    ),
                    _vibrantChip('Last Week', 
                      onTap: () { 
                        tempSelected = _mondayOf(DateTime.now().subtract(const Duration(days: 7))); 
                        setModalState((){}); 
                      },
                      isSelected: tempSelected == _mondayOf(DateTime.now().subtract(const Duration(days: 7))),
                      color: const Color(0xFF6366F1),
                    ),
                    _vibrantChip('2 Weeks Ago', 
                      onTap: () { 
                        tempSelected = _mondayOf(DateTime.now().subtract(const Duration(days: 14))); 
                        setModalState((){}); 
                      },
                      isSelected: tempSelected == _mondayOf(DateTime.now().subtract(const Duration(days: 14))),
                      color: const Color(0xFFF59E0B),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Month Selection
                  Text('Select Month', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 24, // 2 years
                      itemBuilder: (context, index) {
                        final month = DateTime.now().subtract(Duration(days: 30 * index));
                        final monthName = _getMonthName(month);
                        final isSelected = selectedMonth == monthName;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              selectedMonth = monthName;
                              weeksInMonth = _getWeeksInMonth(month);
                              setModalState((){});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected ? const LinearGradient(
                                  colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ) : null,
                                color: isSelected ? null : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF00D4AA) : const Color(0xFF2A2A2A),
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF00D4AA).withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ] : null,
                              ),
                              child: Text(
                                monthName,
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Week Selection
                  if (weeksInMonth.isNotEmpty) ...[
                    Text('Select Week', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: weeksInMonth.length,
                        itemBuilder: (context, index) {
                          final week = weeksInMonth[index];
                          final isSelected = tempSelected == week['start'];
                          
                          return GestureDetector(
                            onTap: () {
                              tempSelected = week['start'];
                              setModalState((){});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: isSelected ? const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ) : null,
                                color: isSelected ? null : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF2A2A2A),
                                  width: 2,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ] : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Week ${index + 1}',
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white : Colors.white70,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    week['range'],
                                    style: GoogleFonts.poppins(
                                      color: isSelected ? Colors.white70 : Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Apply Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4AA).withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () { 
                        setState(() { _weekStart = tempSelected; }); 
                        _load(); 
                        Navigator.pop(ctx); 
                      },
                      child: Text('Apply Filter', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        title: Text('Weekly Muscle Analytics', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openTrainingFocusSettings,
            tooltip: 'Training Focus Settings',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _openFilterSheet,
            tooltip: 'Filter week',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load analytics', style: GoogleFonts.poppins(color: Colors.redAccent)),
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(data),
          const SizedBox(height: 12),
          _buildOverallKPIs(data),
          const SizedBox(height: 16),
          _buildGroupsGrid(data),
          const SizedBox(height: 16),
          _buildSmartSummary(data),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(WeeklyMuscleAnalyticsData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Summary', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              if (_trainingFocus != 'full_body')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF6366F1).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location, color: Color(0xFF6366F1), size: 12),
                      SizedBox(width: 4),
                      Text(
                        _getTrainingFocusLabel(_trainingFocus),
                        style: GoogleFonts.poppins(
                          color: Color(0xFF6366F1),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_getContextualSummary(data), style: GoogleFonts.poppins(color: Colors.white70)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Check if we have enough space for horizontal layout
              final hasEnoughSpace = constraints.maxWidth > 300;
              
              if (hasEnoughSpace) {
                // Horizontal layout for larger screens
                return Row(
                  children: [
                    Expanded(
                      child: _chip('Week: ${_formatDate(data.weekStart)} → ${_formatDate(data.weekEnd)}'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: _thisWeek,
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                        label: Text('Live Data', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Vertical layout for smaller screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chip('Week: ${_formatDate(data.weekStart)} → ${_formatDate(data.weekEnd)}'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D4AA).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: _thisWeek,
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                        label: Text('Live Data', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsGrid(WeeklyMuscleAnalyticsData data) {
    final avg = data.avgGroupLoad;
    
    // Filter groups based on tracked muscle groups (custom selection)
    final trackedIds = data.trackedMuscleGroups;
    final displayGroups = (trackedIds != null && trackedIds.isNotEmpty)
        ? data.groups.where((g) => trackedIds.contains(g.groupId)).toList()
        : data.groups; // Show all if no custom tracking
    
    // Show message if custom selection has no data
    if (displayGroups.isEmpty && trackedIds != null && trackedIds.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Muscle Groups', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center, color: Colors.white54, size: 48),
                SizedBox(height: 12),
                Text(
                  'No workout data yet',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Train your selected muscle groups to see data here!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Muscle Groups', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            if (trackedIds != null && trackedIds.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF00D4AA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF00D4AA).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list, color: Color(0xFF00D4AA), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Custom Focus',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF00D4AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayGroups.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2, // Further increased to 1.2 for better fit
          ),
          itemBuilder: (context, i) {
            final g = displayGroups[i];
            return GestureDetector(
              onTap: () => _openGroupDetail(context, g),
              child: _glowTile(
                name: g.groupName,
                load: g.totalLoad,
                sets: g.totalSets,
                exercises: g.totalExercises,
                reps: _extractRepsFromGroupStat(g),
                avg: avg,
                imageUrl: g.imageUrl ?? (_imageByName[g.groupName] ?? ''),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openGroupDetail(BuildContext context, WeeklyMuscleGroupStat group) async {
    final allMuscles = _data?.muscles ?? [];
    // Primary filter: exact parent id match
    List<WeeklyMuscleStat> muscles = allMuscles.where((m) => (m.groupId ?? -1) == group.groupId).toList();
    // Fallbacks if backend didn’t include groupId on muscles
    if (muscles.isEmpty) {
      muscles = allMuscles.where((m) => _isChildOfGroup(group.groupName, m.muscleName)).toList();
    }
    if (muscles.isEmpty) {
      final key = group.groupName.toLowerCase();
      muscles = allMuscles.where((m) => m.muscleName.toLowerCase().contains(key)).toList();
    }
    final avg = _data?.avgGroupLoad ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => GroupDetailPage(
          group: group,
          muscles: muscles,
          avgGroupLoad: avg,
          imageByName: _imageByName,
        ),
      ),
    );
  }

  Widget _glowTile({
    required String name,
    required double load,
    required int sets,
    required int exercises,
    required int reps,
    required double avg,
    String? imageUrl,
  }) {
    final freq = _currentSessionsForTile(_data, name);
    final ev = _effectiveVolume(load, freq);
    final status = _classifyByEV(ev, sets, freq, avg);
    final glow = _glowFor(status);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: glow.glowColor.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.glowColor.withOpacity(glow.opacity * 0.6),
                blurRadius: glow.blur * 1.5,
                spreadRadius: glow.spread * 1.2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with responsive height
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: double.infinity,
                    height: constraints.maxWidth * 0.5, // Increased back to 0.5 for better visibility
                    child: _thumbnail(imageUrl),
                  ),
                ),
                const SizedBox(height: 4),
                // Muscle name
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white, 
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                // Compact metrics row
                Row(
                  children: [
                    Expanded(
                      child: _compactMetric('Sets', sets.toString()),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _compactMetric('Reps', reps.toString()),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // EV and Status row
                Row(
                  children: [
                    Expanded(
                      child: _compactMetric('EV', _compactNum(ev)),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: _statusPill(status),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbnail(String? url) {
    final has = (url != null && url.isNotEmpty);
    return Container(
      color: const Color(0xFF303030),
      child: has
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 28),
                );
              },
            )
          : Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 22)),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _compactMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value, 
            style: GoogleFonts.poppins(
              color: Colors.white, 
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label, 
            style: GoogleFonts.poppins(
              color: Colors.white70, 
              fontSize: 8, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallKPIs(WeeklyMuscleAnalyticsData data) {
    // Filter groups based on tracked muscle groups (custom selection)
    final trackedIds = data.trackedMuscleGroups;
    
    print('🔍 Overall KPIs - trackedIds: $trackedIds');
    print('🔍 Overall KPIs - trainingFocus: ${data.trainingFocus}');
    print('🔍 Overall KPIs - total groups: ${data.groups.length}');
    
    final displayGroups = (trackedIds != null && trackedIds.isNotEmpty)
        ? data.groups.where((g) => trackedIds.contains(g.groupId)).toList()
        : data.groups;
    
    print('🔍 Overall KPIs - filtered groups: ${displayGroups.length}');
    print('🔍 Overall KPIs - filtered group names: ${displayGroups.map((g) => g.groupName).toList()}');
    
    final k = _computeKPIs(data, filteredGroups: displayGroups);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overall Results', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              if (trackedIds != null && trackedIds.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4AA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF00D4AA).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, color: Color(0xFF00D4AA), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF00D4AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpiTile('Groups Trained', k.totalGroupsTrained.toString()),
              _kpiTile('Training Balance', k.balanceLabel),
              _kpiTile('Strongest Area', k.strongestArea),
              _kpiTile('Weakest Area', k.weakestArea),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label, 
            style: GoogleFonts.poppins(
              color: Colors.white70, 
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: GoogleFonts.poppins(
              color: Colors.white, 
              fontSize: 14, 
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _KPIs _computeKPIs(WeeklyMuscleAnalyticsData data, {List<WeeklyMuscleGroupStat>? filteredGroups}) {
    final groups = filteredGroups ?? data.groups;
    if (groups.isEmpty) return _KPIs(0, 'No Data', 'None', 'None');

    // Compute EV-based status per group
    final avg = data.avgGroupLoad;
    int focused=0, balanced=0, weak=0, neglected=0;
    String strongest = 'None';
    List<String> weakestNames = [];

    // Strongest/weakest by EV; prefer neglected as weakest
    double maxEv = -1;
    double minEv = double.infinity;
    for (final g in groups) {
      final ev = _effectiveVolume(g.totalLoad, g.sessions);
      final s = _classifyByEV(ev, g.totalSets, g.sessions, avg);
      switch (s) {
        case _Status.focused: focused++; break;
        case _Status.balanced: balanced++; break;
        case _Status.weak: weak++; break;
        case _Status.neglected: neglected++; break;
      }
      if (ev > maxEv) { maxEv = ev; strongest = g.groupName; }
      // collect weakest candidates
      if (s == _Status.neglected) {
        weakestNames.add(g.groupName);
      } else {
        if (ev < minEv) {
          minEv = ev;
        }
      }
    }

    final totalGroupsTrained = groups.where((g)=> g.totalSets>0 && g.totalLoad>0).length;

    String balanceLabel;
    if (neglected > 0) balanceLabel = 'Imbalanced';
    else if (balanced >= (groups.length * 0.5)) balanceLabel = 'Balanced';
    else if (focused > weak) balanceLabel = 'Focused';
    else if (weak >= focused) balanceLabel = 'Undertrained';
    else balanceLabel = 'Balanced';
    // If any neglected, show all neglected as weakest; else show all groups tied at min EV (within epsilon)
    String weakest;
    if (weakestNames.isNotEmpty) {
      weakest = weakestNames.join(', ');
    } else {
      const double eps = 1e-6;
      final ties = groups.where((g){
        final ev = _effectiveVolume(g.totalLoad, g.sessions);
        return (ev - minEv).abs() <= eps;
      }).map((g)=>g.groupName).toList();
      weakest = ties.join(', ');
    }

    return _KPIs(totalGroupsTrained, balanceLabel, strongest, weakest);
  }

  Widget _statusPill(_Status status) {
    final text = {
      _Status.focused: 'Focused',
      _Status.balanced: 'Balanced',
      _Status.weak: 'Undertrained',
      _Status.neglected: 'Neglected',
    }[status]!;
    final color = {
      _Status.focused: const Color(0xFF00D4AA), // teal
      _Status.balanced: const Color(0xFF6366F1), // purple
      _Status.weak: const Color(0xFFF59E0B), // orange
      _Status.neglected: const Color(0xFFEF4444), // red
    }[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text, 
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _Status _classify(double load, int sets, double avgLoad) {
    if (sets == 0 || load <= 0) return _Status.neglected;
    if (avgLoad <= 0) return _Status.balanced;
    if (load >= 1.5 * avgLoad) return _Status.focused;
    if (load <= 0.5 * avgLoad) return _Status.weak;
    return _Status.balanced;
  }

  _Glow _glowFor(_Status status) {
    switch (status) {
      case _Status.focused:
        return _Glow(const Color(0xFFEF4444), 0.6, 18, 1.5);
      case _Status.balanced:
        return _Glow(const Color(0xFFF59E0B), 0.45, 12, 1.0);
      case _Status.weak:
        return _Glow(const Color(0xFF10B981), 0.45, 12, 1.0);
      case _Status.neglected:
        return _Glow(const Color(0xFF6B7280), 0.25, 6, 0.5);
    }
  }

  int _extractRepsFromGroupStat(WeeklyMuscleGroupStat g) {
    // Fallback heuristic if backend omits reps
    return g.totalReps ?? (g.totalSets * 9);
  }

  int _extractRepsFromMuscleStat(WeeklyMuscleStat m) {
    return m.totalReps ?? (m.totalSets * 9);
  }

  Widget _buildSmartSummary(WeeklyMuscleAnalyticsData data) {
    // Filter groups based on tracked muscle groups (custom selection)
    final trackedIds = data.trackedMuscleGroups;
    final displayGroups = (trackedIds != null && trackedIds.isNotEmpty)
        ? data.groups.where((g) => trackedIds.contains(g.groupId)).toList()
        : data.groups;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Smart Summary', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              if (trackedIds != null && trackedIds.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4AA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF00D4AA).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, color: Color(0xFF00D4AA), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'Filtered',
                        style: GoogleFonts.poppins(
                          color: Color(0xFF00D4AA),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_composeSmartSummary(data, filteredGroups: displayGroups), style: GoogleFonts.poppins(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _chip(String text, {VoidCallback? onTap, bool isSelected = false}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: isSelected ? const LinearGradient(
          colors: [Color(0xFF00D4AA), Color(0xFF00A8CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        color: isSelected ? null : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF00D4AA) : const Color(0xFF3A3A3A),
          width: 1.5,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        text, 
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.white70, 
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
    return onTap == null ? content : GestureDetector(onTap: onTap, child: content);
  }

  Widget _vibrantChip(String text, {VoidCallback? onTap, bool isSelected = false, required Color color}) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: isSelected ? LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        color: isSelected ? null : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : const Color(0xFF2A2A2A),
          width: 2,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Text(
        text, 
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.white70, 
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
    return onTap == null ? content : GestureDetector(onTap: onTap, child: content);
  }

  Future<void> _openTrainingFocusSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => TrainingFocusSettingsPage()),
    );
    
    // Reload data if settings were changed
    if (result == true) {
      _load();
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getTrainingFocusLabel(String focus) {
    switch (focus) {
      case 'upper_body':
        return 'Upper Body';
      case 'lower_body':
        return 'Lower Body';
      case 'custom':
        return 'Custom Focus';
      default:
        return 'Full Body';
    }
  }

  String _getContextualSummary(WeeklyMuscleAnalyticsData data) {
    final trackedIds = data.trackedMuscleGroups;
    
    print('🔍 Contextual Summary - trackedIds: $trackedIds');
    print('🔍 Contextual Summary - trainingFocus: ${data.trainingFocus}');
    
    // If custom selection is active, generate custom summary
    if (trackedIds != null && trackedIds.isNotEmpty) {
      final displayGroups = data.groups.where((g) => trackedIds.contains(g.groupId)).toList();
      
      if (displayGroups.isEmpty) {
        return 'No training data for your selected muscle groups this week.';
      }
      
      // Generate contextual summary
      final groupNames = displayGroups.map((g) => g.groupName).toList();
      final trained = displayGroups.where((g) => g.totalSets > 0).length;
      final totalSelected = trackedIds.length;
      
      String coverage = trained == totalSelected 
          ? 'You trained all your tracked muscle groups!' 
          : 'You trained $trained out of $totalSelected tracked groups.';
      
      // Find best performing group
      final avg = data.avgGroupLoad;
      final best = displayGroups.reduce((a, b) => 
        _effectiveVolume(a.totalLoad, a.sessions) > _effectiveVolume(b.totalLoad, b.sessions) ? a : b
      );
      
      String performance = ' Best focus: ${best.groupName} (${best.totalSets} sets).';
      
      return coverage + performance;
    }
    
    // Otherwise use the default summary from backend
    return data.summary;
  }

  List<Map<String, dynamic>> _getWeeksInMonth(DateTime month) {
    final weeks = <Map<String, dynamic>>[];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    
    // Find first Monday of the month or before
    DateTime currentMonday = _mondayOf(firstDay);
    if (currentMonday.isAfter(firstDay)) {
      currentMonday = currentMonday.subtract(const Duration(days: 7));
    }
    
    while (currentMonday.isBefore(lastDay) || currentMonday.isAtSameMomentAs(lastDay)) {
      final weekEnd = currentMonday.add(const Duration(days: 6));
      if (currentMonday.month == month.month || weekEnd.month == month.month) {
        weeks.add({
          'start': currentMonday,
          'end': weekEnd,
          'range': '${currentMonday.day}-${weekEnd.day}',
        });
      }
      currentMonday = currentMonday.add(const Duration(days: 7));
    }
    
    return weeks;
  }
}

enum _Status { focused, balanced, weak, neglected }

class _Glow {
  final Color glowColor;
  final double opacity;
  final double blur;
  final double spread;
  final Color border;
  _Glow(Color c, this.opacity, this.blur, this.spread) : glowColor = c, border = c.withOpacity(0.6);
}

class _KPIs {
  final int totalGroupsTrained;
  final String balanceLabel;
  final String strongestArea;
  final String weakestArea;
  _KPIs(this.totalGroupsTrained, this.balanceLabel, this.strongestArea, this.weakestArea);
}

String _composeSmartSummary(WeeklyMuscleAnalyticsData data, {List<WeeklyMuscleGroupStat>? filteredGroups}) {
  final groups = filteredGroups ?? data.groups;
  if (groups.isEmpty) return 'No training data recorded this week.';
  final avg = data.avgGroupLoad;
  final statuses = groups.map((g){
    final ev = _effectiveVolume(g.totalLoad, g.sessions);
    final s = _classifyByEV(ev, g.totalSets, g.sessions, avg);
    return { 'name': g.groupName, 'status': s, 'ev': ev };
  }).toList();
  final focused = statuses.where((x)=> x['status']==_Status.focused).map((x)=> x['name'] as String).toList();
  final neglected = statuses.where((x)=> x['status']==_Status.neglected).map((x)=> x['name'] as String).toList();
  final weak = statuses.where((x)=> x['status']==_Status.weak).map((x)=> x['name'] as String).toList();

  String s1 = focused.isNotEmpty ? 'You focused more on ${focused.join(', ')}.' : 'No clear focus this week.';
  String s2 = neglected.isNotEmpty ? ' Neglected: ${neglected.join(', ')}.' : '';
  String s3 = weak.isNotEmpty ? ' Undertrained: ${weak.join(', ')} (aim 10–20 sets and 2+ sessions).' : '';
  return (s1 + s2 + s3).trim();
}

bool _isChildOfGroup(String groupName, String muscleName) {
  final map = <String, List<String>>{
    'Chest': ['Upper Chest', 'Middle Chest', 'Lower Chest'],
    'Back': ['Upper Back', 'Mid Back', 'Lower Back', 'Lats'],
    'Shoulder': ['Front Shoulders', 'Side Shoulders', 'Rear Shoulders'],
    'Arms': ['Biceps', 'Triceps', 'Forearms', 'Brachialis'],
    'Legs': ['Quads', 'Hamstring', 'Glutes', 'Calves'],
    'Core': ['Abs', 'Obliques'],
  };
  final children = map[groupName] ?? const [];
  return children.contains(muscleName);
}

class _GroupDetailScreen extends StatelessWidget {
  final String groupName;
  final List<WeeklyMuscleStat> muscles;
  final double avg;
  const _GroupDetailScreen({Key? key, required this.groupName, required this.muscles, required this.avg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: Text(groupName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupOverview(groupName: groupName, muscles: muscles, avg: avg),
          const SizedBox(height: 16),
          Text('Muscles', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: muscles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, i) {
              final m = muscles[i];
              final pageState = context.findAncestorStateOfType<_WeeklyMuscleAnalyticsPageState>();
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => _MuscleDetailScreen(muscle: m),
                  ),
                ),
                child: (pageState == null)
                    ? const SizedBox.shrink()
                    : pageState._glowTile(
                  name: m.muscleName,
                  load: m.totalLoad,
                  sets: m.totalSets,
                  exercises: m.totalExercises,
                  reps: pageState._extractRepsFromMuscleStat(m),
                  avg: avg,
                      imageUrl: _safeMuscleImage(pageState, m),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _SmartSummaryBox(text: _composeSmartSummaryFromMuscles(muscles)),
          const SizedBox(height: 16),
          if (muscles.isNotEmpty) _ExercisesList(exercises: _mergeExercises(muscles)),
        ],
      ),
    );
  }
}

class _GroupOverview extends StatelessWidget {
  final String groupName;
  final List<WeeklyMuscleStat> muscles;
  final double avg;
  const _GroupOverview({Key? key, required this.groupName, required this.muscles, required this.avg}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalSets = muscles.fold<int>(0, (a, b) => a + b.totalSets);
    final totalLoad = muscles.fold<double>(0, (a, b) => a + b.totalLoad);
    final totalReps = muscles.fold<int>(0, (a, b) => a + (b.totalReps ?? b.totalSets * 9));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$groupName Overview', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _kpi(context, 'Sets', totalSets.toString()),
              _kpi(context, 'Reps', totalReps.toString()),
              _kpi(context, 'Intensity', totalLoad.toStringAsFixed(0)),
              _kpi(context, 'Status', totalLoad >= 1.5 * avg ? 'Focused' : totalLoad <= 0.5 * avg ? 'Weak' : 'Balanced'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpi(BuildContext ctx, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F2F2F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MuscleDetailScreen extends StatelessWidget {
  final WeeklyMuscleStat muscle;
  const _MuscleDetailScreen({Key? key, required this.muscle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pageState = context.findAncestorStateOfType<_WeeklyMuscleAnalyticsPageState>();
    final reps = pageState!._extractRepsFromMuscleStat(muscle);
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: Text(muscle.muscleName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GroupOverview(groupName: muscle.muscleName, muscles: [muscle], avg: muscle.totalLoad),
          const SizedBox(height: 12),
          _SmartSummaryBox(text: _composeSmartSummaryFromMuscles([muscle])),
          const SizedBox(height: 12),
          Text('Details', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _detailRow('Sets', muscle.totalSets.toString()),
          _detailRow('Reps', reps.toString()),
          _detailRow('Intensity', muscle.totalLoad.toStringAsFixed(0)),
          if (muscle.firstDate != null) _detailRow('First', muscle.firstDate!),
          if (muscle.lastDate != null) _detailRow('Last', muscle.lastDate!),
          const SizedBox(height: 16),
          if (muscle.exercises.isNotEmpty) _ExercisesList(exercises: muscle.exercises),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white54)),
          Text(value, style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
    );
  }
}

class _SmartSummaryBox extends StatelessWidget {
  final String text;
  const _SmartSummaryBox({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white70)),
    );
  }
}

String _composeSmartSummaryFromMuscles(List<WeeklyMuscleStat> muscles) {
  if (muscles.isEmpty) return 'No data available for this selection.';
  final sorted = [...muscles]..sort((a, b) => b.totalLoad.compareTo(a.totalLoad));
  final top = sorted.first.muscleName;
  final bottom = sorted.last.muscleName;
  return 'You emphasized $top this period, while $bottom received less work. Add complementary movements to balance development.';
}

String _safeMuscleImage(_WeeklyMuscleAnalyticsPageState state, WeeklyMuscleStat m) {
  final img = m.imageUrl;
  if (img != null && img.isNotEmpty) return img;
  final mapped = state._imageByName[m.muscleName] ?? '';
  return mapped;
}

String _compactNum(double n) {
  if (n >= 1000000) return (n/1000000).toStringAsFixed(1)+'M';
  if (n >= 1000) return (n/1000).toStringAsFixed(1)+'k';
  return n.toStringAsFixed(0);
}

  // Effective Volume: start with load; optionally adjust by session frequency (heavier weight to higher frequency)
  double _effectiveVolume(double rawLoad, int sessions) {
    final freqFactor = sessions >= 2 ? 1.0 : 0.8; // slight penalty if trained <2 times
    return rawLoad * freqFactor;
  }

  // Get sessions for a tile by name (using loaded groups list)
  int _currentSessionsForTile(WeeklyMuscleAnalyticsData? data, String name) {
    // check group first
    final g = data?.groups.firstWhere(
      (x) => x.groupName == name,
      orElse: () => WeeklyMuscleGroupStat(groupId: -1, groupName: '', totalLoad: 0, totalSets: 0, totalExercises: 0),
    );
    if (g != null && g.groupName == name) return g.sessions;
    // else muscle
    final m = data?.muscles.firstWhere(
      (x) => x.muscleName == name,
      orElse: () => WeeklyMuscleStat(muscleId: -1, muscleName: '', totalLoad: 0, totalSets: 0, totalExercises: 0),
    );
    if (m != null && m.muscleName == name) return m.sessions;
    return 0;
  }

  _Status _classifyByEV(double ev, int sets, int sessions, double avgLoad) {
    if (sets == 0 || ev <= 0) return _Status.neglected;
    // Hypertrophy target: 10–20 sets/week, frequency>=2
    final meetsFreq = sessions >= 2;
    final meetsSets = sets >= 10 && sets <= 20;
    // Compare to average volume
    if (avgLoad > 0 && ev >= 1.5 * avgLoad && meetsSets && meetsFreq) return _Status.focused;
    if ((avgLoad <= 0 || (ev > 0.5 * avgLoad && ev < 1.5 * avgLoad)) && meetsSets && meetsFreq) return _Status.balanced;
    if (!meetsFreq || sets < 10) return _Status.weak;
    return _Status.balanced;
  }



class _ExercisesList extends StatelessWidget {
  final List<WeeklyExerciseStat> exercises;
  const _ExercisesList({Key? key, required this.exercises}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exercises Performed', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...exercises.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.exerciseName, style: GoogleFonts.poppins(color: Colors.white))),
                    Wrap(spacing: 12, children: [
                      _mini(e.sets.toString(), 'Sets'),
                      _mini(e.reps.toString(), 'Reps'),
                      _mini(e.load.toStringAsFixed(0), 'Load'),
                    ]),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _mini(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

List<WeeklyExerciseStat> _mergeExercises(List<WeeklyMuscleStat> muscles) {
  final map = <String, WeeklyExerciseStat>{};
  for (final m in muscles) {
    for (final e in m.exercises) {
      final key = e.exerciseName;
      if (!map.containsKey(key)) {
        map[key] = WeeklyExerciseStat(
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          sets: e.sets,
          reps: e.reps,
          load: e.load,
        );
      } else {
        final prev = map[key]!;
        map[key] = WeeklyExerciseStat(
          exerciseId: prev.exerciseId,
          exerciseName: prev.exerciseName,
          sets: prev.sets + e.sets,
          reps: prev.reps + e.reps,
          load: prev.load + e.load,
        );
      }
    }
  }
  final list = map.values.toList();
  list.sort((a, b) => b.load.compareTo(a.load));
  return list;
}
