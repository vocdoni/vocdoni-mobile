import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class BottomNavigation extends StatelessWidget {
  @override
  Widget build(context) {
    return BottomNavigationBar(
      onTap: (index) {
        onNavigationTap(context, index);
      },
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

  onNavigationTap(BuildContext context, int index) {
    Navigator.pop(context);

    if (index == 0) Navigator.pushReplacementNamed(context, "/home");
    if (index == 1) Navigator.pushReplacementNamed(context, "/organizations");
    if (index == 2) Navigator.pushReplacementNamed(context, "/identityDetails");
  }
}
