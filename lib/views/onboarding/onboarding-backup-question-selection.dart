import 'package:dvote/models/build/dart/client-store/backup.pb.dart';
import 'package:dvote/util/backup.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';

class OnboardingBackupQuestionSelection extends StatelessWidget {
  // already chosen questions. Don't display these as options
  final List<int> currentQuestions;

  OnboardingBackupQuestionSelection(this.currentQuestions);

  @override
  Widget build(BuildContext context) {
    Globals.analytics.trackPage("OnboardingBackupQuestionSelection");
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
    AccountBackup_Questions.values.forEach((question) {
      if (currentQuestions.contains(question.value)) return;
      questions.add(
        ListItem(
          mainText: getBackupQuestionText(
              ctx,
              AccountBackupHandler.getBackupQuestionLanguageKey(
                  question.value)),
          onTap: () {
            Navigator.pop(ctx, question.value);
          },
          mainTextMultiline: 3,
        ),
      );
    });
    return questions;
  }
}
