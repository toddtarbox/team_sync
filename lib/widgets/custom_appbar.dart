import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/connection_status_indicator.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Team? team;

  const CustomAppBar(
      {super.key, required this.title, this.bottom, this.actions, this.team});

  @override
  Widget build(BuildContext context) {
    final combinedActions = <Widget>[
      const ConnectionStatusIndicator(),
      // include any extra actions the caller provided
      if (actions != null) ...actions!,
    ];

    // On web, don't show back button - use browser navigation instead
    final showBackButton = !kIsWeb && Navigator.of(context).canPop();

    return AppBar(
      key: ValueKey('appbar_${team?.id}'), // Force AppBar rebuild
      leading: GestureDetector(
          onTap: () {
            // Only allow back navigation on mobile (not web)
            if (!kIsWeb && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: showBackButton
              ? const Icon(Icons.arrow_back)
              : Image.asset('assets/images/pngs/icon_no_background.png',
                  width: 16, height: 16)),
      title: title,
      actions: combinedActions,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              team?.color1 ?? Theme.of(context).primaryColor,
              team?.color2 ?? Theme.of(context).primaryColorDark,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    // Base AppBar height is 56
    // If we have a bottom widget, add its height
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }
}
