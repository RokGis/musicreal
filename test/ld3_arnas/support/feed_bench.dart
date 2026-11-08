// LD3 – Arnas: bendri draugų srauto (FriendFeed) matavimų įrankiai.
//
// Matuojamas produkcinis valdiklis FriendFeed (lib/pages/home/home_widget.dart)
// ir produkcinė užklausa friendsFeedQuery(). Duomenų šaltinis MeasuredFeedSource
// kartoja FeedSource 1:1, tik šakninė kolekcija paimama iš fake_cloud_firestore,
// o ne iš FirebaseFirestore.instance:
//   todaysPosts -> queryCollection(collectionGroup('userPost'), friendsFeedQuery)
//   author      -> UsersRecord.getDocument(ref)
//   music       -> queryCollection(Music, where SongName ==, singleRecord: true)
// Kiekvienas iškvietimas, kaip ir produkcijoje, grąžina naują srautą. Apvalkalas
// tik skaičiuoja prenumeratas (listen/cancel) ir, jei nurodyta, modeliuoja tinklo
// vėlinimą iki pirmojo atsakymo.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// ignore: implementation_imports
import 'package:fake_cloud_firestore/src/query_snapshot_stream_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/flutter_flow/flutter_flow_audio_player.dart';
import 'package:project_for_management/pages/home/home_widget.dart';

/// Fiksuotas „dabar“: visi įrašai sukurti šią dieną 08:00–19:59.
final DateTime kBenchNow = DateTime(2026, 11, 8, 20, 0);

String friendName(int i) => 'Friend ${i.toString().padLeft(3, '0')}';
String songName(int friend, int post) =>
    'Song ${friend.toString().padLeft(3, '0')}-${post.toString().padLeft(3, '0')}';

/// Sintetinė duomenų bazė: naudotojas „me“, [friends] draugų ir [posts] šios
/// dienos įrašų, paskirstytų draugams paeiliui. Kiekviena daina yra kataloge
/// (Music) su SongURL, todėl kiekviena kortelė turi grotuvą, kaip programoje.
class FeedData {
  FeedData._(this.db);

  final FakeFirebaseFirestore db;
  final List<DocumentReference> friends = [];
  int _posts = 0;

  int get postCount => _posts;

  /// Katalogo dydis nepriklauso nuo scenarijaus. fake_cloud_firestore kiekvienai
  /// užklausai perrenka visą kolekciją, o tikras Firestore naudoja indeksą; esant
  /// pastoviam katalogui vienos dainos užklausos kaina vienoda visuose
  /// scenarijuose, kaip ir su indeksu.
  static const int catalogueSize = 200;

  static Future<FeedData> seed({required int friends, required int posts}) async {
    final data = await _seed(friends: friends, posts: posts);
    for (var i = posts; i < catalogueSize; i++) {
      await data.db.doc('Music/filler$i').set({
        'SongName': 'Filler $i',
        'SongURL': 'https://audio.test/filler$i.mp3',
      });
    }
    return data;
  }

  static Future<FeedData> _seed({required int friends, required int posts}) async {
    final data = FeedData._(FakeFirebaseFirestore());
    for (var i = 0; i < friends; i++) {
      final ref = data.db.doc('users/friend$i');
      await ref.set({'uid': 'friend$i', 'display_name': friendName(i)});
      data.friends.add(ref);
    }
    await data.db.doc('users/me').set({
      'uid': 'me',
      'display_name': 'Me',
      'friends': data.friends,
    });
    for (var k = 0; k < posts; k++) {
      await data.addPost(
        k % friends,
        createdAt: DateTime(2026, 11, 8, 8).add(Duration(minutes: k)),
      );
    }
    return data;
  }

  /// Kito įrašo daina (dar nepaskelbta).
  String nextSong(int friend) => songName(friend, _posts);

  /// Kito įrašo dainą įtraukia į katalogą – programoje daina renkama iš
  /// katalogo, todėl ji ten yra dar prieš paskelbiant įrašą.
  Future<void> catalogueNextSong(int friend) => db.doc('Music/m$_posts').set({
        'SongName': nextSong(friend),
        'SongURL': 'https://audio.test/$_posts.mp3',
      });

