// Mantas — SCRUM-62 (Feature) and SCRUM-65 (Story): choosing an emotion
// (emoji) for the song being uploaded.
//
// Source of truth: Jira export "Jira (1).csv". Each test is named
// "<requirement> / <Jira TC> — <expected behaviour>" and asserts what the
// current Jira acceptance criteria require, not what the code does. Message
// wording is never asserted: Jira does not define it (SCRUM-62 comment).
// EBT-POST-* are error-based tests (task 4c); EBT-POST-07 has no Jira oracle
// and documents a requirement gap.
//
// Acceptance criteria under test
//   SCRUM-62 AC1  no emoji selected -> upload cannot be completed
//   SCRUM-62 AC2  the picker shows a list of 5 emojis
//   SCRUM-62 AC3  the chosen emoji is saved with the song and shown in the
//                 summary
//   SCRUM-62 AC4  only one emoji can be attached to the song
//   SCRUM-65 AC65-1 .. AC65-5 (same rules, user view; AC65-5 = shown in feed)
//
// The real PostWidget, HomeWidget and StatisticsWidget run against an
// in-memory Firestore (see support/). Nothing reaches the network.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_for_management/auth/base_auth_user_provider.dart'
    as auth_state;
import 'package:project_for_management/flutter_flow/flutter_flow_widgets.dart';
import 'package:project_for_management/pages/home/home_widget.dart';
import 'package:project_for_management/pages/post/post_widget.dart';
import 'package:project_for_management/statistics/statistics_widget.dart';

import 'support/test_env.dart';

const _me = 'mantas-uid';
const _friend = 'friend-uid';
const _song = 'Morning Light';
const _otherSong = 'Night Drive';

/// Number of emojis SCRUM-62 AC2 / SCRUM-65 AC65-1 require.
const _requiredEmotionCount = 5;

