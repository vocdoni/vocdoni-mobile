import 'dart:convert';

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
  Entity_Action registerAction;
  List<Entity_Action> actionsToDisplay = [];
  bool actionsLoading = false;
  bool _isRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final entity = ModalRoute.of(super.context).settings.arguments;
      if (entity == null) return;
      fetchVisibleActions(entity);
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    final Entity entity = ModalRoute.of(context).settings.arguments;
    if (entity == null) return buildEmptyEntity(context);

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
    children.add(buildRegisterItem(context, entity));
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

  Future<bool> isActionVisible(Entity_Action action, String entityId) async {
    if (action.visible == null || action.visible == "always") return true;

    String publicKey = identitiesBloc.getCurrentAccount().identityId;
    int timestamp = new DateTime.now().millisecondsSinceEpoch;

    // TODO: Get the private key to sign appropriately
    final privateKey = "";
    debugPrint(
        "TODO: Retrieve the private key to sign the action visibility request");

    try {
      Map payload = {
        "type": action.type,
        'publicKey': publicKey,
        "entityId": entityId,
        "timestamp": timestamp,
        "signature": ""
      };

      if (privateKey != "") {
        payload["signature"] = await signString(
            jsonEncode({"timestamp": timestamp.toString()}), privateKey);
      } else {
        payload["signature"] = "0x"; // TODO: TEMP
      }

      Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
      };

      var response = await http.post(action.visible,
          body: jsonEncode(payload), headers: headers);
      if (response.statusCode != 200 || !(response.body is String))
        return false;
      final body = jsonDecode(response.body);
      if (body is Map && body["visible"] == true) return true;
    } catch (err) {
      return false;
    }

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

  Future<void> fetchVisibleActions(Entity entity) async {
    final List<Entity_Action> toDisplay = [];
    Entity_Action register;

    setState(() {
      actionsLoading = true;
    });

    for (Entity_Action action in entity.actions) {
      if (action.register == true) {
        if (register != null) continue; //only one registerAction is supported
        register = action;
        bool isRegistered = await isActionVisible(action, entity.entityId);
        setState(() {
          registerAction = register;
          _isRegistered = isRegistered;
        });
      } else {
        if (await isActionVisible(action, entity.entityId)) {
          toDisplay.add(action);
        }
      }
    }
    setState(() {
      actionsLoading = false;
      actionsToDisplay = toDisplay;
    });
  }

  Entity_Action getRegisterAction(Entity entity) {
    for (Entity_Action action in entity.actions) {
      if (action.register == true) return action;
    }
    return null;
  }

  /*bool isUserRegistered(Entity entity) async{
    final registerAction = getRegisterAction(entity);
    if(registerAction==null)
      return false;
    return isActionVisible(registerAction, entity.entityId);

  }*/

  Widget buildRegisterItem(BuildContext ctx, Entity entity) {
    if (registerAction == null) return Container();

    if (_isRegistered)
      return ListItem(
        mainText: "Registered",
        rightIcon: null,
        icon: FeatherIcons.checkCircle,
      );
    else
      return ListItem(
        mainText: "Register now",
        rightIcon: null,
        icon: FeatherIcons.arrowDownCircle,
        onTap: () {
          if (registerAction.type == "browser") {
            onBrowserAction(ctx, registerAction, entity);
          }
        },
      );
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
            onBrowserAction(ctx, action, entity);
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

  onBrowserAction(BuildContext ctx, Entity_Action action, Entity entity) {
    final String url = action.url;
    final String title =
        action.name[entity.languages[0]] ?? entity.name[entity.languages[0]];

    final route = MaterialPageRoute(
        builder: (context) => WebAction(
              url: url,
              title: title,
            ));
    Navigator.push(ctx, route);
  }

  unsubscribeFromEntity(BuildContext ctx, Entity entity) async {
    setState(() {
      processingSubscription = true;
    });
    Identity account = identitiesBloc.getCurrentAccount();
    await identitiesBloc.unsubscribeEntityFromAccount(entity, account);
    showMessage(Lang.of(ctx).get("You are no longer subscribed"),
        context: ctx, purpose: Purpose.NONE);
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

      showMessage(Lang.of(ctx).get("You are now subscribed"),
          context: ctx, purpose: Purpose.GOOD);
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
