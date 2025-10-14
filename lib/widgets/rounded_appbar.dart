import 'package:flutter/material.dart';

class RoundedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const RoundedAppBar(
      {super.key, required this.title, this.bottom, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: AppBar(
        title: title,
        actions: actions,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        elevation: 20,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(125);
}
