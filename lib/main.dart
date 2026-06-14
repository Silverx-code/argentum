// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_provider.dart' as ap;
import 'providers/app_provider.dart';
import 'utils/app_theme.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ArgentumApp());
}

class ArgentumApp extends StatelessWidget {
  const ArgentumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ap.AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: 'Argentum AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const _RootNavigator(),
      ),
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
      child: auth.isLoading
          ? const _SplashScreen()
          : auth.isSignedIn
              ? const HomeScreen()
              : SignInScreen(),
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