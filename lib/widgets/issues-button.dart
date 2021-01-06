import 'package:dvote_common/widgets/htmlSummary.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/i18n.dart';

class IssuesButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NavButton(
      style: NavButtonStyle.TIP,
      text: getText(context, "main.imHavingIssues"),
      onTap: () {
        launchUrl(AppConfig.helpURL);
      }, //TODO integrate with help desk
    );
  }
}
