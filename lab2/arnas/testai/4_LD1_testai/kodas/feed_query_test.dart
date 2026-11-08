// SCRUM-49: TC-FEAT49-01..07, TC-FEAT49-13

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import 'helpers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late DocumentReference me;
  late DocumentReference friend;
  late DocumentReference stranger;

  final today = kNow.subtract(const Duration(hours: 1));

  Future<List<DocumentReference>> myFriends() async =>
      UsersRecord.fromSnapshot(await me.get()).friends;

  Future<List<UserPostRecord>> feed({DateTime? now}) async {
    final friends = await myFriends();
    return queryCollection(
      db.collectionGroup('userPost'),
      UserPostRecord.fromSnapshot,
      queryBuilder: (q) => friendsFeedQuery(q, friends, now ?? kNow),
    ).first;
  }

  Future<void> arrayUnion(DocumentReference user, DocumentReference ref) async {
    final friends = UsersRecord.fromSnapshot(await user.get()).friends.toList();
    if (!friends.contains(ref)) friends.add(ref);
    await user.update({'friends': friends});
  }

  Future<void> arrayRemove(DocumentReference user, DocumentReference ref) async {
    final friends = UsersRecord.fromSnapshot(await user.get()).friends.toList()
      ..remove(ref);
    await user.update({'friends': friends});
  }

  Future<void> sendRequest(DocumentReference from, DocumentReference to,
          {String status = 'pending'}) =>
      db.collection('friend_requests').doc('${from.id}_${to.id}').set({
        'sender': from,
        'receiver': to,
        'status': status,
        'created_at': kNow.subtract(const Duration(days: 1)),
      });

  setUp(() async {
    db = FakeFirebaseFirestore();
    friend = await addUser(db, 'friend', name: 'Aiste');
    stranger = await addUser(db, 'stranger', name: 'Lukas');
    me = await addUser(db, 'me', name: 'Me', friends: [friend]);
  });

  group('SCRUM-49 AC1 — confirmed friends\' posts of today', () {
    test('SCRUM-49 / TC-FEAT49-02 — confirmed friend\'s post of today is in the feed',
        () async {
      await addPost(db, friend, 'p1', song: 'Morning Light', createdAt: today);

      expect(paths(await feed()), ['p1']);
    });

    test('SCRUM-49 / TC-FEAT49-03 — confirmed friend\'s post from yesterday is not in the feed',
        () async {
      await addPost(db, friend, 'old', song: 'Night Drive',
          createdAt: kNow.subtract(const Duration(days: 1)));
      await addPost(db, friend, 'older', song: 'Night Drive',
          createdAt: kNow.subtract(const Duration(days: 5)));

      expect(await feed(), isEmpty);
    });

    test('SCRUM-49 / TC-FEAT49-03 (BVA) — 00:00:00 today is in, 23:59:59 yesterday is out',
        () async {
      await addPost(db, friend, 'midnight', song: 'A',
          createdAt: DateTime(2026, 10, 3, 0, 0, 0));
      await addPost(db, friend, 'lastSecondYesterday', song: 'B',
          createdAt: DateTime(2026, 10, 2, 23, 59, 59));

      expect(paths(await feed()), ['midnight']);
    });

    test('SCRUM-49 / TC-FEAT49-07 — one post appears exactly once, on every refresh',
        () async {
      await addPost(db, friend, 'p1', song: 'Morning Light', createdAt: today);

      for (var refresh = 0; refresh < 3; refresh++) {
        expect(paths(await feed()), ['p1'], reason: 'refresh #$refresh');
      }
    });
  });

  group('SCRUM-49 AC2 — no confirmed friendship, no posts', () {
    test('SCRUM-49 / TC-FEAT49-13 — a non-friend\'s post of today is not in the feed',
        () async {
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: today);
      await addPost(db, friend, 'f1', song: 'Morning Light', createdAt: today);

      expect(paths(await feed()), ['f1']);
    });

    test('SCRUM-49 / TC-FEAT49-01 — pending request: post of today is not in the feed',
        () async {
      await sendRequest(stranger, me);
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: today);

      expect(await feed(), isEmpty);
    });

    test('SCRUM-49 / TC-FEAT49-04 — request sent by me, still pending: not in the feed',
        () async {
      await sendRequest(me, stranger);
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: today);

      expect(paths(await feed()), isNot(contains('s1')));
    });

    test('SCRUM-49 / TC-FEAT49-04 — declined request: not in the feed', () async {
      await sendRequest(stranger, me, status: 'rejected');
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: today);

      expect(paths(await feed()), isNot(contains('s1')));
    });
  });

  group('SCRUM-49 AC3/AC4 — friendship changes apply on the next refresh', () {
    test('SCRUM-49 / TC-FEAT49-05 — accepted request: new friend\'s post of today appears',
        () async {
      await sendRequest(stranger, me);
      await addPost(db, stranger, 's1', song: 'City Lines', createdAt: today);
      expect(paths(await feed()), isNot(contains('s1')), reason: 'before');

      await db
          .doc('friend_requests/stranger_me')
          .update({'status': 'accepted'});
      await arrayUnion(me, stranger);
      await arrayUnion(stranger, me);

      expect(paths(await feed()), contains('s1'), reason: 'after refresh');
    });

    test('SCRUM-49 / TC-FEAT49-06 — removed friend: their posts disappear',
        () async {
      await addPost(db, friend, 'f1', song: 'Morning Light', createdAt: today);
      expect(paths(await feed()), ['f1'], reason: 'before');

      await arrayRemove(me, friend);
      await arrayRemove(friend, me);

      final other = await addUser(db, 'other', friends: [me]);
      await arrayUnion(me, other);
      expect(await myFriends(), isNot(contains(friend)));
      expect(paths(await feed()), isNot(contains('f1')), reason: 'after');
    });
  });

  group('SCRUM-49 error-based — unusual data', () {
    test('SCRUM-49 / TC-FEAT49-13 — a post without created_at is not shown as a post of today',
        () async {
      await friend.collection('userPost').doc('noDate').set({
        'song_name': 'Broken',
        'post_user': friend,
        'emoji': kHappy,
      });

      expect(await feed(), isEmpty);
    });

    test('SCRUM-49 / TC-FEAT49-13 — friends with several posts today: all of them, none twice',
        () async {
      final second = await addUser(db, 'second', name: 'Tomas');
      await arrayUnion(me, second);
      await addPost(db, friend, 'a', song: 'A',
          createdAt: kNow.subtract(const Duration(hours: 3)));
      await addPost(db, friend, 'b', song: 'B',
          createdAt: kNow.subtract(const Duration(hours: 1)));
      await addPost(db, second, 'c', song: 'C',
          createdAt: kNow.subtract(const Duration(hours: 2)));

      final ids = paths(await feed());
      expect(ids.toSet(), {'a', 'b', 'c'});
      expect(ids.length, ids.toSet().length);
    });
  });
}
