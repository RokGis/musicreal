// LD3 – Arnas: ekrano vaizdai matavimų įrodymams (ld3_arnas_results/screenshots).
// Tos pačios būsenos, kurias matuoja time_behaviour_test.dart ir
// scalability_test.dart, tik su tikrais šriftais (Roboto, MaterialIcons iš
// Flutter SDK), kad tekstas būtų įskaitomas. Šis failas nieko nematuoja.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/auth/firebase_auth/auth_util.dart' as auth_util;
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

import '../mantas/support/test_env.dart' show setUpMusicRealTestEnv, resetMusicRealTestEnv;
import 'support/feed_bench.dart';
import 'support/rejecting_firestore.dart';

final platform = RejectableFirestore();
const shotKey = ValueKey('shot');
const outDir = 'ld3_arnas_results/screenshots';

String _materialFonts() {
  // .../flutter/bin/cache/artifacts/engine/linux-x64/flutter_tester
  var dir = File(Platform.resolvedExecutable).parent;
  while (!Directory('${dir.path}/material_fonts').existsSync() && dir.parent.path != dir.path) {
    dir = dir.parent;
  }
  return '${dir.path}/material_fonts';
}

Future<void> _loadFonts() async {
  final dir = _materialFonts();
  Future<ByteData> bytes(String f) async =>
      ByteData.sublistView(File('$dir/$f').readAsBytesSync());
  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(bytes('MaterialIcons-Regular.otf'))).load();
}

/// google_fonts šriftai kraunami asinchroniškai – leidžiame jiems įsikelti ir
/// perpiešiame. Naudojama tik ten, kur papildomas kadras nekeičia būsenos.
Future<void> settleFonts(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
}

Future<void> shoot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(shotKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(outDir).createSync(recursive: true);
    File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('SCREENSHOT | $outDir/$name');
}

Widget shotApp(FeedSource source) =>
    RepaintBoundary(key: shotKey, child: feedApp(source, key: const ValueKey('feed')));

void main() {
  setUpAll(() async {
    await setUpMusicRealTestEnv();
    FirebaseFirestorePlatform.instance = platform;
    await _loadFonts();
  });
  setUp(() {
    resetMusicRealTestEnv();
    platform.reset();
    platform.rejectFeedQuery = false;
  });

  testWidgets('S1–S3 srautas, naujas įrašas ir neatitinkantys autoriai', (tester) async {
    usePhoneScreen(tester);
    AudioPluginSpy().install();
    final data = await FeedData.seed(friends: 10, posts: 10);
    final source = await PrebuiltFeedSource.from(data);

    await tester.pumpWidget(shotApp(source));
    expect((await pumpUntil(tester, () => feedComplete(10))).completed, isTrue);
    await settleFonts(tester);
    await shoot(tester, 'S1_srautas_10_irasu.png');

    final author = data.friends.first;
    final song = songName(0, 900);
    source.publish(
      UserPostRecord.getDocumentFromData({
        'song_name': song,
        'post_user': author,
        'created_at': DateTime(2026, 11, 8, 19, 59, 59),
        'emoji': '',
      }, author.collection('userPost').doc('new')),
      MusicRecord.getDocumentFromData(
          {'SongName': song, 'SongURL': 'https://audio.test/new.mp3'}, data.db.doc('Music/new')),
    );
    await tester.pump();
    final bad = mismatchedCards(tester);
    expect(bad, greaterThan(0));
    // ignore: avoid_print
    print('S2: kortelių su neatitinkančiu autoriumi: $bad');
    await shoot(tester, 'S2_naujas_irasas_pirmas_kadras_neatitinka_autoriai.png');

    expect((await pumpUntil(tester, () => feedComplete(11) && mismatchedCards(tester) == 0)).completed,
        isTrue);
    await shoot(tester, 'S3_naujas_irasas_po_3_kadru.png');
  });

  testWidgets('S4 release modelis: užklausą atmeta platforma – begalinis indikatorius',
      (tester) async {
    usePhoneScreen(tester);
    AudioPluginSpy().install();
    final refs = [for (var i = 0; i < 30; i++) FirebaseFirestore.instance.doc('users/friend$i')];
    final meData = {'uid': 'me', 'display_name': 'Me', 'friends': refs};
    platform.seed('users/me', meData);
    auth_util.currentUserDocument =
        UsersRecord.getDocumentFromData(meData, FirebaseFirestore.instance.doc('users/me'));
    platform.rejectFeedQuery = true;

    await tester.pumpWidget(shotApp(const FeedSource()));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(loadersShown(), greaterThan(0));
    await settleFonts(tester);
    await shoot(tester, 'S4_release_modelis_po_10s_begalinis_indikatorius.png');
  });
}
