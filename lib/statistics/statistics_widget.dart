import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/ui/app_ui.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'statistics_model.dart';
export 'statistics_model.dart';

class StatisticsWidget extends StatefulWidget {
  const StatisticsWidget({super.key});

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

    // Only the signed-in user's own posts: statistics are private to them.
    _lastMonthPosts = currentUserReference == null
        ? Stream.value([])
        : queryUserPostRecord(
            parent: currentUserReference,
            queryBuilder: (userPostRecord) => userPostRecord
                .where(
                  'created_at',
                  isGreaterThanOrEqualTo:
                      getCurrentTimestamp.subtract(Duration(days: 30)),
                )
                .orderBy('created_at', descending: true),
          );
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  List<MapEntry<String, int>> _topSongs(List<UserPostRecord> posts) {
    final counts = <String, int>{};
    for (final post in posts) {
      if (post.songName.isEmpty) continue;
      counts[post.songName] = (counts[post.songName] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  Widget _statCard(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppUi.border(context), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(),
                  letterSpacing: 0.0,
                ),
          ),
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

  Widget _card(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppUi.border(context), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(4.0, 24.0, 0.0, 10.0),
      child: Text(
        title,
        style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
              letterSpacing: 0.0,
            ),
      ),
    );
  }

  Widget _countRow(BuildContext context, String label, int count, int max,
      {bool isImage = false}) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: isImage
                    ? Align(
                        alignment: AlignmentDirectional(-1.0, 0.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: Image.network(
                            label,
                            width: 32.0,
                            height: 32.0,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.emoji_emotions_outlined,
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
              ),
              Text('$count', style: FlutterFlowTheme.of(context).bodyMedium),
            ],
          ),
          SizedBox(height: 6.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: max == 0 ? 0.0 : count / max,
              minHeight: 8.0,
              backgroundColor: FlutterFlowTheme.of(context).alternate,
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(BuildContext context, String text) {
    return Text(text, style: FlutterFlowTheme.of(context).labelMedium);
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
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: Text(
            'Statistics',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 1.0,
        ),
        body: SafeArea(
          top: true,
          child: StreamBuilder<List<UserPostRecord>>(
            stream: _lastMonthPosts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load your statistics.',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                );
              }
              // Customize what your widget looks like when it's loading.
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 50.0,
                    height: 50.0,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FlutterFlowTheme.of(context).primary,
                      ),
                    ),
                  ),
                );
              }
              final posts = snapshot.data!;
              final topSongs = _topSongs(posts);
              final emojis =
                  (functions.countEmojiFrequency(posts) as Map<String, int>)
                      .entries
                      .take(5)
                      .toList();

              return ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Streak',
                          '${valueOrDefault(currentUserDocument?.streakCount, 0)} days',
                        ),
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: _statCard(
                          context,
                          'Posts, last 30 days',
                          '${posts.length}',
                        ),
                      ),
                    ],
                  ),
                  _sectionTitle(context, 'Most posted songs'),
                  _card(context, [
                    if (topSongs.isEmpty)
                      _emptyText(context, 'No posts in the last 30 days.'),
                    ...topSongs.map((entry) => _countRow(
                        context, entry.key, entry.value, topSongs.first.value)),
                  ]),
                  _sectionTitle(context, 'Emotions'),
                  _card(context, [
                    if (emojis.isEmpty)
                      _emptyText(
                          context, 'No emotions shared in the last 30 days.'),
                    ...emojis.map((entry) => _countRow(
                          context,
                          entry.key,
                          entry.value,
                          emojis.first.value,
                          isImage: entry.key.startsWith('http'),
                        )),
                  ]),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 32.0, 0.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () async {
                        context.pushNamed(ProfileWidget.routeName);
                      },
                      text: 'Back',
                      options: FFButtonOptions(
                        height: 40.0,
                        padding: EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 0.0),
                        iconPadding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                        color: FlutterFlowTheme.of(context).error,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  font: GoogleFonts.plusJakartaSans(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
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
