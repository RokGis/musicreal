import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:text_search/text_search.dart';
import 'friends_list_add_friend_model.dart';
export 'friends_list_add_friend_model.dart';

/// Search for other people and send them a friend request.
class FriendsListAddFriendWidget extends StatefulWidget {
  const FriendsListAddFriendWidget({super.key});

  static String routeName = 'FriendsListAddFriend';
  static String routePath = '/friendsListAddFriend';

  @override
  State<FriendsListAddFriendWidget> createState() =>
      _FriendsListAddFriendWidgetState();
}

class _FriendsListAddFriendWidgetState
    extends State<FriendsListAddFriendWidget> {
  late FriendsListAddFriendModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FriendsListAddFriendModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _avatar(BuildContext context, UsersRecord user) {
    return Container(
      width: 48.0,
      height: 48.0,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).alternate,
        shape: BoxShape.circle,
      ),
      child: user.photoUrl.isNotEmpty
          ? Image.network(
              user.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            )
          : Icon(
              Icons.person,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
    );
  }

  Widget _placeholder(
      BuildContext context, IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(32.0, 64.0, 32.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.0, color: FlutterFlowTheme.of(context).alternate),
          SizedBox(height: 12.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  letterSpacing: 0.0,
                ),
          ),
          SizedBox(height: 4.0),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(),
                  letterSpacing: 0.0,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context, UsersRecord user) async {
    final target = user.reference;
    if (target == currentUserReference) {
      _showMessage(context, 'You cannot add yourself.');
      return;
    }
    if ((currentUserDocument?.friends.toList() ?? []).contains(target)) {
      _showMessage(context, 'Already in your friends list.');
      return;
    }
    final alreadySent = await queryFriendRequestsRecordOnce(
      queryBuilder: (friendRequestsRecord) => friendRequestsRecord
          .where('sender', isEqualTo: currentUserReference)
          .where('receiver', isEqualTo: target)
          .where('status', isEqualTo: 'pending'),
    );
    if (alreadySent.isNotEmpty) {
      _showMessage(context, 'Friend request already sent.');
      return;
    }
    final alreadyReceived = await queryFriendRequestsRecordOnce(
      queryBuilder: (friendRequestsRecord) => friendRequestsRecord
          .where('sender', isEqualTo: target)
          .where('receiver', isEqualTo: currentUserReference)
          .where('status', isEqualTo: 'pending'),
    );
    if (alreadyReceived.isNotEmpty) {
      _showMessage(context, 'This user already sent you a request.');
      return;
    }

    await FriendRequestsRecord.collection.doc().set(
          createFriendRequestsRecordData(
            sender: currentUserReference,
            receiver: target,
            status: 'pending',
            createdAt: getCurrentTimestamp,
          ),
        );
    _showMessage(context, 'Friend request sent.');
  }

  Widget _resultTile(BuildContext context, UsersRecord user) {
    final isFriend =
        (currentUserDocument?.friends.toList() ?? []).contains(user.reference);

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Color(0xFFEDE8DF), width: 1.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              _avatar(context, user),
              SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  user.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).titleSmall.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        fontSize: 16.0,
                        letterSpacing: 0.0,
                      ),
                ),
              ),
              SizedBox(width: 8.0),
              if (isFriend)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                  child: Text(
                    'Friends',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(),
                          letterSpacing: 0.0,
                        ),
                  ),
                )
              else
                FFButtonWidget(
                  onPressed: () => _sendRequest(context, user),
                  text: 'Add',
                  options: FFButtonOptions(
                    height: 36.0,
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    iconPadding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context)
                        .labelMedium
                        .override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          color: Colors.white,
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                        ),
                    elevation: 0.0,
                    borderSide: BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) => StreamBuilder<List<UsersRecord>>(
        stream: queryUsersRecord(
          queryBuilder: (usersRecord) => usersRecord.where(
            'display_name',
            isNotEqualTo: currentUserDisplayName,
          ),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              body: Center(
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              ),
            );
          }
          final allUsers = snapshot.data!;
          final query = _model.textController2.text.trim();
          final results = _model.simpleSearchResults.toList();

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              appBar: AppBar(
                backgroundColor:
                    FlutterFlowTheme.of(context).secondaryBackground,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
                  onPressed: () =>
                      context.pushNamed(FriendsListWidget.routeName),
                ),
                title: Text(
                  'Add friend',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                        font:
                            GoogleFonts.readexPro(fontWeight: FontWeight.bold),
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
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 12.0, 16.0, 12.0),
                      child: TextFormField(
                        controller: _model.textController2,
                        focusNode: _model.textFieldFocusNode2,
                        onChanged: (_) => EasyDebounce.debounce(
                          '_model.textController2',
                          Duration(milliseconds: 500),
                          () async {
                            safeSetState(() {
                              _model.simpleSearchResults = TextSearch(
                                allUsers
                                    .map(
                                      (record) => TextSearchItem.fromTerms(
                                          record, [record.displayName]),
                                    )
                                    .toList(),
                              )
                                  .search(_model.textController2.text)
                                  .map((r) => r.object)
                                  .toList();
                            });
                          },
                        ),
                        autofocus: false,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: 'Search people by name...',
                          hintStyle:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(),
                                    color: Color(0xFF57636C),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFFEDE8DF), width: 1.0),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFF507583), width: 1.0),
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          contentPadding: EdgeInsetsDirectional.fromSTEB(
                              20.0, 12.0, 20.0, 12.0),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF57636C),
                            size: 20.0,
                          ),
                        ),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(),
                              fontSize: 14.0,
                              letterSpacing: 0.0,
                            ),
                        validator: _model.textController2Validator
                            .asValidator(context),
                      ),
                    ),
                    Expanded(
                      child: query.isEmpty
                          ? _placeholder(
                              context,
                              Icons.person_search_rounded,
                              'Find people to add',
                              'Type a name to search for other users.',
                            )
                          : results.isEmpty
                              ? _placeholder(
                                  context,
                                  Icons.search_off_rounded,
                                  'No one found',
                                  'No user matches "$query".',
                                )
                              : ListView.builder(
                                  padding:
                                      EdgeInsets.only(top: 4.0, bottom: 16.0),
                                  itemCount: results.length,
                                  itemBuilder: (context, index) =>
                                      _resultTile(context, results[index]),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