  /// Draugas [friend] paskelbia naują įrašą.
  Future<String> addPost(int friend,
      {required DateTime createdAt, bool catalogue = true}) async {
    if (catalogue) await catalogueNextSong(friend);
    final k = _posts++;
    final song = songName(friend, k);
    await friends[friend].collection('userPost').doc('p$k').set({
      'song_name': song,
      'post_user': friends[friend],
      'created_at': createdAt,
      'emoji': '',
    });
    // fake_cloud_firestore 3.0.2 praneša apie įrašą tik tikslaus kelio
    // (users/friendX/userPost) ir jo tėvų klausytojams, bet ne collectionGroup
    // ('userPost') klausytojams. Tikras Firestore serveris praneštų ir jiems,
    // todėl tas pats įvykis paskelbiamas collectionGroup keliu.
    await QuerySnapshotStreamManager()
        .fireSnapshotUpdate<Map<String, dynamic>>(db, 'userPost', id: 'p$k');
    return song;
  }
}

/// Vienos rūšies prenumeratų skaitliukai.
class StreamStats {
  int listens = 0;
  int cancels = 0;
  int get active => listens - cancels;

  Map<String, int> snapshot() =>
      {'listens': listens, 'cancels': cancels, 'active': active};
}

class MeasuredFeedSource extends FeedSource {
  MeasuredFeedSource(this.data, {this.latency = Duration.zero, List<DocumentReference>? friendList})
      : friendList = friendList ?? data.friends;

  final FeedData data;
  final List<DocumentReference> friendList;

  /// Modeliuojamas tinklo vėlinimas iki pirmojo kiekvieno srauto atsakymo.
  final Duration latency;

  final StreamStats postStreams = StreamStats();
  final StreamStats authorStreams = StreamStats();
  final StreamStats musicStreams = StreamStats();

  List<StreamStats> get _all => [postStreams, authorStreams, musicStreams];
  int get listens => _all.fold(0, (a, s) => a + s.listens);
  int get cancels => _all.fold(0, (a, s) => a + s.cancels);
  int get active => _all.fold(0, (a, s) => a + s.active);

  Map<String, Object> counts() => {
        'posts': postStreams.snapshot(),
        'authors': authorStreams.snapshot(),
        'music': musicStreams.snapshot(),
        'listens': listens,
        'cancels': cancels,
        'active': active,
      };

  @override
  List<DocumentReference> friends() => friendList;

  @override
  Stream<List<UserPostRecord>> todaysPosts(List<DocumentReference> friends) =>
      _observe(
        postStreams,
        queryCollection(
          data.db.collectionGroup('userPost'),
          UserPostRecord.fromSnapshot,
          queryBuilder: (q) => friendsFeedQuery(q, friends, kBenchNow),
        ),
      );

  @override
  Stream<UsersRecord> author(DocumentReference user) =>
      _observe(authorStreams, UsersRecord.getDocument(user));

  @override
  Stream<List<MusicRecord>> music(String songName) => _observe(
        musicStreams,
        queryCollection(
          data.db.collection('Music'),
          MusicRecord.fromSnapshot,
          queryBuilder: (m) => m.where('SongName', isEqualTo: songName),
          singleRecord: true,
        ),
      );

  Stream<T> _observe<T>(StreamStats stats, Stream<T> inner) {
    late final StreamController<T> controller;
    StreamSubscription<T>? sub;
    Timer? wait;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        stats.listens++;
        void connect() => sub = inner.listen(controller.add,
            onError: controller.addError, onDone: controller.close);
        if (latency == Duration.zero) {
          connect();
        } else {
          wait = Timer(latency, connect);
        }
      },
      onCancel: () {
        stats.cancels++;
        wait?.cancel();
        return sub?.cancel();
      },
    );
    return controller.stream;
  }
}

/// Šaltinis be duomenų bazės: tie patys įrašai, autoriai ir dainos, bet jau
/// paruošti. Naudojamas valdiklių medžio (FriendFeed) kainai matuoti atskirai
/// nuo duomenų bazės pakaitalo kainos. Kaip ir FeedSource, kiekvienas
/// iškvietimas grąžina naują srautą, o įvykiai ateina asinchroniškai, todėl
/// etapų (kadrų) skaičius toks pats kaip su Firestore.
class PrebuiltFeedSource extends FeedSource {
  PrebuiltFeedSource._(this.friendList, this.postList, this.users, this.songs);

