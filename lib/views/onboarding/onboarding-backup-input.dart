import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/util.dart';
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
        bottomNavigationBar: Row(
          children: [
            NavButton(
              style: NavButtonStyle.BASIC,
              text: getText(context, "action.illDoItLater"),
              onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context, "/home", (route) => false),
            ),
            Spacer(),
            NavButton(
              isDisabled: questionIndexes.any((index) => index == 0) ||
                  questionAnswers.any((answer) => answer.length == 0) ||
                  !RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
                      .hasMatch(email),
              style: NavButtonStyle.NEXT,
              text: getText(context, "action.verifyBackup"),
              onTap: () {
                final backupLink = _generateLink();
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

  String _generateLink() {
    return "link"; // TODO generate backup link
  }
}
