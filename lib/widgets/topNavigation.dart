import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class TopNavigation extends StatelessWidget with PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final void Function() onBackButton;

  TopNavigation({this.title, this.showBackButton = true, this.onBackButton});

  @override
  Widget build(context) {
    return AppBar(
      backgroundColor: baseBackgroundColor,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(color: descriptionColor, fontWeight: lightFontWeight),
      ),
      brightness: Brightness.light, // or use Brightness.dark
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? InkWell(
              onTap: () {
                onBackButton == null ? Navigator.pop(context) : onBackButton();
              },
              child: Icon(
                FeatherIcons.arrowLeft,
                color: descriptionColor,
              ))
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
