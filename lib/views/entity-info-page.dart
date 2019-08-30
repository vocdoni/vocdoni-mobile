import 'dart:convert';

import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';
import 'package:http/http.dart' as http;
import 'package:vocdoni/constants/colors.dart';

class EntityInfoPage extends StatefulWidget {
  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  Ent _ent;
  String _status = ''; // loading, ok, fail, disposed
  bool _processingSubscription = false;
  EntityMetadata_Action _registerAction;
  List<EntityMetadata_Action> _actionsToDisplay = [];
  bool _isRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_status == "disposed") return;

    try {
      _ent = ModalRoute.of(super.context).settings.arguments;
      refresh();
      if (_ent == null) return;
      fetchVisibleActions(_ent);
    } catch (err) {
      print(err);
    }
  }

  @override
  void dispose() {
    setState(() {
      _status = "disposed";
    });
    super.dispose();
  }

  @override
  Widget build(context) {
    //final Ent ent = ModalRoute.of(context).settings.arguments;
    return _ent.entityMetadata == null
        ? buildScaffoldWithoutMetadata(_ent)
        : buildScaffold(_ent);
  }

  buildScaffoldWithoutMetadata(Ent ent) {
    return ScaffoldWithImage(
        headerImageUrl: null,
        headerTag: null,
        appBarTitle: "Loading",
        avatarUrl: null,
        avatarHexSource: ent.entitySummary.entityId,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
                delegate: SliverChildListDelegate(
              [
                buildTitleWithoutEntityMeta(ctx, ent),
                buildStatus(_status),
              ],
            ));
          },
        ));
  }

  Widget buildStatus(String status) {
    if (status == "loading")
      return ListItem(
        mainText: "Loading details...",
        rightIcon: null,
      );
    if (status == "fail")
      return ListItem(
        mainText: "Unable to load details",
        purpose: Purpose.DANGER,
        rightIcon: FeatherIcons.refreshCw,
        onTap: refresh,
      );
    if (status == "ok") return Container();
  }

  buildScaffold(Ent ent) {
    return ScaffoldWithImage(
        headerImageUrl: ent.entityMetadata.media.header,
        headerTag: ent.entitySummary.entityId + ent.entityMetadata.media.header,
        appBarTitle: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
        avatarUrl: ent.entityMetadata.media.avatar,
        avatarText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
        avatarHexSource: ent.entitySummary.entityId,
        leftElement: buildRegisterButton(context, ent),
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(getScaffoldChildren(ctx, ent)),
            );
          },
        ));
  }

  List<Widget> actionsBuilder(BuildContext context) {
    final Ent ent = ModalRoute.of(context).settings.arguments;
    return [
      buildShareButton(context, ent),
      SizedBox(height: 48, width: paddingPage),
      buildSubscribeButton(context, ent),
      SizedBox(height: 48, width: paddingPage)
    ];
  }

  buildTest() {
    double avatarHeight = 120;
    return Container(
      height: avatarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            constraints:
                BoxConstraints(minWidth: avatarHeight, minHeight: avatarHeight),
            child: CircleAvatar(
                backgroundColor: Colors.indigo,
                backgroundImage: NetworkImage(
                    "https://instagram.fmad5-1.fna.fbcdn.net/vp/564db12bde06a8cb360e31007fd049a6/5DDF1906/t51.2885-19/s150x150/13167299_1084444071617255_680456677_a.jpg?_nc_ht=instagram.fmad5-1.fna.fbcdn.net")),
          ),
        ],
      ),
    );
  }

  getScaffoldChildren(BuildContext context, Ent ent) {
    List<Widget> children = [];
    //children.add(buildTest());
    children.add(buildTitle(context, ent));
    children.add(buildSubscribeItem(context, ent));
    children.add(buildFeedItem(context, ent));
    children.addAll(buildActionList(context, ent));
    children.add(Section(text: "Details"));
    children.add(Summary(
      text: ent.entityMetadata.description[ent.entityMetadata.languages[0]],
      maxLines: 5,
    ));

    return children;
  }

  buildTitle(BuildContext context, Ent ent) {
    String title = ent.entityMetadata.name[ent.entityMetadata.languages[0]];
    return ListItem(
      mainTextTag: ent.entitySummary.entityId + title,
      mainText: title,
      secondaryText: ent.entitySummary.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildTitleWithoutEntityMeta(BuildContext context, Ent ent) {
    return ListItem(
      mainText: "...",
      secondaryText: ent.entitySummary.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildFeedItem(BuildContext context, Ent ent) {
    return ListItem(
      icon: FeatherIcons.rss,
      mainText: "Feed",
      onTap: () {
        Navigator.pushNamed(context, "/entity/feed", arguments: ent);
      },
    );
  }

  buildSubscribeItem(BuildContext context, Ent ent) {
    //Identity account = identitiesBloc.getCurrentAccount();
    bool isSubscribed = account.isSubscribed(ent.entitySummary);
    String subscribeText = isSubscribed ? "Subscribed" : "Subscribe";
    return ListItem(
      mainText: subscribeText,
      icon: FeatherIcons.heart,
      disabled: _processingSubscription,
      rightIcon: isSubscribed ? FeatherIcons.check : null,
      rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
      // purpose: Purpose.HIGHLIGHT,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, ent)
          : subscribeToEntity(context, ent),
    );
  }

  buildSubscribeButton(BuildContext context, Ent ent) {
    //Identity account = identitiesBloc.getCurrentAccount();
    bool isSubscribed = account.isSubscribed(ent.entitySummary);
    String subscribeText = isSubscribed ? "Following" : "Follow";
    return BaseButton(
      text: subscribeText,
      leftIconData: isSubscribed ? FeatherIcons.check : FeatherIcons.plus,
      isDisabled: _processingSubscription,
      isSmall: true,
      style: BaseButtonStyle.OUTLINE_WHITE,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, ent)
          : subscribeToEntity(context, ent),
    );
  }

  buildShareButton(BuildContext context, Ent ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: ent.entitySummary.entityId));
          showMessage("Identity ID copied on the clipboard",
              context: context, purpose: Purpose.GUIDE);
        });
  }

  Future<bool> isActionVisible(
      EntityMetadata_Action action, String entityId) async {
    if (action.visible == "true") return true;
    if (action.visible == null || action.visible == "false") return false;

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

  Future<void> fetchVisibleActions(Ent ent) async {
    final List<EntityMetadata_Action> actionsToDisplay = [];
    EntityMetadata_Action registerAction;

    if (ent.entityMetadata == null) return;

    for (EntityMetadata_Action action in ent.entityMetadata.actions) {
      if (action.register == true) {
        if (registerAction != null)
          continue; //only one registerAction is supported
        registerAction = action;
        bool isRegistered =
            await isActionVisible(action, ent.entitySummary.entityId);
        setState(() {
          _registerAction = registerAction;
          _isRegistered = isRegistered;
        });
      } else {
        if (await isActionVisible(action, ent.entitySummary.entityId)) {
          actionsToDisplay.add(action);
        }
      }
    }
    setState(() {
      _actionsToDisplay = actionsToDisplay;
    });
  }

  EntityMetadata_Action getRegisterAction(EntityMetadata entity) {
    for (EntityMetadata_Action action in entity.actions) {
      if (action.register == true) return action;
    }
    return null;
  }

  Widget buildRegisterButton(BuildContext ctx, Ent ent) {
    if (_registerAction == null) return Container();

    if (_isRegistered)
      return BaseButton(
        purpose: Purpose.GUIDE,
        leftIconData: FeatherIcons.check,
        text: "Registered",
        isSmall: true,
        style: BaseButtonStyle.FILLED,
        isDisabled: true,
      );
    else
      return BaseButton(
        purpose: Purpose.HIGHLIGHT,
        leftIconData: FeatherIcons.feather,
        text: "Register",
        isSmall: true,
        onTap: () {
          if (_registerAction.type == "browser") {
            onBrowserAction(ctx, _registerAction, ent);
          }
        },
      );
  }

  List<Widget> buildActionList(BuildContext ctx, Ent ent) {
    final List<Widget> actionsToShow = [];

    actionsToShow.add(Section(text: "Actions"));

    if (_actionsToDisplay.length == 0 || _registerAction == null) {
      return [
        ListItem(
          mainText: "No Actions definied",
          disabled: true,
          rightIcon: null,
          icon: FeatherIcons.helpCircle,
        )
      ];
    }

    bool actionsDisabled = false;
    if (!_isRegistered) {
      actionsDisabled = true;
      final entityName =
          ent.entityMetadata.name[ent.entityMetadata.languages[0]];
      ListItem noticeItem = ListItem(
        mainText: "Regsiter to $entityName first",
        secondaryText: null,
        rightIcon: null,
        disabled: false,
        purpose: Purpose.HIGHLIGHT,
      );
      actionsToShow.add(noticeItem);
    }

    for (EntityMetadata_Action action in _actionsToDisplay) {
      ListItem item;
      if (action.type == "browser") {
        if (!(action.name is Map) ||
            !(action.name[ent.entityMetadata.languages[0]] is String))
          return null;

        item = ListItem(
          icon: FeatherIcons.arrowRightCircle,
          mainText: action.name[ent.entityMetadata.languages[0]],
          secondaryText: action.visible,
          disabled: actionsDisabled,
          onTap: () {
            onBrowserAction(ctx, action, ent);
          },
        );
      } else {
        item = ListItem(
          mainText: action.name[ent.entityMetadata.languages[0]],
          secondaryText: "Action type not supported yet: " + action.type,
          icon: FeatherIcons.helpCircle,
          disabled: true,
        );
      }

      actionsToShow.add(item);
    }

    return actionsToShow;
  }

  onBrowserAction(BuildContext ctx, EntityMetadata_Action action, Ent ent) {
    final String url = action.url;
    final String title = action.name[ent.entityMetadata.languages[0]] ??
        ent.entityMetadata.name[ent.entityMetadata.languages[0]];

    final route = MaterialPageRoute(
        builder: (context) => WebAction(
              url: url,
              title: title,
            ));
    Navigator.push(ctx, route);
  }

  unsubscribeFromEntity(BuildContext ctx, Ent ent) async {
    setState(() {
      _processingSubscription = true;
    });
    account.unsubscribe(ent.entitySummary);
    showMessage(
        Lang.of(ctx)
            .get("You will no longer see this organization in your feed"),
        context: ctx,
        purpose: Purpose.NONE);
    setState(() {
      _processingSubscription = false;
    });
  }

  subscribeToEntity(BuildContext ctx, Ent ent) async {
    setState(() {
      _processingSubscription = true;
    });

    try {
      await account.subscribe(ent);

      showMessage(Lang.of(ctx).get("Organization successfully added"),
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
      _processingSubscription = false;
    });
  }

  refresh() async {
    if (_status == "disposed") return;

    try {
      setState(() {
        _status = "loading";
      });
      await _ent.update();
      if (_status == "disposed") return;
      setState(() {
        _ent = _ent;
        _status = "ok";
      });
    } catch (err) {
      setState(() {
        _ent = _ent;

        _status = "fail";
      });
    }
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
