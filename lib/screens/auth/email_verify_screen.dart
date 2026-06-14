// lib/screens/auth/email_verify_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_widgets.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  Timer?   _pollTimer;
  Timer?   _resendTimer;
  int      _resendCooldown = 0;
  bool     _checking       = false;

  @override
  void initState() {
    super.initState();
    // Auto-poll every 3 seconds to detect verification
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    final auth     = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    if (verified && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.resendVerificationEmail();
    // 60-second cooldown
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final email  = auth.user?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon ───────────────────────────────────────────────
              Container(
                width:        80,
                height:       80,
                decoration: BoxDecoration(
                  color:        AppColors.blueGlow,
                  shape:        BoxShape.circle,
                  border:       Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.blue,
                  size:  36,
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ──────────────────────────────────────────────
              Text('Verify Your Email', style: AppText.heading2),
              const SizedBox(height: 12),

              // ── Body ───────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(
                    text: 'We sent a verification link to\n',
                    style: AppText.body,
                  ),
                  TextSpan(
                    text: email,
                    style: AppText.body.copyWith(
                      color:      AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '\n\nClick the link in your inbox, then tap the button below.',
                    style: AppText.body,
                  ),
                ]),
              ),
              const SizedBox(height: 32),

              // ── Info box ───────────────────────────────────────────
              Container(
                padding:    const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        AppColors.blueGlow,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: AppColors.blue, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Check your spam folder too',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ]),
                    if (_checking) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Checking verification status...',
                          style: AppText.mono.copyWith(color: AppColors.blue),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Check button ───────────────────────────────────────
              ArgentumButton(
                label:     "I've Verified My Email",
                onPressed: _checkVerified,
                isLoading: _checking,
              ),
              const SizedBox(height: 16),

              // ── Resend ─────────────────────────────────────────────
              ArgentumButton(
                label: _resendCooldown > 0
                    ? 'RESEND IN ${_resendCooldown}s'
                    : 'Resend Email',
                onPressed: _resendCooldown > 0 ? null : _resend,
                isOutlined: true,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 24),

              // ── Sign out link ──────────────────────────────────────
              TextButton(
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/signin');
                },
                child: const Text(
                  'Sign out and use different account',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
