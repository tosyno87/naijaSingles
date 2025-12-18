import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RotatingGreetingWidget extends StatelessWidget {
  const RotatingGreetingWidget({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 30,
      child: DefaultTextStyle(
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF3E1F0D), // Deep brown color
        ),
        child: AnimatedTextKit(
          repeatForever: true,
          pause: const Duration(seconds: 2),
          animatedTexts: [
            FadeAnimatedText(
              'Nnoo',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Karibu',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Barka da zuwa',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Wamkelekile',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Akwaaba',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Bienvenue',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Muraho',
              fadeInEnd: 0.2,
            ),
            FadeAnimatedText(
              'Salam',
              fadeInEnd: 0.2,
            ),
          ],
        ),
      ),
    );
}
