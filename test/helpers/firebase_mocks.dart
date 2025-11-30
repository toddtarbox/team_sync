import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Setup Firebase mocks for testing
///
/// Call this in your test's setUpAll() to prevent Firebase initialization errors.
class FirebaseMocks {
  static bool _initialized = false;
  static MockFirebaseAuth? _mockAuth;

  /// Initialize Firebase mocks for testing
  ///
  /// Set [authenticatedUser] to true to simulate a signed-in user
  static Future<void> setupFirebaseMocks(
      {bool authenticatedUser = false}) async {
    if (_initialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();

    // Register a mock Firebase Core platform
    FirebasePlatform.instance = _MockFirebasePlatform();

    // Register mock Firebase Auth
    _mockAuth = MockFirebaseAuth(authenticatedUser: authenticatedUser);
    FirebaseAuthPlatform.instance = _mockAuth!;

    _initialized = true;
  }

  /// Set whether a user is authenticated
  static void setAuthenticatedUser(bool authenticated) {
    _mockAuth?.setAuthenticatedUser(authenticated);
  }

  /// Get the mock Firebase Auth instance
  static MockFirebaseAuth? get mockAuth => _mockAuth;

  /// Reset all mocks (call in tearDown if needed)
  static void reset() {
    _initialized = false;
    _mockAuth = null;
  }
}

/// Mock Firebase Platform implementation
class _MockFirebasePlatform extends FirebasePlatform {
  _MockFirebasePlatform() : super();

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _MockFirebaseAppPlatform(
        name,
        const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project-id',
        ));
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _MockFirebaseAppPlatform(
      name ?? defaultFirebaseAppName,
      options ??
          const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project-id',
          ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return [
      _MockFirebaseAppPlatform(
          defaultFirebaseAppName,
          const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project-id',
          )),
    ];
  }
}

/// Mock Firebase App Platform implementation
class _MockFirebaseAppPlatform extends FirebaseAppPlatform {
  _MockFirebaseAppPlatform(String name, FirebaseOptions options)
      : super(name, options);

  @override
  Future<void> delete() async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {}

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}

/// Mock Firebase Auth Platform implementation
class MockFirebaseAuth extends FirebaseAuthPlatform
    with MockPlatformInterfaceMixin {
  MockFirebaseAuth({this.authenticatedUser = false}) : super();

  bool authenticatedUser;
  MockUserPlatform? _mockUser;

  /// Set whether a user is authenticated
  void setAuthenticatedUser(bool authenticated) {
    authenticatedUser = authenticated;
    if (authenticated && _mockUser == null) {
      _mockUser = MockUserPlatform();
    } else if (!authenticated) {
      _mockUser = null;
    }
  }

  @override
  UserPlatform? get currentUser {
    if (authenticatedUser) {
      return _mockUser ??= MockUserPlatform();
    }
    return null;
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    authenticatedUser = true;
    _mockUser = MockUserPlatform();
    return MockUserCredentialPlatform(_mockUser!);
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    authenticatedUser = true;
    _mockUser = MockUserPlatform(email: email);
    return MockUserCredentialPlatform(_mockUser!);
  }

  @override
  Future<void> signOut() async {
    authenticatedUser = false;
    _mockUser = null;
  }

  @override
  Stream<UserPlatform?> authStateChanges() {
    return Stream.value(currentUser);
  }

  @override
  Stream<UserPlatform?> userChanges() {
    return Stream.value(currentUser);
  }

  @override
  Stream<UserPlatform?> idTokenChanges() {
    return Stream.value(currentUser);
  }

  // Required overrides for FirebaseAuthPlatform
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) {
    return this;
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) {
    return this;
  }
}

/// Mock MultiFactorPlatform implementation
class MockMultiFactorPlatform extends MultiFactorPlatform {
  MockMultiFactorPlatform() : super(FirebaseAuthPlatform.instance);
}

/// Mock UserPlatform implementation
class MockUserPlatform extends UserPlatform {
  MockUserPlatform({
    String uid = 'test-uid-123',
    String? email = 'test@example.com',
    String? displayName = 'Test User',
    String? photoURL,
    bool emailVerified = true,
    bool isAnonymous = false,
  }) : super(
          FirebaseAuthPlatform.instance,
          MockMultiFactorPlatform(),
          PigeonUserDetails(
            userInfo: PigeonUserInfo(
              uid: uid,
              email: email,
              displayName: displayName,
              photoUrl: photoURL,
              phoneNumber: null,
              isEmailVerified: emailVerified,
              isAnonymous: isAnonymous,
              creationTimestamp: DateTime.now().millisecondsSinceEpoch,
              lastSignInTimestamp: DateTime.now().millisecondsSinceEpoch,
              providerId: 'password',
              tenantId: null,
            ),
            providerData: [],
          ),
        );
}

/// Mock UserCredentialPlatform implementation
class MockUserCredentialPlatform extends UserCredentialPlatform {
  MockUserCredentialPlatform(UserPlatform user)
      : super(
          auth: FirebaseAuthPlatform.instance,
          additionalUserInfo: null,
          credential: null,
          user: user,
        );
}
