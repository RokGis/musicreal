import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'profile_widget.dart' show ProfileWidget;
import 'package:flutter/material.dart';

class ProfileModel extends FlutterFlowModel<ProfileWidget> {
  ///  State fields for stateful widgets in this page.

  final shortcutsFocusNode = FocusNode();

  @override
  void initState(BuildContext context) {
    shortcutsFocusNode.requestFocus();
  }

  @override
  void dispose() {}
}
