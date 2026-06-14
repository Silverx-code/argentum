// lib/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verify_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus   = FocusNode();
  final _passF        = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _emailFocus.dispose(); _passF.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = context.read<AuthProvider>();
    final success = await auth.signIn(
      email:    _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!success || !mounted) return;

    // If email not verified, go to verify screen
    if (!auth.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerifyScreen()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 32),

                // ── Logo + brand ───────────────────────────────────────
                const ArgentumLogo(size: 68),
                const SizedBox(height: 16),
                Text('ARGENTUM', style: AppText.heading1.copyWith(letterSpacing: 4)),
                const SizedBox(height: 4),
                const ScreenLabel(text: 'AI · STUDY · SYSTEM'),
                const SizedBox(height: 40),

                // ── Error ──────────────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  AuthErrorBanner(
                    message:   auth.errorMessage!,
                    detail:    auth.errorDetail,
                    onDismiss: auth.clearError,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Fields ─────────────────────────────────────────────
                AuthTextField(
                  controller:      _emailCtrl,
                  focusNode:       _emailFocus,
                  nextFocus:       _passF,
                  label:           'Email Address',
                  hint:            'your@email.com',
                  prefixIcon:      Icons.email_outlined,
                  keyboardType:    TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AuthTextField(
                  controller:      _passwordCtrl,
                  focusNode:       _passF,
                  label:           'Password',
                  hint:            'Your password',
                  prefixIcon:      Icons.lock_outline,
                  isPassword:      true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // ── Forgot password ────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: _emailCtrl.text,
                        ),
                      ),
                    ),
                    child: const Text(
                      'FORGOT PASSWORD?',
                      style: TextStyle(
                        color:      AppColors.blue,
                        fontSize:   11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                ArgentumButton(
                  label:     'Sign In',
                  onPressed: _submit,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 20),

                const DividerWithText(text: 'OR'),
                const SizedBox(height: 20),

                GoogleSignInButton(
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    final success = await auth.signInWithGoogle();
                    if (success && mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                ),
                const SizedBox(height: 32),

                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                      TextSpan(
                        text: 'CREATE ONE',
                        style: TextStyle(
                          color:      AppColors.blue,
                          fontSize:   12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
