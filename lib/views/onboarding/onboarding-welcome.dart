import 'package:dvote_common/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/onboarding-features.dart';

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
                      FlatButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => {},
                        child: Text(
                          getText(context, "action.recoverAccount"),
                          style: TextStyle(
                              fontWeight: fontWeightSemiBold,
                              fontSize: fontSizeBase),
                        ),
                      ),
                      Spacer(),
                      RaisedButton(
                        onPressed: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => OnboardingFeaturesPage()),
                          )
                        },
                        color: colorBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_sharp,
                              color: colorCardBackround,
                            ).withRightPadding(5),
                            Text(
                              getText(context, "main.letsGo"),
                              style: TextStyle(
                                fontWeight: fontWeightSemiBold,
                                fontSize: fontSizeBase,
                                color: colorCardBackround,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).withPadding(spaceCard),
                ],
              )),
    );
  }
}
