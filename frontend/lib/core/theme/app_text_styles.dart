import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Typography System for BRL Nexus
///
/// Distinct font roles:
/// - [displayFontFamily] (Space Grotesk): Display, hero headlines, featured cards,
///   dashboard section heads, and editorial titles.
/// - [interfaceFontFamily] (IBM Plex Sans): UI controls, body text, inputs,
///   buttons, tables, navigation, status chips, and metadata.
/// - Selective genuine italics (IBM Plex Sans Italic): Editorial supporting
///   phrases, subtle card descriptions, and empty-state guidance.
class AppTextStyles {
  AppTextStyles._();

  static const String displayFontFamily = 'SpaceGrotesk';
  static const String interfaceFontFamily = 'IBMPlexSans';

  // ---------------------------------------------------------------------------
  // Display & Screen Headings (Space Grotesk — Technical & Distinctive)
  // ---------------------------------------------------------------------------
  static TextStyle get displayLg => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.2,
      );

  static TextStyle get displayMd => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.22,
      );

  static TextStyle get displaySm => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineLg => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.25,
      );

  static TextStyle get headlineMd => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.3,
      );

  static TextStyle get headlineSm => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Section & Card Titles
  // ---------------------------------------------------------------------------
  static TextStyle get titleLg => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get titleMd => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.35,
      );

  static TextStyle get titleSm => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.3,
      );

  static TextStyle get cardTitle => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.3,
      );

  // ---------------------------------------------------------------------------
  // Body & Content (IBM Plex Sans — Clean & Readable)
  // ---------------------------------------------------------------------------
  static TextStyle get bodyLg => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.2,
        height: 1.45,
      );

  static TextStyle get bodyMd => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.45,
      );

  static TextStyle get bodySm => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.4,
      );

  static TextStyle get bodyMdMuted => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
        height: 1.45,
      );

  // ---------------------------------------------------------------------------
  // Selective Italic Typography (Genuine IBM Plex Sans Italic)
  // ---------------------------------------------------------------------------
  /// Editorial subtitle under primary screen headings or featured cards
  static TextStyle get editorialSubtitle => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.1,
        height: 1.45,
      );

  /// Editorial quotes, highlight callouts, or inspirational copy
  static TextStyle get editorialQuote => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.1,
        height: 1.45,
      );

  /// General inline/supporting body italic
  static TextStyle get bodyItalic => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: -0.1,
        height: 1.45,
      );

  /// Small supporting italic caption for empty states and subtle footnotes
  static TextStyle get captionItalic => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: 0.0,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Labels, Captions & Status (IBM Plex Sans)
  // ---------------------------------------------------------------------------
  static TextStyle get labelLg => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.35,
      );

  static TextStyle get labelMd => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.35,
      );

  static TextStyle get labelSm => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        height: 1.35,
      );

  // ---------------------------------------------------------------------------
  // Tabular Numbers for Dashboards, Scanners & Counters
  // ---------------------------------------------------------------------------
  static TextStyle get metricLg => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get metricMd => const TextStyle(
        fontFamily: displayFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  static TextStyle get monoCode => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  // ---------------------------------------------------------------------------
  // Buttons (IBM Plex Sans)
  // ---------------------------------------------------------------------------
  static TextStyle get buttonLg => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get buttonMd => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle get buttonSm => const TextStyle(
        fontFamily: interfaceFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
      );

  static TextStyle get button => buttonMd;

  // ---------------------------------------------------------------------------
  // Material 3 Standard Role Aliases
  // ---------------------------------------------------------------------------
  static TextStyle get displayLarge => displayLg;
  static TextStyle get displayMedium => displayMd;
  static TextStyle get displaySmall => displaySm;

  static TextStyle get headlineLarge => headlineLg;
  static TextStyle get headlineMedium => headlineMd;
  static TextStyle get headlineSmall => headlineSm;

  static TextStyle get titleLarge => titleLg;
  static TextStyle get titleMedium => titleMd;
  static TextStyle get titleSmall => titleSm;

  static TextStyle get bodyLarge => bodyLg;
  static TextStyle get bodyMedium => bodyMd;
  static TextStyle get bodySmall => bodySm;

  static TextStyle get labelLarge => labelLg;
  static TextStyle get labelMedium => labelMd;
  static TextStyle get labelSmall => labelSm;

  // ---------------------------------------------------------------------------
  // Central Material 3 TextTheme Builder
  // ---------------------------------------------------------------------------
  static TextTheme buildTextTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      displayLarge: displayLg.copyWith(color: primary),
      displayMedium: displayMd.copyWith(color: primary),
      displaySmall: displaySm.copyWith(color: primary),
      headlineLarge: headlineLg.copyWith(color: primary),
      headlineMedium: headlineMd.copyWith(color: primary),
      headlineSmall: headlineSm.copyWith(color: primary),
      titleLarge: titleLg.copyWith(color: primary),
      titleMedium: titleMd.copyWith(color: primary),
      titleSmall: titleSm.copyWith(color: primary),
      bodyLarge: bodyLg.copyWith(color: primary),
      bodyMedium: bodyMd.copyWith(color: primary),
      bodySmall: bodySm.copyWith(color: secondary),
      labelLarge: labelLg.copyWith(color: primary),
      labelMedium: labelMd.copyWith(color: secondary),
      labelSmall: labelSm.copyWith(color: secondary),
    );
  }
}
