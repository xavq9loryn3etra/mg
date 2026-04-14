import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF10002B);
  static const Color backgroundLight = Color(0xFF240046);
  
  static const Color surface = Color(0xFF3C096C);
  static const Color surfaceStroke = Color(0xFF7B2CBF);
  
  static const Color primary = Color(0xFFD90429); // Crimson Red
  static const Color primaryDark = Color(0xFF8D0801); 
  
  static const Color success = Color(0xFF2ECC71); // Emerald
  static const Color successDark = Color(0xFF27AE60);
  
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
  
  static const Color accent = Color(0xFFFFB703); // Golden
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFBCA2D4);

  // Gamified Background Gradient
  static const BoxDecoration bgGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [backgroundDark, backgroundLight],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lilitaOne(
          fontSize: 48,
          color: textMain,
          shadows: [
            const Shadow(color: Colors.black54, offset: Offset(2, 4), blurRadius: 4),
          ]
        ),
        displayMedium: GoogleFonts.lilitaOne(
          fontSize: 32,
          color: textMain,
        ),
        titleLarge: GoogleFonts.lilitaOne(
          fontSize: 24,
          color: textMain,
        ),
        titleMedium: GoogleFonts.lilitaOne(
          fontSize: 20,
          color: textMain,
        ),
        bodyLarge: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: textMain),
        bodyMedium: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: textMain),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF5A189A).withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: surfaceStroke, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: surfaceStroke, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accent, width: 3),
        ),
        labelStyle: GoogleFonts.nunito(color: Colors.white70, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: surfaceStroke, width: 3),
        ),
        titleTextStyle: GoogleFonts.lilitaOne(fontSize: 24, color: textMain),
        contentTextStyle: GoogleFonts.nunito(fontSize: 18, color: textMain, fontWeight: FontWeight.bold),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(surfaceStroke.withOpacity(0.8)),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
        interactive: true,
      ),


      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

