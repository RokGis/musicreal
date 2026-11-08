import 'file:///C:/Users/pedse/Downloads/musicreal/test/ld2_statistics_check/coverage_probe.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/demo/demo_data.dart';
import '/index.dart';
import '/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'statistics_model.dart';
export 'statistics_model.dart';

/// One row of the 30-day chart: a song, how often it was posted, and the
/// emotion most often attached to it (SCRUM-48).
class SongStat {
  SongStat(this.songName, this.count, this.topEmoji);

  final String songName;
  final int count;
  final String topEmoji;
}

/// The user's own posts of the last 30 days, newest first: statistics are
/// private to their owner (SCRUM-44).
Stream<List<UserPostRecord>> lastThirtyDaysPosts(
  DocumentReference? user,
  DateTime now,
) =>
    user == null
        ? Stream.value(<UserPostRecord>[])
        : queryUserPostRecord(
            parent: user,
            queryBuilder: (userPostRecord) => userPostRecord
                .where(
                  'created_at',
                  isGreaterThanOrEqualTo: now.subtract(Duration(days: 30)),
                )
                .orderBy('created_at', descending: true),
          );

class StatisticsWidget extends StatefulWidget {
  const StatisticsWidget({super.key, this.posts});

  /// Replaces the Firestore query; for widget tests.
  @visibleForTesting
  final Stream<List<UserPostRecord>>? posts;

  static String routeName = 'Statistics';
  static String routePath = '/statistics';

