import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/ui/app_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_model.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.0),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon,
                size: 20.0,
                color: color ?? FlutterFlowTheme.of(context).secondaryText),
            SizedBox(width: AppUi.gap),
            Expanded(
              child: Text(
                label,
                style: color == null
                    ? AppUi.body(context)
                    : AppUi.body(context).copyWith(color: color),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1.0,
        thickness: 1.0,
        color: AppUi.border(context),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<List<UsersRecord>>(
        stream: queryUsersRecord(
          queryBuilder: (usersRecord) => usersRecord.where(
            'email',
            isEqualTo: currentUserEmail,
          ),
          singleRecord: true,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              body: AppUi.loader(context),
            );
          }
          final profileUsersRecord = snapshot.data!.firstOrNull;

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              title: Text(
                'Profile',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppUi.gutter, AppUi.gutter, AppUi.gutter, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identity
                    AppUi.card(
                      context,
                      padding: EdgeInsets.all(AppUi.gutter),
                      child: Column(
                        children: [
                          AppUi.avatar(context, profileUsersRecord?.photoUrl,
                              size: 88.0),
                          SizedBox(height: AppUi.gap),
                          Text(
                            valueOrDefault<String>(
                              profileUsersRecord?.displayName,
                              'No name',
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.w600),
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            valueOrDefault<String>(
                              profileUsersRecord?.email,
                              '',
                            ),
                            textAlign: TextAlign.center,
                            style: AppUi.muted(context),
                          ),
                          SizedBox(height: AppUi.gutter),
                          AuthUserStreamWidget(
                            builder: (context) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🔥', style: TextStyle(fontSize: 16.0)),
                                  SizedBox(width: 8.0),
                                  Text(
                                    '${valueOrDefault(currentUserDocument?.streakCount, 0)} day streak',
                                    style: AppUi.title(context, size: 15.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppUi.sectionTitle(context, 'Account'),
                    AppUi.card(
                      context,
                      padding: EdgeInsets.symmetric(horizontal: AppUi.gap),
                      child: Column(
                        children: [
                          _row(
                            context,
                            icon: Icons.bar_chart_rounded,
                            label: 'Statistics',
                            onTap: () =>
                                context.pushNamed(StatisticsWidget.routeName),
                          ),
                          _divider(context),
                          _row(
                            context,
                            icon: Icons.group_outlined,
                            label: 'Friends',
                            onTap: () =>
                                context.pushNamed(FriendsListWidget.routeName),
                          ),
                          _divider(context),
                          _row(
                            context,
                            icon: isDark
                                ? Icons.wb_sunny_rounded
                                : Icons.nights_stay,
                            label: isDark
                                ? 'Switch to light mode'
                                : 'Switch to dark mode',
                            onTap: () => setDarkModeSetting(context,
                                isDark ? ThemeMode.light : ThemeMode.dark),
                            trailing: SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    AppUi.sectionTitle(context, 'Session'),
                    SizedBox(
                      width: double.infinity,
                      child: FFButtonWidget(
                        onPressed: () async {
                          GoRouter.of(context).prepareAuthEvent();
                          await authManager.signOut();
                          GoRouter.of(context).clearRedirectLocation();

                          context.goNamedAuth(
                              LogInPageWidget.routeName, context.mounted);
                        },
                        text: 'Log out',
                        options: AppUi.quietButton(context),
                      ),
                    ),
                    SizedBox(height: AppUi.gap),
                    SizedBox(
                      width: double.infinity,
                      child: FFButtonWidget(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text('Delete your account?'),
                              content: Text(
                                  'Your profile, posts and friend links are removed permanently. This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                        color:
                                            FlutterFlowTheme.of(context).error),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }

                          // The onUserDeleted Cloud Function removes the
                          // profile, posts and friend links.
                          await authManager.deleteUser(context);
                          if (FirebaseAuth.instance.currentUser != null) {
                            return;
                          }

                          context.goNamed(LogInPageWidget.routeName);
                        },
                        text: 'Delete account',
                        options: AppUi.quietButton(
                          context,
                          textColor: FlutterFlowTheme.of(context).error,
                        ),
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
