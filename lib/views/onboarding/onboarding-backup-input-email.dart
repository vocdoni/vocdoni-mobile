import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/widgets/issues-button.dart';

import 'onboarding-backup-email-check.dart';

class OnboardingBackupInputEmail extends StatefulWidget {
  final String backupLink;

  OnboardingBackupInputEmail(this.backupLink);

  @override
  _OnboardingBackupInputEmailState createState() =>
      _OnboardingBackupInputEmailState();
}

class _OnboardingBackupInputEmailState
    extends State<OnboardingBackupInputEmail> {
  String email;

  @override
  void initState() {
    email = "";
    Globals.analytics.trackPage("OnboardingBackupInputEmail");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final yourEmail = getText(context, "main.yourEmail");
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
          builder: (context) => Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getText(context,
                            "main.tapSendEmailToSendYourselfABackupLinkForYourRecordsSoYouCanRecoverTheAccountAtAnyTime"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: fontWeightLight,
                        ),
                      ),
                    ).withTopPadding(paddingPage),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: extractBoldText(getText(context,
                          "main.thenClickTheLinkToVerifyThatTheBackupWorks")),
                    ).withVPadding(spaceCard),
                    TextInput.TextInput(
                      hintText: yourEmail[0].toUpperCase() +
                          yourEmail.substring(1).toLowerCase(),
                      textCapitalization: TextCapitalization.none,
                      inputFormatter:
                          FilteringTextInputFormatter.deny(RegExp('[ \t]')),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (newEmail) {
                        setState(() {
                          email = newEmail;
                        });
                      },
                    ).withVPadding(16),
                  ],
                ).withHPadding(focusMargin),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) => Row(
            children: [
              IssuesButton(),
              Spacer(),
              NavButton(
                isDisabled: !RegExp(
                        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
                    .hasMatch(email),
                style: NavButtonStyle.NEXT,
                text: getText(context, "action.sendEmail"),
                onTap: () async {
                  await sendEmail(context);
                },
              ),
            ],
          ).withPadding(spaceCard),
        ),
      ),
    );
  }

  sendEmail(BuildContext context) async {
    bool launched;
    final subject = getText(context, 'main.vocdoniBackupLink');
    final body = getText(context,
            'main.thisLinkProvidesABackupToYourVocdoniAccountMakeSureToKeepItSecret') +
        '\n' +
        getText(context,
            'main.ifYouEverNeedToRecoverYourAccountYouCanSearchForThisEmailAndFollowThisRecoveryLink') +
        ':\n' +
        widget.backupLink +
        '\n' +
        getText(context,
            'main.youWillNeedToRememberAndCorrectlyInputYourSecurityQuestionsInOrderToRestoreTheAccount');
    final url = Uri.encodeFull('mailto:$email?subject=$subject&body=$body');
    try {
      launched = await launch(url);
    } catch (err) {
      logger.log(err.toString());
      launched = false;
    }
    if (!launched) {
      logger.log('Could not launch $url');
      Clipboard.setData(ClipboardData(text: widget.backupLink));
      await showAlert(
          getText(context,
              'main.yourBackupLinkHasBeenCopiedToTheClipboardPleasePasteItSomewhereSecureAndMemorable'),
          title: getText(context, 'error.couldNotLaunchEmailApp'),
          context: context);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OnboardingBackupEmailCheckPage()),
    );
  }
}
