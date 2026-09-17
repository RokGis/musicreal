import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Shared building blocks, so every screen uses the same card, spacing,
/// type scale and empty state instead of its own hand-tuned pixels.
class AppUi {
  static const double gutter = 16.0;
  static const double gap = 12.0;
  static const double radius = 16.0;

  static Color border(BuildContext context) =>
      FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.6);

  static BoxDecoration cardDecoration(BuildContext context) => BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border(context), width: 1.0),
      );

  static Widget card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(gap),
    VoidCallback? onTap,
  }) {
    final content = Container(
      width: double.infinity,
      decoration: cardDecoration(context),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: content,
    );
  }

  static Widget sectionTitle(BuildContext context, String title) => Padding(
        padding: EdgeInsetsDirectional.fromSTEB(4.0, 24.0, 0.0, 10.0),
        child: Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                font: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                letterSpacing: 0.0,
              ),
        ),
      );

  static TextStyle title(BuildContext context, {double size = 16.0}) =>
      FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
            fontSize: size,
            letterSpacing: 0.0,
          );

  static TextStyle body(BuildContext context) =>
      FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.inter(),
            letterSpacing: 0.0,
          );

  static TextStyle muted(BuildContext context) =>
      FlutterFlowTheme.of(context).labelMedium.override(
            font: GoogleFonts.inter(),
            color: FlutterFlowTheme.of(context).secondaryText,
            letterSpacing: 0.0,
          );

  static Widget avatar(BuildContext context, String? photoUrl,
      {double size = 48.0}) {
    final url = photoUrl ?? '';
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).alternate,
        shape: BoxShape.circle,
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person,
                size: size * 0.55,
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            )
          : Icon(
              Icons.person,
              size: size * 0.55,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
    );
  }

  /// Square image that never gets stretched, with a fallback icon.
  static Widget squareImage(BuildContext context, String url,
      {double size = 48.0, IconData fallback = Icons.image_outlined}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          fallback,
          size: size * 0.7,
          color: FlutterFlowTheme.of(context).secondaryText,
        ),
      ),
    );
  }

  static Widget emptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(32.0, 56.0, 32.0, 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.0, color: FlutterFlowTheme.of(context).alternate),
          SizedBox(height: gap),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppUi.title(context),
          ),
          SizedBox(height: 4.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppUi.muted(context),
          ),
          if (action != null) ...[
            SizedBox(height: gap + 4.0),
            action,
          ],
        ],
      ),
    );
  }

  static Widget loader(BuildContext context, {double size = 40.0}) => Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              FlutterFlowTheme.of(context).primary,
            ),
          ),
        ),
      );

  static FFButtonOptions primaryButton(BuildContext context,
      {double height = 44.0}) {
    return FFButtonOptions(
      height: height,
      padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
      iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
      color: FlutterFlowTheme.of(context).primary,
      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 15.0,
            letterSpacing: 0.0,
          ),
      elevation: 0.0,
      borderSide: BorderSide(color: Colors.transparent),
      borderRadius: BorderRadius.circular(12.0),
    );
  }

  static FFButtonOptions quietButton(BuildContext context,
      {double height = 44.0, Color? textColor}) {
    return FFButtonOptions(
      height: height,
      padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
      iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
      color: FlutterFlowTheme.of(context).secondaryBackground,
      textStyle: FlutterFlowTheme.of(context).titleSmall.override(
            font: GoogleFonts.inter(fontWeight: FontWeight.w600),
            color: textColor ?? FlutterFlowTheme.of(context).primaryText,
            fontSize: 15.0,
            letterSpacing: 0.0,
          ),
      elevation: 0.0,
      borderSide: BorderSide(color: border(context), width: 1.0),
      borderRadius: BorderRadius.circular(12.0),
    );
  }
}
