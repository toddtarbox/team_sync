import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const CustomAppBar(
      {super.key, required this.title, this.bottom, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: AppBar(
        leading: GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Navigator.of(context).canPop()
                ? const Icon(Icons.arrow_back, color: Colors.white70)
                : Image.asset('assets/images/pngs/icon_no_background.png',
                    width: 16, height: 16)),
        title: title,
        actions: actions,
        bottom: bottom,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(125);
}
