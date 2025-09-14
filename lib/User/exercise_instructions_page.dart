import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import './models/routine.models.dart';
import './services/exercise_instructions_service.dart';

class ExerciseInstructionsPage extends StatefulWidget {
  final ExerciseModel exercise;
  
  const ExerciseInstructionsPage({
    Key? key,
    required this.exercise,
  }) : super(key: key);

  @override
  _ExerciseInstructionsPageState createState() => _ExerciseInstructionsPageState();
}

class _ExerciseInstructionsPageState extends State<ExerciseInstructionsPage> {
  String selectedTab = 'Instructions';
  bool isVideoPlaying = false;
  double videoSpeed = 1.0;
  int selectedVideoIndex = 0;
  
  ExerciseInstructionData? exerciseData;
  bool isLoading = true;
  String? error;
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadExerciseData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      print('🔍 Loading exercise data for ID: ${widget.exercise.id} (type: ${widget.exercise.id.runtimeType})');
      
      // Test API connection first
      print('🔍 Testing API connection...');
      final isApiReachable = await ExerciseInstructionService.testApiConnection();
      print('🔍 API reachable: $isApiReachable');
      
      // Ensure we pass the ID as an int, handling both null and string cases
      final dynamic exerciseId = widget.exercise.id ?? 0;
      final data = await ExerciseInstructionService.getExerciseDetails(exerciseId);
      
