// lib/utils/validators.dart

class Validators {
  Validators._();

  // ── Email ─────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8)              return 'Minimum 8 characters';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  // ── Confirm password ──────────────────────────────────────────────────
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != original) return 'Passwords do not match';
      return null;
    };
  }

  // ── Display name ──────────────────────────────────────────────────────
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2)               return 'Name is too short';
    if (value.trim().length > 50)              return 'Name is too long';
    return null;
  }

  // ── Required field (generic) ──────────────────────────────────────────
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return '$fieldName is required';
      return null;
    };
  }

  // ── Phone number ──────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
