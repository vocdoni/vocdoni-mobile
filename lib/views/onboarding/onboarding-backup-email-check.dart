import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/widgets/issues-button.dart';

class OnboardingBackupEmailCheckPage extends StatelessWidget {
  OnboardingBackupEmailCheckPage();

  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("OnboardingBackupEmailCheck");
    return Scaffold(
      appBar: TopNavigation(
        title: "",
        onBackButton: () => Navigator.pop(context, null),
      ),
      body: Builder(
        builder: (context) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              Text(
                getText(context, 'main.checkYourEmailForAnEmail'),
                style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
              ).withVPadding(spaceCard),
              Spacer(),
            ],
          ).withHPadding(spaceCard);
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Row(
          children: [
            IssuesButton(),
            Spacer(),
          ],
        ).withPadding(spaceCard),
      ),
    );
  }
}
