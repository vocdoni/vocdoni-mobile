import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/widgets/issues-button.dart';

class OnboardingBackupEmailCheckPage extends StatefulWidget {
  OnboardingBackupEmailCheckPage();

  @override
  _OnboardingBackupEmailCheckPageState createState() =>
      _OnboardingBackupEmailCheckPageState();
}

class _OnboardingBackupEmailCheckPageState
    extends State<OnboardingBackupEmailCheckPage> {
  String linkInput = "";

  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("OnboardingBackupEmailCheck");
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getText(context,
                        'main.ifYouHaveSuccessfullyForwardedYourselfTheEmailLinkWeCanNowCheckThatItWorks'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: fontWeightLight,
                      color: colorDescription,
                    ),
                  ).withVPadding(spaceCard),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getText(
                        context, 'main.pasteTheLinkBelowOrOpenItWithABrowser'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: fontWeightLight,
                      color: colorDescription,
                    ),
                  ).withVPadding(spaceCard),
                ),
                TextField(
                  onChanged: (input) => setState(() => linkInput = input),
                  keyboardType: TextInputType.url,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp('[ \t]'))
                  ],
                  autocorrect: false,
                  autofocus: false,
                  textCapitalization: TextCapitalization.none,
                  style: TextStyle(
                      fontWeight: fontWeightLight,
                      color: colorDescription,
                      fontSize: 17),
                  decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      border: _emptyTextInputBorder(),
                      focusedBorder: _emptyTextInputBorder(),
                      enabledBorder: _emptyTextInputBorder(),
                      disabledBorder: _emptyTextInputBorder(),
                      errorBorder: _emptyTextInputBorder(),
                      hintText: getText(context, "main.pasteLinkOrCodeHere")),
                ).withTopPadding(8),
                Spacer(),
              ],
            ).withHPadding(focusMargin);
          },
        ),
        bottomNavigationBar: Builder(
          builder: (context) => Row(
            children: [
              IssuesButton(),
              Spacer(),
              NavButton(
                text: getText(context, "main.verifyBackup"),
                style: NavButtonStyle.NEXT_FILLED,
                isDisabled: linkInput.length <= 1,
                onTap: onSubmitLink(context),
              ),
            ],
          ).withPadding(spaceCard),
        ),
      ),
    );
  }

  onSubmitLink(BuildContext scaffoldContext) {
    return () async {
      try {
        if (linkInput == null) return;
        if (linkInput is! String) return;

        final link = Uri.tryParse(linkInput);
        if (!(link is Uri) ||
            !link.hasScheme ||
            link.hasEmptyPath ||
            !linkInput.contains("recovery")) throw Exception("Invalid URI");

        await handleIncomingLink(link, scaffoldContext);
      } catch (err) {
        logger.log(err);
        showMessage(
            getText(scaffoldContext,
                "error.theCodeDoesNotContainAValidLinkOrTheDetailsCannotBeRetrieved"),
            context: scaffoldContext,
            purpose: Purpose.DANGER);
      }
    };
  }

  OutlineInputBorder _emptyTextInputBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(color: colorBaseBackground),
      borderRadius: BorderRadius.circular(10),
    );
  }
}
