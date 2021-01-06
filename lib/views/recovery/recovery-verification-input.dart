import 'dart:developer';

import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:dvote_common/widgets/toast.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
import 'package:vocdoni/views/recovery/recovery-success.dart';
import 'package:vocdoni/widgets/issues-button.dart';

class RecoveryVerificationArgs {
  //TODO implement necessary arguments (account name, hash, etc)
  final String accountName;
  final List<int> questionIndexes;
  RecoveryVerificationArgs(
      {@required this.questionIndexes, @required this.accountName});
}

class RecoveryVerificationInput extends StatefulWidget {
  @override
  _RecoveryVerificationInputState createState() =>
      _RecoveryVerificationInputState();
}

class _RecoveryVerificationInputState extends State<RecoveryVerificationInput> {
  List<int> questionIndexes;
  String accountName;
  List<String> questionAnswers;

  @override
  void initState() {
    questionIndexes = [0, 0];
    questionAnswers = ["", ""];
    accountName = "";
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    final RecoveryVerificationArgs args =
        ModalRoute.of(context).settings.arguments;
    if (args == null) {
      Navigator.of(context).pop();
      log("Invalid parameters");
      return;
    }
    questionIndexes = args.questionIndexes;
    accountName = args.accountName;
  }

  @override
  Widget build(BuildContext context) {
    // return Builder(builder: (context) {
    //   return Text("clime");
    // });
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
                            child: extractBoldText(
                                    getText(context, "main.welcomeBackName")
                                        .replaceAll("NAME", accountName))
                                .withHPadding(spaceCard))
                        .withVPadding(paddingPage)
                        .withTopPadding(48),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getText(context, "main.letsVerifyTheSecurityQuestions"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: fontWeightLight,
                          color: colorDescription,
                        ),
                      ).withHPadding(spaceCard),
                    ).withBottomPadding(30),
                    _buildBackupQuestion(0, context),
                    _buildBackupQuestion(1, context),
                  ],
                ).withVPadding(48),
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
                  isDisabled:
                      questionAnswers.any((answer) => answer.length == 0),
                  style: NavButtonStyle.NEXT,
                  text: getText(context, "main.next"),
                  onTap: () {
                    _handleRecovery(context);
                  }),
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
          mainTextMultiline: 3,
          rightIcon: null,
        ),
        TextInput.TextInput(
          hintText: getText(context, "main.answer").toLowerCase(),
          textCapitalization: TextCapitalization.sentences,
          inputFormatter: questionIndexes[position] == 0
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

  _handleRecovery(BuildContext context) async {
    if (questionAnswers.any((answer) => answer.length == 0)) {
      showMessage(getText(context, "main.pleaseAnswerBothRecoveryQuestions"),
          context: context, purpose: Purpose.WARNING);
      return "";
    }
    String pin;
    try {
      if (Globals.appState.pinCache.length > 0) {
        pin = Globals.appState.pinCache;
      } else {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PinPromptModal(
                      Globals.appState.currentAccount,
                      decryptMnemonic: false,
                      accountName: accountName,
                    )));
        if (result == null) return "";
        if (result is InvalidPatternError) {
          showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
              context: context, purpose: Purpose.DANGER);
          return Future.value();
        }
        pin = result;
      }
    } catch (err) {
      log(err.toString());
      showMessage(
          getText(context, "main.thereWasAProblemDecryptingYourPrivateKey"),
          context: context,
          purpose: Purpose.DANGER);
      return Future.value();
    }
    // TODO decode link and generate key
    if (false) {
      // if key not decrypted correctly
      showMessage(
          getText(context,
              "main.eitherThePINOrOneOfTheAnswersIsNotCorrectTryAgain"),
          context: context,
          purpose: Purpose.DANGER);
    } else {
      // TODO detect if generated key already exists. if so, this is the dry run. just navigate home. else:
      // TODO create account, write to storage
      // TODO select account
      Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true, builder: (context) => RecoverySuccess()));
    }
  }
}
