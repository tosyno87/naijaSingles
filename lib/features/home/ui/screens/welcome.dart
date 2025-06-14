import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
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
                            color: _currentPage == index ? Colors.green[700]! : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // Space between dots and button
                    
                    // Next button with improved visibility
                    CustomButton(
                      text: _currentPage == 0 ? "NEXT" : "GET STARTED",
                      onTap: () async {
                        if (_currentPage < 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          // Handle navigation
                          final user = firebaseAuthInstance.currentUser!;
                          if (user.displayName != null) {
                            if (user.displayName!.isNotEmpty) {
                              log(user.displayName.toString());
                              userData.addAll({'UserName': user.displayName});
                              Navigator.pushNamed(
                                  context, RouteName.userDobScreen,
                                  arguments: userData);
                            } else {
                              log("no user name saved yet");
                              Navigator.pushNamed(
                                  context, RouteName.userNameScreen);
                            }
                          } else {
                            log("by default coming users");
                            Navigator.pushNamed(
                                context, RouteName.userNameScreen);
                          }
                        }
                      },

                      color: Colors.green[700]!,
                      active: true,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[100],
            ),
            child: Icon(
              Icons.favorite,
              size: 60,
              color: Colors.green[700]!,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Afropeep",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 40,
                color: Colors.green[700]!,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal),
          ),
          const SizedBox(height: 20),
          Text(
            "Find your perfect match in the African community",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _featureItem(Icons.location_on, "Location Based"),
              _featureItem(Icons.chat_bubble, "Real Connections"),
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
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.green[700]!,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRulesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 60),
          Text(
            "Community Guidelines",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700]!,
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
    );
  }
  
  Widget _buildRuleCard(String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.green[700]!,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
