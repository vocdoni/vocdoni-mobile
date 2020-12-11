import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';

class OnboardingFeaturesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  ).withPadding(spaceCard),
                  Spacer(),
                  Row(
                    children: [
                      Spacer(),
                      FlatButton(
                        onPressed: () => {},
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_forward_sharp,
                              color: colorBlue,
                            ).withRightPadding(5),
                            Text(
                              getText(context, "main.next"),
                              style: TextStyle(
                                fontWeight: fontWeightSemiBold,
                                fontSize: fontSizeBase,
                                color: colorBlue,
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
