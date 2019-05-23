import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class TopNavigation extends StatelessWidget with PreferredSizeWidget {
  final String title;
  final bool showBackButton; 

  TopNavigation({this.title, this.showBackButton = true});

  @override
  Widget build(context) {
    return AppBar(
      backgroundColor: baseBackgroundColor,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(color: descriptionColor, fontWeight: lightFontWeight),
      ),
      centerTitle: true,
      leading: showBackButton
          ? InkWell(
              onTap: () => Navigator.pop(context),
              child: Icon(FeatherIcons.arrowLeft, color: descriptionColor,))
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
