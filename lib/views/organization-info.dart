import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/views/organization-activity.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/alerts.dart';
import '../lang/index.dart';

class OrganizationInfo extends StatelessWidget {
  @override
  Widget build(context) {
    final Organization organization = ModalRoute.of(context).settings.arguments;
    if (organization == null) return buildEmptyOrganization(context);

    return Scaffold(
      body: ListView(
        children: <Widget>[
          PageTitle(
            title: organization.name,
            subtitle: organization.entityId,
          ),
          Section(text: "Description"),
          Text(
            organization.description["en"],
            textAlign: TextAlign.center,
          ), // TODO: LANGUAGE
          Section(text: "Actions"),
          ListItem(
            text: "Subscribe",
            onTap: () => confirmSubscribe(context),
          ),
          ListItem(
            text: "Activity",
            onTap: () {
              Navigator.pushNamed(context, "/organizations/activity",
                  arguments: organization);
            },
          ),
          SizedBox(height: 40),
          Text(
            Lang.of(context).get("You are about to subscribe to:"),
            textAlign: TextAlign.center,
          ),
          Text(
            organization.name,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            Lang.of(context).get("Using the identity:"),
            textAlign: TextAlign.center,
          ),
          Text(
            identitiesBloc.current[appStateBloc.current.selectedIdentity].alias,
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget buildEmptyOrganization(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No organization)"),
    );
  }

  confirmSubscribe(BuildContext ctx) async {
    final accepts = await showPrompt(
        context: ctx,
        title: Lang.of(ctx).get("Organization"),
        text: Lang.of(ctx).get("Do you want to subscribe to the organization?"),
        okButton: Lang.of(ctx).get("Subscribe"));

    if (accepts == true) {
      Navigator.pop(ctx, true);
    }
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
