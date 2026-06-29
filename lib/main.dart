// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart' as ap;
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'utils/routes.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/email_verify_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/quiz/quiz_screen.dart';
import 'screens/quiz/results_screen.dart';
import 'screens/quiz/test_setup_screen.dart';
import 'screens/recovery/recovery_screen.dart';
import 'screens/tutor/tutor_screen.dart';
import 'screens/upload/upload_screen.dart';
import 'screens/dashboard/progress_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show any framework error on screen instead of a blank white page.
  ErrorWidget.builder = (FlutterErrorDetails details) => Material(
    color: const Color(0xFF070A12),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            'Startup error:\n\n${details.exception}',
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
      ),
    ),
  );

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Don't blank the screen — record the error and let the app boot so we
    // can show it. (Auth features won't work until Firebase init succeeds.)
    firebaseError = e.toString();
    debugPrint('Firebase init failed: $e');
  }

  runApp(ArgentumApp(firebaseError: firebaseError));
}

class ArgentumApp extends StatelessWidget {
  final String? firebaseError;
  const ArgentumApp({super.key, this.firebaseError});

  @override
  Widget build(BuildContext context) {
    // If Firebase failed to initialise, show the error instead of a blank/broken app.
    if (firebaseError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                const Text('Firebase failed to initialise',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(firebaseError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12,
                        fontFamily: 'monospace')),
              ]),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Argentum AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Routes that need the mode argument pass it via settings.arguments
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return _fadeRoute(const _RootNavigator(), settings);

      case AppRoutes.home:
        return _fadeRoute(const HomeScreen(), settings);

      case AppRoutes.signIn:
        return _fadeRoute(const SignInScreen(), settings);

      case AppRoutes.signUp:
        return _fadeRoute(const SignUpScreen(), settings);

      case AppRoutes.emailVerify:
        return _fadeRoute(const EmailVerifyScreen(), settings);

      case AppRoutes.forgotPassword:
        final email = (args is Map<String, dynamic>) ? args['email'] as String? ?? '' : '';
        return _fadeRoute(ForgotPasswordScreen(initialEmail: email), settings);

      case AppRoutes.quiz:
        final mode = (args is Map<String, dynamic>) ? args['mode'] as String? ?? 'timed' : 'timed';
        return _fadeRoute(QuizScreen(mode: mode), settings);

      case AppRoutes.results:
        final results = (args is Map<String, dynamic>) ? args['results'] as Map<String, dynamic>? : null;
        return _fadeRoute(ResultsScreen(results: results), settings);

      case AppRoutes.testSetup:
        final mode = (args is Map<String, dynamic>) ? args['initialMode'] as String? : null;
        return _fadeRoute(TestSetupScreen(initialMode: mode), settings);

      case AppRoutes.recovery:
        return _fadeRoute(const RecoveryScreen(), settings);

      case AppRoutes.tutor:
        return _fadeRoute(const TutorScreen(), settings);

      case AppRoutes.upload:
        return _fadeRoute(const UploadScreen(), settings);

      case AppRoutes.progress:
        return _fadeRoute(const ProgressScreen(), settings);

      case AppRoutes.settings:
        return _fadeRoute(const SettingsScreen(), settings);

      default:
        return _fadeRoute(const _RootNavigator(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ap.AuthProvider>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: auth.status == ap.AuthStatus.initial || auth.isLoading
          ? const _SplashScreen()
          : auth.isSignedIn
              ? (!auth.emailVerified
                  ? const EmailVerifyScreen()
                  : const HomeScreen())
              : const SignInScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 72, height: 72,
              child: CircularProgressIndicator(color: AppColors.blue, strokeWidth: 1.5)),
          SizedBox(height: 24),
          Text('ARGENTUM AI', style: TextStyle(fontSize: 13, fontFamily: 'monospace',
              letterSpacing: 4, color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('From Notes to Mastery.', style: TextStyle(
              fontSize: 10, color: AppColors.textDim, fontFamily: 'monospace')),
        ]),
      ),
    );
  }
}