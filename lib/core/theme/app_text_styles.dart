import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Syne - Headlines
  static TextStyle get displayLg => GoogleFonts.syne(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        letterSpacing: -0.02 * 40,
        height: 1.15,
      );

  static TextStyle get headlineLg => GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.01 * 28,
        height: 1.2,
      );

  static TextStyle get headlineMd => GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  static TextStyle get headlineSm => GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        height: 1.3,
      );

  // Inter - Body
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.6,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.5,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceMuted,
        height: 1.4,
      );

  static TextStyle get bodyMdMuted => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceMuted,
        height: 1.5,
      );

  // JetBrains Mono - Labels/Code
  static TextStyle get labelLg => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        letterSpacing: 0.05 * 13,
        height: 1.4,
      );

  static TextStyle get labelMd => GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
        letterSpacing: 0.08 * 11,
        height: 1.4,
      );

  static TextStyle get labelSm => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceMuted,
        letterSpacing: 0.06 * 10,
        height: 1.3,
      );

  static TextStyle get monoCode => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.04 * 12,
      );

  // Gradient text helper - use with ShaderMask
  static TextStyle get gradientHeadline => GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.01 * 28,
      );

  // Button labels
  static TextStyle get buttonLg => GoogleFonts.syne(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonMd => GoogleFonts.syne(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      );
}
