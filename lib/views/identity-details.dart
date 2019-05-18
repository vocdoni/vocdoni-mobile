import "package:flutter/material.dart";
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';

class IdentityDetails extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigation(),
      body: ListView(
        children: <Widget>[
          ListItem(text:"Back up identity", onTap: (){debugPrint("BACK");},),
          ListItem(text:"Log out"),
          ListItem(text:"Test"),
        ],
      ),
    );
  }

  onNavigationTap(BuildContext context, int index) {
    if (index == 0) Navigator.popAndPushNamed(context, "/home");
    if (index == 1) Navigator.popAndPushNamed(context, "/organizations");
    if (index == 2) Navigator.popAndPushNamed(context, "/identityDetails");
  }
}