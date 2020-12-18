import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/set-pin.dart';

class PinTransferPage extends StatelessWidget {
  final String alias;

  PinTransferPage(this.alias);

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
                        "main.theVocdoniAppIsSwitchingFromPatternBasedToPinBasedAuthentication"),
                    style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
                  ).withPadding(spaceCard),
                  Text(
                    getText(context,
                        "main.pleaseEnterYourNewPinThisWillReplaceTheCurrentPatternYouUseToAccessYourAccount"),
                    style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
                  ).withPadding(spaceCard),
                  Spacer(),
                  Row(
                    children: [
                      Spacer(),
                      NavButton(
                        text: getText(context, "main.next"),
                        style: NavButtonStyle.NEXT,
                        onTap: () async {
                          final newLockPattern = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) => SetPinPage(
                                alias,
                                generateIdentity: false,
                              ),
                            ),
                          );
                          if (newLockPattern == null) {
                            return;
                          } else if (newLockPattern is InvalidPatternError) {
                            showMessage(
                                getText(
                                    context, "main.thePinYouEnteredIsNotValid"),
                                purpose: Purpose.DANGER,
                                context: context);
                            return;
                          }
                          Navigator.pop(context, newLockPattern);
                        },
                      ),
                    ],
                  ).withPadding(spaceCard),
                ],
              )),
    );
  }
}