void main() {
  setUpAll(setUpMusicRealTestEnv);

  setUp(() {
    resetMusicRealTestEnv();
    _signInAs(_me);
    fakeFirestore
      ..seed('users/$_me', {
        'uid': _me,
        'email': 'mantas@musicreal.test',
        'display_name': 'Mantas',
        'streak_count': 0,
      })
      ..seed('users/$_friend', {
        'uid': _friend,
        'email': 'friend@musicreal.test',
        'display_name': 'Friend',
        'friends': [userRef(_me)],
      })
      // Songs without a URL so no audio player is ever started.
      ..seed('Music/song-1', {
        'SongName': _song,
        'Author': 'SoundHelix',
        'Genres': ['Chill'],
        'SongURL': '',
      })
      ..seed('Music/song-2', {
        'SongName': _otherSong,
        'Author': 'SoundHelix',
        'Genres': ['Electronic'],
        'SongURL': '',
      });
  });

  group('SCRUM-62 — emotion is chosen while uploading a song', () {
    testWidgets(
        'SCRUM-62 / TC-FEAT62-01 (EP: 0 emojis) — upload is blocked when no '
        'emoji is selected', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      await _pressPost(tester);

      expect(_myPosts(), isEmpty, reason: 'no post may be stored');
      expect(find.text('New post'), findsOneWidget,
          reason: 'the user stays on the upload page');
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'SCRUM-62 / TC-FEAT62-02 (EP: 1 emoji) — upload completes when exactly '
        'one emoji is selected', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      await _chooseEmotion(tester, 0);

      await _pressPost(tester);

      expect(tester.takeException(), isNull);
      expect(_myPosts(), hasLength(1));
      expect(find.text(routeMarker('Home')), findsOneWidget,
          reason: 'a completed upload leaves the upload page');
    });

    testWidgets(
        'SCRUM-62 / TC-FEAT62-03 (BVA: 5) — the picker shows exactly 5 emojis',
        (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      expect(_emotionChoiceCount(tester), _requiredEmotionCount,
          reason: 'SCRUM-62 AC2: "sąrašas iš 5 galimų pasirinkti jaustukų"');
    });

    test(
        'SCRUM-62 / TC-FEAT62-03 (supporting unit test, BVA: 5) — kEmotions '
        'defines exactly 5 distinct emojis', () {
      expect(kEmotions.toSet(), hasLength(_requiredEmotionCount),
          reason: 'lib/pages/post/post_widget.dart kEmotions is the list the '
              'picker is built from');
    });

    testWidgets(
        'SCRUM-62 / TC-FEAT62-04 — choosing a second emoji deselects the first',
        (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      final a = _emotionAt(tester, 0);
      final b = _emotionAt(tester, 1);

      await _chooseEmotion(tester, 0);
      expect(_selectedIndexes(tester), [0]);

      await _chooseEmotion(tester, 1);
      expect(_selectedIndexes(tester), [1],
          reason: 'only B may remain selected');
      expect(_summaryEmotion(tester), b);
      expect(_summaryEmotion(tester), isNot(a));
    });

    testWidgets(
        'SCRUM-62 / TC-FEAT62-05 — the chosen emoji is saved with the song and '
        'shown next to it in the summary (Statistics)', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      final chosen = _emotionAt(tester, 1);
      await _chooseEmotion(tester, 1);
      await _pressPost(tester);

      final stored = fakeFirestore.data(_myPosts().single)!;
      expect(stored['song_name'], _song);
      expect(stored['emoji'], chosen);

      await pumpRoutedPage(
        tester,
        name: StatisticsWidget.routeName,
        path: StatisticsWidget.routePath,
        page: (_) => const StatisticsWidget(),
      );
      final songRow =
          find.ancestor(of: find.text(_song), matching: find.byType(Row));
      expect(
        find.descendant(of: songRow, matching: _networkImage(chosen)),
        findsWidgets,
        reason: 'the summary row of the uploaded song shows emoji X',
      );
    });
  });

  group('SCRUM-65 — user adds an emotion to a song with emojis', () {
    testWidgets(
        'SCRUM-65 / TC-US65-01 (AC65-1) — after choosing a song 5 emojis are '
        'offered', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      expect(_emotionChoiceCount(tester), _requiredEmotionCount);
      final ids = [
        for (var i = 0; i < _emotionChoiceCount(tester); i++)
          _emotionAt(tester, i),
      ];
      expect(ids.toSet(), hasLength(ids.length),
          reason: 'every offered emoji is a different emotion');
    });

    testWidgets(
        'SCRUM-65 / TC-US65-02 (AC65-2) — only one emoji is selected at a time',
        (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      for (var i = 0; i < _emotionChoiceCount(tester); i++) {
        await _chooseEmotion(tester, i);
        expect(_selectedIndexes(tester), [i],
            reason: 'after tapping emoji #$i only it is selected');
      }
    });

    testWidgets(
        'SCRUM-65 / TC-US65-03 (AC65-3) — the upload cannot be completed '
        'without an emoji', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      await _pressPost(tester);
      await _waitForMessageToClose(tester);
      await _pressPost(tester); // trying again changes nothing

      expect(_myPosts(), isEmpty);
      expect(find.text('New post'), findsOneWidget);
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'SCRUM-65 / TC-US65-04 (AC65-4) — the chosen emoji is stored in the '
        'database together with the song', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      final chosen = _emotionAt(tester, 2);
      await _chooseEmotion(tester, 2);

      await _pressPost(tester);

      final posts = _myPosts();
      expect(posts, hasLength(1));
      // The emoji and the song are stored in one and the same post record.
      final stored = fakeFirestore.data(posts.single)!;
      expect(stored['song_name'], _song);
      expect(stored['emoji'], chosen);
      expect(stored['post_user'], 'users/$_me');
    });

    testWidgets(
        'SCRUM-65 / TC-US65-05 (AC65-5) — a friend sees the emoji next to the '
        'song in the feed', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      final chosen = _emotionAt(tester, 0);
      await _chooseEmotion(tester, 0);
      await _pressPost(tester);
      expect(_myPosts(), hasLength(1));

      // Another user, who has Mantas as a friend, opens the feed.
      _signInAs(_friend);
      await pumpRoutedPage(
        tester,
        name: HomeWidget.routeName,
        path: HomeWidget.routePath,
        page: (_) => const HomeWidget(),
      );

      expect(find.text(_song), findsOneWidget);
      final card =
          find.ancestor(of: find.text(_song), matching: find.byType(Row));
      expect(find.descendant(of: card, matching: _networkImage(chosen)),
          findsWidgets);
    });
  });

  group('SCRUM-62 / SCRUM-65 — error-based tests', () {
    testWidgets(
        'EBT-POST-01 (SCRUM-62/65, missing song) — an emoji without a song is '
        'rejected and nothing is stored', (tester) async {
      await _openPostPage(tester);
      await _chooseEmotion(tester, 0);

      await _pressPost(tester);

      expect(_myPosts(), isEmpty);
      expect(find.text('New post'), findsOneWidget);
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'EBT-POST-02 (SCRUM-62/65, nothing chosen) — an empty form is rejected '
        'and nothing is stored', (tester) async {
      await _openPostPage(tester);

      await _pressPost(tester);

      expect(_myPosts(), isEmpty);
      expect(find.text('New post'), findsOneWidget);
      expect(find.text(routeMarker('Home')), findsNothing);
    });

    testWidgets(
        'EBT-POST-03 (SCRUM-62 AC4) — tapping the selected emoji again keeps '
        'exactly one emoji selected', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);

      await _chooseEmotion(tester, 1);
      await _chooseEmotion(tester, 1);

      expect(_selectedIndexes(tester), [1]);
    });

    testWidgets(
        'EBT-POST-04 (SCRUM-62 AC1+AC3) — after a blocked attempt the user can '
        'pick an emoji and the post stores that emoji', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      await _pressPost(tester);
      expect(_myPosts(), isEmpty);
      await _waitForMessageToClose(tester);

      final chosen = _emotionAt(tester, 1);
      await _chooseEmotion(tester, 1);
      await _pressPost(tester);

      expect(_myPosts(), hasLength(1));
      expect(fakeFirestore.data(_myPosts().single)!['emoji'], chosen);
    });

    testWidgets(
        'EBT-POST-05 (SCRUM-62 AC3, repeated submit) — a double tap on Post '
        'stores one post, not two', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      await _chooseEmotion(tester, 0);

      final post = find.widgetWithText(FFButtonWidget, 'Post');
      await tester.tap(post);
      await tester.tap(post, warnIfMissed: false);
      await settle(tester);

      expect(_myPosts(), hasLength(1));
    });

    testWidgets(
        'EBT-POST-06 (SCRUM-62 AC3+AC4, changing choices) — after changing '
        'song and emoji the post stores the last of each', (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      await _chooseEmotion(tester, 0);
      await _chooseSong(tester, _otherSong);
      final chosen = _emotionAt(tester, 2);
      await _chooseEmotion(tester, 2);

      await _pressPost(tester);

      final stored = fakeFirestore.data(_myPosts().single)!;
      expect(stored['song_name'], _otherSong);
      expect(stored['emoji'], chosen);
    });

    testWidgets(
        'EBT-POST-07 (REQUIREMENT GAP: no AC defines a failed upload) — when '
        'saving the post fails the user is told and nothing is stored',
        (tester) async {
      await _openPostPage(tester);
      await _chooseSong(tester, _song);
      await _chooseEmotion(tester, 0);
      fakeFirestore.failWritesWith = Exception('permission-denied');

      // An exception escaping the Post handler is reported by the test
      // framework as an unhandled error and fails this test on its own.
      await _pressPost(tester);

      expect(_myPosts(), isEmpty);
      expect(find.text(routeMarker('Home')), findsNothing,
          reason: 'a failed upload must not look like a successful one');
      expect(find.byType(SnackBar), findsOneWidget,
          reason: 'the user is told the upload failed');
    });
  });
}

