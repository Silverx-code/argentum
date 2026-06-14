// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const background    = Color(0xFF08090D);
  static const surface       = Color(0xFF0F1117);
  static const surfaceLight  = Color(0xFF141720);
  static const border        = Color(0xFF1E2235);
  static const blue          = Color(0xFF3B82F6);
  static const blueDark      = Color(0xFF1D3C6E);
  static const blueDarker    = Color(0xFF0D1F3C);
  static const blueGlow      = Color(0xFF0D1830); // subtle blue tint bg
  static const textPrimary   = Color(0xFFE8ECF7);
  static const textSecondary = Color(0xFFB8BFD4);
  static const textDim       = Color(0xFF5A617A);
  static const textFaint     = Color(0xFF363D52); // very dim, for splash
  static const success       = Color(0xFF22C55E);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const accent        = Color(0xFF60A5FA);
}

// ── Text styles used across screens ────────────────────────────────────────
class AppText {
  AppText._();

  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const body = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
    height: 1.6,
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
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
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
        filled: true, fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary,
            fontFamily: 'monospace', fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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