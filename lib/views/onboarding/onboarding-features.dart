import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/onboarding-account-naming.dart';

class OnboardingFeaturesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("OnboardingFeatures");
    return Scaffold(
      appBar: TopNavigation(
        title: "",
        onBackButton: () => Navigator.pop(context, null),
      ),
      body: Builder(
        builder: (context) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Spacer(),
            Text(
              getText(context,
                  "main.thisAppGuaranteesThatYourVoteIsAnonymousAndYourPersonalInformationIsKeptSecured"),
              style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
            ).withVPadding(spaceCard).withHPadding(focusMargin),
            Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Row(
          children: [
            Spacer(),
            NavButton(
              text: getText(context, "main.next"),
              style: NavButtonStyle.NEXT,
              onTap: () => {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OnboardingAccountNamingPage()),
                )
              },
            ),
          ],
        ).withPadding(focusMargin),
      ),
    );
  }
}
