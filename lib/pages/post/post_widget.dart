import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/components/music_search_sheet_widget.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/ui/app_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'post_model.dart';
export 'post_model.dart';

/// The three emotions a post can carry.
const List<String> kEmotions = [
  'https://static.vecteezy.com/system/resources/thumbnails/059/420/483/small/cool-smiley-face-with-sunglasses-giving-thumbs-up-png.png',
  'https://static.vecteezy.com/system/resources/thumbnails/059/420/444/small/laughing-emoji-with-joyful-expression-and-tears-png.png',
  'https://png.pngtree.com/png-vector/20241102/ourmid/pngtree-crying-sad-emoji-png-image_14216691.png',
];

class PostWidget extends StatefulWidget {
  const PostWidget({super.key});

  static String routeName = 'post';
  static String routePath = '/post';

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late PostModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PostModel());

    _model.emojiTextController ??= TextEditingController();
    _model.emojiFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  String get _selectedEmotion => _model.emojiTextController.text.trim();

  Widget _emotionChoice(BuildContext context, String url) {
    final isSelected = _selectedEmotion == url;
    return InkWell(
      borderRadius: BorderRadius.circular(14.0),
      onTap: () => safeSetState(() {
        _model.emojiTextController?.text = url;
      }),
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).accent1
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : AppUi.border(context),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: AppUi.squareImage(
          context,
          url,
          size: 56.0,
          fallback: Icons.emoji_emotions_outlined,
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final song = FFAppState().CurrentlySelectedSongPost;
    final emoji = _selectedEmotion;

    if (song == '') {
      _showMessage(context, 'Pick a song before posting.');
      return;
    }
    // The emotion buttons store an image URL, not a character.
    if (emoji.isEmpty || !emoji.startsWith('http') || emoji.length > 500) {
      _showMessage(context, 'Pick an emotion before posting.');
      return;
    }

    await UserPostRecord.createDoc(currentUserReference!).set(
      createUserPostRecordData(
        songName: song,
        createdAt: getCurrentTimestamp,
        postUser: currentUserReference,
        emoji: emoji,
      ),
    );

    _model.userData = await queryUsersRecordOnce(
      queryBuilder: (usersRecord) => usersRecord.where(
        'uid',
        isEqualTo: currentUserUid,
      ),
      singleRecord: true,
    ).then((s) => s.firstOrNull);

    final today = functions.startOfDay(getCurrentTimestamp);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final lastPostDay = _model.userData?.lastPostDate == null
        ? null
        : functions.startOfDay(_model.userData!.lastPostDate!);

    if (lastPostDay == null || lastPostDay.isBefore(yesterday)) {
      // First post, or a day was missed: start again.
      await currentUserReference!.update(createUsersRecordData(
        streakCount: 1,
        lastPostDate: getCurrentTimestamp,
      ));
    } else if (lastPostDay.isBefore(today)) {
      // Posted yesterday: the streak carries on.
      await currentUserReference!.update({
        ...createUsersRecordData(lastPostDate: getCurrentTimestamp),
        ...mapToFirestore({'streak_count': FieldValue.increment(1)}),
      });
    } else {
      // Already posted today: the streak stays as it is.
      await currentUserReference!.update(createUsersRecordData(
        lastPostDate: getCurrentTimestamp,
      ));
    }

    context.pushNamed(HomeWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final song = FFAppState().CurrentlySelectedSongPost;
    final emoji = _selectedEmotion;

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
            onPressed: () => context.pushNamed(HomeWidget.routeName),
          ),
          title: Text(
            'New post',
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
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                AppUi.gutter, 0.0, AppUi.gutter, AppUi.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppUi.sectionTitle(context, '1. Choose a song'),
                Expanded(
                  child: AppUi.card(
                    context,
                    padding: EdgeInsets.all(4.0),
                    child: wrapWithModel(
                      model: _model.musicSearchSheetModel,
                      updateCallback: () => safeSetState(() {}),
                      child: MusicSearchSheetWidget(),
                    ),
                  ),
                ),
                AppUi.sectionTitle(context, '2. How do you feel?'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: kEmotions
                      .map((url) => _emotionChoice(context, url))
                      .toList(),
                ),
                SizedBox(height: AppUi.gap),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppUi.gap),
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppUi.border(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        song == ''
                            ? Icons.music_off_outlined
                            : Icons.music_note,
                        size: 18.0,
                        color: song == ''
                            ? FlutterFlowTheme.of(context).secondaryText
                            : FlutterFlowTheme.of(context).primary,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          song == '' ? 'No song chosen yet' : song,
                          overflow: TextOverflow.ellipsis,
                          style: song == ''
                              ? AppUi.muted(context)
                              : AppUi.body(context),
                        ),
                      ),
                      if (emoji.startsWith('http')) ...[
                        SizedBox(width: 8.0),
                        AppUi.squareImage(
                          context,
                          emoji,
                          size: 28.0,
                          fallback: Icons.emoji_emotions_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppUi.gap),
                SizedBox(
                  width: double.infinity,
                  child: FFButtonWidget(
                    onPressed: () => _submit(context),
                    text: 'Post',
                    options: AppUi.primaryButton(context, height: 48.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
}