// ------------------------------------------------------------------ helpers

void _signInAs(String uid) {
  auth_state.currentUser = TestAuthUser(uid: uid);
  fakeAuth.signInAs(FakeIdentity(uid: uid));
}

Future<void> _openPostPage(WidgetTester tester) => pumpRoutedPage(
      tester,
      name: PostWidget.routeName,
      path: PostWidget.routePath,
      page: (_) => const PostWidget(),
    );

Future<void> _chooseSong(WidgetTester tester, String name) async {
  // The song tile is the tappable InkWell in the catalogue list; the summary
  // box also shows the name once a song is chosen, but it is not tappable.
  await tester.tap(find.widgetWithText(InkWell, name));
  await settle(tester);
}

Future<void> _chooseEmotion(WidgetTester tester, int index) async {
  await tester.tap(_emotionChoice(index));
  await settle(tester);
}

Future<void> _pressPost(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FFButtonWidget, 'Post'));
  await settle(tester);
}

/// The validation SnackBar (4 s) covers the Post button; a real user reads it
/// before trying again.
Future<void> _waitForMessageToClose(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await settle(tester);
}

List<String> _myPosts() => fakeFirestore.docsIn('users/$_me/userPost');

/// The row of tappable emojis on the upload page.
final Finder _picker = find.byWidgetPredicate(
  (w) => w is Row && w.children.length > 1 && w.children.every((c) => c is InkWell),
  description: 'emotion picker row',
);

Finder _emotionChoice(int index) =>
    find.descendant(of: _picker, matching: find.byType(InkWell)).at(index);

int _emotionChoiceCount(WidgetTester tester) =>
    tester.widget<Row>(_picker).children.length;

/// Identifier of the emoji offered at [index] (the app stores its image URL).
String _emotionAt(WidgetTester tester, int index) {
  final image = tester.widget<Image>(
    find.descendant(of: _emotionChoice(index), matching: find.byType(Image)),
  );
  return (image.image as NetworkImage).url;
}

/// Indexes of the emojis currently drawn as selected (2px highlighted border).
List<int> _selectedIndexes(WidgetTester tester) => [
      for (var i = 0; i < _emotionChoiceCount(tester); i++)
        if (_isSelected(tester, i)) i,
    ];

bool _isSelected(WidgetTester tester, int index) {
  final box = tester.widget<Container>(
    find
        .descendant(of: _emotionChoice(index), matching: find.byType(Container))
        .first,
  );
  final border = (box.decoration! as BoxDecoration).border! as Border;
  return border.top.width == 2.0;
}

/// Emoji shown in the "song + emotion" summary box above the Post button.
String? _summaryEmotion(WidgetTester tester) {
  final images = tester
      .widgetList<Image>(find.byWidgetPredicate(
          (w) => w is Image && w.width == 28.0 && w.image is NetworkImage))
      .toList();
  return images.isEmpty ? null : (images.single.image as NetworkImage).url;
}

Finder _networkImage(String url) => find.byWidgetPredicate(
      (w) => w is Image && w.image is NetworkImage && (w.image as NetworkImage).url == url,
      description: 'image $url',
    );
