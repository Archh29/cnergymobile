import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/weekly_muscle_analytics_model.dart';
import './weekly_muscle_analytics_page.dart';

class GroupDetailPage extends StatefulWidget {
  final WeeklyMuscleGroupStat group;
  final List<WeeklyMuscleStat> muscles;
  final double avgGroupLoad;
  final Map<String, String> imageByName;

  const GroupDetailPage({
    Key? key,
    required this.group,
    required this.muscles,
    required this.avgGroupLoad,
    required this.imageByName,
  }) : super(key: key);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  DateTime _weekStart = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final k = _computeKPIs();
    final mergedExercises = _mergeExercises(widget.muscles);
    final statusCounts = _statusCounts(widget.muscles, widget.avgGroupLoad);
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00D4AA)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.group.groupName} Analytics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            icon: Container(
              padding: const EdgeInsets.all(8),
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
              child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Week Display
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Check if we have enough space for horizontal layout
                final hasEnoughSpace = constraints.maxWidth > 300;
                
                if (hasEnoughSpace) {
                  // Horizontal layout for larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: Text('Week: ${_formatDate(_weekStart)} → ${_formatDate(_weekStart.add(const Duration(days: 6)))}', 
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
                      Text('Week: ${_formatDate(_weekStart)} → ${_formatDate(_weekStart.add(const Duration(days: 6)))}', 
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
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
          ),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _kpi('Sets', widget.group.totalSets.toString()),
                  _kpi('Reps', (widget.group.totalReps ?? widget.group.totalSets * 9).toString()),
                  _kpi('Exercises', widget.group.totalExercises.toString()),
                  _kpi('Freq', widget.group.sessions.toString()+"/wk"),
                  _kpi('Target Sets', _targetSetsLabel(widget.group.totalSets)),
                  _kpi('Avg Weight (kg)', _avgWeight(widget.group.totalLoad, (widget.group.totalReps ?? widget.group.totalSets * 9))),
                  _kpi('Muscles', widget.muscles.length.toString()),
                  _kpi('Focused', statusCounts.focused.toString()),
                  _kpi('Balanced', statusCounts.balanced.toString()),
                  _kpi('Weak', statusCounts.weak.toString()),
                  _kpi('Neglected', statusCounts.neglected.toString()),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group Summary', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(k.summary, style: GoogleFonts.poppins(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(_smartSuggestionsEV(widget.muscles, widget.avgGroupLoad), style: GoogleFonts.poppins(color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 12),
          Text('Muscles', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.muscles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75, // Taller cards to prevent overflow
                ),
                itemBuilder: (context, i) {
                  final m = widget.muscles[i];
                  return GestureDetector(
                    onTap: () => _showMuscleModal(context, m),
                    child: _glowTile(
                      name: m.muscleName,
                      load: m.totalLoad,
                      sets: m.totalSets,
                      reps: m.totalReps ?? m.totalSets * 9,
                      sessions: m.sessions,
                      exercises: m.totalExercises,
                      avg: widget.avgGroupLoad,
                      imageUrl: m.imageUrl ?? (widget.imageByName[m.muscleName] ?? ''),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Exercises', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...mergedExercises.take(8).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(e.name, style: GoogleFonts.poppins(color: Colors.white))),
                          Wrap(spacing: 12, children: [
                            _kpi('Sets', e.sets.toString()),
                            _kpi('Reps', e.reps.toString()),
                          ]),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowTile({
    required String name,
    required double load,
    required int sets,
    required int sessions,
    required int reps,
    required int exercises,
    required double avg,
    required String imageUrl,
  }) {
    final ev = _effectiveVolume(load, sessions);
    final status = _classifyByEV(ev, sets, sessions, avg);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with responsive height
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: constraints.maxWidth * 0.4, // Reduced to fit more content
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
              const SizedBox(height: 4),
              // Compact metrics row
              Row(
                children: [
                  Expanded(
                    child: _compactMetric('Sets', sets.toString()),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _compactMetric('Reps', reps.toString()),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Status row
              Row(
                children: [
                  Expanded(
                    child: _statusPill(status),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
      ],
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

  Widget _thumbnail(String url) {
    final has = url.isNotEmpty;
    return Container(
      color: const Color(0xFF303030),
      child: has
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 28)),
            )
          : Center(child: Icon(Icons.image_not_supported, color: Colors.white24, size: 22)),
    );
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

  _Status _classifyByEV(double ev, int sets, int sessions, double avgLoad) {
    if (sets == 0 || ev <= 0) return _Status.neglected;
    final meetsFreq = sessions >= 2;
    final meetsSets = sets >= 10 && sets <= 20;
    if (avgLoad > 0 && ev >= 1.5 * avgLoad && meetsSets && meetsFreq) return _Status.focused;
    if ((avgLoad <= 0 || (ev > 0.5 * avgLoad && ev < 1.5 * avgLoad)) && meetsSets && meetsFreq) return _Status.balanced;
    if (!meetsFreq || sets < 10) return _Status.weak;
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

  _KPIs _computeKPIs() {
    final ev = _effectiveVolume(widget.group.totalLoad, widget.group.sessions);
    final status = _classifyByEV(ev, widget.group.totalSets, widget.group.sessions, widget.avgGroupLoad);
    final balance = {
      _Status.focused: 'Focused',
      _Status.balanced: 'Balanced',
      _Status.weak: 'Undertrained',
      _Status.neglected: 'Neglected',
    }[status]!;
    final summary = 'This week, ${widget.group.groupName} is $balance with EV ${_compactNum(ev)} and ${widget.group.totalSets} sets across ${widget.group.sessions}/wk.';
    return _KPIs(summary);
  }

  _StatusCounts _statusCounts(List<WeeklyMuscleStat> muscles, double avg) {
    int f=0,b=0,w=0,n=0;
    for (final m in muscles) {
      final s = _classifyByEV(_effectiveVolume(m.totalLoad, m.sessions), m.totalSets, m.sessions, avg);
      if (s==_Status.focused) f++; else if (s==_Status.balanced) b++; else if (s==_Status.weak) w++; else n++;
    }
    return _StatusCounts(f,b,w,n);
  }


  String _smartSuggestionsEV(List<WeeklyMuscleStat> muscles, double avg) {
    if (muscles.isEmpty) return 'No recorded activity for this group this week. Consider scheduling a session.';
    final sorted = [...muscles]..sort((a,b)=>_effectiveVolume(b.totalLoad, b.sessions).compareTo(_effectiveVolume(a.totalLoad, a.sessions)));
    final top = sorted.first;
    final low = sorted.last;
    final advice = <String>[];
    final topEv = _effectiveVolume(top.totalLoad, top.sessions);
    final lowEv = _effectiveVolume(low.totalLoad, low.sessions);
    if (topEv >= 1.5*avg && top.sessions>=2 && top.totalSets>=10) advice.add('Great progress on ${top.muscleName}. Stay consistent and monitor recovery.');
    if (low.sessions<2 || low.totalSets<10) advice.add('Increase ${low.muscleName} to 10–20 sets with 2+ sessions for better growth.');
    if (advice.isEmpty) advice.add('Balanced effort detected. You can push a bit more on weaker muscles next week.');
    return advice.join(' ');
  }

  List<_MergedExercise> _mergeExercises(List<WeeklyMuscleStat> muscles) {
    final map = <String,_MergedExercise>{};
    for (final m in muscles) {
      for (final e in m.exercises) {
        final key = e.exerciseName;
        final v = map[key];
        if (v==null) {
          map[key] = _MergedExercise(key, e.sets, e.reps, e.load);
        } else {
          v.sets += e.sets; v.reps += e.reps; v.load += e.load;
        }
      }
    }
    final list = map.values.toList();
    list.sort((a,b)=>b.load.compareTo(a.load));
    return list;
  }

  Widget _kpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  String _compactNum(double n) {
    if (n >= 1000000) return (n/1000000).toStringAsFixed(1)+'M';
    if (n >= 1000) return (n/1000).toStringAsFixed(1)+'k';
    return n.toStringAsFixed(0);
  }

  String _avgWeight(double totalLoad, int reps) {
    if (reps <= 0) return '—';
    final avg = totalLoad / reps;
    return avg.toStringAsFixed(1);
  }

  double _effectiveVolume(double rawLoad, int sessions) {
    final freqFactor = sessions >= 2 ? 1.0 : 0.8;
    return rawLoad * freqFactor;
  }

  String _targetSetsLabel(int sets) {
    if (sets < 10) return '$sets / 10–20 (low)';
    if (sets > 20) return '$sets / 10–20 (high)';
    return '$sets / 10–20 (ok)';
  }


  Widget _sectionCard({required Widget child}) {
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
      child: child,
    );
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

  String _getMonthName(DateTime date) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${months[date.month - 1]} ${date.year}';
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

  DateTime _mondayOf(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _thisWeek() {
    setState(() {
      _weekStart = _mondayOf(DateTime.now());
    });
  }

  void _showMuscleModal(BuildContext context, WeeklyMuscleStat muscle) {
    final ev = _effectiveVolume(muscle.totalLoad, muscle.sessions);
    final status = _classifyByEV(ev, muscle.totalSets, muscle.sessions, widget.avgGroupLoad);
    final reps = muscle.totalReps ?? muscle.totalSets * 9;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    muscle.muscleName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Status Pill
              Center(
                child: _statusPill(status),
              ),
              const SizedBox(height: 24),
              
              // Overview Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _kpi('Sets', muscle.totalSets.toString()),
                  _kpi('Reps', reps.toString()),
                  _kpi('Exercises', muscle.totalExercises.toString()),
                  _kpi('Freq', muscle.sessions.toString()+"/wk"),
                  _kpi('Avg Weight', _avgWeight(muscle.totalLoad, reps)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Smart Summary
              Container(
                padding: const EdgeInsets.all(16),
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
                    Text(
                      'Smart Summary',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMuscleSummary(muscle, ev, status),
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _getMuscleSummary(WeeklyMuscleStat muscle, double ev, _Status status) {
    final reps = muscle.totalReps ?? muscle.totalSets * 9;
    final statusText = {
      _Status.focused: 'Focused',
      _Status.balanced: 'Balanced', 
      _Status.weak: 'Undertrained',
      _Status.neglected: 'Neglected',
    }[status]!;
    
    if (status == _Status.neglected) {
      return '${muscle.muscleName} needs attention. No training recorded this week. Consider adding exercises targeting this muscle.';
    } else if (status == _Status.weak) {
      return '${muscle.muscleName} is undertrained with ${muscle.totalSets} sets and ${muscle.sessions} sessions. Aim for 10-20 sets and 2+ sessions weekly.';
    } else if (status == _Status.balanced) {
      return '${muscle.muscleName} is well-balanced with ${muscle.totalSets} sets and ${muscle.sessions} sessions. Maintain this training volume.';
    } else {
      return '${muscle.muscleName} is getting focused attention with ${muscle.totalSets} sets and ${muscle.sessions} sessions. Great training intensity!';
    }
  }
}

class _KPIs {
  final String summary;
  _KPIs(this.summary);
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

class _StatusCounts {
  final int focused;
  final int balanced;
  final int weak;
  final int neglected;
  _StatusCounts(this.focused, this.balanced, this.weak, this.neglected);
}

class _MergedExercise {
  final String name;
  int sets;
  int reps;
  double load;
  _MergedExercise(this.name, this.sets, this.reps, this.load);
}

class MuscleDetailPage extends StatelessWidget {
  final WeeklyMuscleStat muscle;
  final double avgGroupLoad;
  final Map<String, String> imageByName;

  const MuscleDetailPage({
    Key? key,
    required this.muscle,
    required this.avgGroupLoad,
    required this.imageByName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reps = muscle.totalReps ?? muscle.totalSets * 9;
    final balance = (muscle.totalLoad >= 1.5 * avgGroupLoad)
        ? 'Focused'
        : (muscle.totalLoad <= 0.5 * avgGroupLoad)
            ? 'Undertrained'
            : 'Balanced';
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00D4AA)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${muscle.muscleName} Analytics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overview', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _kpi('Sets', muscle.totalSets.toString()),
                  _kpi('Reps', reps.toString()),
                  _kpi('Exercises', muscle.totalExercises.toString()),
                  _kpi('Intensity', muscle.totalLoad.toStringAsFixed(0)),
                ]),
                const SizedBox(height: 12),
                Text('This muscle is $balance relative to weekly average.', style: GoogleFonts.poppins(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}


