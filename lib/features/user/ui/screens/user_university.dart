import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:naijasingles/common/routes/route_name.dart';

class UniversityPage extends StatefulWidget {
  const UniversityPage({super.key});

  @override
  _UniversityPage createState() => _UniversityPage();
}

class _UniversityPage extends State<UniversityPage> {
  String university = '';
  final TextEditingController _universityController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  // Popular universities in Africa and diaspora
  final List<String> _suggestions = [
    'University of Lagos',
    'University of Ibadan',
    'Covenant University',
    'Howard University',
    'University of Cape Town',
    'Ashesi University'
  ];

  @override
  void initState() {
    super.initState();

    // Listen for focus changes
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    // Auto focus the text field after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _universityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For adding userdetails in this user map from navigation
    var userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Progress indicator
                      Container(
                        height: 4,
                        width: screenSize.width *
                            0.95, // 95% of screen width (almost complete)
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Title section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Where did you go to school?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "This helps us connect you with alumni or people nearby",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Input section with card-style design
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: _universityController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          onChanged: (value) {
                            setState(() {
                              university = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "e.g. University of Lagos",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.school_rounded,
                              color: _isFocused
                                  ? const Color(0xFF27AE60)
                                  : Colors.grey[400],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Suggestions section with chips
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Popular universities",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: _suggestions.map((suggestion) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    university = suggestion;
                                    _universityController.text = suggestion;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Continue labelLarge fixed at the bottom
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: university.isNotEmpty
                      ? () {
                          userData.addAll({
                            'editInfo': {
                              'university': university,
                              'userGender': userData['userGender'],
                              'showOnProfile': userData['showOnProfile']
                            }
                          });

                          log(userData.toString());
                          Navigator.pushNamed(
                              context, RouteName.profilePicSetScreen,
                              arguments: userData);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "CONTINUE",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
