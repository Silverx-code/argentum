// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
export 'auth_widgets.dart' show ArgentumLogo;

// ─── Monosp Label ───────────────────────────────────────────────────────────

class MonoLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;
  const MonoLabel(this.text, {super.key, this.color, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: fontSize,
        fontFamily: 'monospace',
        letterSpacing: 2,
        color: color ?? AppColors.textDim,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── Tag Badge ──────────────────────────────────────────────────────────────

class ArgTag extends StatelessWidget {
  final String text;
  final Color color;
  const ArgTag(this.text, {super.key, this.color = AppColors.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        border: Border.all(color: color.withValues(alpha:0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontFamily: 'monospace',
          color: color,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Primary Button ─────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.blueDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: (color ?? AppColors.blue).withValues(alpha:0.5)),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
      ),
    );
  }
}

// ─── Surface Card ───────────────────────────────────────────────────────────

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: borderColor ?? AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}

// ─── Accuracy Bar ───────────────────────────────────────────────────────────

class AccuracyBar extends StatelessWidget {
  final double accuracy; // 0-100
  final double height;
  const AccuracyBar({super.key, required this.accuracy, this.height = 4});

  Color get _color {
    if (accuracy >= 75) return AppColors.success;
    if (accuracy >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: accuracy / 100,
        minHeight: height,
        backgroundColor: Colors.white.withValues(alpha:0.05),
        valueColor: AlwaysStoppedAnimation(_color),
      ),
    );
  }
}

// ─── Difficulty Badge ────────────────────────────────────────────────────────

class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  const DifficultyBadge(this.difficulty, {super.key});

  Color get _color {
    switch (difficulty.toLowerCase()) {
      case 'easy':   return AppColors.success;
      case 'hard':   return AppColors.error;
      default:       return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) => ArgTag(difficulty, color: _color);
}

// ─── Bottom Nav Bar ─────────────────────────────────────────────────────────

class ArgNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ArgNavBar({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.grid_view_rounded, label: 'Home'),
    (icon: Icons.bolt_rounded, label: 'Tests'),
    (icon: Icons.upload_file_rounded, label: 'Upload'),
    (icon: Icons.bar_chart_rounded, label: 'Progress'),
    (icon: Icons.smart_toy_outlined, label: 'Tutor'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha:0.95),
        border: Border.all(color: AppColors.blue.withValues(alpha:0.15)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.4), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.blue.withValues(alpha:0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(item.icon,
                    size: 20,
                    color: active ? AppColors.blue : AppColors.textDim),
                const SizedBox(height: 2),
                Text(item.label,
                    style: TextStyle(
                      fontSize: 8,
                      fontFamily: 'monospace',
                      color: active ? AppColors.blue : AppColors.textDim,
                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                    )),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Loading Shimmer ────────────────────────────────────────────────────────

class ShimmerBlock extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  const ShimmerBlock({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}