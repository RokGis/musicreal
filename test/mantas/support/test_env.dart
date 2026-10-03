// Shared, deterministic test environment for Mantas's suites.
//
// * Firebase core is initialised with the official FlutterFire test mocks.
// * Firestore, FirebaseAuth, Google Sign-In and Facebook Login are replaced
//   at their platform-interface layer by the fakes in this folder.
// * google_fonts is served a bundled font from assets/ instead of
//   downloading one, so no test depends on the network.
//
// Production code is not modified: the pages under test run exactly as in the
// app, only the outside world (Google, Facebook, Firebase servers) is faked.

// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth_platform_interface/flutter_facebook_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:project_for_management/app_state.dart';
import 'package:project_for_management/auth/base_auth_user_provider.dart'
    as auth_state;
import 'package:project_for_management/auth/firebase_auth/auth_util.dart'
    as auth_util;

import 'fake_auth.dart';
import 'fake_firestore.dart';

export 'fake_auth.dart';
export 'fake_firestore.dart';

final FakeFirestore fakeFirestore = FakeFirestore();
final FakeFirebaseAuth fakeAuth = FakeFirebaseAuth();
final FakeGoogleSignIn fakeGoogle = FakeGoogleSignIn();
final FakeFacebookAuth fakeFacebook = FakeFacebookAuth();

/// Call once from `setUpAll`.
Future<void> setUpMusicRealTestEnv() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  await Firebase.initializeApp();

  FirebaseFirestorePlatform.instance = fakeFirestore;
  FirebaseAuthPlatform.instance = fakeAuth;
  GoogleSignInPlatform.instance = fakeGoogle;
  FacebookAuthPlatform.instance = fakeFacebook;

  google_fonts_base.assetManifest = _OfflineFontManifest();
}

/// Call from `setUp`: every test starts signed out with an empty database.
void resetMusicRealTestEnv() {
  fakeFirestore.reset();
  fakeAuth.reset();
  fakeGoogle.reset();
  fakeFacebook.reset();
  FFAppState.reset();
  auth_state.currentUser = null;
  auth_util.currentUserDocument = null;
  _serveOfflineFonts();
}

/// Minimal signed-in user for pages that read `currentUser` directly.
class TestAuthUser extends auth_state.BaseAuthUser {
  TestAuthUser({required String uid, String? email, String? displayName})
      : _info = auth_state.AuthUserInfo(
          uid: uid,
          email: email,
          displayName: displayName,
        );

  final auth_state.AuthUserInfo _info;

  @override
  bool get loggedIn => true;
  @override
  bool get emailVerified => true;
  @override
  auth_state.AuthUserInfo get authUserInfo => _info;
  @override
  Future? delete() => null;
  @override
  Future? updateEmail(String email) => null;
  @override
  Future? updatePassword(String newPassword) => null;
  @override
  Future? sendEmailVerification() => null;
}

DocumentReference userRef(String uid) =>
    FirebaseFirestore.instance.doc('users/$uid');

/// Text shown by the placeholder page that stands in for any route the page
/// under test navigates to, e.g. `ROUTE:Home`.
String routeMarker(String name) => 'ROUTE:$name';

/// Pumps [page] as the initial route of a GoRouter app. Every other route the
/// page may navigate to is a placeholder showing [routeMarker], so a test can
/// assert where the user ended up without building unrelated screens.
Future<GoRouter> pumpRoutedPage(
  WidgetTester tester, {
  required String name,
  required String path,
  required WidgetBuilder page,
  List<(String name, String path)> otherRoutes = const [
    ('Home', '/home'),
    ('LogInPage', '/logInPage'),
    ('post', '/post'),
  ],
}) async {
  tester.view.physicalSize = const Size(1236, 2745); // 412 x 915 phone
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: path,
    routes: [
      GoRoute(name: name, path: path, builder: (context, _) => page(context)),
      for (final (routeName, routePath) in otherRoutes)
        if (routeName != name)
          GoRoute(
            name: routeName,
            path: routePath,
            builder: (_, __) =>
                Scaffold(body: Center(child: Text(routeMarker(routeName)))),
          ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider<FFAppState>.value(
      value: FFAppState(),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
  return router;
}

/// Advances frames, timers and fake async I/O without `pumpAndSettle`, which
/// never returns on pages that show an endless loading spinner.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// --------------------------------------------------------- offline fonts

/// Tells google_fonts that every font it asks for is bundled under
/// `offline_fonts/`, and [_serveOfflineFonts] answers those asset requests
/// with a real font file that ships in this repository.
class _OfflineFontManifest implements AssetManifest {
  static const _families = ['Inter', 'PlusJakartaSans', 'ReadexPro', 'Urbanist'];
  static const _weights = [
    'Thin', 'ExtraLight', 'Light', 'Regular', 'Medium', //
    'SemiBold', 'Bold', 'ExtraBold', 'Black',
  ];

  static final List<String> _assets = [
    for (final family in _families)
      for (final weight in _weights) ...[
        'offline_fonts/$family-$weight.ttf',
        'offline_fonts/$family-${weight == 'Regular' ? 'Italic' : '${weight}Italic'}.ttf',
      ],
  ];

  @override
  List<String> listAssets() => _assets;

  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

Uint8List? _fontBytes;

void _serveOfflineFonts() {
  final assetDir = Platform.environment['UNIT_TEST_ASSETS'];
  _fontBytes ??= File('assets/fonts/Satoshi-Regular.otf').readAsBytesSync();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) {
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key.startsWith('offline_fonts/')) {
      return SynchronousFuture(ByteData.sublistView(_fontBytes!));
    }
    // Everything else behaves exactly like flutter_test's own asset mock.
    if (assetDir == null) return null;
    final file = File('$assetDir/$key');
    if (!file.existsSync()) return null;
    return SynchronousFuture(ByteData.sublistView(file.readAsBytesSync()));
  });
}
