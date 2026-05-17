import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Teal family
  static const Color teal = Color(0xFF1D9E75);
  static const Color tealLight = Color(0xFFE1F5EE);
  static const Color tealMid = Color(0xFF9FE1CB);
  static const Color tealDark = Color(0xFF085041);

  // Coral family
  static const Color coral = Color(0xFFD85A30);
  static const Color coralLight = Color(0xFFFAECE7);
  static const Color coralMid = Color(0xFFF5C4B3);

  // Amber family
  static const Color amber = Color(0xFFBA7517);
  static const Color amberLight = Color(0xFFFAEEDA);

  // Gray family
  static const Color gray = Color(0xFF888780);
  static const Color grayLight = Color(0xFFF1EFE8);
  static const Color grayMid = Color(0xFFD3D1C7);

  // Text
  static const Color text = Color(0xFF2C2C2A);
  static const Color textMuted = Color(0xFF5F5E5A);
  static const Color textHint = Color(0xFF888780);

  // Surface / background
  static const Color bg = Color(0xFFF8F6F1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD3D1C7);
}

abstract final class AppRadius {
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 9999.0;
}

abstract final class AppTextStyles {
  // Display / headings — DM Serif Display
  static TextStyle displayLarge({Color color = AppColors.text}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.2,
      );

  static TextStyle displayMedium({Color color = AppColors.text}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.25,
      );

  static TextStyle displaySmall({Color color = AppColors.text}) =>
      GoogleFonts.dmSerifDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.3,
      );

  // Body — DM Sans
  static TextStyle bodyLarge({Color color = AppColors.text}) =>
      GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color color = AppColors.text}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall({Color color = AppColors.textMuted}) =>
      GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  // UI labels (11px, caps-aware)
  static TextStyle uiLabel({Color color = AppColors.textMuted}) =>
      GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
        height: 1.4,
      );

  // UI input text
  static TextStyle uiInput({Color color = AppColors.text}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // Tagline
  static TextStyle tagline({Color color = AppColors.text}) =>
      GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  // Button
  static TextStyle button({Color color = AppColors.white}) =>
      GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
      );
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        brightness: Brightness.light,
        primary: AppColors.teal,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.tealLight,
        onPrimaryContainer: AppColors.tealDark,
        secondary: AppColors.coral,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.text,
        surfaceContainerHighest: AppColors.grayLight,
        outline: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge(),
        displayMedium: AppTextStyles.displayMedium(),
        displaySmall: AppTextStyles.displaySmall(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.bodyMedium(),
        bodySmall: AppTextStyles.bodySmall(),
        labelSmall: AppTextStyles.uiLabel(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.bodyLarge(color: AppColors.text).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.0),
        ),
        hintStyle: AppTextStyles.uiInput(color: AppColors.textHint),
        errorStyle: AppTextStyles.bodySmall(color: AppColors.coral),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.text,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(42),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button(color: AppColors.text),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.text,
        contentTextStyle: AppTextStyles.bodySmall(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.tealLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.uiLabel(color: AppColors.teal);
          }
          return AppTextStyles.uiLabel(color: AppColors.gray);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.teal, size: 22);
          }
          return const IconThemeData(color: AppColors.gray, size: 22);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.border,
      ),
    );
  }
}
