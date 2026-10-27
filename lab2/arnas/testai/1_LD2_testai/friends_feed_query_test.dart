// LD2 8 užduotis – Arnas: friendsFeedQuery() testai.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import '../mantas/support/test_env.dart' as env;
import '../tests/helpers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late DocumentReference aiste;
  late DocumentReference tomas;
  late DocumentReference stranger;

  // kNow from helpers.dart is 2026-10-03 12:00:00.
  final startOfToday = DateTime(2026, 10, 3);

  /// Runs the query under test against every `userPost` subcollection and
  /// returns the ids of the documents it returns, in order.
  Future<List<String>> feedIds(List<DocumentReference> friends,
      {DateTime? now}) async {
    final snapshot = await friendsFeedQuery(
      db.collectionGroup('userPost'),
      friends,
      now ?? kNow,
    ).get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    aiste = await addUser(db, 'aiste', name: 'Aiste');
    tomas = await addUser(db, 'tomas', name: 'Tomas');
    stranger = await addUser(db, 'stranger', name: 'Lukas');
  });

  group('friendsFeedQuery', () {
    test('Q01 friend posted today → post returned', () async {
      await addPost(db, aiste, 'p1',
          song: 'Morning Light', createdAt: DateTime(2026, 10, 3, 11));

      expect(await feedIds([aiste]), ['p1']);
    });

    test('Q02 several friends posted today → all returned, newest first',
        () async {
      await addPost(db, aiste, 'a08', song: 'A', createdAt: DateTime(2026, 10, 3, 8));
      await addPost(db, tomas, 't11', song: 'B', createdAt: DateTime(2026, 10, 3, 11));
      await addPost(db, aiste, 'a10', song: 'C', createdAt: DateTime(2026, 10, 3, 10));

      expect(await feedIds([aiste, tomas]), ['t11', 'a10', 'a08'],
          reason: 'posts must be ordered by created_at, descending');
    });

    test('Q03 post at 00:00:00 today → included, 23:59:59 yesterday → excluded',
        () async {
      await addPost(db, aiste, 'midnight', song: 'A', createdAt: startOfToday);
      await addPost(db, aiste, 'lastSecondYesterday',
          song: 'B', createdAt: DateTime(2026, 10, 2, 23, 59, 59));

      expect(await feedIds([aiste]), ['midnight']);
    });

    test('Q04 now at 23:59:59 → early post of the same day still included',
        () async {
      await addPost(db, aiste, 'early', song: 'A', createdAt: DateTime(2026, 10, 3, 0, 5));

      expect(await feedIds([aiste], now: DateTime(2026, 10, 3, 23, 59, 59)),
          ['early'],
          reason: 'the lower bound is the start of the day of `now`');
    });

    test('Q05 post dated after now (tomorrow) → included', () async {
      // Possible defect: the query has only a lower bound (start of today), so
      // a post with a future created_at (e.g. a wrong device clock) is shown
      // in today's feed.
      await addPost(db, aiste, 'tomorrow', song: 'A', createdAt: DateTime(2026, 10, 4, 9));
      await addPost(db, aiste, 'today', song: 'B', createdAt: DateTime(2026, 10, 3, 9));

      expect(await feedIds([aiste]), ['tomorrow', 'today']);
    });

    test('Q06 non-friend posted today → post not returned', () async {
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: DateTime(2026, 10, 3, 9));
      await addPost(db, aiste, 'a1', song: 'Morning Light', createdAt: DateTime(2026, 10, 3, 9));

      expect(await feedIds([aiste]), ['a1'],
          reason: 'only posts whose post_user is in the friends list match');
    });

    test('Q07 post without created_at → not returned', () async {
      await aiste.collection('userPost').doc('noDate').set({
        'song_name': 'Broken',
        'post_user': aiste,
        'emoji': kHappy,
      });
      await addPost(db, aiste, 'withDate', song: 'A', createdAt: DateTime(2026, 10, 3, 9));

      expect(await feedIds([aiste]), ['withDate']);
    });

    test('Q09 more than 30 friends → query fails with ArgumentError', () async {
      // Possible defect: whereIn accepts at most 30 values (Firestore limit;
      // fake_cloud_firestore throws ArgumentError, real cloud_firestore
      // asserts). A user with 31 or more friends gets no feed at all.
      final friends = [
        aiste,
        for (var i = 0; i < 30; i++) await addUser(db, 'friend$i'),
      ];
      await addPost(db, aiste, 'a1', song: 'A', createdAt: DateTime(2026, 10, 3, 9));

      expect(friends, hasLength(31));
      await expectLater(() => feedIds(friends), throwsArgumentError);
    });
  });

  group('friendsFeedQuery with the real cloud_firestore query code', () {
    // fake_cloud_firestore cannot run where() without a condition (it throws
    // 'Unsupported'), so this case uses the platform-level fake from
    // test/mantas/support: the real cloud_firestore Query code builds the query.
    setUpAll(env.setUpMusicRealTestEnv);
    setUp(env.resetMusicRealTestEnv);

    test('Q08 empty friends list → no friend filter, every post of today returned',
        () async {
      // Possible defect: friendsFeedQuery() uses the FlutterFlow extension
      // QueryExtension.whereIn (lib/backend/backend.dart), which turns an empty
      // list into where(field, whereIn: null), i.e. no condition at all. The
      // query then returns today's posts of all users. In the app
      // FriendFeed.build() shows the empty state before calling it.
      env.fakeFirestore.seed('users/aiste/userPost/a1', {
        'song_name': 'A',
        'post_user': env.userRef('aiste'),
        'created_at': DateTime(2026, 10, 3, 9),
      });
      env.fakeFirestore.seed('users/stranger/userPost/s1', {
        'song_name': 'B',
        'post_user': env.userRef('stranger'),
        'created_at': DateTime(2026, 10, 3, 10),
      });
      env.fakeFirestore.seed('users/aiste/userPost/old', {
        'song_name': 'C',
        'post_user': env.userRef('aiste'),
        'created_at': DateTime(2026, 10, 2, 9),
      });

      final snapshot = await friendsFeedQuery(
        FirebaseFirestore.instance.collectionGroup('userPost'),
        const <DocumentReference>[],
        kNow,
      ).get();

      expect(snapshot.docs.map((doc) => doc.id).toList(), ['s1', 'a1'],
          reason: 'without friends only the start-of-today filter remains');
    });
  });
}
