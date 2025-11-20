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

  Future<void> goToWebSite() async {
    if (kIsWeb) {
      final uri = Uri.parse('https://sites.google.com/view/team-sync/home');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  return AppBar(
    leading: !automaticallyImplyLeading
        ? InkWell(
            onTap: () {
              goToWebSite();
            },
            child: Image.asset('assets/images/pngs/icon_no_background.png',
                width: 16, height: 16),
          )
        : (showBackButton
            ? null // Let AppBar handle the back button
            : InkWell(
                onTap: () {
                  goToWebSite();
                },
                child: Image.asset('assets/images/pngs/icon_no_background.png',
                    width: 16, height: 16),
              )),
    automaticallyImplyLeading: showBackButton,
    title: !showBackButton
        ? InkWell(
            onTap: () {
              goToWebSite();
            },
            child: title,
          )
        : title,
    actions: combinedActions,
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