  @override
  State<StatisticsWidget> createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  late StatisticsModel _model;
  late Stream<List<UserPostRecord>> _lastMonthPosts;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StatisticsModel());

    // Recalculated every time the screen opens, over the user's own posts
    // only: statistics are private to their owner (SCRUM-44).
    _lastMonthPosts = widget.posts ??
        (kDemoMode
            ? Stream.value(DemoData.myLastMonth)
            : lastThirtyDaysPosts(currentUserReference, getCurrentTimestamp));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// TOP-10 songs of the last 30 days, each with its most frequent emotion.
  List<SongStat> _topSongs(List<UserPostRecord> posts) {
    StatisticsProbe.statement('_topSongs:statement:84:5'); final counts = <String, int>{};
    StatisticsProbe.statement('_topSongs:statement:85:5'); final emojiPerSong = <String, Map<String, int>>{};

    StatisticsProbe.statement('_topSongs:statement:87:5'); for (final post in StatisticsProbe.iterations('_topSongs:loop-decision:87:24', (posts))) {
      StatisticsProbe.statement('_topSongs:statement:88:7'); final song = post.songName;
      StatisticsProbe.statement('_topSongs:statement:89:7'); if (StatisticsProbe.condition('_topSongs:decision:89:11', (song.isEmpty))) { StatisticsProbe.statement('_topSongs:statement:89:25'); continue; }
      StatisticsProbe.statement('_topSongs:statement:90:7'); counts[song] = (counts[song] ?? 0) + 1;
      StatisticsProbe.statement('_topSongs:statement:91:7'); if (StatisticsProbe.condition('_topSongs:decision:91:11', (post.emoji.isNotEmpty))) {
        StatisticsProbe.statement('_topSongs:statement:92:9'); final forSong = emojiPerSong.putIfAbsent(song, () => <String, int>{});
        StatisticsProbe.statement('_topSongs:statement:93:9'); forSong[post.emoji] = (forSong[post.emoji] ?? 0) + 1;
      }
    }

    StatisticsProbe.statement('_topSongs:statement:97:5'); final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    StatisticsProbe.statement('_topSongs:statement:100:5'); return ranked.take(10).map((entry) {
      StatisticsProbe.statement('_topSongs:statement:101:7'); final emojis = emojiPerSong[entry.key];
      StatisticsProbe.statement('_topSongs:statement:102:7'); var topEmoji = '';
      StatisticsProbe.statement('_topSongs:statement:103:7'); var best = 0;
      StatisticsProbe.statement('_topSongs:statement:104:7'); emojis?.forEach((emoji, count) {
        StatisticsProbe.statement('_topSongs:statement:105:9'); if (StatisticsProbe.condition('_topSongs:decision:105:13', (count > best))) {
          StatisticsProbe.statement('_topSongs:statement:106:11'); best = count;
          StatisticsProbe.statement('_topSongs:statement:107:11'); topEmoji = emoji;
        }
      });
      StatisticsProbe.statement('_topSongs:statement:110:7'); return SongStat(entry.key, entry.value, topEmoji);
    }).toList();
  }

  Map<String, int> _emotionTotals(List<UserPostRecord> posts) {
    StatisticsProbe.statement('_emotionTotals:statement:115:5'); final counts = <String, int>{};
    StatisticsProbe.statement('_emotionTotals:statement:116:5'); for (final post in StatisticsProbe.iterations('_emotionTotals:loop-decision:116:24', (posts))) {
      StatisticsProbe.statement('_emotionTotals:statement:117:7'); if (StatisticsProbe.condition('_emotionTotals:decision:117:11', (post.emoji.isEmpty))) { StatisticsProbe.statement('_emotionTotals:statement:117:31'); continue; }
      StatisticsProbe.statement('_emotionTotals:statement:118:7'); counts[post.emoji] = (counts[post.emoji] ?? 0) + 1;
    }
    StatisticsProbe.statement('_emotionTotals:statement:120:5'); final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    StatisticsProbe.statement('_emotionTotals:statement:122:5'); return Map.fromEntries(sorted);
  }

  Widget _statCard(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.all(AppUi.gutter),
      decoration: AppUi.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppUi.muted(context)),
          SizedBox(height: 6.0),
          Text(
            value,
            style: FlutterFlowTheme.of(context).headlineSmall.override(
                  font: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                  color: FlutterFlowTheme.of(context).primary,
                  letterSpacing: 0.0,
                ),
          ),
        ],
      ),
    );
  }

  /// A horizontal bar: the song's share of the most-posted song.
  Widget _chartRow(BuildContext context, int rank, SongStat stat, int max) {
    final fraction = max == 0 ? 0.0 : stat.count / max;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22.0,
            child: Text('$rank.', style: AppUi.muted(context)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.songName,
                        overflow: TextOverflow.ellipsis,
                        style: AppUi.body(context),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Text('${stat.count}',
                        style: AppUi.title(context, size: 14.0)),
                  ],
                ),
                SizedBox(height: 6.0),
                LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        height: 10.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).alternate,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      Container(
                        height: 10.0,
                        width: constraints.maxWidth * fraction,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppUi.gap),
          // The emotion most often attached to this song.
          stat.topEmoji.isEmpty
              ? SizedBox(width: 32.0)
              : AppUi.squareImage(
                  context,
                  stat.topEmoji,
                  size: 32.0,
                  fallback: Icons.emoji_emotions_outlined,
                ),
        ],
      ),
    );
  }

  Widget _emotionRow(
      BuildContext context, String emoji, int count, int max, int total) {
    final fraction = max == 0 ? 0.0 : count / max;
    final percent = total == 0 ? 0 : (count * 100 / total).round();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
      child: Row(
        children: [
          AppUi.squareImage(
            context,
            emoji,
            size: 32.0,
            fallback: Icons.emoji_emotions_outlined,
          ),
          SizedBox(width: AppUi.gap),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Container(
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  Container(
                    height: 10.0,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondary,
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: AppUi.gap),
          Text('$count ($percent%)', style: AppUi.muted(context)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            onPressed: () => context.pushNamed(ProfileWidget.routeName),
          ),
          title: Text(
            'Statistics',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<UserPostRecord>>(
            stream: _lastMonthPosts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AppUi.emptyState(
                  context,
                  icon: Icons.error_outline,
                  title: 'Could not load your statistics',
                  message: 'Check your connection and try again.',
                );
              }
              if (!snapshot.hasData) {
                return AppUi.loader(context);
              }
              final posts = snapshot.data!;
              final topSongs = _topSongs(posts);
              final emotions = _emotionTotals(posts);
              final emotionMax = emotions.isEmpty ? 0 : emotions.values.first;

              if (posts.isEmpty) {
                return AppUi.emptyState(
                  context,
                  icon: Icons.insights_outlined,
                  title: 'Nothing to show yet',
                  message:
                      'Post a song with an emotion and your last 30 days appear here.',
                );
              }

              return ListView(
                padding: EdgeInsets.fromLTRB(
                    AppUi.gutter, AppUi.gutter, AppUi.gutter, 32.0),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Streak',
                          '${kDemoMode ? DemoData.me.streakCount : valueOrDefault(currentUserDocument?.streakCount, 0)} days',
                        ),
                      ),
                      SizedBox(width: AppUi.gap),
                      Expanded(
                        child: _statCard(
                          context,
                          'Posts, last 30 days',
                          '${posts.length}',
                        ),
                      ),
                    ],
                  ),
                  AppUi.sectionTitle(context, 'Top 10 songs, last 30 days'),
                  AppUi.card(
                    context,
                    padding: EdgeInsets.all(AppUi.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Each bar shows how often you posted the song, with the emotion you attached to it most.',
                          style: AppUi.muted(context),
                        ),
                        SizedBox(height: 4.0),
                        ...topSongs.asMap().entries.map(
                              (entry) => _chartRow(
                                context,
                                entry.key + 1,
                                entry.value,
                                topSongs.first.count,
                              ),
                            ),
                      ],
                    ),
                  ),
                  AppUi.sectionTitle(context, 'Emotions, last 30 days'),
                  AppUi.card(
                    context,
                    padding: EdgeInsets.all(AppUi.gutter),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: emotions.isEmpty
                          ? [
                              Text(
                                'No emotions shared in the last 30 days.',
                                style: AppUi.muted(context),
                              )
                            ]
                          : emotions.entries
                              .map((entry) => _emotionRow(
                                    context,
                                    entry.key,
                                    entry.value,
                                    emotionMax,
                                    posts.length,
                                  ))
                              .toList(),
                    ),
                  ),
                  SizedBox(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: FFButtonWidget(
                      onPressed: () async {
                        context.pushNamed(ProfileWidget.routeName);
                      },
                      text: 'Back to profile',
                      options: AppUi.quietButton(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