      if (data != null) {
        print('✅ Exercise data loaded successfully');
        setState(() {
          exerciseData = data;
          isLoading = false;
        });
        
        _initializeVideoPlayer();
      } else {
        print('❌ Failed to load exercise data - data is null');
        setState(() {
          error = 'Failed to load exercise data: No data returned from server';
          isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Error loading exercise data: $e');
      setState(() {
        error = 'Failed to load exercise data: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> _initializeVideoPlayer() async {
    final urls = videoUrls;
    if (urls.isNotEmpty && _isVideoFile(urls[selectedVideoIndex])) {
      try {
        _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(urls[selectedVideoIndex])
        );
        
        await _videoController!.initialize();
        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        print('Error initializing video: $e');
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }
  
  bool _isVideoFile(String url) {
    final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v'];
    return videoExtensions.any((ext) => url.toLowerCase().contains(ext));
  }
  
  List<String> get videoUrls {
    if (exerciseData?.videoUrl != null && exerciseData!.videoUrl.isNotEmpty) {
      return [exerciseData!.videoUrl];
    }
    if (exerciseData?.imageUrl != null && exerciseData!.imageUrl.isNotEmpty) {
      return [exerciseData!.imageUrl];
    }
    return [
      'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/518724939_1274839543510024_1614919070104890848_n.jpg-yDDZqqxgCX8rmxCnn2huZLucWdb0mr.jpeg',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: isLoading 
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A5568),
              ),
            )
          : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading exercise data',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      error!,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadExerciseData,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // Video Player Section
                  SliverToBoxAdapter(
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: _isVideoFile(videoUrls[selectedVideoIndex])
                                ? (_isVideoInitialized && _videoController != null)
                                    ? AspectRatio(
                                        aspectRatio: _videoController!.value.aspectRatio,
                                        child: VideoPlayer(_videoController!),
                                      )
                                    : Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      )
                                : Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(videoUrls[selectedVideoIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                          ),
                          
                          if (_isVideoFile(videoUrls[selectedVideoIndex]))
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  print('[v0] Play button tapped, controller: ${_videoController != null}');
                                  if (_videoController != null && _isVideoInitialized) {
                                    setState(() {
                                      if (_videoController!.value.isPlaying) {
                                        _videoController!.pause();
                                        isVideoPlaying = false;
                                        print('[v0] Video paused');
                                      } else {
                                        _videoController!.play();
                                        isVideoPlaying = true;
                                        print('[v0] Video playing');
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedOpacity(
                                      opacity: (!isVideoPlaying || !_videoController!.value.isPlaying) ? 1.0 : 0.0,
                                      duration: Duration(milliseconds: 300),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(40),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          (_videoController != null && _videoController!.value.isPlaying) 
                                              ? Icons.pause 
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          
                          Positioned(
                            top: 16,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Row(
                              children: List.generate(
                                videoUrls.length,
                                (index) => Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: _buildVideoThumbnail(index == selectedVideoIndex, index),
                                ),
                              ),
                            ),
                          ),
                          
                          if (_isVideoFile(videoUrls[selectedVideoIndex]))
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        if (_videoController != null) {
                                          setState(() {
                                            videoSpeed = videoSpeed == 1.0 ? 1.5 : videoSpeed == 1.5 ? 2.0 : 1.0;
                                          });
                                          _videoController!.setPlaybackSpeed(videoSpeed);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${videoSpeed}x',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Fullscreen mode activated')),
                                        );
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          Icons.fullscreen,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content Section
                  SliverFillRemaining(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and favorite
                          Row(
                            children: [
                              Text(
                                'Video & Instructions',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              Spacer(),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Added to favorites!')),
                                  );
                                },
                                child: Icon(
                                  Icons.favorite_border,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          
                          Text(
                            exerciseData?.name ?? widget.exercise.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          
                          // Tab buttons
                          Row(
                            children: [
                              _buildTabButton('Instructions', selectedTab == 'Instructions'),
                              SizedBox(width: 16),
                              _buildTabButton('Target', selectedTab == 'Target'),
                            ],
                          ),
                          SizedBox(height: 24),
                          
                          // Content based on selected tab
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildTabContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVideoThumbnail(bool isSelected, int index) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedVideoIndex = index;
          _isVideoInitialized = false;
        });
        
        // Initialize new video if it's a video file
        if (_isVideoFile(videoUrls[index])) {
          await _initializeVideoPlayer();
        }
      },
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _isVideoFile(videoUrls[index])
              ? Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(videoUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }


  Widget _buildTabButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = title;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4A5568) : Color(0xFF2D3748),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 'Instructions':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exerciseData?.instructionSteps != null && exerciseData!.instructionSteps.isNotEmpty)
              ...exerciseData!.instructionSteps.map((step) => Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: _buildInstructionStep(step.step, step.instruction),
              )).toList()
            else
              Text(
                'No instructions available for this exercise.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
          ],
        );
      case 'Target':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exerciseData?.targetMuscles != null) ...[
              // Primary muscles
              if (exerciseData!.targetMuscles['primary']?.isNotEmpty == true) ...[
                ...exerciseData!.targetMuscles['primary']!.map((muscle) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildTargetMuscle('Primary', muscle.name, Colors.red),
                )).toList(),
              ],
              // Secondary muscles
              if (exerciseData!.targetMuscles['secondary']?.isNotEmpty == true) ...[
                ...exerciseData!.targetMuscles['secondary']!.map((muscle) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildTargetMuscle('Secondary', muscle.name, Colors.orange),
                )).toList(),
              ],
              // Stabilizer muscles
              if (exerciseData!.targetMuscles['stabilizer']?.isNotEmpty == true) ...[
                ...exerciseData!.targetMuscles['stabilizer']!.map((muscle) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildTargetMuscle('Stabilizer', muscle.name, Colors.blue),
                )).toList(),
              ],
              SizedBox(height: 24),
              Text(
                'Muscle Benefits',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              if (exerciseData!.benefits.isNotEmpty)
                ...exerciseData!.benefits.map((benefit) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (benefit.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          benefit.description,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[300],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList()
              else if (exerciseData?.description != null && exerciseData!.description.isNotEmpty)
                Text(
                  exerciseData!.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[300],
                    fontSize: 16,
                    height: 1.5,
                  ),
                )
              else
                Text(
                  'No muscle benefits information available for this exercise.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
            ] else
              Text(
                'No target muscle information available for this exercise.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildInstructionStep(int stepNumber, String instruction) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Step $stepNumber selected')),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF4A5568),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                instruction,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetMuscle(String type, String muscleName, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$muscleName muscle info')),
        );
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            SizedBox(width: 12),
            Text(
              type,
              style: GoogleFonts.poppins(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '•',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                muscleName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
