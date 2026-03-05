import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../common/routes/route_name.dart';

import '../../../../common/widgets/custom_snackbar.dart';

class SexualOrientation extends StatefulWidget {
  const SexualOrientation({super.key});

  @override
  _SexualOrientationState createState() => _SexualOrientationState();
}

class _SexualOrientationState extends State<SexualOrientation> {
  List<Map<String, dynamic>> orientationList = [
    {'name': 'Straight', 'selected': false},
    {'name': 'Gay', 'selected': false},
    {'name': 'Lesbian', 'selected': false},
    {'name': 'Bisexual', 'selected': false},
    {'name': 'Asexual', 'selected': false},
    {'name': 'Demisexual', 'selected': false},
    {'name': 'Pansexual', 'selected': false},
    {'name': 'Queer', 'selected': false},
  ];

  List<String> selectedOrientations = [];
  bool showOnProfile = true;

  void _toggleOrientation(int index) {
    setState(() {
      // Toggle selection state
      orientationList[index]['selected'] = !orientationList[index]['selected'];

      final String orientation = orientationList[index]['name'];

      if (orientationList[index]['selected']) {
        // Check if we already have 3 selections
        if (selectedOrientations.length >= 3) {
          // Show message and revert selection
          orientationList[index]['selected'] = false;
          CustomSnackbar.showSnackBarSimple(
            'You can select up to 3 orientations',
            context,
          );
          return;
        }

        // Add to selected list
        selectedOrientations.add(orientation);
      } else {
        // Remove from selected list
        selectedOrientations.remove(orientation);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData =
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
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Progress indicator
                      Container(
                        height: 4,
                        width: screenSize.width *
                            0.75, // 75% of screen width (fifth step)
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
                            'My sexual orientation is',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select all that apply (up to 3)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Orientation options with pill-shaped labelLarges
                      _buildOrientationGrid(),

                      const SizedBox(height: 20),

                      // "Prefer not to say" option
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // Clear all other selections
                            for (var orientation in orientationList) {
                              orientation['selected'] = false;
                            }
                            selectedOrientations.clear();

                            // Add "Prefer not to say"
                            selectedOrientations.add('Prefer not to say');
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedOrientations
                                      .contains('Prefer not to say')
                                  ? const Color(0xFF27AE60)
                                  : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            color: selectedOrientations
                                    .contains('Prefer not to say')
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              'Prefer not to say',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selectedOrientations
                                        .contains('Prefer not to say')
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: selectedOrientations
                                        .contains('Prefer not to say')
                                    ? const Color(0xFF27AE60)
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // iOS-style toggle for "Show my orientation on profile"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Show my orientation on my profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            CupertinoSwitch(
                              value: showOnProfile,
                              activeTrackColor: const Color(0xFF27AE60),
                              onChanged: (value) {
                                setState(() {
                                  showOnProfile = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 100,
                      ), // Space for the bottom labelLarge
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Continue labelLarge at the bottom
            Container(
              padding: const EdgeInsets.all(24),
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
                  onPressed: selectedOrientations.isEmpty
                      ? null
                      : () {
                          userData.addAll({
                            'sexualOrientation': {
                              'orientation': selectedOrientations,
                              'showOnProfile': showOnProfile,
                            },
                          });
                          log(userData.toString());
                          unawaited(
                            Navigator.pushNamed(
                              context,
                              RouteName.showGenderScreen,
                              arguments: userData,
                            ),
                          );
                        },
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
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  Widget _buildOrientationGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: orientationList.length,
        itemBuilder: (context, index) {
          final orientation = orientationList[index];
          final isSelected = orientation['selected'];

          return GestureDetector(
            onTap: () {
              // Don't allow selection if "Prefer not to say" is selected
              if (selectedOrientations.contains('Prefer not to say')) {
                setState(() {
                  selectedOrientations.clear();
                });
              }

              _toggleOrientation(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF27AE60) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF27AE60) : Colors.grey[300]!,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  orientation['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      );
}
