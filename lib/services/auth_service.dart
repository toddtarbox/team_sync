import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for ClubSync
class AuthService {
  static final AuthService instance = AuthService._internal();

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSigningIn = false;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Prevent concurrent sign-in attempts on web
    if (kIsWeb && _isSigningIn) {
      debugPrint('Sign-in already in progress, ignoring duplicate request');
      return null;
    }

    try {
      if (kIsWeb) {
        _isSigningIn = true;
      }

      GoogleAuthProvider provider = GoogleAuthProvider();

      if (kIsWeb) {
        // Web sign-in with popup
        return await _auth.signInWithPopup(provider);
      } else {
        // Mobile sign-in with provider (uses native Google Sign-In)
        return await _auth.signInWithProvider(provider);
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    } finally {
      if (kIsWeb) {
        _isSigningIn = false;
      }
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error signing in with email/password: $e');
      rethrow;
    }
  }

  /// Create account with email and password
  Future<UserCredential> createAccountWithEmailPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error creating account: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'web-context-already-presented':
          return 'A sign-in is already in progress. Please wait.';
        case 'popup-blocked':
          return 'Sign-in popup was blocked. Please allow popups for this site.';
        case 'popup-closed-by-user':
          return 'Sign-in was cancelled.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'operation-not-allowed':
          return 'Sign-in method not enabled. Contact support.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return error.message ?? 'Authentication error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
