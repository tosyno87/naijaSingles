import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class MyThemes {
  static final darkTheme = ThemeData(
      // for appbar color
      scaffoldBackgroundColor: const Color(0xff1E1E1E),
      primaryColor: const Color(0xff252020),
      colorScheme: const ColorScheme.dark(),
      fontFamily: GoogleFonts.lato().fontFamily,
      useMaterial3: false);

  static final lightTheme = ThemeData(
      // for appbar color
      scaffoldBackgroundColor: primaryColor,
      primaryColor: Colors.white,
      colorScheme: const ColorScheme.light(),
      fontFamily: GoogleFonts.lato().fontFamily,
      useMaterial3: false);
}
