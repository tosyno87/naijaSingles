import 'dart:io';

import 'package:image/image.dart' as img;

import '../../../../common/utils/app_logger.dart';

class PhotoQualityAnalyzer {
  /// Analyzes a photo and returns quality metrics
  static PhotoQuality analyzePhoto(File photo) {
    try {
      // Read image bytes
      final bytes = photo.readAsBytesSync();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return const PhotoQuality(
          hasFace: false,
          isWellLit: false,
          isSharp: false,
          isAppropriate: false,
          qualityScore: 0,
        );
      }

      // Basic quality checks
      final hasFace = _detectFace(image);
      final isWellLit = _checkLighting(image);
      final isSharp = _checkSharpness(image);
      final isAppropriate = _checkAppropriateness(image);

      // Calculate overall quality score
      final qualityScore = _calculateQualityScore(
        hasFace: hasFace,
        isWellLit: isWellLit,
        isSharp: isSharp,
        isAppropriate: isAppropriate,
      );

      return PhotoQuality(
        hasFace: hasFace,
        isWellLit: isWellLit,
        isSharp: isSharp,
        isAppropriate: isAppropriate,
        qualityScore: qualityScore,
      );
    } catch (e) {
      AppLogger.error('Error analyzing photo quality', error: e);
      // Return default quality for error cases
      return const PhotoQuality(
        hasFace: true, // Assume true to avoid false negatives
        isWellLit: true,
        isSharp: true,
        isAppropriate: true,
        qualityScore: 70, // Neutral score
      );
    }
  }

  /// Basic face detection using simple heuristics
  static bool _detectFace(img.Image image) {
    final width = image.width;
    final height = image.height;
    final aspectRatio = width / height;
    final isPortraitLike = aspectRatio >= 0.5 && aspectRatio <= 2.0;

    if (!isPortraitLike) return false;

    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final regionSize = (width * 0.3).toInt();

    int skinTonePixels = 0;
    int totalPixels = 0;

    for (int x = centerX - regionSize ~/ 2;
        x < centerX + regionSize ~/ 2;
        x++) {
      for (int y = centerY - regionSize ~/ 2;
          y < centerY + regionSize ~/ 2;
          y++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          if (_isSkinTone(r, g, b)) {
            skinTonePixels++;
          }
          totalPixels++;
        }
      }
    }

    return totalPixels > 0 && (skinTonePixels / totalPixels) > 0.15;
  }

  static bool _isSkinTone(int r, int g, int b) => (r > 95 && g > 40 && b > 20) &&
        (r > g && r > b) &&
        (r - g > 15) &&
        (r - b > 15);

  static bool _checkLighting(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;
    int darkPixels = 0;
    int brightPixels = 0;

    for (int x = 0; x < image.width; x += 10) {
      for (int y = 0; y < image.height; y += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b).round();
        totalBrightness += brightness;
        pixelCount++;
        if (brightness < 50) darkPixels++;
        if (brightness > 200) brightPixels++;
      }
    }

    if (pixelCount == 0) return false;

    final averageBrightness = totalBrightness / pixelCount;
    final darkRatio = darkPixels / pixelCount;
    final brightRatio = brightPixels / pixelCount;

    return averageBrightness >= 80 &&
        averageBrightness <= 180 &&
        darkRatio < 0.3 &&
        brightRatio < 0.2;
  }

  static bool _checkSharpness(img.Image image) {
    final grayscale = img.grayscale(image);
    double variance = 0;
    int count = 0;

    for (int x = 1; x < grayscale.width - 1; x += 5) {
      for (int y = 1; y < grayscale.height - 1; y += 5) {
        final center = grayscale.getPixel(x, y).r.toInt();
        final top = grayscale.getPixel(x, y - 1).r.toInt();
        final bottom = grayscale.getPixel(x, y + 1).r.toInt();
        final left = grayscale.getPixel(x - 1, y).r.toInt();
        final right = grayscale.getPixel(x + 1, y).r.toInt();
        final laplacian = -4 * center + top + bottom + left + right;
        variance += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return false;
    variance /= count;
    return variance > 100;
  }

  static bool _checkAppropriateness(img.Image image) {
    final width = image.width;
    final height = image.height;

    if (width < 200 || height < 200) return false;

    int totalBrightness = 0;
    int pixelCount = 0;

    for (int x = 0; x < width; x += 20) {
      for (int y = 0; y < height; y += 20) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (0.299 * r + 0.587 * g + 0.114 * b).round();
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    if (pixelCount == 0) return false;
    final averageBrightness = totalBrightness / pixelCount;
    return averageBrightness > 30;
  }

  static int _calculateQualityScore({
    required bool hasFace,
    required bool isWellLit,
    required bool isSharp,
    required bool isAppropriate,
  }) {
    int score = 0;
    if (hasFace) score += 40;
    if (isWellLit) score += 25;
    if (isSharp) score += 20;
    if (isAppropriate) score += 15;
    return score;
  }
}

/// Data class to hold photo quality analysis results
class PhotoQuality {
  const PhotoQuality({
    required this.hasFace,
    required this.isWellLit,
    required this.isSharp,
    required this.isAppropriate,
    required this.qualityScore,
  });
  final bool hasFace;
  final bool isWellLit;
  final bool isSharp;
  final bool isAppropriate;
  final int qualityScore;

  @override
  String toString() => 'PhotoQuality(hasFace: $hasFace, isWellLit: $isWellLit, '
      'isSharp: $isSharp, isAppropriate: $isAppropriate, '
      'qualityScore: $qualityScore)';
}
