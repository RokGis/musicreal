// Mantas — SCRUM-30 (Feature) and SCRUM-33 (Story): registration, sign-in
// and profile using only external identity providers (Google, Meta/Facebook).
//
// Source of truth: Jira export "Jira (1).csv". Each test is named
// "<requirement> / <Jira TC> — <expected behaviour>" and asserts what the
// current Jira acceptance criteria require, not what the code does. Where a
// TC asks for more than its AC (TC-FEAT30-06 "rodoma uid"), the AC wins.
// EBT-AUTH-* are error-based tests (task 4c); their oracle is named in the
// test name.
//
// Acceptance criteria under test
//   SCRUM-30 AC1 the sign-in UI offers the supported external providers
//   SCRUM-30 AC2 the first successful sign-in creates exactly one profile
//   SCRUM-30 AC3 the profile stores at least uid, e-mail and display name
//                when the provider supplies them
//   SCRUM-30 AC4 signing in again with the same account creates no profile
//   SCRUM-30 AC5 a signed-in user can reach their profile information
//   SCRUM-30 AC6 failed or cancelled authentication: user not signed in and
//                an error message is shown
//   SCRUM-33 AC1 Google and Meta/Facebook registration are offered
//   SCRUM-33 AC2 a successful authentication creates the account
//   SCRUM-33 AC3 the profile is filled from provider data (name, e-mail)
//   SCRUM-33 AC4 after registration the user is signed in automatically
//   SCRUM-33 AC5 no additional registration form has to be filled in
//   SCRUM-33 AC6 failed or cancelled authentication shows an error message
//
// The real LogInPageWidget, FirebaseAuthManager, google_auth.dart,
// facebook_auth.dart, maybeCreateUser() and ProfileWidget run unchanged; only
// the Google / Facebook SDKs and Firebase servers are faked (see support/).

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'package:project_for_management/auth/firebase_auth/auth_util.dart';
import 'package:project_for_management/pages/log_in_page/log_in_page_widget.dart';
import 'package:project_for_management/pages/profile/profile_widget.dart';

import 'support/test_env.dart';

const _email = 'jonas.jonaitis@example.com';
const _name = 'Jonas Jonaitis';
const _googleUid = 'firebase-uid-google-1';
const _facebookUid = 'firebase-uid-facebook-1';

