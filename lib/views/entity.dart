import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';
import 'package:http/http.dart' as http;
import 'package:vocdoni/constants/colors.dart';

class EntityInfo extends StatefulWidget {
  @override
  _EntityInfoState createState() => _EntityInfoState();
}

class _EntityInfoState extends State<EntityInfo> {
  bool collapsed = false;
  bool processingSubscription = false;
  List<Entity_Action> actionsToDisplay = [];
  bool actionsLoading = false;

  @override
  Widget build(context) {
    final Entity entity = ModalRoute.of(context).settings.arguments;
    if (entity == null) return buildEmptyEntity(context);

    if (!actionsLoading) {
      setActionsToDisplay(context, entity);
      actionsLoading = true;
    }

    return ScaffoldWithImage(
        headerImageUrl: entity.media.header,
        title: entity.name[entity.languages[0]] ?? "(entity)",
        collapsedTitle: entity.name[entity.languages[0]] ?? "(entity)",
        subtitle: entity.name[entity.languages[0]] ?? "(entity)",
        avatarUrl: entity.media.avatar,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate:
                  SliverChildListDelegate(getScaffoldChildren(ctx, entity)),
            );
          },
        ));
  }

  getScaffoldChildren(BuildContext context, Entity entity) {
    List<Widget> children = [];
    children.add(buildSubscribeItem(context, entity));
    children.addAll(buildActionList(context, entity));
    children.add(ListItem(
      icon: FeatherIcons.rss,
      mainText: "Feed",
      onTap: () {
        Navigator.pushNamed(context, "/entity/activity", arguments: entity);
      },
    ));
    children.add(Section(text: "Details"));
    children.add(Summary(
      text: entity.description[entity.languages[0]],
      maxLines: 5,
    ));
    return children;
  }

  buildSubscribeItem(BuildContext context, Entity entity) {
    Identity account = identitiesBloc.getCurrentAccount();
    bool isSubscribed = identitiesBloc.isSubscribed(account, entity);
    String subscribeText = isSubscribed ? "Subscribed" : "Subscribe";
    return ListItem(
      mainText: subscribeText,
      icon: FeatherIcons.heart,
      disabled: processingSubscription,
      rightIcon: isSubscribed ? FeatherIcons.check : null,
      rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
      // purpose: Purpose.HIGHLIGHT,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, entity)
          : subscribeToEntity(context, entity),
    );
  }

  dynamic sign(String payload) async {
    //TODO
    return "";
  }

  Future<bool> actionIsVisible(Entity_Action action) async {
    if (action.visible == null) return true;

    if (action.visible == "always") return true;

    String publicKey = identitiesBloc.getCurrentAccount().identityId;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    dynamic payload = {
      'publicKey': publicKey,
      'signature': sign(timestamp.toString())
    };

    var response = await http.post(action.visible, body: payload);
    if (response.statusCode != 200) return false;

    if (response.body == "true") return true;

    return false;
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text("(No entity)"),
        ));
  }

  Future<List<ListItem>> setActionsToDisplay(
      BuildContext ctx, Entity entity) async {
    final List<ListItem> actionsToShow = [];

    for (Entity_Action action in entity.actions) {
      var show = await actionIsVisible(action);
      setState(() {
        actionsToDisplay.add(action);
      });
    }
  }

  List<ListItem> buildActionList(BuildContext ctx, Entity entity) {
    final List<ListItem> actionsToShow = [];

    if (actionsToDisplay.length == 0)
      return [
        ListItem(
          mainText: "No Actions definied",
          disabled: true,
          rightIcon: null,
          icon: FeatherIcons.helpCircle,
        )
      ];

    for (Entity_Action action in actionsToDisplay) {
      ListItem item;
      if (action.type == "browser") {
        if (!(action.name is Map) ||
            !(action.name[entity.languages[0]] is String)) return null;

        item = ListItem(
          icon: FeatherIcons.arrowRightCircle,
          mainText: action.name[entity.languages[0]],
          secondaryText: action.visible,
          onTap: () {
            final String url = action.url;
            final String title = action.name[entity.languages[0]] ??
                entity.name[entity.languages[0]];

            final route = MaterialPageRoute(
                builder: (context) => WebAction(
                      url: url,
                      title: title,
                    ));
            Navigator.push(ctx, route);
          },
        );
      } else {
        item = ListItem(
          mainText: action.name[entity.languages[0]],
          secondaryText: "Action type not supported yet: " + action.type,
          icon: FeatherIcons.helpCircle,
          disabled: true,
        );
      }

      actionsToShow.add(item);
    }

    return actionsToShow;
  }

  unsubscribeFromEntity(BuildContext ctx, Entity entity) async {
    setState(() {
      processingSubscription = true;
    });
    Identity account = identitiesBloc.getCurrentAccount();
    await identitiesBloc.unsubscribeEntityFromAccount(entity, account);
    showMessage(Lang.of(ctx).get("You are no longer subscribed"), context: ctx);
    setState(() {
      processingSubscription = false;
    });
  }

  subscribeToEntity(BuildContext ctx, Entity entity) async {
    setState(() {
      processingSubscription = true;
    });

    try {
      Identity account = identitiesBloc.getCurrentAccount();
      await identitiesBloc.subscribeEntityToAccount(entity, account);

      showMessage(Lang.of(ctx).get("You are now subscribed"), context: ctx);
    } catch (err) {
      if (err == "Already subscribed") {
        showMessage(
            Lang.of(ctx).get(
              "You are already subscribed to this entity",
            ),
            context: ctx,
            purpose: Purpose.DANGER);
      } else {
        showMessage(
            Lang.of(ctx).get("The subscription could not be registered"),
            context: ctx,
            purpose: Purpose.DANGER);
      }
    }
    setState(() {
      processingSubscription = false;
    });
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
