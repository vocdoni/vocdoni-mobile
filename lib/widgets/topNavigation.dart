import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class TopNavigation extends StatelessWidget with PreferredSizeWidget{
  final String title;

  TopNavigation({this.title});

  @override
  Widget build(context) {
    return AppBar(
      backgroundColor: baseBackgroundColor,
      elevation: 0,
      title: Text(title,style: TextStyle(color: guideColor),),
    
      centerTitle: true,
      leading:  Navigator.canPop(context) ? InkWell(
          onTap: () => Navigator.pop(context),
          child: Icon(FeatherIcons.arrowLeft)):null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
