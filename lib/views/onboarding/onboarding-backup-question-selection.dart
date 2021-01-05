import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/i18n.dart';

class OnboardingBackupQuestionSelection extends StatelessWidget {
  final List<int> currentQuestions;

  OnboardingBackupQuestionSelection(this.currentQuestions);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Text(
            getText(context,
                "main.selectAQuestionWithAnAnswerThatIsNotPubliclyAvailableAndYouWillRememberInTheFuture"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: fontWeightLight,
            ),
          ).withPadding(spaceCard),
          Column(
            children: _generateQuestionList(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateQuestionList(BuildContext ctx) {
    final List<Widget> questions = [];
    AppConfig.backupQuestionTexts.asMap().forEach((index, question) {
      if (currentQuestions.contains(index) || index == 0) return;
      questions.add(
        ListItem(
          mainText: getText(ctx, "main." + question),
          onTap: () {
            Navigator.pop(ctx, index);
          },
          mainTextMultiline: 3,
        ),
      );
    });
    return questions;
  }
}
