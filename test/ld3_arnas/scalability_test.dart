// LD3 – Arnas: draugų srauto mastelio kaita (ISO/IEC 25010:2023, lankstumas →
// mastelio kaita / scalability).
//
// M1 – didžiausias palaikomas draugų skaičius: ar srautas parodo visų draugų
//      šios dienos įrašus, kai draugų 30 ir 31 (papildomai 100). Naudojamas
//      nepakeistas produkcinis FeedSource (FirebaseFirestore.instance) ant Manto
//      platformos lygio pakaitalo, todėl veikia tikras cloud_firestore Dart kodas.
//      M1-R – release režimo modelis: užklausą atmeta platforma, ką mato naudotojas.
// M2 – išteklių augimas su įrašų skaičiumi: Firestore prenumeratos (listen),
//      grotuvų atidarymai (assets_audio_player 'open') ir sukurtos kortelės
//      (a) atidarant srautą, (b) atėjus vienam naujam draugo įrašui,
//      (c) persikūrus tėviniam valdikliui (pasikeitus naudotojo dokumentui).
//      Naudojamas MeasuredFeedSource su fake_cloud_firestore (produkcinė
//      friendsFeedQuery() ir queryCollection()).

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/auth/firebase_auth/auth_util.dart' as auth_util;
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import '../mantas/support/test_env.dart'
    show setUpMusicRealTestEnv, resetMusicRealTestEnv, settle;
import 'support/feed_bench.dart';
import 'support/rejecting_firestore.dart';

final platform = RejectableFirestore();

