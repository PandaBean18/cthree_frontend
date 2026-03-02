import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _background = Color(0xFF12151C);
  static const Color _surface = Color(0xFF1E222A);
  static const Color _surfaceHighlight = Color(0xFF1A253A);
  static const Color _primary = Color(0xFF45A2FF);
  static const Color _secondary = Color(0xFFE157A4);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF6F7685);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      primaryColor: _primary,
      
      cardTheme: const CardThemeData(
        color: _surface,
        margin: EdgeInsets.all(8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        onSurface: _textPrimary,
        onPrimary: _textPrimary,
        surfaceContainerHighest: _surfaceHighlight, 
      ),

      textTheme: GoogleFonts.robotoMonoTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        // You can still override specific styles here
        displayLarge: GoogleFonts.robotoMono(
          color: _textPrimary, 
          fontWeight: FontWeight.bold
        ),
        bodyLarge: GoogleFonts.robotoMono(color: _textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.robotoMono(color: _textSecondary, fontSize: 14),
      ),
      
      // Also apply it to the general font family for UI components like Buttons
      fontFamily: GoogleFonts.robotoMono().fontFamily,

      // textTheme: const TextTheme(
      //   displayLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold),
      //   bodyLarge: TextStyle(color: _textPrimary, fontSize: 16),
      //   bodyMedium: TextStyle(color: _textSecondary, fontSize: 14),
      // ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        hintStyle: const TextStyle(color: _textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}