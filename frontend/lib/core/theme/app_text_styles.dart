import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ---------------------------------------------------------------------------
  // Display & Screen Headings (Apple style clean sans-serif)
  // ---------------------------------------------------------------------------
  static TextStyle get displayLg => GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get headlineSm => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Section & Card Titles
  // ---------------------------------------------------------------------------
  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.3,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      );

  // ---------------------------------------------------------------------------
  // Body & Content
  // ---------------------------------------------------------------------------
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.3,
        height: 1.45,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.45,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
      );

  static TextStyle get bodyMdMuted => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
        height: 1.45,
      );

  // ---------------------------------------------------------------------------
  // Labels, Captions & Status
  // ---------------------------------------------------------------------------
  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.35,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.35,
      );

  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Tabular Numbers for Dashboards, Scanners & Counters
  // ---------------------------------------------------------------------------
  static TextStyle get metricLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get metricMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get monoCode => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ---------------------------------------------------------------------------
  // Buttons
  // ---------------------------------------------------------------------------
  static TextStyle get buttonLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get buttonMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle get buttonSm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );
}
