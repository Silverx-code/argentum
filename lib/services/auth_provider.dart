// lib/services/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/auth_exception.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ── State ─────────────────────────────────────────────────────────────
  AuthStatus  _status  = AuthStatus.initial;
  UserModel?  _user;
  String?     _errorMessage;
  String?     _errorDetail;
  bool        _isLoading = false;

  // ── Getters ───────────────────────────────────────────────────────────
  AuthStatus  get status        => _status;
  UserModel?  get user          => _user;
  String?     get errorMessage  => _errorMessage;
  String?     get errorDetail   => _errorDetail;
  bool        get isLoading     => _isLoading;
  bool        get isSignedIn    => _status == AuthStatus.authenticated;
  bool        get emailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    _listenToAuthState();
  }

  // ── Listen to Firebase auth state changes ─────────────────────────────
  void _listenToAuthState() {
    _authService.authStateChanges.listen((userModel) {
      if (userModel != null) {
        _user   = userModel;
        _status = AuthStatus.authenticated;
      } else {
        _user   = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // SIGN UP
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    String? university,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.signUpWithEmail(
        email:       email,
        password:    password,
        displayName: displayName,
        university:  university,
      );
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // SIGN IN
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithEmail(
        email:    email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN IN
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _authService.signInWithGoogle();
      _status = AuthStatus.authenticated;
      _clearError();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // EMAIL VERIFICATION
  // ─────────────────────────────────────────────────────────────────────

  Future<void> resendVerificationEmail() async {
    _setLoading(true);
    try {
      await _authService.sendVerificationEmail();
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkEmailVerified() async {
    final verified = await _authService.checkEmailVerified();
    if (verified && _user != null) {
      _user = _user!.copyWith(emailVerified: true);
      notifyListeners();
    }
    return verified;
  }

  // ─────────────────────────────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _clearError();
      return true;
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> updateProfile({String? displayName, String? university}) async {
    _setLoading(true);
    try {
      _user = await _authService.updateProfile(
        displayName: displayName,
        university:  university,
      );
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message, e.detail);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    _clearError();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String message, [String? detail]) {
    _errorMessage = message;
    _errorDetail  = detail;
    _status       = AuthStatus.error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _errorDetail  = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
