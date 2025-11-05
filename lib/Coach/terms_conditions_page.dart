import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
                  colors: [Color(0xFF96CEB4).withOpacity(0.8), Color(0xFF4ECDC4).withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF96CEB4).withOpacity(0.3),
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
                      Icons.description,
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
                          'User Agreement',
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
                'By using this app, you agree to the following terms and conditions. Please read them carefully.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 24),

            // Main content
            _buildTermsSection(
              title: '1. Use of Service',
              icon: Icons.app_registration,
              content: 'You agree to use the app only for lawful purposes and in a way that does not infringe on the rights of others. You must not use the app in any way that could damage, disable, overburden, or impair our services.',
            ),

            _buildTermsSection(
              title: '2. Account Responsibility',
              icon: Icons.account_circle,
              content: 'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            ),

            _buildTermsSection(
              title: '3. QR Code Policy',
              icon: Icons.qr_code_scanner,
              content: 'Your QR code is personal and confidential. Sharing, distributing, or allowing others to use your QR code is strictly prohibited. If you are caught sharing your QR code with unauthorized individuals, your account will be immediately terminated. You are solely responsible for all activities performed using your QR code.',
            ),

            _buildTermsSection(
              title: '4. Modifications',
              icon: Icons.update,
              content: 'We reserve the right to modify these terms at any time. Continued use of the app means you accept the changes. We will notify you of significant changes through the app or via email.',
            ),

            _buildTermsSection(
              title: '5. Termination',
              icon: Icons.block,
              content: 'We may suspend or terminate your access to the app at our discretion, without prior notice. This may occur if you violate these terms or engage in activities that could harm other users or our services.',
            ),

            _buildTermsSection(
              title: '6. Content Ownership',
              icon: Icons.copyright,
              content: 'All content provided in the app, including but not limited to text, graphics, logos, and software, is owned by us or our licensors and is protected by copyright and other intellectual property laws.',
            ),

            _buildTermsSection(
              title: '7. Limitation of Liability',
              icon: Icons.gavel,
              content: 'We are not liable for any damages that may occur from using our app. This includes direct, indirect, incidental, punitive, and consequential damages. Use the app at your own risk.',
            ),

            _buildTermsSection(
              title: '8. Governing Law',
              icon: Icons.balance,
              content: 'These terms shall be governed by and construed in accordance with the laws of the jurisdiction in which our company is registered, without regard to its conflict of law provisions.',
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

  Widget _buildTermsSection({
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
            color: Color(0xFF96CEB4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Color(0xFF96CEB4),
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
        iconColor: Color(0xFF96CEB4),
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