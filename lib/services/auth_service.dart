import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication service for TeamSync
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

  /// Check if Apple sign-in is available on current platform
  bool get isAppleSignInAvailable => kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;

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
        // Web sign-in with popup
        GoogleAuthProvider provider = GoogleAuthProvider().addScope('email');
        return await _auth.signInWithPopup(provider);
      } else {
        // Use Firebase's built-in provider flow
        GoogleAuthProvider provider = GoogleAuthProvider().addScope('email');
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

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    // Apple sign-in is only supported on iOS and web
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('Apple sign-in is not supported on this platform');
    }

    // Prevent concurrent sign-in attempts on web
    if (kIsWeb && _isSigningIn) {
      debugPrint('Sign-in already in progress, ignoring duplicate request');
      return null;
    }

    try {
      if (kIsWeb) {
        _isSigningIn = true;
        // Web sign-in with popup
        AppleAuthProvider provider = AppleAuthProvider().addScope('email');
        return await _auth.signInWithPopup(provider);
      } else {
        AppleAuthProvider provider = AppleAuthProvider().addScope('email');
        return await _auth.signInWithProvider(provider);
      }
    } catch (e) {
      debugPrint('Error signing in with Apple: $e');
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

  /// Ensure the user is signed in (anonymously if needed)
  /// This is particularly important for web viewers.
  Future<void> ensureAnonymousSignIn() async {
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
        debugPrint('Signed in anonymously');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'admin-restricted-operation') {
          debugPrint(
              'WARNING: Anonymous authentication is disabled in Firebase Console. Please enable it in Authentication > Sign-in method.');
        }
        debugPrint('Error signing in anonymously: ${e.code} - ${e.message}');
      } catch (e) {
        debugPrint('Error signing in anonymously: $e');
      }
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
