// Additional verification on 2026-10-26; separate from Rokas' original LD2 tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/statistics/statistics_widget.dart';
import '../mantas/support/test_env.dart';
import 'coverage_probe.dart';

const _happy = 'https://emoji.test/happy.png';
const _sad = 'https://emoji.test/sad.png';

UserPostRecord _post(int id, String song, String emoji) =>
    UserPostRecord.getDocumentFromData({
      'song_name': song,
      'emoji': emoji,
      'created_at': DateTime(2026, 10, 20, 12),
    }, userRef('statistics-check').collection('userPost').doc('$id'));

Future<void> _open(WidgetTester tester, List<UserPostRecord> posts) async {
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      MaterialApp(home: StatisticsWidget(posts: Stream.value(posts))));
  await settle(tester);
}

void main() {
  setUpAll(setUpMusicRealTestEnv);
  setUp(resetMusicRealTestEnv);
  tearDownAll(StatisticsProbe.report);

  testWidgets('V01 empty posts show empty state', (tester) async {
    await _open(tester, []);
    expect(find.text('Nothing to show yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('V02 duplicates and missing fields exercise aggregation',
      (tester) async {
    await _open(tester, [
      _post(1, 'Song A', _happy),
      _post(2, 'Song A', _happy),
      _post(3, 'Song A', _sad),
      _post(4, 'Song B', ''),
      _post(5, '', _sad),
    ]);
    expect(find.text('Song A'), findsOneWidget);
    expect(find.text('Song B'), findsOneWidget);
    expect(find.text('2 (40%)'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('V03 top songs are limited to ten', (tester) async {
    await _open(
        tester, [for (var i = 0; i < 12; i++) _post(i, 'Track $i', '')]);
    final songs = find.byWidgetPredicate((widget) =>
        widget is Text && (widget.data?.startsWith('Track ') ?? false));
    expect(songs, findsNWidgets(10));
    expect(
        find.text('No emotions shared in the last 30 days.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
