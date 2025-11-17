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
      bottom: _commonTeamBottomWidget(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: SafeArea(
        child: Container(
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
      ),
    );
  }

  @override
  Size get preferredSize {
    // Include status bar height + toolbar height + optional bottom widget height
    final bottomHeight = bottom?.preferredSize.height ?? 80;
    // The AppBar automatically accounts for status bar padding when used in a Scaffold
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  PreferredSizeWidget? _commonTeamBottomWidget() {
    if (bottom != null) return bottom;

    if (bottom == null && team != null) {
      return PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
              padding: EdgeInsets.all(20),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                team!.logoUrl != null && team!.logoUrl!.isNotEmpty
                    ? CircleAvatar(
                        child: ClipOval(
                          child: Image.network(
                            team!.logoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(team!.fullName[0]);
                            },
                          ),
                        ),
                      )
                    : Container(),
                team!.logoUrl != null ? const SizedBox(width: 10) : Container(),
                Text(team!.fullName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold))
              ])));
    }

    return null;
  }
}
