import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageUtils {
  // Background categories and their images
  static const Map<String, List<String>> backgroundCategories = {
    'Blue Nebula': [
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_01-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_02-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_03-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_04-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_05-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_06-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_07-1024x1024.png',
      'resources/Backgrounds/Blue Nebula/Blue_Nebula_08-1024x1024.png',
    ],
    'Green Nebula': [
      'resources/Backgrounds/Green Nebula/Green_Nebula_01-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_02-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_03-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_04-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_05-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_06-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_07-1024x1024.png',
      'resources/Backgrounds/Green Nebula/Green_Nebula_08-1024x1024.png',
    ],
    'Purple Nebula': [
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_01-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_02-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_03-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_04-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_05-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_06-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_07-1024x1024.png',
      'resources/Backgrounds/Purple Nebula/Purple_Nebula_08-1024x1024.png',
    ],
    'Starfields': [
      'resources/Backgrounds/Starfields/Starfield_01-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_02-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_03-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_04-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_05-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_06-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_07-1024x1024.png',
      'resources/Backgrounds/Starfields/Starfield_08-1024x1024.png',
    ],
  };

  // Ball image list
  static List<String> get ballImages {
    return List.generate(
      56,
      (index) =>
          'resources/Balls/OrbsWithoutOutline_${index.toString().padLeft(4, '0')}_Circle.png',
    );
  }

  /// Get a random background image path
  static String getRandomBackgroundImage() {
    final random = Random();
    final categories = backgroundCategories.values.toList();
    final randomCategory = categories[random.nextInt(categories.length)];
    return randomCategory[random.nextInt(randomCategory.length)];
  }

  /// Get a random ball image path
  static String getRandomBallImage() {
    final random = Random();
    final balls = ballImages;
    return balls[random.nextInt(balls.length)];
  }

  /// Create a custom image with a letter overlay on a ball image
  /// This paints a letter on top of the ball image
  static Future<ui.Image> createBallWithLetter(
    String ballImagePath,
    String letter,
    double size,
  ) async {
    try {
      // Load the ball image
      final ByteData ballImageData = await rootBundle.load(ballImagePath);
      final ui.Codec ballCodec = await ui.instantiateImageCodec(
        ballImageData.buffer.asUint8List(),
        targetWidth: size.toInt(),
        targetHeight: size.toInt(),
      );
      final ui.FrameInfo ballFrame = await ballCodec.getNextFrame();
      final ui.Image ballImage = ballFrame.image;

      // Create a new image with letter overlay
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw the ball image
      canvas.drawImage(ballImage, Offset.zero, Paint());

      // Draw the letter on top with shadow for visibility
      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5, // Proportional font size
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Center the text
      final offsetX = (size - textPainter.width) / 2;
      final offsetY = (size - textPainter.height) / 2;

      // Draw shadow (offset by 1 pixel, dark color)
      final shadowTextPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: Colors.black87,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      shadowTextPainter.layout();
      shadowTextPainter.paint(canvas, Offset(offsetX + 1, offsetY + 1));

      // Draw the main white text
      textPainter.paint(canvas, Offset(offsetX, offsetY));

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.toInt(),
        size.toInt(),
      );

      return image;
    } catch (e) {
      // Fallback: return a solid circle if image loading fails
      debugPrint('Error loading ball image: $e');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = Colors.blue;
      canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final offsetX = (size - textPainter.width) / 2;
      final offsetY = (size - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(offsetX, offsetY));

      final picture = recorder.endRecording();
      return picture.toImage(size.toInt(), size.toInt());
    }
  }

  /// Preload a background image
  static Future<ImageProvider> loadBackgroundImage(String imagePath) async {
    return AssetImage(imagePath);
  }

  /// Preload a ball image with letter
  static Future<ui.Image> loadBallWithLetter(
    String ballImagePath,
    String letter,
    double ballSize,
  ) async {
    return createBallWithLetter(ballImagePath, letter, ballSize);
  }
}
