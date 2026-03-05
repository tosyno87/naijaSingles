import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen image viewer widget
class FullScreenImageViewer extends StatelessWidget {
  const FullScreenImageViewer({
    required this.imageUrl,
    super.key,
    this.title,
    this.showAppBar = true,
  });
  final String imageUrl;
  final String? title;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: showAppBar
            ? AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: title != null
                    ? Text(
                        title!,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              )
            : null,
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              errorWidget: (context, url, error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Show full-screen image viewer
  static Future<void> show({
    required BuildContext context,
    required String imageUrl,
    String? title,
    bool showAppBar = true,
  }) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenImageViewer(
            imageUrl: imageUrl,
            title: title,
            showAppBar: showAppBar,
          ),
          fullscreenDialog: true,
        ),
      );
}
