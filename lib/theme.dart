import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bgTop = Color(0xFF420909);
  static const accent = Color(0xFFE53935);
  static const textPri = Colors.white;
  static const textSec = Color(0xB3FFFFFF);

  static TextStyle title() => GoogleFonts.alumniSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: textPri,
  );

  static TextStyle artist() => GoogleFonts.alumniSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textSec,
  );

  static ThemeData theme() => ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
    useMaterial3: true,
    textTheme:
    GoogleFonts.alumniSansTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionColor: Color.fromRGBO(255, 255, 255, 0.12),
      selectionHandleColor: Colors.white,
    ),
  );
}
