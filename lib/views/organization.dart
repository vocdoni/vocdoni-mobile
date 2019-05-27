import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/avatar.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import '../lang/index.dart';

class OrganizationInfo extends StatefulWidget {
  @override
  _OrganizationInfoState createState() => _OrganizationInfoState();
}

class _OrganizationInfoState extends State<OrganizationInfo> {
  bool collapsed = false;
  @override
  Widget build(context) {
    final Organization organization = ModalRoute.of(context).settings.arguments;
    if (organization == null) return buildEmptyOrganization(context);

    bool alreadySubscribed = false;
    if (appStateBloc.current != null &&
        appStateBloc.current.selectedIdentity >= 0) {
      final Identity currentIdentity =
          identitiesBloc.current[appStateBloc.current.selectedIdentity];
      if (currentIdentity != null && currentIdentity.organizations.length > 0) {
        alreadySubscribed = currentIdentity.organizations
            .any((o) => o.entityId == organization.entityId);
      }
    }

    return ScaffoldWithImage(
        headerImageUrl: organization.imageHeader ??
            "https://images.unsplash.com/photo-1557518016-299b3b3c2e7f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80",
        title: organization.name,
        collapsedTitle: organization.name,
        subtitle: organization.name,
        avatarUrl: organization.avatar,
        children: [
          Section(text: "Description"),
          Summary(
            text: organization.description[organization.languages[0]],
            maxLines: 5,
          ),
          Section(text: "Actions"),
          ListItem(
            text: "Activity",
            onTap: () {
              Navigator.pushNamed(context, "/organization/activity",
                  arguments: organization);
            },
          ),
          (alreadySubscribed
              ? buildAlreadySubscribed(context, organization) // CUSTOM ACTIONS
              : buildSubscriptionTiles(context, organization) // SUBSCRIBE

          ),
        ]);
  }

  /// NO ORGANIZATION

  Widget buildEmptyOrganization(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        backgroundColor: baseBackgroundColor,
        body: Center(
          child: Text("(No organization)"),
        ));
  }

  /// ALREADY REGISTERED CONTENT

  Widget buildAlreadySubscribed(BuildContext ctx, Organization organization) {
    // TODO: Handle all actions
    final List<Widget> actions = organization.actions
        .map((action) {
          if (!(action is Map) ||
              !(action["name"] is Map) ||
              !(action["name"][organization.languages[0]] is String))
            return null;
          return ListItem(
            text: action["name"][organization.languages[0]],
            onTap: () {
              Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (context) => WebAction(
                            url: action["url"],
                            title: action["name"][organization.languages[0]] ??
                                organization.name,
                          )));
            },
          );
        })
        .toList()
        .where((w) => w != null)
        .toList();

    return Column(children: <Widget>[
      ...actions,
      SizedBox(height: 40),
      Text(
        Lang.of(ctx).get("You are already subscribed"),
        textAlign: TextAlign.center,
      )
    ]);
  }

  /// PROMPT TO SUBSCRIBE

  Widget buildSubscriptionTiles(BuildContext ctx, Organization organization) {
    return Column(children: <Widget>[
      ListItem(
        text: "Subscribe",
        onTap: () => subscribeToOrganization(ctx, organization),
      ),
      SizedBox(height: 40),
      Text(
        Lang.of(ctx).get("You are about to subscribe to:"),
        textAlign: TextAlign.center,
      ),
      Text(
        organization.name,
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 20),
      Text(
        Lang.of(ctx).get("Using the identity:"),
        textAlign: TextAlign.center,
      ),
      Text(
        identitiesBloc.current[appStateBloc.current.selectedIdentity].alias,
        textAlign: TextAlign.center,
      )
    ]);
  }

  subscribeToOrganization(BuildContext ctx, Organization organization) async {
    final accepted = await showPrompt(
        context: ctx,
        title: Lang.of(ctx).get("Organization"),
        text: Lang.of(ctx).get("Do you want to subscribe to the organization?"),
        okButton: Lang.of(ctx).get("Subscribe"));

    if (accepted == false) return;

    try {
      await identitiesBloc.subscribe(organization);

      showMessage(Lang.of(context).get("The subscription has been registered"),
          context: context);
    } catch (err) {
      if (err == "Already subscribed") {
        showMessage(
            Lang.of(context)
                .get("You are already subscribed to this organization"),
            context: context);
      } else {
        showMessage(
            Lang.of(context)
                .get("The subscription could not be registered"),
            context: context);
      }
    }
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