void main() {
  setUpAll(setUpMusicRealTestEnv);
  setUp(resetMusicRealTestEnv);

  group('SCRUM-33 — registration through Google or Meta/Facebook', () {
    testWidgets(
        'SCRUM-33 AC1 / SCRUM-30 AC1 — the sign-in screen offers Google and '
        'Meta/Facebook', (tester) async {
      await _openSignIn(tester);

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.textContaining(RegExp('Facebook|Meta')), findsOneWidget);
    });

    testWidgets(
        'SCRUM-33 / TC-US33-01 (EP: Google) — registration through Google '
        'creates a new account and signs the user in', (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(_profiles(), ['users/$_googleUid']);
      expect(fakeAuth.receivedCredentials.single.providerId, 'google.com');
      expect(find.text(routeMarker('Home')), findsOneWidget);
    });

    testWidgets(
        'SCRUM-33 / TC-US33-02 (EP: Facebook) — registration through '
        'Meta/Facebook creates a new account and signs the user in',
        (tester) async {
      _facebookWillSucceed();
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(_profiles(), ['users/$_facebookUid']);
      expect(fakeAuth.receivedCredentials.single.providerId, 'facebook.com');
      expect(find.text(routeMarker('Home')), findsOneWidget);
    });

    testWidgets(
        'SCRUM-33 / TC-US33-03 (DT: error branch) — failed Google '
        'authentication shows an error and creates no account', (tester) async {
      _googleWillBeRejected();
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(_profiles(), isEmpty);
      expect(_userMessage(), findsOneWidget);
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'SCRUM-33 / TC-US33-04 (DT: cancel branch) — cancelling Facebook '
        'registration returns to the screen with a message, no account',
        (tester) async {
      fakeFacebook.nextResult = FakeFacebookAuth.cancelled();
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(_profiles(), isEmpty);
      expect(find.text('Sign In'), findsOneWidget,
          reason: 'back on the registration / sign-in screen');
      expect(_userMessage(), findsOneWidget,
          reason: 'SCRUM-33 AC6: an error / info message is shown');
    });

    testWidgets(
        'SCRUM-33 / TC-US33-05 — after registration the user is signed in '
        'automatically, without a separate login step', (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(find.text(routeMarker('Home')), findsOneWidget);
      expect(fakeGoogle.signInCalls, 1, reason: 'one provider dialog only');
      expect(fakeAuth.currentUser?.uid, _googleUid);
      expect(currentUserDocument?.uid, _googleUid,
          reason: 'the app session holds the new profile');
    });

    testWidgets(
        'SCRUM-33 / TC-US33-06 — the profile is filled from Google data and '
        'no extra registration form is shown', (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);
      expect(find.byType(EditableText), findsNothing,
          reason: 'no local registration form fields on the entry screen');

      await _tapGoogle(tester);

      final profile = fakeFirestore.data('users/$_googleUid')!;
      expect(profile['display_name'], _name);
      expect(profile['email'], _email);
      expect(find.text(routeMarker('Home')), findsOneWidget,
          reason: 'the user lands in the app, not on a form');
    });
  });

  group('SCRUM-30 — external authentication, registration and profile', () {
    testWidgets(
        'SCRUM-30 / TC-FEAT30-01 (DT R1) — failed Google authentication: not '
        'signed in and an error message is shown', (tester) async {
      _googleWillBeRejected();
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(currentUserDocument, isNull);
      expect(find.text(routeMarker('Home')), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
      expect(_userMessage(), findsOneWidget);
    });

    testWidgets(
        'SCRUM-30 / TC-FEAT30-02 (DT R1) — cancelling Meta/Facebook sign-in '
        'returns to the sign-in screen with a message, not signed in',
        (tester) async {
      fakeFacebook.nextResult = FakeFacebookAuth.cancelled();
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(find.text(routeMarker('Home')), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
      expect(_userMessage(), findsOneWidget,
          reason: 'SCRUM-30 AC6: an error message is shown');
    });

    testWidgets(
        'SCRUM-30 / TC-FEAT30-03 (DT R2) — the first sign-in creates exactly '
        'one profile with uid, e-mail and name', (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(_profiles(), hasLength(1));
      final profile = fakeFirestore.data('users/$_googleUid')!;
      expect(profile['uid'], _googleUid);
      expect(profile['email'], _email);
      expect(profile['display_name'], _name);
    });

    testWidgets(
        'SCRUM-30 / TC-FEAT30-04 (DT R3) — signing in again with the same '
        'Google account opens the existing profile, no new one', (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);
      await _tapGoogle(tester);
      final createdAt = fakeFirestore.data('users/$_googleUid')!['created_time'];
      // The user has used the app since: the existing profile holds data.
      fakeFirestore.seed('users/$_googleUid', {
        ...fakeFirestore.data('users/$_googleUid')!,
        'streak_count': 7,
      });

      // Same Google account, second sign-in.
      await fakeAuth.signOut();
      await _openSignIn(tester);
      await _tapGoogle(tester);

      expect(fakeGoogle.signInCalls, 2);
      expect(_profiles(), ['users/$_googleUid'], reason: 'still one profile');
      final profile = fakeFirestore.data('users/$_googleUid')!;
      expect(profile['created_time'], createdAt,
          reason: 'it is the profile created at the first sign-in');
      expect(profile['streak_count'], 7,
          reason: 'the existing profile was not replaced by a new one');
      expect(find.text(routeMarker('Home')), findsOneWidget);
    });

    testWidgets(
        'SCRUM-30 / TC-FEAT30-05 (EP: no name) — Facebook without a display '
        'name still creates a profile with uid and e-mail', (tester) async {
      fakeFacebook.nextResult = FakeFacebookAuth.success();
      fakeAuth.nextIdentity = const FakeIdentity(
        uid: _facebookUid,
        email: _email,
        providerId: 'facebook.com',
      );
      await _openSignIn(tester);

      await _tapFacebook(tester);

      final profile = fakeFirestore.data('users/$_facebookUid')!;
      expect(profile['uid'], _facebookUid);
      expect(profile['email'], _email);
      expect(profile['display_name'] ?? '', isEmpty,
          reason: 'empty / default value, no invented name');
      expect(find.text(routeMarker('Home')), findsOneWidget,
          reason: 'no error: the user is signed in');
    });

    // AC5 requires that the signed-in user can reach their profile
    // information; AC3 requires uid to be *stored*. Neither AC requires the
    // uid to be printed on screen (the TC wording "rodoma ... uid" goes beyond
    // the AC — reported as a requirement gap, not tested as a UI defect).
    testWidgets(
        'SCRUM-30 / TC-FEAT30-06 — after signing in the user reaches their '
        'stored profile: name and e-mail shown, uid held in the profile record',
        (tester) async {
      fakeFirestore.seed('users/other-user', {
        'uid': 'other-user',
        'email': 'someone.else@example.com',
        'display_name': 'Someone Else',
      });
      _googleWillSucceed();
      await _openSignIn(tester);
      await _tapGoogle(tester);
      expect(find.text(routeMarker('Home')), findsOneWidget);

      await pumpRoutedPage(
        tester,
        name: ProfileWidget.routeName,
        path: ProfileWidget.routePath,
        page: (_) => const ProfileWidget(),
      );

      expect(find.text(_name), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
      expect(find.text('Someone Else'), findsNothing,
          reason: 'the user sees their own profile, not another one');
      expect(currentUserDocument?.uid, _googleUid,
          reason: 'the profile record available to the signed-in user '
              'carries the stored uid');
    });

    testWidgets(
        'SCRUM-30 AC6 / SCRUM-33 AC6 (no Jira TC, AC6-GOOGLE-CANCEL) — closing '
        'the Google account picker: not signed in and a message is shown',
        (tester) async {
      fakeGoogle.signInError = FakeGoogleSignIn.userCancelled;
      await _openSignIn(tester);

      await _tapGoogle(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(_profiles(), isEmpty);
      expect(find.text(routeMarker('Home')), findsNothing);
      expect(find.text('Sign In'), findsOneWidget);
      expect(_userMessage(), findsOneWidget,
          reason: 'AC6: "atšaukus autentifikaciją ... pateikiamas klaidos '
              'pranešimas"');
    });
  });

  group('SCRUM-30 / SCRUM-33 — error-based tests', () {
    testWidgets(
        'EBT-AUTH-02 (oracle: SCRUM-30 AC6 failure branch) — a Google SDK '
        'network_error is reported to the user, not signed in', (tester) async {
      fakeGoogle.signInError = PlatformException(
        code: 'network_error',
        message: 'A network error occurred.',
      );
      await _openSignIn(tester);

      // An exception escaping the button handler is reported by the test
      // framework as an unhandled error and fails this test on its own.
      await _tapGoogle(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(_profiles(), isEmpty);
      expect(find.text(routeMarker('Home')), findsNothing);
      expect(_userMessage(), findsOneWidget);
    });

    testWidgets(
        'EBT-AUTH-03 (oracle: SCRUM-30 AC6 failure branch) — a FAILED Facebook '
        'login is reported to the user, not signed in', (tester) async {
      fakeFacebook.nextResult = FakeFacebookAuth.failed();
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(fakeAuth.currentUser, isNull);
      expect(_profiles(), isEmpty);
      expect(find.text(routeMarker('Home')), findsNothing);
      expect(_userMessage(), findsOneWidget);
    });

    testWidgets(
        'EBT-AUTH-04 (SCRUM-30 AC6, credential conflict) — Facebook account '
        'whose e-mail is already registered with Google: error shown, no '
        'second profile', (tester) async {
      fakeFirestore.seed('users/$_googleUid', {
        'uid': _googleUid,
        'email': _email,
        'display_name': _name,
      });
      fakeFacebook.nextResult = FakeFacebookAuth.success();
      fakeAuth.nextError = FirebaseAuthException(
        code: 'account-exists-with-different-credential',
        message: 'An account already exists with the same email address but '
            'different sign-in credentials.',
      );
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(_profiles(), ['users/$_googleUid']);
      expect(fakeAuth.currentUser, isNull);
      expect(_userMessage(), findsOneWidget);
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'EBT-AUTH-07 (SCRUM-30 AC3 "jei juos pateikia", missing optional '
        'data) — a Facebook account without e-mail still gets a profile and '
        'is signed in', (tester) async {
      fakeFacebook.nextResult = FakeFacebookAuth.success();
      fakeAuth.nextIdentity = const FakeIdentity(
        uid: _facebookUid,
        displayName: _name,
        providerId: 'facebook.com',
      );
      await _openSignIn(tester);

      await _tapFacebook(tester);

      expect(_profiles(), ['users/$_facebookUid']);
      final profile = fakeFirestore.data('users/$_facebookUid')!;
      expect(profile['uid'], _facebookUid);
      expect(profile['email'] ?? '', isEmpty, reason: 'no invented e-mail');
      expect(find.text(routeMarker('Home')), findsOneWidget);
    });

    testWidgets(
        'EBT-AUTH-05 (SCRUM-30 AC6) — FirebaseAuthManager returns null (no '
        'user) when Google sign-in is cancelled or rejected', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        })),
      ));

      // Real async for the same reason as _tapProviderButton.
      fakeGoogle.signInError = FakeGoogleSignIn.userCancelled;
      final cancelled =
          await tester.runAsync(() => authManager.signInWithGoogle(context));
      expect(cancelled, isNull);
      expect(fakeGoogle.signInCalls, 1, reason: 'the provider was asked');

      fakeGoogle.signInError = null;
      _googleWillBeRejected();
      final rejected =
          await tester.runAsync(() => authManager.signInWithGoogle(context));
      expect(rejected, isNull);
      expect(fakeAuth.receivedCredentials, hasLength(1));
      await settle(tester);

      expect(_profiles(), isEmpty);
    });

    testWidgets(
        'EBT-AUTH-06 (SCRUM-30 AC2, repeated tap) — a double tap on "Continue '
        'with Google" opens one sign-in and creates one profile',
        (tester) async {
      _googleWillSucceed();
      await _openSignIn(tester);

      await _tapProviderButton(tester, 'Continue with Google', taps: 2);

      expect(fakeGoogle.signInCalls, 1);
      expect(_profiles(), hasLength(1));
    });
  });
}

