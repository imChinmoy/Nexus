import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Dark Theme Definition (Apple Charcoal & Deep Slate)
  // ---------------------------------------------------------------------------
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          brightness: Brightness.dark,
          primary: AppColors.darkAccent,
          onPrimary: Colors.white,
          secondary: Color(0xFF5E5CE6),
          onSecondary: Colors.white,
          error: AppColors.errorDark,
          onError: Colors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          outline: AppColors.darkSeparator,
          surfaceContainerHighest: AppColors.darkElevatedSurface,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: AppColors.darkTextPrimary,
          displayColor: AppColors.darkTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.darkBackground,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkElevatedSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.darkAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorDark, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.errorDark, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x0AFFFFFF), width: 0.5),
          ),
          hintStyle: GoogleFonts.inter(
            color: AppColors.darkTextTertiary,
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.inter(
            color: AppColors.darkTextSecondary,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkSeparator,
          thickness: 0.5,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.darkElevatedSurface,
          contentTextStyle: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.darkAccent,
          unselectedItemColor: AppColors.darkTextTertiary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkElevatedSurface,
          side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 12),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkElevatedSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x1AFFFFFF), width: 0.5),
          ),
          elevation: 4,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
        ),
      );

  // ---------------------------------------------------------------------------
  // Light Theme Definition (Apple Clean White & Warm Silver)
  // ---------------------------------------------------------------------------
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          brightness: Brightness.light,
          primary: AppColors.lightAccent,
          onPrimary: Colors.white,
          secondary: Color(0xFF5E5CE6),
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          outline: AppColors.lightSeparator,
          surfaceContainerHighest: AppColors.lightSecondaryBackground,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: AppColors.lightTextPrimary,
          displayColor: AppColors.lightTextPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.lightTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: AppColors.lightBackground,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x0F000000), width: 0.5),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSecondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x0A000000), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x05000000), width: 0.5),
          ),
          hintStyle: GoogleFonts.inter(
            color: AppColors.lightTextTertiary,
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.inter(
            color: AppColors.lightTextSecondary,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightSeparator,
          thickness: 0.5,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.lightTextPrimary,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.lightAccent,
          unselectedItemColor: AppColors.lightTextTertiary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightSecondaryBackground,
          side: const BorderSide(color: Color(0x0F000000), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: GoogleFonts.inter(color: AppColors.lightTextSecondary, fontSize: 12),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0x0F000000), width: 0.5),
          ),
          elevation: 4,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          elevation: 8,
        ),
      );
}
