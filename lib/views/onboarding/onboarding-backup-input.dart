import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:dvote_common/widgets/toast.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
import 'package:vocdoni/views/onboarding/onboarding-backup-email-send.dart';
import 'package:vocdoni/views/onboarding/onboarding-backup-question-selection.dart';

class OnboardingBackupInput extends StatefulWidget {
  @override
  _OnboardingBackupInputState createState() => _OnboardingBackupInputState();
}

class _OnboardingBackupInputState extends State<OnboardingBackupInput> {
  List<int> questionIndexes;
  List<String> questionAnswers;
  String email;

  @override
  void initState() {
    questionIndexes = [0, 0];
    questionAnswers = ["", ""];
    email = "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              getText(context, "main.backup"),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: fontWeightLight,
                              ),
                            ).withHPadding(spaceCard))
                        .withVPadding(paddingPage)
                        .withTopPadding(paddingPage),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: extractBoldText(getText(context,
                              "main.ifYouLoseYourPhoneOrUninstallTheAppYouWontBeAbleToVoteLetsCreateASecureBackup"))
                          .withHPadding(spaceCard),
                    ),
                    Align(
                            alignment: Alignment.centerLeft,
                            child: extractBoldText(
                              getText(context,
                                      "main.keepInMindThatYouWillStillNeedToCorrectlyInputYourPinAndRecoveryPhrasesToRestoreYourAccount") +
                                  ".",
                            ).withHPadding(spaceCard))
                        .withVPadding(paddingPage)
                        .withTopPadding(paddingChip),
                    _buildBackupQuestion(0, context),
                    _buildBackupQuestion(1, context),
                    Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              getText(context,
                                  "main.weWillSendTheBackupToYourEmailSoYouCanRecoverYourAccountAtAnyTime"),
                              style: TextStyle(
                                fontSize: fontSizeBase,
                                color: colorDescription,
                              ),
                            ).withHPadding(spaceCard))
                        .withVPadding(paddingPage)
                        .withTopPadding(paddingChip),
                    TextInput.TextInput(
                      hintText:
                          getText(context, "main.yourEmail").toLowerCase(),
                      textCapitalization: TextCapitalization.none,
                      inputFormatter:
                          FilteringTextInputFormatter.deny(RegExp('[ \t]')),
                      onChanged: (newEmail) {
                        setState(() {
                          email = newEmail;
                        });
                      },
                    ).withHPadding(spaceCard),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Builder(
          builder: (context) => Row(
            children: [
              NavButton(
                  style: NavButtonStyle.BASIC,
                  text: getText(context, "action.illDoItLater"),
                  onTap: () {
                    Globals.appState.pinCache = "";
                    Globals.appState.currentAccount?.identity?.value?.backedUp =
                        false;
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/home", (route) => false);
                  }),
              Spacer(),
              NavButton(
                isDisabled: questionIndexes.any((index) => index == 0) ||
                    questionAnswers.any((answer) => answer.length == 0) ||
                    !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
                        .hasMatch(email),
                style: NavButtonStyle.NEXT,
                text: getText(context, "action.verifyBackup"),
                onTap: () async {
                  final backupLink = await _generateLink(context);
                  if (backupLink == null || backupLink.length == 0) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            OnboardingBackupEmailSendPage(backupLink, email)),
                  );
                },
              ),
            ],
          ).withPadding(spaceCard),
        ),
      ),
    );
  }

  _buildBackupQuestion(int position, BuildContext ctx) {
    if (questionIndexes.length <= position) return Container();
    final usedQuestions = questionIndexes.toList();
    usedQuestions.removeAt(position);
    return Column(
      children: [
        ListItem(
          mainText: (position + 1).toString() +
              ". " +
              getText(
                  ctx,
                  "main." +
                      AppConfig.backupQuestionTexts[questionIndexes[position]]),
          onTap: () async {
            final newIndex = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      OnboardingBackupQuestionSelection(usedQuestions),
                ));
            setState(() {
              questionIndexes[position] = newIndex ?? questionIndexes[position];
            });
          },
          mainTextMultiline: 3,
        ),
        TextInput.TextInput(
          hintText: getText(context, "main.answer").toLowerCase(),
          textCapitalization: TextCapitalization.sentences,
          inputFormatter: questionIndexes[position] == 0
              ? FilteringTextInputFormatter.allow("")
              : null,
          onChanged: (answer) {
            questionAnswers[position] = answer;
          },
        ).withHPadding(paddingPage),
      ],
    ).withHPadding(8);
  }

  Future<String> _generateLink(BuildContext ctx) async {
    String mnemonic;
    try {
      if (Globals.appState.pinCache.length > 0) {
        final loading = showLoading(getText(context, "main.generatingIdentity"),
            context: ctx);
        final encryptedMnemonic = Globals
            .appState.currentAccount.identity.value.keys[0].encryptedMnemonic;
        mnemonic = await Symmetric.decryptStringAsync(
            encryptedMnemonic, Globals.appState.pinCache);
        loading.close();
      } else {
        final result = await Navigator.push(
            ctx,
            MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) =>
                    PinPromptModal(Globals.appState.currentAccount)));
        if (result is InvalidPatternError) {
          showMessage(getText(ctx, "main.thePinYouEnteredIsNotValid"),
              context: ctx, purpose: Purpose.DANGER);
          return Future.value();
        }
        mnemonic = result;
      }
    } catch (err) {
      logger.log(err.toString());
      showMessage(getText(ctx, "main.thereWasAProblemDecryptingYourPrivateKey"),
          context: ctx);
      return Future.value();
    }
    Globals.appState.currentAccount.identity.value.backedUp = true;
    return mnemonic; // TODO generate backup link
  }
}
