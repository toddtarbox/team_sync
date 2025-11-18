import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/connection_status_indicator.dart';

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

  return AppBar(
    leading: !automaticallyImplyLeading
        ? GestureDetector(
            onTap: () {},
            child: Image.asset('assets/images/pngs/icon_no_background.png',
                width: 16, height: 16),
          )
        : (showBackButton
            ? null // Let AppBar handle the back button
            : GestureDetector(
                onTap: () {},
                child: Image.asset('assets/images/pngs/icon_no_background.png',
                    width: 16, height: 16),
              )),
    automaticallyImplyLeading: showBackButton,
    title: title,
    actions: combinedActions,
    bottom: bottom,
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
