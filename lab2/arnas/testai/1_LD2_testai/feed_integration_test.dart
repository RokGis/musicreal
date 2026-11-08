// LD2 6.3 – Arnas: draugų srauto komponentų integracinis testas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/auth/firebase_auth/auth_util.dart'
    as auth_util;
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import '../mantas/support/test_env.dart';

void main() {
  setUpAll(setUpMusicRealTestEnv);
  setUp(resetMusicRealTestEnv);

  group('feed integration', () {
    testWidgets(
        'I01 posts in the database → real feed shows only the friend\'s post of today',
        (tester) async {
      // The default FeedSource reads the real clock (getCurrentTimestamp), so
      // the times are relative to the start of the current day. A run that
      // crosses midnight between seeding and querying may be unstable.
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      final me = userRef('me');
      final friend = userRef('friend');
      final stranger = userRef('stranger');

      final meData = {
        'uid': 'me',
        'display_name': 'Me',
        'friends': [friend],
      };
      fakeFirestore.seed('users/me', meData);
      fakeFirestore.seed('users/friend', {
        'uid': 'friend',
        'display_name': 'Aiste',
        'friends': [me],
      });
      fakeFirestore.seed('users/stranger', {
        'uid': 'stranger',
        'display_name': 'Lukas',
        'friends': <DocumentReference>[],
      });
      fakeFirestore.seed('users/friend/userPost/today', {
        'song_name': 'Morning Light',
        'post_user': friend,
        'created_at': startOfToday.add(const Duration(seconds: 1)),
        'emoji': '',
      });
      fakeFirestore.seed('users/friend/userPost/yesterday', {
        'song_name': 'Night Drive',
        'post_user': friend,
        'created_at': startOfToday.subtract(const Duration(seconds: 1)),
        'emoji': '',
      });
      fakeFirestore.seed('users/stranger/userPost/today', {
        'song_name': 'City Lines',
        'post_user': stranger,
        'created_at': startOfToday.add(const Duration(seconds: 1)),
        'emoji': '',
      });

      // Signed-in user whose friends list FeedSource.friends() reads.
      auth_util.currentUserDocument = UsersRecord.getDocumentFromData(meData, me);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: FriendFeed())),
      ));
      await settle(tester);

      expect(find.text('Aiste'), findsOneWidget);
      expect(find.text('Morning Light'), findsOneWidget);
      expect(find.text('Night Drive'), findsNothing,
          reason: 'yesterday\'s post must not be in today\'s feed');
      expect(find.text('City Lines'), findsNothing,
          reason: 'a non-friend\'s post must not be in the feed');
      expect(find.text('Your feed is empty'), findsNothing);
      expect(find.text('No posts today'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
