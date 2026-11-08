// LD2 8 užduotis – Arnas: FriendFeed.build() testai.

import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/friends_list_add_friend/friends_list_add_friend_widget.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import '../tests/helpers.dart';

/// Feed data chosen by the test instead of Firestore. Records how
/// [todaysPosts] was called.
class StubFeedSource extends FeedSource {
  StubFeedSource({
    this.friendList = const [],
    Stream<List<UserPostRecord>>? posts,
    this.names = const {},
  }) : posts = posts ?? const Stream<List<UserPostRecord>>.empty();

  final List<DocumentReference> friendList;
  final Stream<List<UserPostRecord>> posts;
  final Map<String, String> names;

  int todaysPostsCalls = 0;
  List<DocumentReference>? requestedFriends;

  @override
  List<DocumentReference> friends() => friendList;

  @override
  Stream<List<UserPostRecord>> todaysPosts(List<DocumentReference> friends) {
    todaysPostsCalls++;
    requestedFriends = friends;
    return posts;
  }

  @override
  Stream<UsersRecord> author(DocumentReference ref) =>
      Stream.value(user(ref, names[ref.id] ?? ref.id));

  @override
  Stream<List<MusicRecord>> music(String songName) => Stream.value(const []);
}

void main() {
  final db = FakeFirebaseFirestore();
  final aiste = userRef(db, 'aiste');
  final tomas = userRef(db, 'tomas');
  const names = {'aiste': 'Aiste', 'tomas': 'Tomas'};
  final today = DateTime(2026, 10, 3, 9);

  const noFriendsTitle = 'Your feed is empty';
  const noPostsTitle = 'No posts today';

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  /// Lets the stream builders deliver their events: posts → author of each
  /// card → song of each card, one frame each.
  Future<void> flushStreams(WidgetTester tester) async {
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump();
    }
  }

  /// Shows the feed and lets the streams deliver their first events.
  Future<void> showFeed(WidgetTester tester, StubFeedSource source) async {
    await tester.pumpWidget(host(SingleChildScrollView(
      child: FriendFeed(source: source),
    )));
    await flushStreams(tester);
  }

  group('FriendFeed.build', () {
    testWidgets('F01 no friends → empty-feed state with "Find friends", posts not requested',
        (tester) async {
      final source = StubFeedSource();

      await showFeed(tester, source);

      expect(find.text(noFriendsTitle), findsOneWidget);
      expect(find.text('Find friends'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(source.todaysPostsCalls, 0,
          reason: 'with no friends the feed must not query posts');
    });

    testWidgets('F02 friends with two posts → both shown in stream order with author and song',
        (tester) async {
      useTallScreen(tester);
      final source = StubFeedSource(
        friendList: [aiste, tomas],
        names: names,
        posts: Stream.value([
          post(aiste, 'p1', song: 'Song A', createdAt: today),
          post(tomas, 'p2', song: 'Song B', createdAt: today),
        ]),
      );

      await showFeed(tester, source);

      expect(source.requestedFriends, [aiste, tomas],
          reason: 'todaysPosts() gets the list returned by friends()');
      expect(find.text('Aiste'), findsOneWidget);
      expect(find.text('Tomas'), findsOneWidget);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Song B'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Song A')).dy,
          lessThan(tester.getTopLeft(find.text('Song B')).dy),
          reason: 'posts are shown in the order of the stream');
      expect(find.text(noPostsTitle), findsNothing);
    });

    testWidgets('F03 friends, no posts today → "No posts today" state',
        (tester) async {
      await showFeed(
        tester,
        StubFeedSource(friendList: [aiste], posts: Stream.value(const [])),
      );

      expect(find.text(noPostsTitle), findsOneWidget);
      expect(find.text(noFriendsTitle), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('F04 tap "Find friends" → friend search route opened',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: SingleChildScrollView(
                child: FriendFeed(source: StubFeedSource()),
              ),
            ),
          ),
          GoRoute(
            name: FriendsListAddFriendWidget.routeName,
            path: FriendsListAddFriendWidget.routePath,
            builder: (_, __) => const Scaffold(body: Text('ROUTE:FriendsListAddFriend')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      await tester.tap(find.text('Find friends'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('ROUTE:FriendsListAddFriend'), findsOneWidget);
    });

    testWidgets('F05 friends, posts not loaded yet → loader, no empty-feed message',
        (tester) async {
      final posts = StreamController<List<UserPostRecord>>();
      addTearDown(posts.close);

      await showFeed(
        tester,
        StubFeedSource(friendList: [aiste], posts: posts.stream),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(noPostsTitle), findsNothing);
      expect(find.text(noFriendsTitle), findsNothing);
    });

    testWidgets('F06 posts arrive after loading → loader replaced by the post',
        (tester) async {
      final posts = StreamController<List<UserPostRecord>>();
      addTearDown(posts.close);
      await showFeed(
        tester,
        StubFeedSource(friendList: [aiste], names: names, posts: posts.stream),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'before the first event');

      posts.add([post(aiste, 'p1', song: 'Morning Light', createdAt: today)]);
      await flushStreams(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Morning Light'), findsOneWidget);
      expect(find.text('Aiste'), findsOneWidget);
    });

    testWidgets('F07 posts stream fails → loader stays, no error or empty message',
        (tester) async {
      // build() has no snapshot.hasError branch: an error leaves hasData false,
      // so the loader is shown forever. Possible defect, see SCRUM-167.
      await showFeed(
        tester,
        StubFeedSource(
          friendList: [aiste],
          posts: Stream.error(
              FirebaseException(plugin: 'cloud_firestore', code: 'unavailable')),
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(noPostsTitle), findsNothing);
      expect(find.text(noFriendsTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
