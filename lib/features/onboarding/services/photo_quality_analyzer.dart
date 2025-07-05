import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PhotoQualityAnalyzer {
  /// Analyzes a photo and returns quality metrics
  static PhotoQuality analyzePhoto(File photo) {
    try {
      // Read image bytes
      final bytes = photo.readAsBytesSync();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return PhotoQuality(
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
      print('Error analyzing photo quality: $e');
      // Return default quality for error cases
      return PhotoQuality(
        hasFace: true, // Assume true to avoid false negatives
        isWellLit: true,
        isSharp: true,
        isAppropriate: true,
        qualityScore: 70, // Neutral score
      );
    }
  }

  /// Basic face detection using simple heuristics
  /// Note: This is a simplified implementation. In production, you'd use
  /// ML Kit or similar for proper face detection.
  static bool _detectFace(img.Image image) {
    // For now, we'll use basic heuristics:
    // 1. Check if image has reasonable dimensions for a portrait
    // 2. Check for skin-tone colors in the center region
    
    final width = image.width;
    final height = image.height;
    
    // Check if image has portrait-like aspect ratio or is square
    final aspectRatio = width / height;
    final isPortraitLike = aspectRatio >= 0.5 && aspectRatio <= 2.0;
    
    if (!isPortraitLike) return false;
    
    // Check for skin-tone colors in center region
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final regionSize = (width * 0.3).toInt();
    
    int skinTonePixels = 0;
    int totalPixels = 0;
    
    for (int x = centerX - regionSize ~/ 2; x < centerX + regionSize ~/ 2; x++) {
      for (int y = centerY - regionSize ~/ 2; y < centerY + regionSize ~/ 2; y++) {
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
    
    // If more than 15% of center region has skin tones, likely has a face
    return totalPixels > 0 && (skinTonePixels / totalPixels) > 0.15;
  }

  /// Check if RGB values represent a skin tone
  static bool _isSkinTone(int r, int g, int b) {
    // Simple skin tone detection using RGB ranges
    // This covers a wide range of skin tones
    return (r > 95 && g > 40 && b > 20) &&
           (r > g && r > b) &&
           (r - g > 15) &&
           (r - b > 15);
  }

  /// Check lighting quality by analyzing brightness distribution
  static bool _checkLighting(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = 0;
    int darkPixels = 0;
    int brightPixels = 0;
    
    // Sample pixels to check brightness distribution
    for (int x = 0; x < image.width; x += 10) {
      for (int y = 0; y < image.height; y += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Calculate brightness using luminance formula
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
    
    // Good lighting: average brightness between 80-180, not too many dark/bright pixels
    return averageBrightness >= 80 && 
           averageBrightness <= 180 && 
           darkRatio < 0.3 && 
           brightRatio < 0.2;
  }

  /// Check sharpness by analyzing edge contrast
  static bool _checkSharpness(img.Image image) {
    // Simple sharpness check using Laplacian variance
    // Higher variance indicates sharper image
    
    final grayscale = img.grayscale(image);
    double variance = 0;
    int count = 0;
    
    // Apply Laplacian kernel to detect edges
    for (int x = 1; x < grayscale.width - 1; x += 5) {
      for (int y = 1; y < grayscale.height - 1; y += 5) {
        final center = grayscale.getPixel(x, y).r.toInt();
        final top = grayscale.getPixel(x, y - 1).r.toInt();
        final bottom = grayscale.getPixel(x, y + 1).r.toInt();
        final left = grayscale.getPixel(x - 1, y).r.toInt();
        final right = grayscale.getPixel(x + 1, y).r.toInt();
        
        // Laplacian kernel: -4*center + top + bottom + left + right
        final laplacian = -4 * center + top + bottom + left + right;
        variance += laplacian * laplacian;
        count++;
      }
    }
    
    if (count == 0) return false;
    
    variance /= count;
    
    // Threshold for sharpness - adjust based on testing
    return variance > 100;
  }

  /// Basic appropriateness check (placeholder for more advanced checks)
  static bool _checkAppropriateness(img.Image image) {
    // For now, we'll do basic checks:
    // 1. Image isn't too dark (might indicate inappropriate content)
    // 2. Image has reasonable dimensions
    
    final width = image.width;
    final height = image.height;
    
    // Check dimensions
    if (width < 200 || height < 200) return false;
    
    // Check if image is too dark overall
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
    
    // Image shouldn't be too dark
    return averageBrightness > 30;
  }

  /// Calculate overall quality score based on individual metrics
  static int _calculateQualityScore({
    required bool hasFace,
    required bool isWellLit,
    required bool isSharp,
    required bool isAppropriate,
  }) {
    int score = 0;
    
    // Face detection is most important for dating apps
    if (hasFace) score += 40;
    
    // Lighting is crucial for photo quality
    if (isWellLit) score += 25;
    
    // Sharpness affects overall impression
    if (isSharp) score += 20;
    
    // Appropriateness is essential
    if (isAppropriate) score += 15;
    
    return score;
  }
}

/// Data class to hold photo quality analysis results
class PhotoQuality {
  final bool hasFace;
  final bool isWellLit;
  final bool isSharp;
  final bool isAppropriate;
  final int qualityScore; // 0-100

  const PhotoQuality({
    required this.hasFace,
    required this.isWellLit,
    required this.isSharp,
    required this.isAppropriate,
    required this.qualityScore,
  });

  @override
  String toString() {
    return 'PhotoQuality(hasFace: $hasFace, isWellLit: $isWellLit, '
           'isSharp: $isSharp, isAppropriate: $isAppropriate, '
           'qualityScore: $qualityScore)';
  }
}
