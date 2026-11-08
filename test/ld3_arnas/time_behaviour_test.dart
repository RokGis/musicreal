// LD3 – Arnas: draugų srauto laiko elgsena (ISO/IEC 25010:2023, veikimo
// efektyvumas → laiko elgsena).
//
// L1    – srauto įkėlimo laikas kliente: nuo FriendFeed atsiradimo ekrane iki
//         kadro, kuriame visos N kortelių turi autorių ir grotuvą, be įkėlimo
//         indikatorių. Duomenys paruošti atmintyje (PrebuiltFeedSource), todėl
//         matuojama tik produkcinio valdiklio (build/layout/paint) kaina.
// L1-M  – srauto įkėlimas su modeliuotu tinklo vėlinimu (virtualus laikrodis):
//         po kiek nuoseklių užklausų etapų srautas pilnas.
// L2    – naujo draugo įrašo pasirodymo laikas: nuo atnaujinto užklausos
//         rezultato gavimo iki kadro, kuriame nauja kortelė pilnai parodyta ir
//         visų kortelių autoriai atitinka jų dainas.
// L1-DB – kontrolinis: L1 su fake_cloud_firestore (produkcinė užklausa). Rodo,
//         kiek laiko sunaudoja pats duomenų bazės pakaitalas; programos laikui
//         neskelbiama.
//
// Kiekvienas scenarijus: 2 apšilimo paleidimai + 7 matuojami (L1-DB: 1 + 5),
// skelbiama mediana (min–max). Laikas – sienos laikrodžio (Stopwatch) kadrų
// trukmių suma flutter_test (debug, JIT) režimu.

import 'package:flutter/widgets.dart' show UniqueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart' show FeedSource;

import '../mantas/support/test_env.dart' show setUpMusicRealTestEnv, resetMusicRealTestEnv;
import 'support/feed_bench.dart';

const int kWarmups = 2;
const int kRuns = 7;

/// Scenarijai: (draugų, įrašų). Pagrindiniai – 10 ir 30 įrašų; 1 – bazinis,
/// 100 – apkrovos (30 draugų, keli įrašai per dieną; programa tai leidžia).
const scenarios = [(1, 1), (10, 10), (30, 30), (30, 100)];

