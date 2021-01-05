import 'dart:developer';

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
        bottomNavigationBar: Row(
          children: [
            Spacer(),
            NavButton(
              isDisabled: questionAnswers.any((answer) => answer.length == 0),
              style: NavButtonStyle.NEXT,
              text: getText(context, "main.next"),
              onTap: () {},
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
            questionAnswers[position] = answer;
          },
        ).withHPadding(paddingPage),
      ],
    ).withHPadding(8);
  }
}