void main() {
  setUpAll(() async {
    await setUpMusicRealTestEnv();
    // Prieš pirmą FirebaseFirestore.instance panaudojimą.
    FirebaseFirestorePlatform.instance = platform;
  });
  setUp(() {
    resetMusicRealTestEnv();
    platform.reset();
    platform.rejectFeedQuery = false;
  });

  /// Produkcinė aplinka: naudotojas „me“ su [friends] draugų, kiekvienas
  /// draugas šiandien paskelbė po vieną įrašą, daina yra kataloge.
  void seedProduction(int friends) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final refs = [for (var i = 0; i < friends; i++) FirebaseFirestore.instance.doc('users/friend$i')];
    for (var i = 0; i < friends; i++) {
      platform.seed('users/friend$i', {'uid': 'friend$i', 'display_name': friendName(i)});
      platform.seed('users/friend$i/userPost/p$i', {
        'song_name': songName(i, i),
        'post_user': refs[i],
        'created_at': startOfToday.add(Duration(seconds: 1 + i)),
        'emoji': '',
      });
      platform.seed('Music/m$i', {'SongName': songName(i, i), 'SongURL': 'https://audio.test/$i.mp3'});
    }
    final meData = {'uid': 'me', 'display_name': 'Me', 'friends': refs};
    platform.seed('users/me', meData);
    auth_util.currentUserDocument =
        UsersRecord.getDocumentFromData(meData, FirebaseFirestore.instance.doc('users/me'));
  }

  int postsShown() =>
      countOf(find.textContaining(RegExp(r'^Song \d{3}-'), skipOffstage: false));

  /// Naudotojui matomi tekstai, išskyrus programos pavadinimą.
  List<String> visibleTexts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => s.isNotEmpty && s != 'MusicReal')
      .toList();

  group('M1 didžiausias palaikomas draugų skaičius (produkcinis FeedSource)', () {
    for (final friends in [30, 31, 100]) {
      testWidgets('M1 $friends draugų, kiekvienas paskelbė po įrašą', (tester) async {
        usePhoneScreen(tester);
        AudioPluginSpy().install();
        seedProduction(friends);

        await tester.pumpWidget(feedApp(const FeedSource()));
        await settle(tester);

        final errors = <Object>[];
        for (Object? e = tester.takeException(); e != null; e = tester.takeException()) {
          errors.add(e);
        }
        final shown = postsShown();
        final e0 = errors.isEmpty ? null : errors.first;
        final firstError = e0 == null
            ? 'nėra'
            : e0 is AssertionError
                ? 'AssertionError (cloud_firestore/src/query.dart): ${e0.message}'
                : '${e0.runtimeType}: ${e0.toString().split('\n').first}';
        report(
          'M1',
          '${friends}_draugu',
          'parodyta įrašų $shown/$friends (${(100 * shown / friends).round()} %); '
              'klaida: $firstError',
          {
            'friends': friends,
            'postsExpected': friends,
            'postsShown': shown,
            'errorWidget': countOf(find.byType(ErrorWidget)),
            'errors': errors.map((e) => e.toString().split('\n').first).toList(),
          },
        );

        if (friends <= 30) {
          expect(shown, friends);
          expect(errors, isEmpty);
        } else {
          expect(shown, 0);
          expect(errors.first, isA<AssertionError>());
        }
      });
    }

    testWidgets('M1-R release modelis: užklausą atmeta platforma (31 draugas)',
        (tester) async {
      usePhoneScreen(tester);
      AudioPluginSpy().install();
      // 30 draugų sąrašas praeina debug assert'ą; platforma atmeta užklausą taip,
      // kaip release režimu atmestų 31 draugo užklausą.
      seedProduction(30);
      platform.rejectFeedQuery = true;

      await tester.pumpWidget(feedApp(const FeedSource()));
      // 10 s virtualaus laiko.
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final loader = loadersShown();
      final texts = visibleTexts(tester);
      report(
        'M1-R',
        'platforma_atmeta',
        'po 10 s: parodyta įrašų ${postsShown()}; įkėlimo indikatorius rodomas: '
            '${loader > 0 ? 'taip' : 'ne'}; naudotojui rodomi tekstai: '
            '${texts.isEmpty ? 'nėra' : texts.join(' | ')}; išimčių: '
            '${tester.takeException() == null ? 0 : 1}',
        {
          'postsShown': postsShown(),
          'loaders': loader,
          'visibleTexts': texts,
          'virtualSeconds': 10,
        },
      );
      expect(postsShown(), 0);
      expect(loader, greaterThan(0), reason: 'klaida nuryjama – lieka įkėlimo būsena');
      expect(texts, isEmpty, reason: 'nėra klaidos pranešimo ar pakartojimo mygtuko');
    });
  });

  group('M2 išteklių augimas su įrašų skaičiumi', () {
    for (final (friends, posts) in [(1, 1), (10, 10), (30, 30), (30, 100)]) {
      testWidgets('M2 $posts įrašų ($friends draugų)', (tester) async {
        usePhoneScreen(tester);
        final audio = AudioPluginSpy()..install();
        final data = await FeedData.seed(friends: friends, posts: posts);
        final source = MeasuredFeedSource(data);
        final tick = ValueNotifier<int>(0);
        addTearDown(tick.dispose);

        Map<String, int> audioCounts() => {
              for (final m in audio.calls.toSet()) m: audio.count(m),
            };

        // (a) Srauto atidarymas.
        await tester.pumpWidget(feedApp(source, key: const ValueKey('feed'), parentTick: tick));
        final load = await pumpUntil(tester, () => feedComplete(posts));
        expect(load.completed, isTrue);
        final loadCounts = source.counts();
        final loadAudio = audioCounts();
        final built = authorsShown();
        final onScreen = cardsOnScreen(tester);

        // (b) Vienas draugas paskelbia naują įrašą.
        await data.catalogueNextSong(0);
        final song = data.nextSong(0);
        final l0 = source.listens, c0 = source.cancels;
        audio.calls.clear();
        var mismatchFrames = 0;
        final update = await pumpUntil(
          tester,
          () {
            if (mismatchedCards(tester) > 0) mismatchFrames++;
            return feedComplete(posts + 1) &&
                find.text(song, skipOffstage: false).evaluate().isNotEmpty &&
                mismatchedCards(tester) == 0;
          },
          first: () => data.addPost(0,
              createdAt: DateTime(2026, 11, 8, 19, 59, 59), catalogue: false),
        );
        expect(update.completed, isTrue);
        final updListens = source.listens - l0;
        final updCancels = source.cancels - c0;
        final updAudio = audioCounts();

        // (c) Tėvinis valdiklis persikuria (pvz., pasikeitė streak_count).
        final l1 = source.listens, c1 = source.cancels;
        audio.calls.clear();
        tick.value++;
        for (var i = 0; i < 6; i++) {
          await tester.pump();
        }
        expect(feedComplete(posts + 1), isTrue);
        final parListens = source.listens - l1;
        final parCancels = source.cancels - c1;
        final parAudio = audioCounts();

        report(
          'M2',
          '${posts}_irasu',
          'atidarant: prenumeratų ${loadCounts['listens']} '
              '(įrašai ${(loadCounts['posts'] as Map)['listens']} + autoriai '
              '${(loadCounts['authors'] as Map)['listens']} + dainos '
              '${(loadCounts['music'] as Map)['listens']}), grotuvų atidaryta ${loadAudio['open'] ?? 0}, '
              'kortelių sukurta $built, ekrane $onScreen; '
              'naujas įrašas: naujų prenumeratų $updListens, nutrauktų $updCancels, '
              'grotuvo kreipinių ${updAudio.values.fold(0, (a, b) => a + b)} $updAudio, '
              'kadrų su neatitinkančiu autoriumi $mismatchFrames; '
              'tėvinio valdiklio perkūrimas: naujų prenumeratų $parListens, nutrauktų $parCancels',
          {
            'friends': friends,
            'posts': posts,
            'load': {
              'streams': loadCounts,
              'audioCalls': loadAudio,
              'cardsBuilt': built,
              'cardsOnScreen': onScreen,
            },
            'newPost': {
              'newSubscriptions': updListens,
              'cancelledSubscriptions': updCancels,
              'audioCalls': updAudio,
              'framesWithMismatchedAuthor': mismatchFrames,
              'activeAfter': source.active,
            },
            'parentRebuild': {
              'newSubscriptions': parListens,
              'cancelledSubscriptions': parCancels,
              'audioCalls': parAudio,
            },
          },
        );
      });
    }
  });
}
