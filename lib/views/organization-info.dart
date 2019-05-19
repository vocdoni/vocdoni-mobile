import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
// import 'package:vocdoni/views/organization-activity.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class OrganizationInfo extends StatelessWidget {
  @override
  Widget build(context) {
    final Organization organization = ModalRoute.of(context).settings.arguments;
    if (organization == null) return buildEmptyOrganization(context);

    return ListView(
      children: <Widget>[
        PageTitle(
          title: organization.name,
          subtitle: organization.entityId,
        ),
        Section(text: "Description"),
        Section(text: "Actions"),
        ListItem(
          text: "Subscribe",
          onTap: () {
            debugPrint("Subscriing?");
          },
        ),
        ListItem(
          text: "Activity",
          onTap: () {
            Navigator.pushNamed(context, "/organizations/activity",
                arguments: organization);
          },
        ),
      ],
    );
  }

  Widget buildEmptyOrganization(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No organization)"),
    );
  }
}
