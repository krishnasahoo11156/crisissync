import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// CrisisSync Design System — "The Orchestrated Pulse"
///
/// Built for high-stakes decision-making under pressure. Combines rigid,
/// technical precision with fluid, atmospheric depth.
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ── Core backgrounds (deep space void with blue undertone) ──
  static const Color void_ = Color(0xFF0E0E13);
  static const Color surface = Color(0xFF131319);
  static const Color surfaceContainer = Color(0xFF19191F);
  static const Color elevated = Color(0xFF1F1F26);
  static const Color surfaceHighest = Color(0xFF25252D);
  static const Color surfaceBright = Color(0xFF2C2B33);

  // ── Ghost borders (barely-there structural hints) ──
  static const Color borderDark = Color(0xFF2A2A35);
  static const Color borderGhost = Color(0x2648474D); // 15% outline_variant
  static const Color borderSubtle = Color(0x1AF9F5FD); // 10% on_surface

  // ── Primary — Royal Purple (system triggers & authority) ──
  static const Color primaryPurple = Color(0xFFB6A0FF);
  static const Color primaryPurpleDim = Color(0xFF7E51FF);
  static const Color primaryPurpleDeep = Color(0xFF6834EB);

  // ── Legacy alias (keep imports working) ──
  static const Color geminiPurple = primaryPurple;

  // ── Secondary — Signal Teal (guest portals & resolution) ──
  static const Color signalTeal = Color(0xFF68FADD);
  static const Color signalTealDim = Color(0xFF56EBCF);
  static const Color signalTealContainer = Color(0xFF006B5C);

  // ── Tertiary — Coral (staff & active crisis) ──
  static const Color crisisRed = Color(0xFFFF716C);
  static const Color crisisRedDim = Color(0xFFF94D4E);
  static const Color crisisGlow = Color(0x40FF716C);

  // ── Amber Alert ──
  static const Color amberAlert = Color(0xFFFFB74D);

  // ── Text hierarchy ──
  static const Color textPrimary = Color(0xFFF9F5FD);
  static const Color textSecondary = Color(0xFFACAAB1);
  static const Color textMuted = Color(0xFF76747B);

  // ── Guest portal (light theme) ──
  static const Color guestBg = Color(0xFFF8F9FA);
  static const Color guestCard = Color(0xFFFFFFFF);
  static const Color guestBorder = Color(0xFFE8E8EC);

  // ── Crisis type colors ──
  static const Color fireColor = Color(0xFFFF8C00);
  static const Color medicalColor = Color(0xFF5B9BFF);
  static const Color securityColor = Color(0xFF8B8FA3);

  // ── Severity colors (refined gradient) ──
  static const Map<int, Color> severityBg = {
    1: Color(0xFF132E1B),
    2: Color(0xFF0D2E2A),
    3: Color(0xFF2E2200),
    4: Color(0xFF2E1500),
    5: Color(0xFF2A0A08),
  };

  static const Map<int, Color> severityText = {
    1: Color(0xFF4CAF50),
    2: Color(0xFF68FADD),
    3: Color(0xFFFFB74D),
    4: Color(0xFFFF8A65),
    5: Color(0xFFFF716C),
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

/// ─────────────────────────────────────────────────────────────────────────────
/// Typography — Three-font system
///
/// • Space Grotesk → Headlines & display (tech-brutalist authority)
/// • Manrope       → Body & titles (modern, functional readability)
/// • JetBrains Mono → Data, timestamps, codes (technical precision)
/// ─────────────────────────────────────────────────────────────────────────────

class AppTextStyles {
  AppTextStyles._();

  /// Display & headline font — Space Grotesk (geometric, authoritative)
  static TextStyle clashDisplay({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Body font — Manrope (clean, functional readability)
  static TextStyle dmSans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  /// Monospace font — JetBrains Mono (data, timestamps, IDs)
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
  static const double sos = 70;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Animation constants — consistent motion language
/// ─────────────────────────────────────────────────────────────────────────────

class AppAnimation {
  AppAnimation._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pulse = Duration(milliseconds: 1500);
  static const Duration stagger = Duration(milliseconds: 80);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// App theme data — "Aegis Protocol" dark theme
/// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.void_,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surfaceContainer,
      dividerColor: AppColors.borderDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.signalTeal,
        tertiary: AppColors.crisisRed,
        surface: AppColors.surface,
        error: AppColors.crisisRed,
        onPrimary: Color(0xFF340090),
        onSecondary: Color(0xFF005D4F),
        onSurface: AppColors.textPrimary,
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
        bodySmall: AppTextStyles.dmSans(fontSize: 12, color: AppColors.textSecondary),
        labelLarge: AppTextStyles.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
        labelSmall: AppTextStyles.jetBrainsMono(fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.void_,
        elevation: 0,
        titleTextStyle: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.clashDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderGhost),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTextStyles.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderGhost),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.borderGhost),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
        ),
        hintStyle: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
        labelStyle: AppTextStyles.dmSans(fontSize: 14, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.elevated,
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
        displayLarge: AppTextStyles.clashDisplay(fontSize: 72, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
        headlineLarge: AppTextStyles.clashDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
        headlineMedium: AppTextStyles.clashDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
        titleLarge: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
        titleMedium: AppTextStyles.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A2E)),
        bodyLarge: AppTextStyles.dmSans(fontSize: 16, color: const Color(0xFF1A1A2E)),
        bodyMedium: AppTextStyles.dmSans(fontSize: 14, color: const Color(0xFF1A1A2E)),
        bodySmall: AppTextStyles.dmSans(fontSize: 12, color: const Color(0xFF6B6B80)),
        labelLarge: AppTextStyles.dmSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A2E)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.guestCard,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        titleTextStyle: AppTextStyles.clashDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E)),
      ),
    );
  }
}
