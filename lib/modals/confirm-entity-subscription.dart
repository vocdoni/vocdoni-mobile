import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/alerts.dart';
import '../constants/colors.dart';
import '../lang/index.dart';

class ConfirmEntitySubscriptionModal extends StatelessWidget {
  @required
  final Organization organization;
  ConfirmEntitySubscriptionModal(this.organization);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Lang.of(context).get("Organization")),
        backgroundColor: mainBackgroundColor,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(children: [
                    Text(
                      Lang.of(context).get("You are about to subscribe to:"),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      organization.name,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      organization.entityId,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      organization.resolverAddress,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      organization.networkId,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      organization.entryPoints.join(", "),
                      textAlign: TextAlign.center,
                    )
                  ]),
                ),
              ),
            ]),
            Row(
              children: <Widget>[
                Expanded(
                  child: FlatButton(
                    color: Colors.blue[100],
                    child: Padding(
                        child: Text("Subscribe"), padding: EdgeInsets.all(24)),
                    onPressed: () => promptAction(context),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  promptAction(BuildContext ctx) async {
    final accepts = await showPrompt(
      context: ctx,
        title: Lang.of(ctx).get("Organization"),
        text: Lang.of(ctx).get("Do you want to subscribe to the organization?"),
        okButton: Lang.of(ctx).get("Subscribe"));

    if (accepts != true) {
      goBack(ctx);
    } else {
      Navigator.pop(ctx, true);
    }
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
