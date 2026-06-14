// lib/screens/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'sign_in_screen.dart';
import 'email_verify_screen.dart';
import '../home/home_screen.dart';

/// AuthGate sits at the root of the widget tree.
/// It watches AuthProvider and routes to the correct screen
/// based on auth state — no manual navigation needed anywhere else.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      // ── Loading / initial ────────────────────────────────────────────
      case AuthStatus.initial:
        return const _SplashLoader();

      // ── Authenticated ────────────────────────────────────────────────
      case AuthStatus.authenticated:
        // Force email verification gate
        if (!auth.emailVerified) {
          return const EmailVerifyScreen();
        }
        return const HomeScreen();

      // ── Not authenticated ────────────────────────────────────────────
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const SignInScreen();

      // ── Loading state ────────────────────────────────────────────────
      case AuthStatus.loading:
        return const _SplashLoader();
    }
  }
}

// ── Splash / loading screen while Firebase initializes ───────────────────
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ArgentumLogo(size: 72),
            const SizedBox(height: 24),
            Text('ARGENTUM', style: AppText.heading1.copyWith(letterSpacing: 4)),
            const SizedBox(height: 8),
            const ScreenLabel(text: 'AI · STUDY · SYSTEM'),
            const SizedBox(height: 48),
            const SizedBox(
              width:  24,
              height: 24,
              child:  CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing...',
              style: AppText.mono.copyWith(color: AppColors.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}
