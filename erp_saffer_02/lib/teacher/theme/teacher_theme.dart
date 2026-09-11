import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// Shared color palette for the Teacher ERP panel.
/// Mirrors the Student ERP theme: parchment background, navy + brass accents.
class TeacherColors {
  TeacherColors._();

  static const Color parchment = ErpColors.bg;
  static const Color navy = ErpColors.primary;
  static const Color navyLight = ErpColors.primaryLight;
  static const Color brass = ErpColors.accent;
  static const Color brassLight = ErpColors.accentLight;
  static const Color white = ErpColors.bgWhite;

  static const Color textPrimary = ErpColors.textPrimary;
  static const Color textSecondary = ErpColors.textSecondary;
  static const Color textMuted = ErpColors.textMuted;

  static const Color success = ErpColors.success;
  static const Color danger = ErpColors.danger;
  static const Color warning = ErpColors.warning;
  static const Color info = ErpColors.info;

  static const Color divider = ErpColors.divider;
}

/// Shared text styles for the Teacher ERP panel.
class TeacherTextStyles {
  TeacherTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: TeacherColors.navy,
    letterSpacing: 0.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: TeacherColors.navy,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TeacherColors.navy,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: TeacherColors.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: TeacherColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: TeacherColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: TeacherColors.navy,
  );

  static const TextStyle brassAccent = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: TeacherColors.brass,
  );
}

/// Shared decorations (premium white cards with soft shadow, rounded corners).
class TeacherDecorations {
  TeacherDecorations._();

  static BoxDecoration card({double radius = 18, Color color = TeacherColors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: TeacherColors.navy.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration navyCard({double radius = 18}) {
    return BoxDecoration(
      color: TeacherColors.navy,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: TeacherColors.navy.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration brassBorder({double radius = 16}) {
    return BoxDecoration(
      color: TeacherColors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: TeacherColors.brass.withValues(alpha: 0.4), width: 1),
    );
  }
}

/// App-wide ThemeData for the Teacher panel (Material 3).
class TeacherAppTheme {
  TeacherAppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: TeacherColors.parchment,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TeacherColors.navy,
        primary: TeacherColors.navy,
        secondary: TeacherColors.brass,
        surface: TeacherColors.white,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: TeacherColors.parchment,
        elevation: 0,
        foregroundColor: TeacherColors.navy,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: TeacherColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TeacherColors.navy,
          foregroundColor: TeacherColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TeacherColors.navy,
          side: const BorderSide(color: TeacherColors.navy, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TeacherColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: TeacherColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: TeacherColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: TeacherColors.brass, width: 1.6),
        ),
      ),
      dividerTheme: const DividerThemeData(color: TeacherColors.divider, thickness: 1),
    );
  }
}
