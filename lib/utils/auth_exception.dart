// lib/utils/auth_exception.dart

class AuthException implements Exception {
  final String code;
  final String message;
  final String? detail;

  const AuthException({
    required this.code,
    required this.message,
    this.detail,
  });

  // ── Map Firebase error codes to user-friendly messages ───────────────
  factory AuthException.fromFirebase(String code) {
    switch (code) {
      // ── Sign Up ──────────────────────────────────────────────────────
      case 'email-already-in-use':
        return const AuthException(
          code: 'email-already-in-use',
          message: 'An account with this email already exists.',
          detail: 'Try signing in or use a different email.',
        );
      case 'invalid-email':
        return const AuthException(
          code: 'invalid-email',
          message: 'That email address looks invalid.',
          detail: 'Check for typos and try again.',
        );
      case 'weak-password':
        return const AuthException(
          code: 'weak-password',
          message: 'Password is too weak.',
          detail: 'Use at least 8 characters with numbers and symbols.',
        );
      case 'operation-not-allowed':
        return const AuthException(
          code: 'operation-not-allowed',
          message: 'Email sign-up is not enabled.',
          detail: 'Contact support.',
        );

      // ── Sign In ──────────────────────────────────────────────────────
      case 'user-not-found':
        return const AuthException(
          code: 'user-not-found',
          message: 'No account found with this email.',
          detail: 'Create an account to get started.',
        );
      case 'wrong-password':
        return const AuthException(
          code: 'wrong-password',
          message: 'Incorrect password.',
          detail: 'Double-check and try again.',
        );
      case 'invalid-credential':
        return const AuthException(
          code: 'invalid-credential',
          message: 'Email or password is incorrect.',
        );
      case 'user-disabled':
        return const AuthException(
          code: 'user-disabled',
          message: 'This account has been disabled.',
          detail: 'Contact support for help.',
        );
      case 'too-many-requests':
        return const AuthException(
          code: 'too-many-requests',
          message: 'Too many failed attempts.',
          detail: 'Wait a few minutes and try again.',
        );

      // ── Google Sign-In ───────────────────────────────────────────────
      case 'account-exists-with-different-credential':
        return const AuthException(
          code: 'account-exists-with-different-credential',
          message: 'Account exists with a different sign-in method.',
          detail: 'Try signing in with email/password.',
        );
      case 'popup-closed-by-user':
        return const AuthException(
          code: 'popup-closed-by-user',
          message: 'Google sign-in was cancelled.',
        );

      // ── Network ──────────────────────────────────────────────────────
      case 'network-request-failed':
        return const AuthException(
          code: 'network-request-failed',
          message: 'No internet connection.',
          detail: 'Check your network and try again.',
        );

      // ── Email Verification ───────────────────────────────────────────
      case 'email-not-verified':
        return const AuthException(
          code: 'email-not-verified',
          message: 'Please verify your email first.',
          detail: 'Check your inbox for a verification link.',
        );

      // ── Password Reset ───────────────────────────────────────────────
      case 'expired-action-code':
        return const AuthException(
          code: 'expired-action-code',
          message: 'This reset link has expired.',
          detail: 'Request a new password reset.',
        );
      case 'invalid-action-code':
        return const AuthException(
          code: 'invalid-action-code',
          message: 'This reset link is invalid or already used.',
        );

      default:
        return AuthException(
          code: code,
          message: 'Something went wrong.',
          detail: 'Error code: $code',
        );
    }
  }

  @override
  String toString() => 'AuthException($code): $message';
}
