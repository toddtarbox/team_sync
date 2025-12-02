import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/connection_status_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper function to create a standard AppBar with connection status indicator.
/// Use this throughout the app for consistent AppBar styling.
/// Optionally provide a team to apply gradient colors to the AppBar.
AppBar buildStandardAppBar({
  required BuildContext context,
  required Widget title,
  Team? team,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
  bool automaticallyImplyLeading = true,
}) {
  final combinedActions = <Widget>[
    const ConnectionStatusIndicator(),
    if (actions != null) ...actions,
  ];

  // On web, don't show back button - use browser navigation instead
  final showBackButton = !kIsWeb && Navigator.of(context).canPop();

  Future<void> launchPrivacyPolicy() async {
    final uri = Uri.parse('https://sites.google.com/view/team-sync/home');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  // Determine the leading widget
  Widget? leadingWidget;
  bool implicitLeading = false;

  if (!automaticallyImplyLeading) {
    // Custom icon without auto back button
    leadingWidget = InkWell(
      onTap: launchPrivacyPolicy,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/pngs/icon_no_background.png',
            width: 16, height: 16),
      ),
    );
  } else if (showBackButton) {
    // Let AppBar handle the back button
    leadingWidget = null;
    implicitLeading = true;
  } else {
    // Custom icon when no back button is needed
    leadingWidget = InkWell(
      onTap: launchPrivacyPolicy,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/pngs/icon_no_background.png',
            width: 16, height: 16),
      ),
    );
  }

  return AppBar(
    leading: leadingWidget,
    automaticallyImplyLeading: implicitLeading,
    title: !showBackButton
        ? InkWell(
            onTap: launchPrivacyPolicy,
            child: title,
          )
        : title,
    actions: combinedActions.isNotEmpty ? combinedActions : null,
    bottom: bottom,
    // Set icon and title colors to white when using gradient, otherwise use theme defaults
    iconTheme: team != null ? const IconThemeData(color: Colors.white) : null,
    actionsIconTheme:
        team != null ? const IconThemeData(color: Colors.white) : null,
    titleTextStyle: team != null
        ? const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          )
        : null,
    flexibleSpace: team != null
        ? Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [team.color1, team.color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          )
        : null,
  );
}
