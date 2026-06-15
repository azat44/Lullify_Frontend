import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Quicksand pour le corps — lisible et doux
  // VT323 pour les titres display — pixel art / vaporwave
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.vt323(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 2,
      ),
      displayMedium: GoogleFonts.vt323(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.quicksand(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}