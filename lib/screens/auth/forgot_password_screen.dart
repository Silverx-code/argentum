// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth    = context.read<AuthProvider>();
    final success = await auth.sendPasswordReset(_emailCtrl.text);
    if (success && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title:           const Text('Reset Password'),
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _SentState(email: _emailCtrl.text) : _FormState(
            formKey:   _formKey,
            emailCtrl: _emailCtrl,
            auth:      auth,
            onSubmit:  _submit,
          ),
        ),
      ),
    );
  }
}

// ── Form state ────────────────────────────────────────────────────────────
class _FormState extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final AuthProvider auth;
  final VoidCallback onSubmit;

  const _FormState({
    required this.formKey,
    required this.emailCtrl,
    required this.auth,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Container(
            width:  60, height: 60,
            decoration: BoxDecoration(
              color:  AppColors.blueGlow,
              shape:  BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.lock_reset, color: AppColors.blue, size: 28),
          ),
          const SizedBox(height: 20),

          Text('Forgot your password?', style: AppText.heading2),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you a link to reset your password via Firebase.',
            style: AppText.body,
          ),
          const SizedBox(height: 28),

          if (auth.errorMessage != null) ...[
            AuthErrorBanner(
              message:   auth.errorMessage!,
              detail:    auth.errorDetail,
              onDismiss: auth.clearError,
            ),
            const SizedBox(height: 16),
          ],

          AuthTextField(
            controller:   emailCtrl,
            label:        'Email Address',
            hint:         'your@email.com',
            prefixIcon:   Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          ArgentumButton(
            label:     'Send Reset Link',
            onPressed: onSubmit,
            isLoading: auth.isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Sent state ────────────────────────────────────────────────────────────
class _SentState extends StatelessWidget {
  final String email;
  const _SentState({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color:  AppColors.success.withOpacity(0.1),
            shape:  BoxShape.circle,
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 24),
        Text('Reset Link Sent!', style: AppText.heading2),
        const SizedBox(height: 12),
        Text(
          'Check $email for a password reset link. It expires in 1 hour.',
          textAlign: TextAlign.center,
          style: AppText.body,
        ),
        const SizedBox(height: 32),
        ArgentumButton(
          label:     'Back to Sign In',
          onPressed: () => Navigator.pushReplacementNamed(context, '/signin'),
        ),
      ],
    );
  }
}
