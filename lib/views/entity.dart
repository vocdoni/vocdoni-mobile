// import 'dart:io';
import "package:flutter/material.dart";
// import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
// import 'package:vocdoni/widgets/avatar.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';

import 'package:dvote/dvote.dart' show Entity;

class EntityInfo extends StatefulWidget {
  @override
  _EntityInfoState createState() => _EntityInfoState();
}

class _EntityInfoState extends State<EntityInfo> {
  bool collapsed = false;
  @override
  Widget build(context) {
    final Entity organization = ModalRoute.of(context).settings.arguments;
    if (organization == null) return buildEmptyOrganization(context);

    bool alreadySubscribed = false;
    if (appStateBloc.current != null &&
        appStateBloc.current.selectedIdentity >= 0) {
      final Identity currentIdentity =
          identitiesBloc.current[appStateBloc.current.selectedIdentity];
      if (currentIdentity != null &&
          currentIdentity.peers.entities.length > 0) {
        alreadySubscribed = currentIdentity.peers.entities
            .any((o) => o.entityId == organization.entityId);
      }
    }

    return ScaffoldWithImage(
        // headerImageUrl: organization.imageHeader ?? // TODO: Use dynamic image header
        headerImageUrl:
            "https://images.unsplash.com/photo-1557518016-299b3b3c2e7f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80",
        title: organization.name[organization.languages[0]] ?? "(entity)",
        collapsedTitle:
            organization.name[organization.languages[0]] ?? "(entity)",
        subtitle: organization.name[organization.languages[0]] ?? "(entity)",
        avatarUrl: organization.media.avatar,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(
                  getScaffoldChildren(ctx, organization, alreadySubscribed)),
            );
          },
        ));
  }

  getScaffoldChildren(
      BuildContext context, Entity organization, bool alreadySubscribed) {
    return [
      Section(text: "Description"),
      Summary(
        text: organization.description[organization.languages[0]],
        maxLines: 5,
      ),
      Section(text: "Actions"),
      /*  ListItem(
        text: "Subscribe",
        onTap: () => subscribeToOrganization(context, organization),
      ), */
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
    ];
  }

  /// NO ORGANIZATION

  Widget buildEmptyOrganization(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text("(No entity)"),
        ));
  }

  /// ALREADY REGISTERED CONTENT

  Widget buildAlreadySubscribed(BuildContext ctx, Entity organization) {
    // TODO: Handle all actions
    final List<Widget> actions = organization.actions
        .map((action) {
          if (action.type == "browser") {
            if (!(action.name is Map) ||
                !(action.name[organization.languages[0]] is String))
              return null;
            return ListItem(
              text: action.name[organization.languages[0]],
              onTap: () {
                final String url = action.url;
                final String title = action.name[organization.languages[0]] ??
                    organization.name[organization.languages[0]];

                final route = MaterialPageRoute(
                    builder: (context) => WebAction(
                          url: url,
                          title: title,
                        ));
                Navigator.push(ctx, route);
              },
            );
          } else if (action.type == "image") {
            return ListItem(text: "TO DO: EntityActionImage");
          } else {
            return null;
          }
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

  Widget buildSubscriptionTiles(BuildContext ctx, Entity organization) {
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
        organization.name[organization.languages[0]] ?? "(entity)",
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

  subscribeToOrganization(BuildContext ctx, Entity organization) async {
    final accepted = await showPrompt(
        context: ctx,
        title: Lang.of(ctx).get("Entity"),
        text: Lang.of(ctx).get("Do you want to subscribe to the entity?"),
        okButton: Lang.of(ctx).get("Subscribe"));

    if (accepted == false) return;

    try {
      await identitiesBloc.subscribe(organization);

      showMessage(Lang.of(ctx).get("The subscription has been registered"),
          context: ctx);
    } catch (err) {
      if (err == "Already subscribed") {
        showMessage(
            Lang.of(ctx).get("You are already subscribed to this entity"),
            context: ctx);
      } else {
        showMessage(
            Lang.of(ctx).get("The subscription could not be registered"),
            context: ctx);
      }
    }
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
