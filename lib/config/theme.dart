import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CrisisSync design system colors.
class AppColors {
  AppColors._();

  // Core dark theme
  static const Color void_ = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color elevated = Color(0xFF242424);
  static const Color borderDark = Color(0xFF333333);

  // Crisis colors
  static const Color crisisRed = Color(0xFFC0392B);
  static const Color crisisGlow = Color(0x40C0392B);
  static const Color signalTeal = Color(0xFF00BFA5);
  static const Color amberAlert = Color(0xFFFF8C00);
  static const Color geminiPurple = Color(0xFF6C63FF);

  // Guest portal
  static const Color guestBg = Color(0xFFF5F5F0);
  static const Color guestCard = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF0F0EC);
  static const Color textMuted = Color(0xFF888880);

  // Crisis type colors
  static const Color fireColor = Color(0xFFFF8C00);
  static const Color medicalColor = Color(0xFF3B82F6);
  static const Color securityColor = Color(0xFF6B7280);

  // Severity colors
  static const Map<int, Color> severityBg = {
    1: Color(0xFF1A3A1A),
    2: Color(0xFF0D2E2A),
    3: Color(0xFF3A2200),
    4: Color(0xFF3A1500),
    5: Color(0xFF2A0A08),
  };

  static const Map<int, Color> severityText = {
    1: Color(0xFF43A047),
    2: Color(0xFF00BFA5),
    3: Color(0xFFFF8C00),
    4: Color(0xFFE64A19),
    5: Color(0xFFC0392B),
  };

  static Color colorForCrisisType(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return fireColor;
      case 'medical':
        return medicalColor;
      case 'security':
        return securityColor;
      default:
        return textMuted;
    }
  }

  static Color colorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return crisisRed;
      case 'accepted':
        return amberAlert;
      case 'responding':
        return amberAlert;
      case 'escalated':
        return amberAlert;
      case 'resolved':
        return signalTeal;
      default:
        return textMuted;
    }
  }

  static Color adiColor(double score) {
    if (score <= 30) return signalTeal;
    if (score <= 60) return amberAlert;
    return crisisRed;
  }
}

/// CrisisSync text styles using Google Fonts.
class AppTextStyles {
  AppTextStyles._();

  // Clash Display — headings
  static TextStyle clashDisplay({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    // Clash Display is not on Google Fonts — use Outfit as a similar geometric display face
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // DM Sans — body
  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // JetBrains Mono — data/timestamps
  static TextStyle jetBrainsMono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textMuted,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

/// Spacing constants based on 8px grid.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Border radius constants.
class AppRadius {
  AppRadius._();

  static const double button = 8;
  static const double card = 12;
  static const double badge = 100;
  static const double modal = 16;
  static const double sos = 70; // 50% of 140
}

/// App theme data.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.void_,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      dividerColor: AppColors.borderDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.crisisRed,
        secondary: AppColors.signalTeal,
        surface: AppColors.surface,
        error: AppColors.crisisRed,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.clashDisplay(fontSize: 72, fontWeight: FontWeight.w700),
        displayMedium: AppTextStyles.clashDisplay(fontSize: 48, fontWeight: FontWeight.w700),
        headlineLarge: AppTextStyles.clashDisplay(fontSize: 28, fontWeight: FontWeight.w600),
        headlineMedium: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: AppTextStyles.dmSans(fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: AppTextStyles.dmSans(fontSize: 16),
        bodyMedium: AppTextStyles.dmSans(fontSize: 14),
        bodySmall: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textMuted),
        labelLarge: AppTextStyles.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
        labelSmall: AppTextStyles.jetBrainsMono(fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.void_,
        elevation: 0,
        titleTextStyle: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crisisRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.clashDisplay(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.crisisRed),
        ),
        hintStyle: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
        labelStyle: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
      ),
    );
  }

  static ThemeData get guestTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.guestBg,
      canvasColor: AppColors.guestCard,
      cardColor: AppColors.guestCard,
      colorScheme: const ColorScheme.light(
        primary: AppColors.crisisRed,
        secondary: AppColors.signalTeal,
        surface: AppColors.guestCard,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.clashDisplay(fontSize: 72, fontWeight: FontWeight.w700, color: Colors.black87),
        headlineLarge: AppTextStyles.clashDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black87),
        headlineMedium: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
        titleLarge: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        titleMedium: AppTextStyles.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        bodyLarge: AppTextStyles.dmSans(fontSize: 16, color: Colors.black87),
        bodyMedium: AppTextStyles.dmSans(fontSize: 14, color: Colors.black87),
        bodySmall: AppTextStyles.dmSans(fontSize: 12, color: Colors.black54),
        labelLarge: AppTextStyles.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.guestCard,
        foregroundColor: Colors.black87,
        elevation: 0,
        titleTextStyle: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }
}
