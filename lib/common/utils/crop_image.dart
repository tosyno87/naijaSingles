import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CropMedia extends StatefulWidget {
  final String title;
  final File file;
  final String checktype;

  const CropMedia(
      {Key? key,
      required this.title,
      required this.file,
      required this.checktype})
      : super(key: key);

  @override
  CropMediaState createState() => CropMediaState();
}

class CropMediaState extends State<CropMedia>
    with SingleTickerProviderStateMixin {
  CropController controller = CropController();
  bool isFinished = true;
  bool _hasChanges = false;

  // Animation controller - using nullable types instead of late
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set aspect ratio based on checktype for better user experience
    double aspectRatio = 1.0; // Default square
    if (widget.checktype == 'profile') {
      aspectRatio = 1.0; // Square for profile photos
    } else if (widget.checktype == 'fullbody') {
      aspectRatio = 0.75; // 3:4 for full body photos
    } else if (widget.checktype == 'activity') {
      aspectRatio = 1.33; // 4:3 for activity photos
    }

    controller = CropController(aspectRatio: aspectRatio);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
        _animationController!.forward();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _onCropChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF27AE60),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crop Your Photo",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          isFinished
              ? IconButton(
                  icon: const Icon(
                    Icons.check,
                    color: Color(0xFF27AE60),
                  ),
                  onPressed: () {
                    setState(() {
                      isFinished = false;
                    });
                    _finished().then((value) {
                      setState(() {
                        isFinished = true;
                      });
                    });
                  },
                )
              : const Padding(
                  padding: EdgeInsets.fromLTRB(0, 18, 10, 18),
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
        ],
      ),
      body: _fadeAnimation != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: _buildBodyContent(isDarkMode),
            )
          : _buildBodyContent(isDarkMode),
    );
  }

  Widget _buildBodyContent(bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child: Hero(
            tag: 'profileImage',
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: CropImage(
                controller: controller,
                image: Image.file(widget.file),
                gridColor: Colors.white,
                gridCornerSize: 25,
                gridThinWidth: 1,
                gridThickWidth: 1,
                alwaysShowThirdLines: true,
                minimumImageSize: 150,
              ),
            ),
          ),
        ),

        // Instruction text
        Container(
          color: isDarkMode ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "Tip: Make sure your face is clearly visible.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),

        // Bottom toolbar
        Container(
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolbarButton(
                Icons.rotate_90_degrees_ccw,
                "Rotate Left",
                () {
                  controller.rotateLeft();
                  _onCropChanged();
                },
              ),
              _buildToolbarButton(
                Icons.rotate_90_degrees_cw,
                "Rotate Right",
                () {
                  controller.rotateRight();
                  _onCropChanged();
                },
              ),
              _buildToolbarButton(
                Icons.refresh,
                "Reset",
                () {
                  // Recreate controller to reset
                  final aspectRatio = controller.aspectRatio;
                  controller.dispose();
                  setState(() {
                    controller = CropController(aspectRatio: aspectRatio);
                  });
                  _onCropChanged();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFF27AE60),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF27AE60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finished() async {
    try {
      final image = await controller.croppedBitmap();

      // Use JPEG format for better compression and smaller file sizes
      final data = await image.toByteData(format: ImageByteFormat.rawRgba);
      if (data == null) {
        throw Exception('Failed to get image data');
      }

      // Convert to JPEG for better compression
      final bytes = data.buffer.asUint8List();
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = tempDir.path;
      Random random = Random();
      int randomNumber = random.nextInt(1000);
      var filePath =
          '$tempPath/cropped_${DateTime.now().millisecondsSinceEpoch}_$randomNumber.jpg';

      // Write as JPEG with proper quality
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Compress the final image for optimal size
      final compressedFile = await _compressImage(file);

      // ignore: use_build_context_synchronously
      Navigator.pop(context, compressedFile);
    } catch (e) {
      debugPrint('Error in _finished: $e');
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  /// Compress the cropped image to optimal size
  Future<File> _compressImage(File imageFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Use flutter_image_compress for better compression
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        compressedPath,
        quality: 85, // High quality for profile photos
        minWidth: 400,
        minHeight: 400,
        format: CompressFormat.jpeg,
        keepExif: false, // Remove EXIF data for privacy
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      } else {
        return imageFile; // Return original if compression fails
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }
}
