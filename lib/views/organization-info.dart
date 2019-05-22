import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/constants/colors.dart' as prefix0;
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import '../lang/index.dart';

class OrganizationInfo extends StatelessWidget {
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

    double height = 200;
    double zoneHeight = 100;
    double pos = 0;
    double opacity = 0;

    return Scaffold(
        backgroundColor: baseBackgroundColor,
        body: CustomScrollView(controller: ScrollController(), slivers: [
          SliverAppBar(
              floating: true,
              snap: true,
              pinned: true,
              elevation: 0,
              //title: Text('SliverAppBar'),
              backgroundColor: baseBackgroundColor,
              expandedHeight: height,
              flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                pos = constraints.biggest.height;
                // print('constraints=' + constraints.toString());

                opacity = (pos / zoneHeight) < 1 ? pos / height : 1;

                return FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text(
                      organization.name,
                      style: TextStyle(color: titleColor.withOpacity(opacity)),
                    ),
                    background: Image.network(
                      "https://images.unsplash.com/photo-1542601098-3adb3baeb1ec?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=5bb9a9747954cdd6eabe54e3688a407e&auto=format&fit=crop&w=500&q=60",
                      fit: BoxFit.cover,
                    ));
              })
              //flexibleSpace: FlexibleSpaceBar(
              //  background:Image.network(organization.avatar)
              //),
              ),
          SliverFixedExtentList(
            itemExtent: 150.0,
            delegate: SliverChildListDelegate([
              PageTitle(
                title: organization.name,
                subtitle: organization.entityId,
                titleColor: titleColor.withOpacity(1.0 - opacity),
              ),
              Section(text: "Description"),
              Summary(
                text: organization.description[organization.languages[0]],
                maxLines: 5,
              ),
              Section(text: "Actions"),
              ListItem(
                text: "Activity",
                onTap: () {
                  Navigator.pushNamed(context, "/organizations/activity",
                      arguments: organization);
                },
              ),
              alreadySubscribed
                  ? buildAlreadySubscribed(
                      context, organization) // CUSTOM ACTIONS
                  : buildSubscriptionTiles(context, organization) // SUBSCRIBE
            ]),
          ),
        ]));
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
        onTap: () => confirmSubscribe(ctx),
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
