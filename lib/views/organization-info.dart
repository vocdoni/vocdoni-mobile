import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/summary.dart';
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

    double totalHeaderHeight = 350;
    double titleHeight = 50;
    double headerImageHeight = totalHeaderHeight - titleHeight;
    double pos = 0;
    double opacity = 0;

    return Scaffold(
        backgroundColor: baseBackgroundColor,
        body: CustomScrollView(controller: ScrollController(), slivers: [
          SliverAppBar(
              floating: false,
              snap: false,
              pinned: true,
              elevation: 0,
              //title: Text('SliverAppBar'),
              backgroundColor: baseBackgroundColor,
              expandedHeight: totalHeaderHeight,
              leading: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    FeatherIcons.arrowLeft,
                    color: collapsed ? descriptionColor : Colors.white,
                  )),
              flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                pos = constraints.biggest.height;
                // print('constraints=' + constraints.toString());
                double minAppBarHeight = 48;

                double o = ((pos - minAppBarHeight) / (titleHeight));
                opacity = o < 1 ? o : 1;
                debugPrint(opacity.toString());

                double collapseTrigger = 0.5;
                if (o < collapseTrigger && collapsed == false) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    setState(() {
                      collapsed = true;
                    });
                  });
                } else if (o >= collapseTrigger && collapsed == true) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    setState(() {
                      collapsed = false;
                    });
                  });
                }

                return FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    centerTitle: true,
                    title: Text(
                      organization.name,
                      style: TextStyle(
                          color: descriptionColor.withOpacity(1 - opacity),
                          fontWeight: lightFontWeight),
                    ),
                    background: Column(children: [
                      Expanded(
                        child: Image.network(
                            "https://images.unsplash.com/photo-1557518016-299b3b3c2e7f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80",
                            fit: BoxFit.cover,
                            height: headerImageHeight,
                            width: double.infinity),
                      ),
                      PageTitle(
                        title: organization.name,
                        subtitle: organization.entityId,
                        titleColor: titleColor.withOpacity(opacity),
                      ),
                      //ListItem( text: opacity.toString(),)
                    ]));
              })),
          SliverList(
            delegate: SliverChildListDelegate([
              Section(text: "Description"),
              Summary(
                text: organization.description[organization.languages[0]],
                maxLines: 5,
              ),
              Summary(
                text: organization.description[organization.languages[0]],
                maxLines: 10,
              ),
              Section(text: "Actions"),
              ListItem(
                text: "Activity",
                onTap: () {
                  Navigator.pushNamed(context, "/organizations/activity",
                      arguments: organization);
                },
              ),
              (alreadySubscribed
                  ? buildAlreadySubscribed(
                      context, organization) // CUSTOM ACTIONS
                  : buildSubscriptionTiles(context, organization) // SUBSCRIBE

              ),
            ]),
          ),
          Section(text: "Description"),
          Summary(text: organization.description[organization.languages[0]], maxLines: 5,),
          Section(text: "Actions"),
          ListItem(
            text: "Activity",
            onTap: () {
              Navigator.pushNamed(context, "/organizations/activity",
                  arguments: organization);
            },
          ),
          alreadySubscribed
              ? buildAlreadySubscribed(context, organization) // CUSTOM ACTIONS
              : buildSubscriptionTiles(context, organization) // SUBSCRIBE
        ],
      ),
    );
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
                            title: action["name"][organization.languages[0]] ?? organization.name,
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
