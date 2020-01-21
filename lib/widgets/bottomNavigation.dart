import "package:flutter/material.dart";
// import 'package:vocdoni/constants/colors.dart';
// import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedTab;
  final Function onTabSelect;

  BottomNavigation({this.selectedTab, this.onTabSelect});

  @override
  Widget build(context) {
    return BottomNavigationBar(
      onTap: (index) {
        if (onTabSelect is Function) onTabSelect(index);
      },
      currentIndex: selectedTab,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.home),
          title: Text(''),
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.award),
          title: Text(''),
        ),
        BottomNavigationBarItem(
          icon: Icon(FeatherIcons.user),
          title: Text(''),
        ),
      ],
    );
  }
}
