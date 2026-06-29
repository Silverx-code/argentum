// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_model.dart';
import '../utils/auth_exception.dart';

class AuthService {
  // ── Singletons ────────────────────────────────────────────────────────
  final FirebaseAuth    _auth      = FirebaseAuth.instance;
  final FirebaseFirestore _db      = FirebaseFirestore.instance;
  // google_sign_in is only used on native platforms; web uses signInWithPopup
  final GoogleSignIn    _google    = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ── Firestore collection ref ──────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ════════════════════════════════════════════════════════════════════
  // AUTH STATE STREAM
  // ════════════════════════════════════════════════════════════════════

  /// Emits [UserModel] when signed in, null when signed out.
  /// Wrap your entire app in a [StreamBuilder] on this.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      // Try Firestore first, fall back to basic UserModel from Firebase
      final firestoreUser = await _getUserFromFirestore(firebaseUser.uid);
      if (firestoreUser != null) return firestoreUser;
      // Firestore doc not yet created — return basic UserModel so nav works
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        emailVerified: firebaseUser.emailVerified,
        plan: SubscriptionPlan.free,
        createdAt: DateTime.now(),
      );
    });
  }

  /// Quick check — is anyone signed in right now?
  bool get isSignedIn => _auth.currentUser != null;

  /// Current Firebase user (raw)
  User? get currentFirebaseUser => _auth.currentUser;

  // ════════════════════════════════════════════════════════════════════
  // SIGN UP WITH EMAIL + PASSWORD
  // ════════════════════════════════════════════════════════════════════

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    String? university,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email:    email.trim(),
        password: password,
      );
      final user = credential.user!;

      // 2. Update display name in Firebase Auth profile
      await user.updateDisplayName(displayName.trim());

      // 3. Send email verification
      await user.sendEmailVerification();

      // 4. Create Firestore profile document
      final userModel = UserModel(
        uid:           user.uid,
        email:         email.trim(),
        displayName:   displayName.trim(),
        university:    university?.trim(),
        emailVerified: false,
        createdAt:     DateTime.now(),
        lastLoginAt:   DateTime.now(),
      );
      await _users.doc(user.uid).set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Sign up failed.',
        detail: e.toString(),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // SIGN IN WITH EMAIL + PASSWORD
  // ════════════════════════════════════════════════════════════════════

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    email.trim(),
        password: password,
      );
      final user = credential.user!;

      // Reload to get latest emailVerified status
      await user.reload();
      final refreshed = _auth.currentUser!;

      // Update Firestore: lastLoginAt + emailVerified status.
      // If the doc is missing (e.g. an orphaned Auth account from a
      // signup that failed partway through), back-fill it instead of
      // crashing on update().
      final docRef = _users.doc(user.uid);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        final userModel = UserModel(
          uid:           user.uid,
          email:         refreshed.email ?? email.trim(),
          displayName:   refreshed.displayName ?? '',
          emailVerified: refreshed.emailVerified,
          createdAt:     DateTime.now(),
          lastLoginAt:   DateTime.now(),
        );
        await docRef.set(userModel.toFirestore());
      } else {
        await docRef.update({
          'lastLoginAt':   Timestamp.fromDate(DateTime.now()),
          'emailVerified': refreshed.emailVerified,
        });
      }

      return (await _getUserFromFirestore(user.uid))!;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: 'Sign in failed.',
        detail: e.toString(),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ════════════════════════════════════════════════════════════════════

  Future<UserModel> signInWithGoogle() async {
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        // Web: use Firebase signInWithPopup (google_sign_in is deprecated on web)
        userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Native (Android/iOS): use google_sign_in plugin for native UX
        final googleUser = await _google.signIn();
        if (googleUser == null) {
          throw const AuthException(
            code: 'popup-closed-by-user',
            message: 'Google sign-in was cancelled.',
          );
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken:     googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user!;
      final displayName = user.displayName ?? 'Student';
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Create or update Firestore doc
      final docRef = _users.doc(user.uid);
      final docSnap = isNewUser ? null : await docRef.get();

      if (isNewUser || docSnap == null || !docSnap.exists) {
        final userModel = UserModel(
          uid:           user.uid,
          email:         user.email!,
          displayName:   displayName,
          photoUrl:      user.photoURL,
          emailVerified: true,           // Google accounts are pre-verified
          createdAt:     DateTime.now(),
          lastLoginAt:   DateTime.now(),
        );
        await docRef.set(userModel.toFirestore());
        return userModel;
      } else {
        await docRef.update({
          'lastLoginAt':   Timestamp.fromDate(DateTime.now()),
          'emailVerified': true,
        });
        return (await _getUserFromFirestore(user.uid))!;
      }
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    } catch (e) {
      throw AuthException(
        code: 'google-sign-in-failed',
        message: 'Google sign-in failed.',
        detail: e.toString(),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // EMAIL VERIFICATION
  // ════════════════════════════════════════════════════════════════════

  /// Send (or resend) verification email to current user.
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  /// Poll Firebase to check if email has been verified.
  /// Call this after the user says "I verified it".
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    if (verified) {
      // Update Firestore. Use set(merge: true) instead of update() so
      // this can't throw if the doc happens to be missing.
      await _users.doc(user.uid).set(
        {'emailVerified': true},
        SetOptions(merge: true),
      );
    }
    return verified;
  }

  // ════════════════════════════════════════════════════════════════════
  // PASSWORD RESET
  // ════════════════════════════════════════════════════════════════════

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // UPDATE PROFILE
  // ════════════════════════════════════════════════════════════════════

  Future<UserModel> updateProfile({
    String? displayName,
    String? university,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(code: 'no-user', message: 'Not signed in.');

    try {
      final updates = <String, dynamic>{};
      if (displayName != null) {
        await user.updateDisplayName(displayName.trim());
        updates['displayName'] = displayName.trim();
      }
      if (university != null) {
        updates['university'] = university.trim();
      }

      if (updates.isNotEmpty) {
        // set(merge: true) instead of update() so this self-heals if the
        // Firestore doc was never created for this account.
        await _users.doc(user.uid).set(updates, SetOptions(merge: true));
      }

      return (await _getUserFromFirestore(user.uid))!;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // SIGN OUT
  // ════════════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    if (kIsWeb) {
      await _auth.signOut();
    } else {
      await Future.wait([
        _auth.signOut(),
        _google.signOut(),
      ]);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ════════════════════════════════════════════════════════════════════

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      // Delete Firestore data first
      await _users.doc(user.uid).delete();
      // Delete Firebase Auth account
      await user.delete();
      if (!kIsWeb) await _google.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const AuthException(
          code: 'requires-recent-login',
          message: 'Please sign in again before deleting your account.',
        );
      }
      throw AuthException.fromFirebase(e.code);
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ════════════════════════════════════════════════════════════════════

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }
}