  final List<DocumentReference> friendList;
  List<UserPostRecord> postList;
  final Map<String, UsersRecord> users;
  final Map<String, MusicRecord> songs;
  final StreamController<List<UserPostRecord>> _updates =
      StreamController.broadcast(sync: true);

  /// Naujas įrašas srauto viršuje – kaip Firestore klausytojui atėjęs
  /// atnaujintas užklausos rezultatas.
  void publish(UserPostRecord post, MusicRecord song) {
    songs[song.songName] = song;
    postList = [post, ...postList];
    _updates.add(postList);
  }

  static Future<PrebuiltFeedSource> from(FeedData data) async {
    final posts = await queryCollectionOnce(
      data.db.collectionGroup('userPost'),
      UserPostRecord.fromSnapshot,
      queryBuilder: (q) => friendsFeedQuery(q, data.friends, kBenchNow),
    );
    final users = <String, UsersRecord>{
      for (final f in data.friends)
        f.path: UsersRecord.fromSnapshot(await f.get()),
    };
    final music = await data.db.collection('Music').get();
    final songs = <String, MusicRecord>{
      for (final d in music.docs)
        (d.data()['SongName'] as String): MusicRecord.fromSnapshot(d),
    };
    return PrebuiltFeedSource._(data.friends, posts, users, songs);
  }

  @override
  List<DocumentReference> friends() => friendList;
  @override
  Stream<List<UserPostRecord>> todaysPosts(List<DocumentReference> friends) async* {
    yield postList;
    yield* _updates.stream;
  }
  @override
  Stream<UsersRecord> author(DocumentReference user) =>
      Stream.value(users[user.path]!);
  @override
  Stream<List<MusicRecord>> music(String songName) =>
      Stream.value([if (songs[songName] != null) songs[songName]!]);
}

/// assets_audio_player kanalų pakaitalas: skaičiuoja, kiek kartų grotuvas
/// kreipėsi į platformą (open – sukurtas ir paruoštas naujas grotuvas).
class AudioPluginSpy {
  final List<String> calls = [];

  int count(String method) => calls.where((c) => c == method).length;

  /// Kaip įrenginyje: paruošęs garso įrašą, platformos grotuvas atsiunčia
  /// 'player.current' (trukmė). Tik tada FlutterFlowAudioPlayer nupiešia
  /// grojimo mygtuką ir slankiklį (CombineLatest laukia `current`).
  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('assets_audio_player'),
        (call) async {
      calls.add(call.method);
      if (call.method == 'open') {
        final id = (call.arguments as Map)['id'] as String;
        scheduleMicrotask(() => messenger.handlePlatformMessage(
              'assets_audio_player/$id',
              const StandardMethodCodec().encodeMethodCall(
                  const MethodCall('player.current', {'totalDurationMs': 180000})),
              (_) {},
            ));
      }
      return null;
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('assets_audio_player_notification'), (call) async {
      calls.add(call.method);
      return null;
    });
  }
}

/// Telefono ekranas 412 x 915 (kaip Manto testuose).
const Size kPhone = Size(412, 915);

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = Size(kPhone.width * 3, kPhone.height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Tokia pati struktūra kaip HomeWidget: AppBar + SafeArea +
/// SingleChildScrollView + FriendFeed. Kai [source] null – tuščias kūnas, kad
/// matuojant būtų keičiamas tik srautas, o ne visa programa.
///
/// [parentTick] pakeitimas perkuria tėvinį valdiklį su nauju FriendFeed()
/// egzemplioriumi – taip HomeWidget elgiasi, kai AuthUserStreamWidget gauna
/// naują naudotojo dokumento versiją (pvz., pasikeitė streak_count).
Widget feedApp(FeedSource? source, {Key? key, ValueNotifier<int>? parentTick}) {
  Widget body() => source == null
      ? const SizedBox.shrink()
      : SingleChildScrollView(child: FriendFeed(key: key, source: source));
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('MusicReal')),
      body: SafeArea(
        child: parentTick == null
            ? body()
            : ValueListenableBuilder<int>(
                valueListenable: parentTick,
                builder: (_, __, ___) => body(),
              ),
      ),
    ),
  );
}

