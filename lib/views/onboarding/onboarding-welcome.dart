import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/onboarding-features%20copy.dart';

class OnboardingWelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
          builder: (context) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(),
                  Text(
                    getText(context, "main.welcome"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      color: colorDescription,
                    ),
                  ),
                  Text(
                    getText(context,
                        "main.vocdoniAllowsYouToStayConnectedToYourCollectivesByParticipatingInSecureVotingProcessesAndFollowingTheirActivity"),
                    style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
                  ).withPadding(spaceCard),
                  Spacer(),
                  Row(
                    children: [
                      NavButton(
                        style: NavButtonStyle.BASIC,
                        text: getText(context, "action.recoverAccount"),
                        onTap: () => showRestoreIdentity(context),
                      ),
                      Spacer(),
                      NavButton(
                        style: NavButtonStyle.NEXT_FILLED,
                        text: getText(context, "main.letsGo"),
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OnboardingFeaturesPage()),
                          )
                        },
                      ),
                    ],
                  ).withPadding(spaceCard),
                ],
              )),
    );
  }

  void showRestoreIdentity(BuildContext context) {
    Navigator.pushNamed(context, "/identity/restore");
  }
}
