import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core palette — warm stone tones
  static const Color background = Color(0xFF0C0A09);
  static const Color surface = Color(0xFF1C1917);
  static const Color surfaceLight = Color(0xFF292524);

  static const Color textPrimary = Color(0xFFFAFAF9);
  static const Color textSecondary = Color(0xFFA8A29E);
  static const Color textMuted = Color(0xFF57534E);

  static const Color border = Color(0xFF292524);
  static const Color borderSubtle = Color(0xFF1C1917);
  static const Color divider = Color(0xFF292524);

  // Backward-compatible aliases
  static const Color accent = textPrimary;
  static const Color text = textPrimary;
  static const Color cardBackground = surface;

  // Brand violet (sphere, special elements)
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF6D28D9);

  // Recording sphere
  static const Color recordingPrimary = Color(0xFFFF8C00);
  static const Color recordingSecondary = Color(0xFFFF7700);
  static const Color recordingAccent = Color(0xFFFF6600);
  static const Color recordingHighlight = Color(0xFFFF9900);
}

class AppStyles {
  static TextStyle _base({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
      fontStyle: fontStyle,
    );
  }

  // ---- Display ----

  static TextStyle mainHeader() => _base(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle secondaryHeader() => _base(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // ---- Body / Questions ----

  static TextStyle mainText() => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
      );

  static TextStyle questionText() => _base(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      );

  static TextStyle questionSubtext() => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle pageHeader() => _base(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  // ---- Small / Utility ----

  static TextStyle label() => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      );

  static TextStyle caption() => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  // ---- Button ----

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.textPrimary,
      foregroundColor: AppColors.background,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      disabledBackgroundColor: AppColors.textPrimary.withValues(alpha: 0.08),
      disabledForegroundColor: AppColors.textMuted,
    );
  }
}
