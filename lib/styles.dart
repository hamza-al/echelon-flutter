import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool _isDark = true;
  static bool get isDark => _isDark;

  static final ValueNotifier<bool> themeNotifier = ValueNotifier(true);

  static void setMode({required bool dark}) {
    _isDark = dark;
    themeNotifier.value = dark;
  }

  // Core palette
  static Color get background =>
      _isDark ? const Color(0xFF0C0A09) : const Color(0xFFF7F5F3);
  static Color get surface =>
      _isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFFFF);
  static Color get surfaceLight =>
      _isDark ? const Color(0xFF292524) : const Color(0xFFF0EDEB);

  static Color get textPrimary =>
      _isDark ? const Color(0xFFFAFAF9) : const Color(0xFF292524);
  static Color get textSecondary =>
      _isDark ? const Color(0xFFA8A29E) : const Color(0xFF78716C);
  static Color get textMuted =>
      _isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E);

  static Color get border =>
      _isDark ? const Color(0xFF292524) : const Color(0xFFD6D3D1);
  static Color get borderSubtle =>
      _isDark ? const Color(0xFF1C1917) : const Color(0xFFE7E5E4);
  static Color get divider =>
      _isDark ? const Color(0xFF292524) : const Color(0xFFE7E5E4);

  // Backward-compatible aliases
  static Color get accent => textPrimary;
  static Color get text => textPrimary;
  static Color get cardBackground => surface;

  // Brand violet (sphere, special elements)
  static Color get primary =>
      _isDark ? const Color(0xFF7C3AED) : const Color(0xFF8B5CF6);
  static Color get primaryLight =>
      _isDark ? const Color(0xFFA78BFA) : const Color(0xFFB197FC);
  static Color get primaryDark =>
      _isDark ? const Color(0xFF6D28D9) : const Color(0xFF7C3AED);

  // Theme-aware overlay (white in dark, warm grey in light)
  static Color get overlay =>
      _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF44403C);

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
    Color? color,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color ?? AppColors.textPrimary,
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

  // ---- Primary marketing CTAs (Let's go, See plans, paywall, etc.) ----

  static BoxDecoration vibrantCtaDecoration({double radius = 14}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryDark,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.42),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static BoxDecoration vibrantCtaDecorationDisabled({double radius = 14}) {
    return BoxDecoration(
      color: AppColors.overlay.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.overlay.withValues(alpha: 0.08),
        width: 0.5,
      ),
    );
  }

  static TextStyle vibrantCtaText() => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Colors.white,
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
