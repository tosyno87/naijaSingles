import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

class RotatingGreetingWidget extends StatelessWidget {
  const RotatingGreetingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF3E1F0D), // Deep brown color
        ),
        child: AnimatedTextKit(
          repeatForever: true,
          pause: const Duration(seconds: 2),
          animatedTexts: [
            FadeAnimatedText('Nnoo', 
              duration: const Duration(seconds: 2),
              fadeInEnd: 0.2,
              fadeOutBegin: 0.8,
            ),
            FadeAnimatedText('Karibu', 
              duration: const Duration(seconds: 2),
              fadeInEnd: 0.2,
              fadeOutBegin: 0.8,
            ),
            FadeAnimatedText('Barka da zuwa', 
              duration: const Duration(seconds: 2),
              fadeInEnd: 0.2,
              fadeOutBegin: 0.8,
            ),
            FadeAnimatedText('Wamkelekile', 
              duration: const Duration(seconds: 2),
              fadeInEnd: 0.2,
              fadeOutBegin: 0.8,
            ),
            FadeAnimatedText('Akwaaba', 
              duration: const Duration(seconds: 2),
              fadeInEnd: 0.2,
              fadeOutBegin: 0.8,
            ),
          ],
        ),
      ),
    );
  }
}
