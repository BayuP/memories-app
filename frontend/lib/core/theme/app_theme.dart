import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppColors — warm cream minimalist palette
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Background
  static const Color bg = Color(0xFFF5F3EF);
  static const Color background = Color(0xFFF5F3EF); // alias for bg
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF0EDE8);
  static const Color surfaceVariant = Color(0xFFF0EDE8); // alias for surfaceElevated

  // Text
  static const Color text = Color(0xFF2D2A26);
  static const Color textPrimary = Color(0xFF2D2A26); // alias for text
  static const Color textSecondary = Color(0xFF8A7F75);
  static const Color textMuted = Color(0xFFB5AFA8);
  static const Color textDisabled = Color(0xFFB5AFA8); // alias for textMuted

  // Primary action
  static const Color primary = Color(0xFF1A1815);
  static const Color primaryLight = Color(0xFF3D3A36);
  static const Color primaryDark = Color(0xFF0A0908);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // alias for onPrimary

  // Border / divider
  static const Color border = Color(0xFFE8E4DE);
  static const Color divider = Color(0xFFF0ECE6);

  // Semantic
  static const Color error = Color(0xFF8B3A3A);
  static const Color white = Color(0xFFFFFFFF);

  // Accent — warm muted green (replaces old teal, maps legacy accentGreen usage)
  static const Color accentGreen = Color(0xFF6B8F71);
  static const Color accentGreenLight = Color(0xFFE4EDE5);

  // Status badge backgrounds (warm-neutralised)
  static const Color badgeOngoing = Color(0xFFE4EDE5);  // muted warm green tint
  static const Color badgeUpcoming = Color(0xFFF0EDE8); // surface elevated
  static const Color badgePast = Color(0xFFEBE8E3);     // warm light gray
}

// ─────────────────────────────────────────────────────────────────────────────
// AppSpacing
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppRadius
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 20.0;
  static const double card = 14.0;   // maps legacy AppRadius.card
  static const double sheet = 20.0;  // maps legacy AppRadius.sheet
  static const double pill = 9999.0;
  static const double full = 9999.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppShadows
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.text.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.text.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get fab => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AppDurations
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles — Playfair Display (headings) + Inter (body)
//
// All styles are static getters using default theme colors.
// Use .copyWith(color: ...) at the call site to override color.
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTextStyles {
  // Display — Playfair Display italic
  static TextStyle get displayLarge => GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontStyle: FontStyle.italic,
        color: AppColors.text,
        height: 1.2,
      );

  static TextStyle get displayMedium => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontStyle: FontStyle.italic,
        color: AppColors.text,
        height: 1.25,
      );

  static TextStyle get displaySmall => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontStyle: FontStyle.italic,
        color: AppColors.text,
        height: 1.3,
      );

  // Headline — Playfair Display (upright, for section titles)
  static TextStyle get headlineLarge => GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.3,
      );

  static TextStyle get headlineMedium => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
        height: 1.35,
      );

  static TextStyle get headlineSmall => GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
        height: 1.4,
      );

  // Body — Inter
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Labels — Inter semi-bold
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 0.2,
      );

  // Caption — Inter regular, secondary color
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  // Button — Inter semi-bold, on-primary color
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.onPrimary,
        letterSpacing: 0.1,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.surfaceElevated,
        onPrimaryContainer: AppColors.text,
        secondary: AppColors.accentGreen,
        onSecondary: AppColors.onPrimary,
        secondaryContainer: AppColors.accentGreenLight,
        onSecondaryContainer: AppColors.text,
        tertiary: AppColors.textSecondary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.surfaceVariant,
        onTertiaryContainer: AppColors.text,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        errorContainer: const Color(0xFFF5E4E4),
        onErrorContainer: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
        shadow: Colors.transparent,
        scrim: const Color(0x66000000),
        inverseSurface: AppColors.primary,
        onInverseSurface: AppColors.onPrimary,
        inversePrimary: AppColors.surfaceElevated,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.text),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.text,
          textStyle: AppTextStyles.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.0),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
          height: 1.4,
        ),
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        isDense: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.10),
        labelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall.copyWith(color: AppColors.primary);
          }
          return AppTextStyles.labelSmall;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.border,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
