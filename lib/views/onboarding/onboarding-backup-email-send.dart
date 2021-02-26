import 'dart:async';

import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/dvote_common.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/notifications.dart';
import 'package:vocdoni/view-modals/action-account-select.dart';
import 'package:vocdoni/widgets/issues-button.dart';

import '../../app-config.dart';

class OnboardingBackupEmailSendPage extends StatefulWidget {
  final String backupLink;
  final String email;

  OnboardingBackupEmailSendPage(this.backupLink, this.email);

  @override
  _OnboardingBackupEmailSendPageState createState() =>
      _OnboardingBackupEmailSendPageState();
}

class _OnboardingBackupEmailSendPageState
    extends State<OnboardingBackupEmailSendPage> {
  BuildContext scaffoldBodyContext;
  StreamSubscription<Uri> linkChangeStream;

  @override
  void initState() {
    try {
      getInitialUri()
          .then((initialUri) => handleLink(initialUri))
          .catchError((err) => handleIncomingLinkError(err));

      // HANDLE RUNTIME LINKS
      linkChangeStream = getUriLinksStream()
          .listen((uri) => handleLink(uri), onError: handleIncomingLinkError);

      // Display the screen for a notification (if one is pending)
      Future.delayed(Duration(seconds: 1))
          .then((_) => Notifications.handlePendingNotification());
    } catch (err) {
      showAlert(getText(context, "main.theLinkYouFollowedAppearsToBeInvalid"),
          title: getText(context, "main.error"), context: context);

      super.initState();
    }
  }

  @override
  void dispose() {
    // RUNTIME LINK HANDLING
    if (linkChangeStream != null) linkChangeStream.cancel();

    super.dispose();
  }

  handleLink(Uri givenUri) {
    if (givenUri == null || !Globals.accountPool.hasValue) return;
    if (Globals.accountPool.value.length == 1 ||
        givenUri.path.contains("recovery")) {
      handleIncomingLink(givenUri, scaffoldBodyContext ?? context)
          .catchError(handleIncomingLinkError);
    } else {
      Navigator.push(context,
              MaterialPageRoute(builder: (context) => LinkAccountSelect()))
          .then((result) {
        if (result != null && result is int) {
          Globals.appState.selectAccount(result);
          handleIncomingLink(givenUri, scaffoldBodyContext ?? context)
              .catchError(handleIncomingLinkError);
        }
      });
    }
  }

  handleIncomingLinkError(err) {
    logger.log(err?.toString() ?? "handleIncomingLinkError");
    final ctx = scaffoldBodyContext ?? context;
    showAlert(getText(ctx, "error.thereWasAProblemHandlingTheLink"),
        title: getText(scaffoldBodyContext ?? context, "main.error"),
        context: scaffoldBodyContext ?? context);
  }

  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("OnboardingBackupEmailCheck");
    return Scaffold(
      body: Builder(
        builder: (context) {
          scaffoldBodyContext = context;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              Text(
                getText(context,
                    'main.tapSendEmailToSendYourselfABackupLinkForYourRecordsThenClickTheLinkToVerifyThatTheBackupWorks'),
                style: TextStyle(fontSize: 18, fontWeight: fontWeightLight),
              ).withVPadding(spaceCard),
              ListItem(
                mainText: getText(context, 'action.sendEmail'),
                onTap: () async {
                  await sendEmail(context);
                },
              ),
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

  sendEmail(BuildContext context) async {
    bool launched;
    final subject = getText(context, 'main.vocdoniBackupLink');
    final body = getText(context,
            'main.thisLinkProvidesABackupToYourVocdoniAccountMakeSureToKeepItSecret') +
        '\n' +
        getText(context,
            'main.ifYouEverNeedToRecoverYourAccountYouCanSearchForThisEmailAndFollowThisRecoveryLink') +
        ':\n' +
        "https://" +
        AppConfig.LINKING_DOMAIN +
        "/" +
        widget.backupLink +
        '\n' +
        getText(context,
            'main.youWillNeedToRememberAndCorrectlyInputYourSecurityQuestionsInOrderToRestoreTheAccount');
    final url =
        Uri.encodeFull('mailto:${widget.email}?subject=$subject&body=$body');
    try {
      launched = await launch(url);
    } catch (err) {
      logger.log(err.toString());
      launched = false;
    }
    if (!launched) {
      logger.log('Could not launch $url');
      Clipboard.setData(ClipboardData(
          text: AppConfig.LINKING_DOMAIN + "/" + widget.backupLink));
      showAlert(
          getText(context,
              'main.yourBackupLinkHasBeenCopiedToTheClipboardPleasePasteItSomewhereSecureAndMemorable'),
          title: getText(context, 'error.couldNotLaunchEmailApp'),
          context: context);
    }
  }
}
