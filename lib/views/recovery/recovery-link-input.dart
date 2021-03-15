import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';

class RecoveryLinkInput extends StatefulWidget {
  @override
  _RecoveryLinkInputState createState() => _RecoveryLinkInputState();
}

class _RecoveryLinkInputState extends State<RecoveryLinkInput> {
  bool restoring = false;
  String recoveryLink;

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("RecoveryLinkInput");
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        appBar: TopNavigation(
          title: getText(context, "main.accountRecovery"),
        ),
        body: Builder(
          builder: (context) {
            return ListView(children: <Widget>[
              Text(
                getText(context,
                    "main.toRestoreYourAccountEitherTapYourRecoveryLinkOrEnterItBelow"),
                style: TextStyle(
                  fontWeight: fontWeightLight,
                  fontSize: 18,
                ),
              ).withPadding(16),
              Text(
                getText(context,
                    "main.youWillNeedYourPinAndRecoveryQuestionAnswersToRestoreTheAccount"),
                style: TextStyle(fontWeight: fontWeightLight, fontSize: 16),
              ).withPadding(16),
              TextField(
                keyboardType: TextInputType.url,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp('[ \t]'))
                ],
                autocorrect: false,
                autofocus: false,
                textCapitalization: TextCapitalization.none,
                style: TextStyle(
                    fontWeight: fontWeightLight,
                    color: colorDescription,
                    fontSize: 17),
                decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    border: _emptyTextInputBorder(),
                    focusedBorder: _emptyTextInputBorder(),
                    enabledBorder: _emptyTextInputBorder(),
                    disabledBorder: _emptyTextInputBorder(),
                    errorBorder: _emptyTextInputBorder(),
                    hintText: getText(context, "main.pasteLinkOrCodeHere")),
                onSubmitted: onSubmitLink(context),
              ).withPadding(16).withTopPadding(8),
            ]);
          },
        ),
      ),
    );
  }

  onSubmitLink(BuildContext scaffoldContext) {
    return (String input) async {
      try {
        if (input == null) return;
        if (input is! String) return;

        final link = Uri.tryParse(input);
        if (!(link is Uri) ||
            !link.hasScheme ||
            link.hasEmptyPath ||
            !input.contains("recovery")) throw Exception("Invalid URI");

        await handleIncomingLink(link, scaffoldContext);
      } catch (err) {
        logger.log(err);
        showMessage(
            getText(scaffoldContext,
                "error.theCodeDoesNotContainAValidLinkOrTheDetailsCannotBeRetrieved"),
            context: scaffoldContext,
            purpose: Purpose.DANGER);
      }
    };
  }

  OutlineInputBorder _emptyTextInputBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(color: colorBaseBackground),
      borderRadius: BorderRadius.circular(10),
    );
  }
}
