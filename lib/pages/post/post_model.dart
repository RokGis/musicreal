import '/backend/backend.dart';
import '/components/music_search_sheet_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'post_widget.dart' show PostWidget;
import 'package:flutter/material.dart';

class PostModel extends FlutterFlowModel<PostWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MusicSearchSheet component.
  late MusicSearchSheetModel musicSearchSheetModel;
  // State field(s) for Emoji widget.
  FocusNode? emojiFocusNode;
  TextEditingController? emojiTextController;
  String? Function(BuildContext, String?)? emojiTextControllerValidator;
  // Stores action output result for [Firestore Query - Query a collection] action in Upload widget.
  UsersRecord? userData;

  @override
  void initState(BuildContext context) {
    musicSearchSheetModel = createModel(context, () => MusicSearchSheetModel());
  }

  @override
  void dispose() {
    musicSearchSheetModel.dispose();
    emojiFocusNode?.dispose();
    emojiTextController?.dispose();
  }
}
