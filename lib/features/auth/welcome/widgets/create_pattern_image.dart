import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// This is a utility function to create a simple African pattern image
/// Run this function once to generate the pattern image and save it to the assets folder
Future<void> createAfricanPatternImage() async {
  // Create a picture recorder
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Define the size of the pattern
  const size = Size(500, 500);
  
  // Define colors
  final backgroundColor = const Color(0xFFFFF6E5);
  final patternColor = const Color(0xFF008037).withOpacity(0.2);
  
  // Fill the background
  final backgroundPaint = Paint()..color = backgroundColor;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
  
  // Draw the pattern
  final patternPaint = Paint()
    ..color = patternColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  
  // Draw geometric patterns
  // Triangles
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      final path = Path();
      path.moveTo(i * 50 + 25, j * 50);
      path.lineTo(i * 50 + 50, j * 50 + 50);
      path.lineTo(i * 50, j * 50 + 50);
      path.close();
      canvas.drawPath(path, patternPaint);
    }
  }
  
  // Circles
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      canvas.drawCircle(
        Offset(i * 50 + 25, j * 50 + 25),
        10,
        patternPaint,
      );
    }
  }
  
  // Zigzag lines
  for (int i = 0; i < 10; i++) {
    final path = Path();
    path.moveTo(0, i * 50 + 25);
    for (int j = 0; j < 10; j++) {
      path.lineTo(j * 50 + 25, i * 50 + 12.5);
      path.lineTo(j * 50 + 50, i * 50 + 25);
    }
    canvas.drawPath(path, patternPaint);
  }
  
  // End the recording and convert to an image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save the image to the assets folder
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/african_pattern.png');
  await file.writeAsBytes(buffer);
  
  print('Pattern image created at: ${file.path}');
  print('Copy this file to your assets folder: asset/images/african_pattern.png');
}
