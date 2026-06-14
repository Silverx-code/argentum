// lib/widgets/auth_widgets.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Argentum Logo Widget ──────────────────────────────────────────────────
class ArgentumLogo extends StatelessWidget {
  final double size;
  const ArgentumLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background glow
    final bgPaint = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF1A3A6E).withOpacity(0.6),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bgPaint);

    // Neural network nodes
    final nodes = <Offset>[];
    for (int i = 0; i < 10; i++) {
      final angle = (i * 36 - 90) * (3.14159 / 180);
      nodes.add(Offset(
        center.dx + (radius * 0.9) * (angle > 0 ? 1 : -1) * (i % 2 == 0 ? 0.8 : 1.0),
        center.dy + (radius * 0.9) * (i < 5 ? -1 : 1) * ((i % 3 == 0) ? 0.6 : 0.9),
      ));
    }

    // Node lines
    final linePaint = Paint()
      ..color = const Color(0xFF4A9EFF).withOpacity(0.5)
      ..strokeWidth = size.width * 0.012
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawLine(nodes[i], nodes[(i + 1) % nodes.length], linePaint);
    }

    // Nodes
    final nodePaint = Paint()..color = const Color(0xFF4A9EFF);
    for (final node in nodes) {
      canvas.drawCircle(node, size.width * 0.025, nodePaint);
    }

    // S letter
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          fontSize:   size.width * 0.48,
          fontWeight: FontWeight.w900,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0C4DE), Color(0xFF607B9E)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Primary Button ────────────────────────────────────────────────────────
class ArgentumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;

  const ArgentumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? Colors.transparent
              : (color ?? AppColors.blueDark),
          side: BorderSide(
            color: color ?? AppColors.blue,
            width: 1,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width:  20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label.toUpperCase(),
                style: const TextStyle(
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: AppColors.surface,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G icon (simplified)
                  Container(
                    width: 20, height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CONTINUE WITH GOOGLE',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Auth Text Field ───────────────────────────────────────────────────────
class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.nextFocus,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:       widget.controller,
      focusNode:        widget.focusNode,
      keyboardType:     widget.keyboardType,
      obscureText:      widget.isPassword && _obscure,
      textInputAction:  widget.textInputAction,
      validator:        widget.validator,
      style: const TextStyle(
        color:    AppColors.textPrimary,
        fontSize: 14,
      ),
      onFieldSubmitted: (_) {
        if (widget.nextFocus != null) {
          FocusScope.of(context).requestFocus(widget.nextFocus);
        }
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText:  widget.hint,
        prefixIcon: Icon(widget.prefixIcon, color: AppColors.textDim, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textDim,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback? onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.detail,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    style: TextStyle(
                      color: AppColors.error.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: AppColors.error, size: 16),
            ),
        ],
      ),
    );
  }
}

// ── Divider with Text ─────────────────────────────────────────────────────
class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: AppText.label,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ── Screen Label ──────────────────────────────────────────────────────────
class ScreenLabel extends StatelessWidget {
  final String text;
  const ScreenLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text.toUpperCase(), style: AppText.label),
    );
  }
}