void main() {
  setUpAll(setUpMusicRealTestEnv);
  setUp(resetMusicRealTestEnv);

  /// Vienas srauto įkėlimas: programa jau atidaryta, srautas įdedamas į ekraną.
  Future<FrameRun> loadOnce(WidgetTester tester, int n, FeedSource source) async {
    await tester.pumpWidget(feedApp(null));
    return pumpUntil(
      tester,
      () => feedComplete(n),
      first: () => tester.pumpWidget(feedApp(source, key: UniqueKey())),
    );
  }

  void reportRuns(String id, int friends, int posts, List<FrameRun> runs,
      {String extra = '', Map<String, Object?> more = const {}}) {
    final totals = runs.map((r) => r.totalMs).toList();
    final maxFrames = runs.map((r) => r.maxFrameMs).toList();
    report(
      id,
      '${posts}_irasu',
      '${id.startsWith('L2') ? 'iki parodytos naujos kortelės' : 'iki pilno srauto'} '
          '${fmtStats(totals)}; kadrų ${runs.first.frames}; ilgiausias kadras '
          '${fmtStats(maxFrames)}$extra',
      {
        'friends': friends,
        'posts': posts,
        'medianTotalMs': round2(median(totals)),
        'medianMaxFrameMs': round2(median(maxFrames)),
        'runs': runs.map((r) => r.toJson()).toList(),
        ...more,
      },
    );
  }

  group('L1 srauto įkėlimo laikas kliente', () {
    for (final (friends, posts) in scenarios) {
      testWidgets('L1 $posts įrašų ($friends draugų)', (tester) async {
        usePhoneScreen(tester);
        AudioPluginSpy().install();
        final data = await FeedData.seed(friends: friends, posts: posts);

        final runs = <FrameRun>[];
        for (var i = 0; i < kWarmups + kRuns; i++) {
          final source = await PrebuiltFeedSource.from(data);
          expect(source.postList, hasLength(posts));
          final run = await loadOnce(tester, posts, source);
          expect(run.completed, isTrue, reason: 'srautas turi būti pilnai parodytas');
          if (i >= kWarmups) runs.add(run);
        }
        reportRuns('L1', friends, posts, runs,
            extra: '; kortelių ekrane ${cardsOnScreen(tester)} iš $posts');
      });
    }
  });

  group('L1-M srauto įkėlimas su modeliuotu tinklo vėlinimu', () {
    for (final (posts, rttMs) in [(10, 100), (30, 100), (10, 300), (30, 300)]) {
      testWidgets('L1-M $posts įrašų, RTT $rttMs ms', (tester) async {
        usePhoneScreen(tester);
        AudioPluginSpy().install();
        final data = await FeedData.seed(friends: posts, posts: posts);
        final source = MeasuredFeedSource(data, latency: Duration(milliseconds: rttMs));

        // Virtualus laikas: kiekvienas žingsnis – 5 ms.
        const step = 5;
        int? tCards, tAuthors, tPlayers;
        var t = 0;
        await tester.pumpWidget(feedApp(source));
        while (tPlayers == null && t < 10000) {
          await tester.pump(const Duration(milliseconds: step));
          t += step;
          // Kortelių vietos atsiranda, kai gaunamas įrašų sąrašas (N indikatorių).
          tCards ??= loadersShown() >= posts ? t : null;
          tAuthors ??= authorsShown() == posts ? t : null;
          tPlayers ??= feedComplete(posts) ? t : null;
        }
        expect(tPlayers, isNotNull);

        report(
          'L1-M',
          '${posts}_irasu_RTT_${rttMs}ms',
          'įrašų sąrašas $tCards ms → autoriai $tAuthors ms → grotuvai $tPlayers ms '
              '(${(tPlayers! / rttMs).toStringAsFixed(1).replaceAll('.', ',')} × RTT); '
              'užklausų ${source.listens}',
          {
            'posts': posts,
            'rttMs': rttMs,
            'stepMs': step,
            'tPostListMs': tCards,
            'tAuthorsMs': tAuthors,
            'tCompleteMs': tPlayers,
            'requests': source.listens,
          },
        );
      });
    }
  });

  group('L2 naujo draugo įrašo pasirodymo laikas', () {
    for (final (friends, posts) in scenarios) {
      testWidgets('L2 srautas su $posts įrašų ($friends draugų)', (tester) async {
        usePhoneScreen(tester);
        AudioPluginSpy().install();
        final data = await FeedData.seed(friends: friends, posts: posts);
        final author = data.friends.first;

        final runs = <FrameRun>[];
        final staleFrames = <int>[];
        for (var i = 0; i < kWarmups + kRuns; i++) {
          final source = await PrebuiltFeedSource.from(data);
          final loaded = await loadOnce(tester, posts, source);
          expect(loaded.completed, isTrue);

          final song = songName(0, 900 + i);
          final post = UserPostRecord.getDocumentFromData({
            'song_name': song,
            'post_user': author,
            'created_at': DateTime(2026, 11, 8, 19, 59, 59),
            'emoji': '',
          }, author.collection('userPost').doc('new$i'));
          final music = MusicRecord.getDocumentFromData(
              {'SongName': song, 'SongURL': 'https://audio.test/new$i.mp3'},
              data.db.doc('Music/new$i'));

          var stale = 0;
          final run = await pumpUntil(
            tester,
            () {
              final bad = mismatchedCards(tester);
              if (bad > 0) stale++;
              return feedComplete(posts + 1) &&
                  find.text(song, skipOffstage: false).evaluate().isNotEmpty &&
                  bad == 0;
            },
            first: () async {
              source.publish(post, music);
              await tester.pump();
            },
          );
          expect(run.completed, isTrue, reason: 'naujas įrašas turi atsirasti');
          if (i >= kWarmups) {
            runs.add(run);
            staleFrames.add(stale);
          }
        }
        reportRuns('L2', friends, posts, runs,
            extra: '; kadrų su neatitinkančiu autoriumi ${median(staleFrames.map((e) => e.toDouble()).toList()).toInt()}',
            more: {'framesWithMismatchedAuthor': staleFrames});
      });
    }
  });

  group('L1-DB kontrolinis: su fake_cloud_firestore', () {
    for (final (friends, posts) in [(10, 10), (30, 30)]) {
      testWidgets('L1-DB $posts įrašų ($friends draugų)', (tester) async {
        usePhoneScreen(tester);
        AudioPluginSpy().install();
        final data = await FeedData.seed(friends: friends, posts: posts);

        final runs = <FrameRun>[];
        for (var i = 0; i < 1 + 5; i++) {
          final run = await loadOnce(tester, posts, MeasuredFeedSource(data));
          expect(run.completed, isTrue);
          if (i >= 1) runs.add(run);
        }
        reportRuns('L1-DB', friends, posts, runs);
      });
    }
  });
}
