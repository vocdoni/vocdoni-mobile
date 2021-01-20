import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';

class RecoverySuccess extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("RecoverySuccess");
    return Scaffold(
      body: Builder(
        builder: (context) => Align(
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              Spacer(),
              Text(
                getText(context, "main.congratulations"),
                // textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  color: colorDescription,
                ),
              ),
              Text(
                getText(context, "main.yourAccountIsSecured"),
                style: TextStyle(fontSize: 24, fontWeight: fontWeightLight),
              ).withPadding(spaceCard),
              Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Row(
          children: [
            Spacer(),
            NavButton(
              style: NavButtonStyle.NEXT,
              text: getText(context, "main.go"),
              onTap: () => {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/home",
                  (Route _) => false,
                )
              },
            ),
          ],
        ).withPadding(spaceCard),
      ),
    );
  }
}
