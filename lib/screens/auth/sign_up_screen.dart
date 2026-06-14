// lib/screens/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'email_verify_screen.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _uniCtrl      = TextEditingController();

  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();
  final _uniFocus      = FocusNode();

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose(); _uniCtrl.dispose();
    _nameFocus.dispose(); _emailFocus.dispose();
    _passwordFocus.dispose(); _confirmFocus.dispose(); _uniFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth    = context.read<AuthProvider>();
    final success = await auth.signUp(
      email:       _emailCtrl.text,
      password:    _passwordCtrl.text,
      displayName: _nameCtrl.text,
      university:  _uniCtrl.text.isEmpty ? null : _uniCtrl.text,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmailVerifyScreen()),
      );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Header ─────────────────────────────────────────────
                Row(
                  children: [
                    const ArgentumLogo(size: 42),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ARGENTUM', style: AppText.heading2.copyWith(letterSpacing: 3)),
                        const ScreenLabel(text: 'Create Account'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Error banner ───────────────────────────────────────
                if (auth.errorMessage != null) ...[
                  AuthErrorBanner(
                    message:   auth.errorMessage!,
                    detail:    auth.errorDetail,
                    onDismiss: auth.clearError,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Form fields ────────────────────────────────────────
                AuthTextField(
                  controller:      _nameCtrl,
                  focusNode:       _nameFocus,
                  nextFocus:       _emailFocus,
                  label:           'Full Name',
                  hint:            'Your full name',
                  prefixIcon:      Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AuthTextField(
                  controller:      _emailCtrl,
                  focusNode:       _emailFocus,
                  nextFocus:       _passwordFocus,
                  label:           'Email Address',
                  hint:            'your@university.edu.ng',
                  prefixIcon:      Icons.email_outlined,
                  keyboardType:    TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AuthTextField(
                  controller:      _passwordCtrl,
                  focusNode:       _passwordFocus,
                  nextFocus:       _confirmFocus,
                  label:           'Password',
                  hint:            'At least 8 characters',
                  prefixIcon:      Icons.lock_outline,
                  isPassword:      true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Include at least one number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AuthTextField(
                  controller:      _confirmCtrl,
                  focusNode:       _confirmFocus,
                  nextFocus:       _uniFocus,
                  label:           'Confirm Password',
                  hint:            'Repeat your password',
                  prefixIcon:      Icons.lock_outline,
                  isPassword:      true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AuthTextField(
                  controller:      _uniCtrl,
                  focusNode:       _uniFocus,
                  label:           'University (Optional)',
                  hint:            'e.g. University of Lagos',
                  prefixIcon:      Icons.school_outlined,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 8),

                // ── Privacy note ───────────────────────────────────────
                Text(
                  'Your account is secured by Firebase Authentication. '
                  'A verification email will be sent to you.',
                  style: AppText.body.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 24),

                // ── Submit ─────────────────────────────────────────────
                ArgentumButton(
                  label:     'Create Account',
                  onPressed: _submit,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 16),

                // ── Divider ────────────────────────────────────────────
                const DividerWithText(text: 'OR CONTINUE WITH'),
                const SizedBox(height: 16),

                // ── Google ─────────────────────────────────────────────
                GoogleSignInButton(
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    final success = await auth.signInWithGoogle();
                    if (success && mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  },
                ),
                const SizedBox(height: 24),

                // ── Sign in link ───────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                        TextSpan(
                          text: 'SIGN IN',
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
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
