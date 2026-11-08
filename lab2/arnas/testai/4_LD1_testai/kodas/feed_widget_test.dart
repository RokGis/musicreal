// SCRUM-67: TC-US67-01..05; SCRUM-49: TC-FEAT49-07..10, TC-FEAT49-13

import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import 'helpers.dart';

class FakeFeedSource extends FeedSource {
  FakeFeedSource({
    this.friendList = const [],
    Stream<List<UserPostRecord>>? posts,
    this.authors = const {},
  }) : posts = posts ?? Stream.value(const []);

  final List<DocumentReference> friendList;
  final Stream<List<UserPostRecord>> posts;
  final Map<String, String> authors;

  @override
  List<DocumentReference> friends() => friendList;

  @override
  Stream<List<UserPostRecord>> todaysPosts(List<DocumentReference> friends) =>
      posts;

  @override
  Stream<UsersRecord> author(DocumentReference ref) =>
      Stream.value(user(ref, authors[ref.id] ?? ref.id));

  @override
  Stream<List<MusicRecord>> music(String songName) => Stream.value(const []);
}

void main() {
  final db = FakeFirebaseFirestore();
  final aiste = userRef(db, 'aiste');
  final tomas = userRef(db, 'tomas');
  const names = {'aiste': 'Aiste', 'tomas': 'Tomas'};
  final today = kNow.subtract(const Duration(hours: 1));

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump();
    }
  }

  Future<void> pumpFeed(WidgetTester tester, FakeFeedSource source) async {
    await tester.pumpWidget(host(SingleChildScrollView(
      child: FriendFeed(source: source),
    )));
    await settle(tester);
  }

  List<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();

  final emptyMessage =
      RegExp(r'empty|no posts|nothing|not posted|haven.t', caseSensitive: false);

  group('SCRUM-67 AC2 / SCRUM-49 AC6 — empty feed', () {
    testWidgets('SCRUM-67 / TC-US67-01 — no friends: an empty-feed message is shown',
        (tester) async {
      await pumpFeed(tester, FakeFeedSource());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(texts(tester).any(emptyMessage.hasMatch), isTrue,
          reason: 'texts on screen: ${texts(tester)}');
    });

    testWidgets('SCRUM-67 / TC-US67-02 — friends, no posts today: the SAME message as with no friends',
        (tester) async {
      await pumpFeed(tester, FakeFeedSource());
      final noFriends = texts(tester).first;

      await pumpFeed(tester, FakeFeedSource(friendList: [aiste, tomas]));
      final noPosts = texts(tester).first;

      expect(texts(tester).any(emptyMessage.hasMatch), isTrue,
          reason: 'an empty-feed message must be shown');
      expect(noPosts, noFriends,
          reason: 'TC-US67-02 expects the same "nothing to show" message as '
              'TC-US67-01 (R1)');
    });

    testWidgets('SCRUM-49 / TC-FEAT49-09 — both empty cases show the same empty-feed message',
        (tester) async {
      await pumpFeed(tester, FakeFeedSource());
      final noFriends = texts(tester).where(emptyMessage.hasMatch).toList();

      await pumpFeed(tester,
          FakeFeedSource(friendList: [aiste], posts: Stream.value(const [])));
      final noPostsToday = texts(tester).where(emptyMessage.hasMatch).toList();

      expect(noFriends, isNotEmpty);
      expect(noPostsToday, isNotEmpty);
      expect(noPostsToday, noFriends);
    });
  });

  group('SCRUM-67 AC1/AC3/AC4 / SCRUM-49 AC5 — post contents', () {
    testWidgets('SCRUM-67 / TC-US67-03 — a friend posted today: the post is shown with name, song and emotion',
        (tester) async {
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [aiste],
          authors: names,
          posts: Stream.value([
            post(aiste, 'p1', song: 'Morning Light', createdAt: today, emoji: kCool),
          ]),
        ),
      );

      expect(find.text('Aiste'), findsOneWidget);
      expect(find.text('Morning Light'), findsOneWidget);
      expect(imageUrls(tester), contains(kCool));
      expect(texts(tester).any(emptyMessage.hasMatch), isFalse);
    });

    testWidgets('SCRUM-67 / TC-US67-04 — every post shows the emotion its author picked',
        (tester) async {
      useTallScreen(tester);
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [aiste, tomas],
          authors: names,
          posts: Stream.value([
            post(aiste, 'p1', song: 'Song A', createdAt: today, emoji: kHappy),
            post(tomas, 'p2', song: 'Song B', createdAt: today, emoji: kSad),
            post(aiste, 'p3', song: 'Song C', createdAt: today, emoji: kCool),
          ]),
        ),
      );

      for (final (song, emoji) in [
        ('Song A', kHappy),
        ('Song B', kSad),
        ('Song C', kCool),
      ]) {
        final row = find.ancestor(of: find.text(song), matching: find.byType(Row)).first;
        expect(imageUrls(tester, row), [emoji], reason: song);
      }
    });

    testWidgets('SCRUM-67 / TC-US67-05 — every post shows its author\'s account name',
        (tester) async {
      useTallScreen(tester);
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [aiste, tomas],
          authors: names,
          posts: Stream.value([
            post(aiste, 'p1', song: 'Song A', createdAt: today),
            post(tomas, 'p2', song: 'Song B', createdAt: today),
          ]),
        ),
      );

      for (final (song, name) in [('Song A', 'Aiste'), ('Song B', 'Tomas')]) {
        final row = find.ancestor(of: find.text(song), matching: find.byType(Row)).first;
        expect(find.descendant(of: row, matching: find.text(name)), findsOneWidget,
            reason: song);
      }
    });

    testWidgets('SCRUM-49 / TC-FEAT49-08 — a post shows author name, song name and emotion',
        (tester) async {
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [tomas],
          authors: names,
          posts: Stream.value([
            post(tomas, 'p1', song: 'Night Drive', createdAt: today, emoji: kSad),
          ]),
        ),
      );

      final row = find.ancestor(of: find.text('Night Drive'), matching: find.byType(Row)).first;
      expect(find.descendant(of: row, matching: find.text('Tomas')), findsOneWidget);
      expect(imageUrls(tester, row), [kSad]);
    });

    testWidgets('SCRUM-49 / TC-FEAT49-07 — refreshing does not duplicate a post',
        (tester) async {
      final refreshes = StreamController<List<UserPostRecord>>();
      addTearDown(refreshes.close);
      final p1 = post(aiste, 'p1', song: 'Morning Light', createdAt: today);

      await pumpFeed(
        tester,
        FakeFeedSource(friendList: [aiste], authors: names, posts: refreshes.stream),
      );
      for (var i = 0; i < 3; i++) {
        refreshes.add([p1]);
        await settle(tester);
        expect(find.text('Morning Light'), findsOneWidget, reason: 'refresh #$i');
      }
    });
  });

  group('SCRUM-49 AC7 — data loading failure', () {
    testWidgets('SCRUM-49 / TC-FEAT49-10 — loading failure: error message with a retry action, not the empty message',
        (tester) async {
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [aiste],
          posts: Stream.error(FirebaseException(
              plugin: 'cloud_firestore', code: 'unavailable')),
        ),
      );
      await tester.pump(const Duration(seconds: 5));

      final shown = texts(tester);
      expect(shown.any(emptyMessage.hasMatch), isFalse,
          reason: 'a failure must not be shown as an empty feed');
      expect(shown.any(RegExp(r'error|could not|failed|went wrong', caseSensitive: false).hasMatch),
          isTrue,
          reason: 'expected an error message; texts on screen: $shown, '
              'loading spinner shown: '
              '${find.byType(CircularProgressIndicator).evaluate().isNotEmpty}');
      expect(find.textContaining(RegExp(r'try again|retry', caseSensitive: false)),
          findsWidgets,
          reason: 'expected a retry action');
    });
  });

  group('SCRUM-67 / SCRUM-49 error-based — incomplete posts', () {
    testWidgets('SCRUM-49 / TC-FEAT49-13 — a post without an emotion still renders, with a placeholder',
        (tester) async {
      await pumpFeed(
        tester,
        FakeFeedSource(
          friendList: [aiste],
          authors: names,
          posts: Stream.value([
            post(aiste, 'p1', song: 'Morning Light', createdAt: today, emoji: null),
          ]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Aiste'), findsOneWidget);
      expect(find.text('Morning Light'), findsOneWidget);
    });
  });
}
