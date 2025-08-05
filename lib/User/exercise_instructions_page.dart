import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './models/routine.models.dart';

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
  
  final List<String> videoUrls = [
    'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/518724939_1274839543510024_1614919070104890848_n.jpg-yDDZqqxgCX8rmxCnn2huZLucWdb0mr.jpeg',
    'https://hebbkx1anhila5yf.public.blob.vercel-storage.com/518724939_1274839543510024_1614919070104890848_n.jpg-yDDZqqxgCX8rmxCnn2huZLucWdb0mr.jpeg', // Replace with second image URL
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: CustomScrollView(
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
                    // Video/Image display
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isVideoPlaying = !isVideoPlaying;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(videoUrls[selectedVideoIndex]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: !isVideoPlaying
                            ? Center(
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    
                    // Back button
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
                    
                    // Video thumbnails at bottom
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
                    
                    // Video controls
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                videoSpeed = videoSpeed == 1.0 ? 1.5 : videoSpeed == 1.5 ? 2.0 : 1.0;
                              });
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
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              // Handle fullscreen
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
                      widget.exercise.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Tab buttons (removed Equipment)
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
      onTap: () {
        setState(() {
          selectedVideoIndex = index;
        });
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
          child: Container(
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
            _buildInstructionStep(
              1,
              'Start with your feet hip-width apart and knees slightly bent. Place your left hand on a bench while holding a dumbbell in your right hand.',
            ),
            SizedBox(height: 16),
            _buildInstructionStep(
              2,
              'Bend your torso forward until it\'s almost parallel to the floor. Your right arm should be extended straight down from your shoulder, palm facing your thigh.',
            ),
            SizedBox(height: 16),
            _buildInstructionStep(
              3,
              'Squeeze your shoulder blades together and pull the dumbbell to your side, keeping your elbow close to your torso.',
            ),
            SizedBox(height: 16),
            _buildInstructionStep(
              4,
              'Pause briefly at the top of the movement, then slowly lower the weight back to the starting position.',
            ),
            SizedBox(height: 16),
            _buildInstructionStep(
              5,
              'Repeat for the desired number of repetitions, then switch sides.',
            ),
          ],
        );
      case 'Target':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTargetMuscle('Primary', 'Latissimus Dorsi', Colors.red),
            SizedBox(height: 12),
            _buildTargetMuscle('Secondary', 'Rhomboids', Colors.orange),
            SizedBox(height: 12),
            _buildTargetMuscle('Secondary', 'Middle Trapezius', Colors.orange),
            SizedBox(height: 12),
            _buildTargetMuscle('Stabilizer', 'Posterior Deltoid', Colors.blue),
            SizedBox(height: 12),
            _buildTargetMuscle('Stabilizer', 'Biceps Brachii', Colors.blue),
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
            Text(
              'This exercise primarily targets the latissimus dorsi, helping to build width and thickness in your back. It also engages the rhomboids and middle trapezius for better posture and upper back strength.',
              style: GoogleFonts.poppins(
                color: Colors.grey[300],
                fontSize: 16,
                height: 1.5,
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
            Text(
              muscleName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
