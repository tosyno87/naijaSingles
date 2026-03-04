import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart' as au;
import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
import '../../../../common/constants/constants.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../common/utils/upload_media.dart';

class UserProfilePic extends StatefulWidget {
  const UserProfilePic({super.key});

  @override
  State<UserProfilePic> createState() => _UserProfilePicState();
}

class _UserProfilePicState extends State<UserProfilePic>
    with SingleTickerProviderStateMixin {
  final au.FirebaseAuth? auth = firebaseAuthInstance;

  // List to store multiple photos
  List<File?> photos = [null, null, null];
  int selectedPhotoIndex = 0;

  // Animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Initialize animation
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _animationController != null) {
        unawaited(_animationController!.forward());
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  // Count how many photos have been added
  int get photoCount => photos.where((photo) => photo != null).length;

  // Check if we have at least 1 photo to continue
  bool get canContinue => photoCount >= 1;

  @override
  Widget build(BuildContext context) {
    final userData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

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

                      // Header section
                      if (_fadeAnimation != null)
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: _buildHeaderSection(),
                        )
                      else
                        _buildHeaderSection(),

                      const SizedBox(height: 40),

                      // Main photo upload section
                      if (_fadeAnimation != null)
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: _buildMainPhotoSection(),
                        )
                      else
                        _buildMainPhotoSection(),

                      const SizedBox(height: 24),

                      // Photo grid section
                      if (_fadeAnimation != null)
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: _buildPhotoGridSection(),
                        )
                      else
                        _buildPhotoGridSection(),

                      const SizedBox(height: 24),

                      // Tips section
                      if (_fadeAnimation != null)
                        FadeTransition(
                          opacity: _fadeAnimation!,
                          child: _buildTipsSection(),
                        )
                      else
                        _buildTipsSection(),

                      const SizedBox(
                        height: 100,
                      ), // Space for the bottom labelLarge
                    ],
                  ),
                ),
              ),
            ),

            // Continue labelLarge fixed at the bottom
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
                  onPressed: canContinue
                      ? () {
                          log('userdata is ${userData.toString()}');
                          unawaited(Navigator.pushNamed(
                            context,
                            RouteName.allowLocationScreen,
                            arguments: {
                              'userData': userData,
                              'profilePic': photos[selectedPhotoIndex],
                            },
                          ));
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
                  child: Text(
                    canContinue ? 'CONTINUE' : 'ADD AT LEAST 1 PHOTO',
                    style: const TextStyle(
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

  // Header section with title and subtitle
  Widget _buildHeaderSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Let them see you',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Profiles with clear photos get more matches.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );

  // Main photo upload section
  Widget _buildMainPhotoSection() => Center(
        child: GestureDetector(
          onTap: () => _pickImage(selectedPhotoIndex),
          child: Container(
            width: 280,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: photos[selectedPhotoIndex] != null
                  ? Border.all(
                      color: Colors.transparent,
                      width: 2,
                    )
                  : null,
              boxShadow: [
                if (photos[selectedPhotoIndex] != null)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: photos[selectedPhotoIndex] != null
                ? Stack(
                    children: [
                      // Photo preview
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          photos[selectedPhotoIndex]!,
                          width: 280,
                          height: 350,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Edit labelLarge overlay
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _pickImage(selectedPhotoIndex),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Container for dashed border
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: Colors.grey[300]!,
                            strokeWidth: 2,
                            gap: 5,
                          ),
                          size: const Size(280, 350),
                        ),
                      ),

                      // Placeholder content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27AE60),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );

  // Photo grid section
  Widget _buildPhotoGridSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your photos ($photoCount/3)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (photos[index] != null) {
                      // Select this photo
                      setState(() {
                        selectedPhotoIndex = index;
                      });
                    } else {
                      unawaited(_pickImage(index));
                    }
                  },
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selectedPhotoIndex == index && photos[index] != null
                                ? const Color(0xFF27AE60)
                                : Colors.grey[300]!,
                        width:
                            selectedPhotoIndex == index && photos[index] != null
                                ? 2
                                : 1,
                      ),
                    ),
                    child: photos[index] != null
                        ? Stack(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(
                                  photos[index]!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Selected indicator
                              if (selectedPhotoIndex == index)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF27AE60),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  // Tips section
  Widget _buildTipsSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Color(0xFF27AE60),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips for great photos:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Choose photos where your face is clearly visible\n'
                    '• Avoid group shots as your main photo\n'
                    '• Add at least one full-body photo\n'
                    '• Show your interests and personality',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // Method to pick an image
  Future<void> _pickImage(int index) async {
    final file =
        await UploadMedia.getImage(context: context, checktype: 'profile');
    if (file != null && mounted) {
      setState(() {
        photos[index] = file;
        selectedPhotoIndex = index;
      });
    }
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });
  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Draw top line
    _drawDashedLine(canvas, paint, const Offset(0, 0), Offset(size.width, 0));

    // Draw right line
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width, 0),
      Offset(size.width, size.height),
    );

    // Draw bottom line
    _drawDashedLine(
      canvas,
      paint,
      Offset(size.width, size.height),
      Offset(0, size.height),
    );

    // Draw left line
    _drawDashedLine(canvas, paint, Offset(0, size.height), const Offset(0, 0));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    // Calculate the distance and direction
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Calculate the number of dashes
    final dashCount = distance / (strokeWidth + gap);

    // Calculate the small dx and dy for each dash
    final dashDx = dx / dashCount;
    final dashDy = dy / dashCount;

    // Start drawing from the start point
    var currentPoint = start;

    // Draw the dashes
    final int count = dashCount.floor();
    for (var i = 0; i < count; i++) {
      // Draw a dash
      canvas.drawLine(
        currentPoint,
        Offset(currentPoint.dx + dashDx / 2, currentPoint.dy + dashDy / 2),
        paint,
      );

      // Move to the next dash start point (skipping the gap)
      currentPoint = Offset(
        currentPoint.dx + dashDx,
        currentPoint.dy + dashDy,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
