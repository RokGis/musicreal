// Test doubles for the external identity providers used by MusicReal.
//
// Each fake replaces only the *platform* layer, so the production code in
// lib/auth/firebase_auth/{google_auth,facebook_auth,firebase_auth_manager}.dart
// and the real google_sign_in / flutter_facebook_auth / firebase_auth Dart
// packages all run unchanged. No real Google or Facebook OAuth is performed.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Identity a provider hands back to Firebase after a successful sign-in.
class FakeIdentity {
  const FakeIdentity({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.providerId = 'google.com',
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String providerId;
}

// ------------------------------------------------------------ FirebaseAuth

class FakeFirebaseAuth extends FirebaseAuthPlatform {
  FakeFirebaseAuth() : super();

  UserPlatform? _currentUser;
  final StreamController<UserPlatform?> _changes =
      StreamController<UserPlatform?>.broadcast();

  /// Identity returned by the next `signInWithCredential`.
  FakeIdentity? nextIdentity;

  /// When set, `signInWithCredential` throws it (e.g. an expired credential).
  FirebaseAuthException? nextError;

  /// Credentials Firebase received, in order.
  final List<AuthCredential> receivedCredentials = [];

  void reset() {
    _currentUser = null;
    nextIdentity = null;
    nextError = null;
    receivedCredentials.clear();
    _changes.add(null);
  }

  /// Makes [identity] the signed-in Firebase user without any provider flow.
  void signInAs(FakeIdentity identity) {
    _currentUser = FakeUser(this, identity);
    _changes.add(_currentUser);
  }

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) =>
      this;

  @override
  UserPlatform? get currentUser => _currentUser;

  @override
  set currentUser(UserPlatform? userPlatform) => _currentUser = userPlatform;

  Stream<UserPlatform?> _userStream() => Stream<UserPlatform?>.multi((c) {
        c.add(_currentUser);
        final sub = _changes.stream.listen(c.add);
        c.onCancel = sub.cancel;
      });

  @override
  Stream<UserPlatform?> authStateChanges() => _userStream();

  @override
  Stream<UserPlatform?> idTokenChanges() => _userStream();

  @override
  Stream<UserPlatform?> userChanges() => _userStream();

  @override
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential credential,
  ) async {
    receivedCredentials.add(credential);
    await Future<void>.delayed(Duration.zero);
    final error = nextError;
    if (error != null) throw error;
    final identity = nextIdentity;
    if (identity == null) {
      throw StateError('Test did not configure FakeFirebaseAuth.nextIdentity');
    }
    final user = FakeUser(this, identity);
    _currentUser = user;
    _changes.add(user);
    return FakeUserCredential(this, user, credential);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _changes.add(null);
  }
}

class _FakeMultiFactor extends MultiFactorPlatform {
  _FakeMultiFactor(super.auth);
}

class FakeUser extends UserPlatform {
  FakeUser(FirebaseAuthPlatform auth, FakeIdentity identity)
      : super(
          auth,
          _FakeMultiFactor(auth),
          PigeonUserDetails(
            userInfo: PigeonUserInfo(
              uid: identity.uid,
              email: identity.email,
              displayName: identity.displayName,
              photoUrl: identity.photoUrl,
              isAnonymous: false,
              isEmailVerified: identity.email != null,
              providerId: identity.providerId,
            ),
            providerData: const [],
          ),
        );
}

class FakeUserCredential extends UserCredentialPlatform {
  FakeUserCredential(
    FirebaseAuthPlatform auth,
    UserPlatform user,
    AuthCredential credential,
  ) : super(auth: auth, user: user, credential: credential);
}

// ----------------------------------------------------------- Google Sign-In

class FakeGoogleSignIn extends GoogleSignInPlatform {
  /// Account the Google account picker returns. Null = picker returned nothing.
  GoogleSignInUserData? nextAccount;

  /// Thrown by the account picker instead of returning (cancel / failure).
  Object? signInError;

  int signInCalls = 0;

  void reset() {
    nextAccount = null;
    signInError = null;
    signInCalls = 0;
  }

  /// What the native SDK throws when the user closes the account picker;
  /// google_sign_in turns exactly this error into a `null` account.
  static PlatformException get userCancelled =>
      PlatformException(code: 'sign_in_canceled', message: 'User cancelled');

  @override
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
  }) async {}

  @override
  Future<void> initWithParams(SignInInitParameters params) async {}

  @override
  Future<GoogleSignInUserData?> signIn() async {
    signInCalls++;
    final error = signInError;
    if (error != null) throw error;
    return nextAccount;
  }

  @override
  Future<GoogleSignInTokenData> getTokens({
    required String email,
    bool? shouldRecoverAuth,
  }) async =>
      GoogleSignInTokenData(
        idToken: 'google-id-token-for-$email',
        accessToken: 'google-access-token',
      );

  @override
  Future<void> signOut() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<void> clearAuthCache({required String token}) async {}
}

// ----------------------------------------------------------------- Facebook

class FakeFacebookAuth extends FacebookAuthPlatform {
  /// What the Facebook login dialog returns.
  LoginResult nextResult = LoginResult(status: LoginStatus.cancelled);

  int loginCalls = 0;
  String? lastNonce;

  void reset() {
    nextResult = LoginResult(status: LoginStatus.cancelled);
    loginCalls = 0;
    lastNonce = null;
  }

  static LoginResult success({String token = 'facebook-token'}) => LoginResult(
        status: LoginStatus.success,
        accessToken: ClassicToken(
          declinedPermissions: const [],
          grantedPermissions: const ['email', 'public_profile'],
          userId: 'facebook-user-1',
          expires: DateTime(2030),
          tokenString: token,
          applicationId: 'musicreal-test-app',
        ),
      );

  /// What flutter_facebook_auth returns when the user presses "Cancel".
  static LoginResult cancelled() =>
      LoginResult(status: LoginStatus.cancelled, message: 'User cancelled');

  /// What flutter_facebook_auth returns when the dialog fails.
  static LoginResult failed() => LoginResult(
      status: LoginStatus.failed, message: 'Facebook login failed');

  @override
  Future<LoginResult> login({
    List<String> permissions = const ['email', 'public_profile'],
    LoginBehavior loginBehavior = LoginBehavior.dialogOnly,
    LoginTracking loginTracking = LoginTracking.enabled,
    String? nonce,
  }) async {
    loginCalls++;
    lastNonce = nonce;
    return nextResult;
  }

  @override
  Future<void> webAndDesktopInitialize({
    required String appId,
    required bool cookie,
    required bool xfbml,
    required String version,
  }) async {}

  @override
  bool get isWebSdkInitialized => true;

  @override
  Future<LoginResult> expressLogin() async => nextResult;

  @override
  Future<Map<String, dynamic>> getUserData({
    String fields = 'name,email,picture.width(200)',
  }) async =>
      const {};

  @override
  Future<void> autoLogAppEventsEnabled(bool enabled) async {}

  @override
  Future<bool> get isAutoLogAppEventsEnabled async => false;

  @override
  Future<void> logOut() async {}

  @override
  Future<AccessToken?> get accessToken async => nextResult.accessToken;
}