// ------------------------------------------------------------------ helpers

void _googleWillSucceed() {
  fakeGoogle.nextAccount = GoogleSignInUserData(
    email: _email,
    id: 'google-account-1',
    displayName: _name,
  );
  fakeAuth.nextIdentity = const FakeIdentity(
    uid: _googleUid,
    email: _email,
    displayName: _name,
    providerId: 'google.com',
  );
}

/// Google returns an account but Firebase rejects its credential.
void _googleWillBeRejected() {
  fakeGoogle.nextAccount = GoogleSignInUserData(email: _email, id: 'google-1');
  fakeAuth.nextError = FirebaseAuthException(
    code: 'invalid-credential',
    message: 'The supplied auth credential is malformed or has expired.',
  );
}

void _facebookWillSucceed() {
  fakeFacebook.nextResult = FakeFacebookAuth.success();
  fakeAuth.nextIdentity = const FakeIdentity(
    uid: _facebookUid,
    email: _email,
    displayName: _name,
    providerId: 'facebook.com',
  );
}

Future<void> _openSignIn(WidgetTester tester) => pumpRoutedPage(
      tester,
      name: LogInPageWidget.routeName,
      path: LogInPageWidget.routePath,
      page: (_) => const LogInPageWidget(),
    );

Future<void> _tapGoogle(WidgetTester tester) =>
    _tapProviderButton(tester, 'Continue with Google');

Future<void> _tapFacebook(WidgetTester tester) =>
    _tapProviderButton(tester, 'Continue with Facebook');

/// Taps a provider button and lets the sign-in flow run in *real* async.
///
/// google_auth.dart keeps one module-level GoogleSignIn whose calls are
/// chained on the previous call's future. A future created inside one test's
/// fake-async zone never completes in the next test, so every test after the
/// first would hang. Running the flow with `runAsync` keeps those futures in
/// the real zone, exactly as in the running app.
Future<void> _tapProviderButton(
  WidgetTester tester,
  String label, {
  int taps = 1,
}) async {
  await tester.runAsync(() async {
    for (var i = 0; i < taps; i++) {
      await tester.tap(find.text(label), warnIfMissed: i == 0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await settle(tester);
}

List<String> _profiles() => fakeFirestore.docsIn('users');

/// AC6 requires "an error message" but not its wording; the app's only
/// message mechanism is a SnackBar, so any SnackBar satisfies the oracle.
Finder _userMessage() => find.byType(SnackBar);
