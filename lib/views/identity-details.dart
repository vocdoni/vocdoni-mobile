import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import '../lang/index.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';

class IdentityDetails extends StatelessWidget {
  @override
  Widget build(context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigation()
    );
  }

  onNavigationTap(BuildContext context, int index) {
    if (index == 0) Navigator.popAndPushNamed(context, "/home");
    if (index == 1) Navigator.popAndPushNamed(context, "/organizations");
    if (index == 2) Navigator.popAndPushNamed(context, "/identityDetails");
  }
}
