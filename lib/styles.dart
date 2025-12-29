import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Colors.black;
  static const Color accent = Colors.white;
  static const Color text = Colors.white; // Alias for accent
  static const Color cardBackground = Color(0xFF1C1C1E); // Dark card background
  static const Color primary = Color(0xFF7C3AED); // Vibrant purple (Violet-600)
  static const Color primaryLight = Color(0xFFA78BFA); // Lighter purple
  static const Color primaryDark = Color(0xFF6D28D9); // Darker purple
  
  // Recording sphere colors (orange)
  static const Color recordingPrimary = Color(0xFFFF8C00);
  static const Color recordingSecondary = Color(0xFFFF7700);
  static const Color recordingAccent = Color(0xFFFF6600);
  static const Color recordingHighlight = Color(0xFFFF9900);
}

class AppStyles {
  static TextStyle mainHeader() {
    return GoogleFonts.instrumentSerif(
      fontSize: 48,
      letterSpacing: -0.02,
      color: AppColors.accent,
      fontStyle: FontStyle.italic,
    );
  }

  static TextStyle mainText() {
    return GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.01,
      color: AppColors.accent,
    );
  }

  static TextStyle secondaryHeader() {
    return GoogleFonts.bebasNeue( 
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: AppColors.accent,
      height: 1.0,
    );
  }

  static TextStyle questionText() {
    return GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.01,
      color: AppColors.accent,
    );
  }

  static TextStyle questionSubtext() {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      color: AppColors.accent.withOpacity(0.7),
    );
  }

  static TextStyle pageHeader() {
    return GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppColors.accent,
    );
  }
}

