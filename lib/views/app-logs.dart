import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';

class AppLogs extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "main.appLogs"),
      ),
      body: Scrollbar(
        child: ListView(
          children: (logger?.sessionLogs?.length ?? 0) > 0
              ? logger.sessionLogs
                  .split("\n")
                  .map((line) => Text(line).withBottomPadding(7))
                  .cast<Widget>()
                  .toList()
                  .reversed
                  .toList()
              : [Container()],
          reverse: true,
        ).withPadding(paddingPage),
      ),
      bottomNavigationBar: Builder(
        builder: (context) => Row(
          children: [
            NavButton(
              style: NavButtonStyle.BASIC,
              text: getText(context, "main.copyToTheClipboard"),
              onTap: () {
                _copyToClipboard(context);
              },
            ),
            Spacer(),
            NavButton(
              style: NavButtonStyle.BASIC,
              text: getText(context, "main.sendEmail"),
              onTap: () {
                _sendEmail(context);
              },
            ),
          ],
        ).withBottomPadding(spaceCard).withHPadding(spaceCard),
      ),
    );
  }

  _copyToClipboard(BuildContext ctx) {
    if (logger.sessionLogs?.isNotEmpty ?? false)
      Clipboard.setData(ClipboardData(text: logger.sessionLogs)).then((_) =>
          showMessage(getText(ctx, "main.contentCopiedToTheClipboard"),
              context: ctx, purpose: Purpose.GOOD));
  }

  _sendEmail(BuildContext ctx) async {
    if (logger.sessionLogs?.isNotEmpty ?? false) {
      final url = Uri.encodeFull(
          'mailto:?subject=${getText(ctx, "main.vocdoniAppLogs")}&body=${logger.sessionLogs}');
      try {
        await launch(url);
      } catch (err) {
        logger.log(err.toString());
      }
    }
  }
}