int countOf(Finder f) => f.evaluate().length;

int playersBuilt() =>
    countOf(find.byType(FlutterFlowAudioPlayer, skipOffstage: false));

int loadersShown() =>
    countOf(find.byType(CircularProgressIndicator, skipOffstage: false));

int authorsShown() =>
    countOf(find.textContaining(RegExp(r'^Friend \d{3}$'), skipOffstage: false));

/// Grotuvai su nupieštu grojimo mygtuku (grotuvas paruoštas naudoti).
int playButtonsShown() =>
    countOf(find.byIcon(Icons.play_circle_fill_rounded, skipOffstage: false));

/// Srautas pilnai parodytas: [n] kortelių su autoriumi ir paruoštu grotuvu
/// (matomas grojimo mygtukas), be įkėlimo indikatorių.
bool feedComplete(int n) =>
    playersBuilt() == n &&
    playButtonsShown() == n &&
    authorsShown() == n &&
    loadersShown() == 0;

/// Kortelių (autoriaus vardų), kurių viršus patenka į ekraną, skaičius.
int cardsOnScreen(WidgetTester tester) {
  final finder = find.textContaining(RegExp(r'^Friend \d{3}$'), skipOffstage: false);
  return finder
      .evaluate()
      .where((e) => tester.getTopLeft(find.byWidget(e.widget)).dy < kPhone.height)
      .length;
}

/// Kortelės, kuriose autorius nesutampa su dainos autoriumi (daina „Song 007-…“
/// priklauso „Friend 007“). Tekstai imami medžio tvarka: autorius, daina.
int mismatchedCards(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text, skipOffstage: false))
      .map((t) => t.data ?? '')
      .where((s) => s.startsWith('Friend ') || s.startsWith('Song '))
      .toList();
  var bad = 0;
  for (var i = 0; i + 1 < texts.length; i++) {
    if (texts[i].startsWith('Friend ') && texts[i + 1].startsWith('Song ')) {
      if (texts[i].substring(7) != texts[i + 1].substring(5, 8)) bad++;
    }
  }
  return bad;
}

double ms(Stopwatch sw) => sw.elapsedMicroseconds / 1000.0;

/// Kadrų laikai iki sąlygos [done]. Sąlygos tikrinimas į laiką neįskaičiuojamas.
class FrameRun {
  final List<double> frameMs = [];
  bool completed = false;

  int get frames => frameMs.length;
  double get totalMs => frameMs.fold(0.0, (a, b) => a + b);
  double get maxFrameMs => frameMs.isEmpty ? 0 : frameMs.reduce(math.max);

  Map<String, Object> toJson() => {
        'totalMs': round2(totalMs),
        'frames': frames,
        'maxFrameMs': round2(maxFrameMs),
        'frameMs': frameMs.map(round2).toList(),
        'completed': completed,
      };
}

Future<FrameRun> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Future<void> Function()? first,
  int maxFrames = 40,
  Duration step = Duration.zero,
}) async {
  final run = FrameRun();
  if (first != null) {
    final sw = Stopwatch()..start();
    await first();
    run.frameMs.add(ms(sw));
  }
  while (!done() && run.frames < maxFrames) {
    final sw = Stopwatch()..start();
    await tester.pump(step);
    run.frameMs.add(ms(sw));
  }
  run.completed = done();
  return run;
}

double round2(num v) => (v * 100).round() / 100;

double median(List<double> xs) {
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

/// „mediana (min–max)“ lietuvišku formatu.
String fmtStats(List<double> xs, {int digits = 1}) {
  String f(double v) => v.toStringAsFixed(digits).replaceAll('.', ',');
  return '${f(median(xs))} ms (${f(xs.reduce(math.min))}–${f(xs.reduce(math.max))})';
}

/// Rezultatų eilutė žurnalui ir JSON failas ld3_arnas_results/raw/.
void report(String id, String scenario, String summary, Map<String, Object?> raw) {
  // ignore: avoid_print
  print('RESULT | $id | $scenario | $summary');
  final dir = Directory('ld3_arnas_results/raw')..createSync(recursive: true);
  final name = '${id}_$scenario'.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  File('${dir.path}/$name.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({'id': id, 'scenario': scenario, 'summary': summary, ...raw}));
}
