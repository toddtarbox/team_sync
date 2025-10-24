import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final Team? team;

  const CustomAppBar(
      {super.key, required this.title, this.bottom, this.actions, this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: AppBar(
        leading: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Navigator.of(context).canPop()
                ? const Icon(Icons.arrow_back)
                : Image.asset('assets/images/pngs/icon_no_background.png',
                    width: 16, height: 16)),
        title: title,
        actions: actions,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(125);
}
