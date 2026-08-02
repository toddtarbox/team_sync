import 'package:firebase_auth/firebase_auth.dart';

/// Service to check if user is an admin
class AdminService {
  static final AdminService instance = AdminService._internal();

  AdminService._internal();

  /// List of admin emails
  static const List<String> adminEmails = [
    'ttarbox0603@gmail.com',
  ];

  /// Check if current user is an admin
  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final email = user.email?.toLowerCase();
    if (email == null) return false;

    return adminEmails.contains(email);
  }

  /// Get current user email
  String? get currentUserEmail {
    return FirebaseAuth.instance.currentUser?.email;
  }

  /// Check if a specific email is an admin
  bool isEmailAdmin(String email) {
    return adminEmails.contains(email.toLowerCase());
  }

  /// Stream of admin status changes
  Stream<bool> get adminStatusStream {
    return FirebaseAuth.instance.authStateChanges().map((user) {
      if (user == null) return false;
      final email = user.email?.toLowerCase();
      if (email == null) return false;
      return adminEmails.contains(email);
    });
  }

  /// Require admin access - throws if not admin
  void requireAdmin() {
    if (!isAdmin) {
      throw Exception(
          'Admin access required. Only ${adminEmails.join(", ")} can perform this action.');
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Get current user ID
  String? get currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
