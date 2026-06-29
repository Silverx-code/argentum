// lib/widgets/auth_widgets.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

// ── Argentum Logo Widget ──────────────────────────────────────────────────
class ArgentumLogo extends StatelessWidget {
  final double size;
  const ArgentumLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        // Cyan-blue halo echoing the logo's neural glow
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.28),
            blurRadius: size * 0.4,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: SizedBox(
          width:  size,
          height: size,
          child: Image.asset(
            'assets/images/logo.jpeg',
            fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width:  size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text('A', style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w900,
                color: AppColors.blue,
              )),
            ),
          ),
        ),
      ),
        ),
    );
  }
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
    final useGradient = !isOutlined && color == null;
    final disabled    = onPressed == null && !isLoading;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        width:  double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: useGradient ? AppColors.primaryGradient : null,
          color: isOutlined ? Colors.transparent : (useGradient ? null : color),
          border: isOutlined
              ? Border.all(color: AppColors.blue.withValues(alpha: 0.6), width: 1.4)
              : null,
          // Soft electric-blue glow, echoing the logo
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: (color ?? AppColors.blue).withValues(alpha: 0.35),
                    blurRadius:  20,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: isOutlined ? AppColors.textPrimary : Colors.white,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
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
        color:        AppColors.error.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: AppColors.error.withValues(alpha:0.3)),
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
                      color: AppColors.error.withValues(alpha:0.7),
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
