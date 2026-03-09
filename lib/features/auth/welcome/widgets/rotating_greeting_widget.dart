import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RotatingGreetingWidget extends StatelessWidget {
  const RotatingGreetingWidget({
    super.key,
    this.fontSize,
    this.fontWeight,
    this.textColor,
  });

  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.montserrat(
      fontSize: fontSize ?? 18,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: textColor ?? const Color(0xFF3E1F0D),
    );

    return SizedBox(
      height: (fontSize ?? 18) * 1.6,
      child: DefaultTextStyle(
        style: style,
        child: AnimatedTextKit(
          repeatForever: true,
          pause: const Duration(seconds: 2),
          animatedTexts: [
            FadeAnimatedText('Nnoo', fadeInEnd: 0.2),
            FadeAnimatedText('Karibu', fadeInEnd: 0.2),
            FadeAnimatedText('Barka da zuwa', fadeInEnd: 0.2),
            FadeAnimatedText('Wamkelekile', fadeInEnd: 0.2),
            FadeAnimatedText('Akwaaba', fadeInEnd: 0.2),
            FadeAnimatedText('Bienvenue', fadeInEnd: 0.2),
            FadeAnimatedText('Muraho', fadeInEnd: 0.2),
            FadeAnimatedText('Salam', fadeInEnd: 0.2),
          ],
        ),
      ),
    );
  }
}
