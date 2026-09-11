import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/design_system.dart';

/// Design tokens for the College ERP app.
///
/// Palette is inspired by academic regalia: deep navy (the "gown"),
/// a warm brass/gold (the "medal"), and a soft parchment background.
/// This keeps the app from reading like a generic blue-and-white
/// admin dashboard template.
class AppColors {
  AppColors._();

  static const Color navy = ErpColors.primary;
  static const Color navyLight = ErpColors.primaryLight;
  static const Color brass = ErpColors.accent;
  static const Color brassLight = ErpColors.accentLight;
  static const Color parchment = ErpColors.bg;
  static const Color card = ErpColors.bgCard;
  static const Color ink = ErpColors.textPrimary;
  static const Color inkMuted = ErpColors.textMuted;
  static const Color success = ErpColors.success;
  static const Color danger = ErpColors.danger;
  static const Color warning = ErpColors.warning;
  static const Color divider = ErpColors.divider;

  // Module accent colors (used sparingly, one per module card)
  static const Color moduleAttendance = ErpColors.attendance;
  static const Color moduleResults = ErpColors.results;
  static const Color moduleFees = ErpColors.fees;
  static const Color moduleTimetable = ErpColors.timetable;
  static const Color moduleLibrary = ErpColors.library;
  static const Color moduleNotices = ErpColors.accent;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.ink),
      displayMedium: GoogleFonts.poppins(
          fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.ink),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
      titleMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: AppColors.ink),
      bodyMedium: GoogleFonts.inter(fontSize: 13.5, color: AppColors.inkMuted),
      labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.inkMuted),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.parchment,
      primaryColor: AppColors.navy,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.navy,
        secondary: AppColors.brass,
        surface: AppColors.card,
        error: AppColors.danger,
      ),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navy, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.inkMuted,
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
