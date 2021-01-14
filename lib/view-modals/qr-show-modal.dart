import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/extensions.dart';

class QrShowModal extends StatelessWidget {
  final String title;
  final String content;

  QrShowModal(this.title, this.content) {
    assert(content is String && content.length > 0);
  }

  onCopy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content))
        .then((_) => showMessage(
            getText(context, "main.contentCopiedToTheClipboard"),
            context: context,
            purpose: Purpose.GOOD))
        .catchError((err) {
      logger.log(err);

      showMessage(getText(context, "main.couldNotCopyTheEntityId"),
          context: context, purpose: Purpose.DANGER);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: title ?? "Vocdoni", // getText(context, "main.scan")
        showBackButton: true,
        onBackButton: () => Navigator.of(context).pop(),
      ),
      body: Builder(builder: (context) {
        return Container(
          child: Column(children: [
            SizedBox(height: 50),
            Center(
              child: QrImage(
                data: content,
                version: QrVersions.auto,
                size: 300.0,
              ),
            ),
            Container(
              child: FlatButton(
                color: colorBlue,
                textColor: Colors.white,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(paddingButton),
                splashColor: Colors.blueAccent,
                onPressed: () => onCopy(context),
                child: Text(
                  getText(context, "main.copyToTheClipboard"),
                  style: TextStyle(fontSize: 20.0),
                ).withHPadding(16).withVPadding(8),
              ).withPadding(32).withTopPadding(8),
            )
          ]),
        );
      }),
    );
  }
}
