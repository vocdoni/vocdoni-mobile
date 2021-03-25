import 'package:convert/convert.dart';
import 'package:dvote/models/build/dart/client-store/backup.pb.dart';
import 'package:dvote/util/backup.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
import 'package:vocdoni/views/onboarding/onboarding-backup-input-email.dart';
import 'package:vocdoni/views/onboarding/onboarding-backup-question-selection.dart';

class OnboardingBackupInput extends StatefulWidget {
  final String pinCache;

  OnboardingBackupInput({this.pinCache});

  @override
  _OnboardingBackupInputState createState() => _OnboardingBackupInputState();
}

class _OnboardingBackupInputState extends State<OnboardingBackupInput> {
  List<int> questionIndexes;
  List<String> questionAnswers;

  @override
  void initState() {
    questionIndexes = [-1, -1];
    questionAnswers = ["", ""];
    Globals.analytics.trackPage("OnboardingBackupInput");
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
                    Navigator.pushNamedAndRemoveUntil(
                        context, "/home", (route) => false);
                  }),
              Spacer(),
              NavButton(
                isDisabled: questionIndexes.any((index) =>
                        !AccountBackupHandler.isValidBackupQuestionIndex(
                            index)) ||
                    questionAnswers.any((answer) => answer.length == 0),
                style: NavButtonStyle.NEXT,
                text: getText(context, "action.verifyBackup"),
                onTap: () async {
                  final backupLink = await _retrieveBackupLink(context);
                  if (backupLink == null || backupLink.length == 0) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            OnboardingBackupInputEmail(backupLink)),
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
    final index = questionIndexes[position];
    usedQuestions.removeAt(position);
    return Column(
      children: [
        ListItem(
          isLink: !AccountBackupHandler.isValidBackupQuestionIndex(index),
          mainText: (position + 1).toString() +
              ". " +
              (AccountBackupHandler.isValidBackupQuestionIndex(index)
                  ? getBackupQuestionText(ctx,
                      AccountBackupHandler.getBackupQuestionLanguageKey(index))
                  : getText(ctx, "main.selectQuestion")),
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
          enabled: AccountBackupHandler.isValidBackupQuestionIndex(index),
          hintText: getText(context, "main.answer").toLowerCase(),
          textCapitalization: TextCapitalization.sentences,
          inputFormatter: !AccountBackupHandler.isValidBackupQuestionIndex(
                  questionIndexes[position])
              ? FilteringTextInputFormatter.allow("")
              : null,
          onChanged: (answer) {
            setState(() {
              questionAnswers[position] = answer;
            });
          },
        ).withHPadding(paddingPage),
      ],
    ).withHPadding(8);
  }

  Future<String> _retrieveBackupLink(BuildContext ctx) async {
    String pin;
    String mnemonic;
    String backupLink;

    try {
      // If widget wasn't passed a pin (user is backing up at some later point) ask for pin
      if (widget.pinCache == null || widget.pinCache == "") {
        final result = await Navigator.push(
            ctx,
            MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PinPromptModal(
                      Globals.appState.currentAccount,
                      returnPin: true,
                    )));
        if (result is InvalidPatternError) {
          showMessage(getText(ctx, "main.thePinYouEnteredIsNotValid"),
              context: ctx, purpose: Purpose.DANGER);
          return Future.value();
        }
        pin = result;
      } else {
        pin = widget.pinCache;
      }
      // Decrypt stored encrypted mnemonic with pin
      final loading = showLoading(getText(context, "main.generatingIdentity"),
          context: ctx);
      final encryptedMnemonic = Globals
          .appState.currentAccount.identity.value.keys[0].encryptedMnemonic;
      mnemonic = await Symmetric.decryptStringAsync(encryptedMnemonic, pin);
      final backup = await AccountBackupHandler.createBackup(
          Globals.appState.currentAccount.identity.value.alias,
          questionIndexes,
          AccountBackup_Auth.PIN,
          mnemonic,
          pin,
          questionAnswers);
      final backupBytes = backup.writeToBuffer();
      final backupString = hex.encode(backupBytes);
      backupLink =
          "https://" + AppConfig.LINKING_DOMAIN + "/recovery/" + backupString;
      loading.close();
    } catch (err) {
      logger.log(err.toString());
      showMessage(getText(ctx, "main.thereWasAProblemDecryptingYourPrivateKey"),
          context: ctx);
      return Future.value();
    }
    Globals.appState.currentAccount.identity.value.backedUp = true;
    Globals.accountPool.writeToStorage();
    return backupLink;
  }
}
