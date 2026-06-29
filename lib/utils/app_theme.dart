// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette tuned to the Argentum logo: an electric-blue neural ring with
/// bright cyan glowing nodes and a silvery-white "S" on a deep navy-black.
class AppColors {
  // Deep navy-black backdrop (blue undertone, softer & warmer than pure black)
  static const background    = Color(0xFF070A12);
  static const surface       = Color(0xFF0E1422);
  static const surfaceLight  = Color(0xFF18223A);
  static const border        = Color(0xFF243149);

  // Brand blues — the glowing ring
  static const blue          = Color(0xFF3B97FF); // electric blue (primary)
  static const blueDark      = Color(0xFF1E4E8F);
  static const blueDarker    = Color(0xFF0E2547);
  static const blueGlow      = Color(0xFF0E1F3D); // subtle blue tint bg

  // Cyan node-glow accent + silvery "S" highlight
  static const cyan          = Color(0xFF5CD2FF); // bright node glow
  static const silver        = Color(0xFFD7E3F5); // metallic S tone

  // Text — cool silvery whites
  static const textPrimary   = Color(0xFFEAF1FF);
  static const textSecondary = Color(0xFFB2BDD6);
  static const textDim       = Color(0xFF6B7693);
  static const textFaint     = Color(0xFF38415A); // very dim, for splash

  // Status — slightly softened for a friendlier feel
  static const success       = Color(0xFF34D399);
  static const warning       = Color(0xFFFBBF24);
  static const error         = Color(0xFFF87171);
  static const accent        = Color(0xFF5CD2FF);

  // Signature blue→cyan glow gradient (buttons, logo, accents)
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end:   Alignment.bottomRight,
    colors: [Color(0xFF3B97FF), Color(0xFF5CD2FF)],
  );
}

// ── Text styles used across screens ────────────────────────────────────────
class AppText {
  AppText._();

  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontSize: 13.5,
    color: AppColors.textSecondary,
    height: 1.55,
  );

  static const mono = TextStyle(
    fontSize: 10,
    fontFamily: 'monospace',
    color: AppColors.textDim,
    letterSpacing: 0.5,
  );

  static const label = TextStyle(
    fontSize: 9,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w700,
    color: AppColors.textDim,
    letterSpacing: 1.2,
  );
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.cyan,
        selectionHandleColor: AppColors.cyan,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.cyan),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary, letterSpacing: -0.3),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary,
            fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating, elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
            color: AppColors.textPrimary),
      ),
    );
  }
}