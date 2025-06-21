import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naijasingles/common/routes/route_name.dart';
import 'package:naijasingles/common/widgets/custom_button.dart';

import '../../../../common/constants/colors.dart';
import '../../../../common/constants/constants.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  Map<String, dynamic> userData = {};
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Afropeep MVP theme colors
  static const Color backgroundColor = Color(0xFFFDF0E7);
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: textDarkBrown),
          leading: Navigator.canPop(context) ? IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ) : null,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Welcome Page
                  _buildWelcomePage(),
                  
                  // Rules Page
                  _buildRulesPage(),
                ],
              ),
            ),
            
            // Button
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicator moved here for better spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        2,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index ? afropeepGreen : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Space between dots and button
                    
                    // Next/Get Started button with MVP styling
                    ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Navigate directly to email sign-up screen
                          Navigator.pushReplacementNamed(context, RouteName.emailSignup);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: afropeepGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: Text(
                        _currentPage == 0 ? "NEXT" : "GET STARTED",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ));
  }
  
  Widget _buildWelcomePage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: backgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Logo container - Using the Afropeep sparkle + heart logo with transparent background
          Container(
            height: 150,
            width: 150,
            decoration: const BoxDecoration(
              // Match the container background to the page background to hide square edges
              color: backgroundColor,
            ),
            child: Image.asset(
              'assets/images/logo2.png',
              fit: BoxFit.contain,
            ),
          ),
          
          // Increased spacing between logo and heading
          const SizedBox(height: 24),
          
          // Heading
          Text(
            "Afropeep",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textDarkBrown,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Find your perfect match in the African community",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: textLightBrown,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Feature icons row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _featureItem(Icons.place, "Location Based"),
              _featureItem(Icons.chat_bubble_outline, "Real Connections"),
              _featureItem(Icons.verified_user, "Verified Profiles"),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: afropeepGreen,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textLightBrown,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRulesPage() {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 60),
            Text(
              "Community Guidelines",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: afropeepGreen,
              ),
            ),
            const SizedBox(height: 20),
            _buildRuleCard(
              "Be yourself",
              "Make sure your photos, age, and bio are true to who you are.",
              Icons.person,
            ),
            _buildRuleCard(
              "Play it cool",
              "Respect others and treat them as you would like to be treated.",
              Icons.favorite,
            ),
            _buildRuleCard(
              "Stay safe",
              "Don't be too quick to give out personal information.",
              Icons.security,
            ),
            _buildRuleCard(
              "Be proactive",
              "Always report bad behavior.",
              Icons.flag,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRuleCard(String title, String description, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: afropeepGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textDarkBrown,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textLightBrown,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
