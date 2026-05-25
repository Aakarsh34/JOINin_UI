import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep Navy / Charcoal Base
  static const Color darkBackground = Color(0xFF0D1117); 
  static const Color cardDark = Color(0xFF161B22);
  static const Color cardDarkElevated = Color(0xFF21262D);
  
  // Vibrant Accent Colors
  static const Color primaryAccent = Color(0xFF00FF87); // Electric Green
  static const Color secondaryAccent = Color(0xFF00B4D8); // Bright Blue
  
  static const Color textLight = Color(0xFFF0F6FC);
  static const Color textMuted = Color(0xFF8B949E);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: darkBackground,
      cardColor: cardDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: textLight,
        displayColor: textLight,
      ).copyWith(
        displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textLight),
        headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textLight),
        titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, color: textLight),
        labelMedium: GoogleFonts.firaCode(fontWeight: FontWeight.w500, color: textLight), // Monospace for numbers
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: cardDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: textLight),
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(color: textLight, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryAccent,
        unselectedItemColor: textMuted,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: darkBackground,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}
