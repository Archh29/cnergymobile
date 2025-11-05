import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF45B7D1).withOpacity(0.8), Color(0xFF4ECDC4).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF45B7D1).withOpacity(0.3),
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
                      Icons.privacy_tip,
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
                          'Our Commitment to Privacy',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Last updated: June 2025',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Introduction
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'We value your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our app.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Main content
            _buildPrivacySection(
              title: 'Information Collection',
              icon: Icons.folder_open,
              content: 'We may collect personal information such as your name, email address, and activity data within the app to improve your experience. This includes workout data, preferences, and usage patterns to personalize your fitness journey.',
            ),

            _buildPrivacySection(
              title: 'Use of Information',
              icon: Icons.data_usage,
              content: 'Your data helps us provide better services, support, and improve our features. We do not sell your personal data to third parties. We use your information to enhance your workout experience, provide personalized recommendations, and improve our app functionality.',
            ),

            _buildPrivacySection(
              title: 'Data Security',
              icon: Icons.security,
              content: 'We implement strong security measures to protect your information. However, no method of transmission is 100% secure. We use industry-standard encryption, secure servers, and regular security audits to ensure your data remains protected.',
            ),

            _buildPrivacySection(
              title: 'Your Rights',
              icon: Icons.gavel,
              content: 'You have the right to access, correct, or delete your personal information at any time. You can request a copy of your data or ask us to remove your account completely through the app settings or by contacting our support team.',
            ),

            _buildPrivacySection(
              title: 'Third-Party Services',
              icon: Icons.public,
              content: 'Our app may use third-party services that collect information. These services have their own privacy policies and we encourage you to review them. We carefully select partners who maintain similar privacy standards.',
            ),

            _buildPrivacySection(
              title: 'Changes to Policy',
              icon: Icons.update,
              content: 'We may update this policy periodically. You will be notified of any significant changes within the app. We recommend reviewing this policy occasionally to stay informed about how we protect your information.',
            ),

            SizedBox(height: 24),
            Center(
              child: Text(
                'Effective Date: June 2025',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color(0xFF45B7D1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFF45B7D1),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconColor: Color(0xFF45B7D1),
        collapsedIconColor: Colors.grey,
        children: [
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}