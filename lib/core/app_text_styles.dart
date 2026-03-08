import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
        letterSpacing: 2,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 16,
        color: AppColors.primaryText,
      );

  static TextStyle get tagline => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.secondaryText,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w300,
      );

  static TextStyle get loading => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.secondaryText,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w300,
      );
}
