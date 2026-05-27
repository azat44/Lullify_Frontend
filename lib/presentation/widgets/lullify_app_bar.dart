import 'package:flutter/material.dart';

class LullifyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LullifyAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    );
  }
}
