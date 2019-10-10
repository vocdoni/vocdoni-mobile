import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/modals/web-action.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';
import 'package:vocdoni/constants/colors.dart';

class EntityInfoPage extends StatefulWidget {
  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  Ent _ent;
  bool _processingSubscription = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      EntityReference entityReference =
          ModalRoute.of(super.context).settings.arguments;

      analytics.trackPage(
          pageId: "EntityInfoPage", entityId: entityReference.entityId);
      _ent = account.getEnt(entityReference);
      if (_ent == null) _ent = new Ent(entityReference);

      refresh();
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    return StateBuilder(
        viewModels: [_ent],
        tag: [EntTags.ENTITY_METADATA],
        builder: (ctx, tagId) {
          return _ent.entityMetadata == null
              ? buildScaffoldWithoutMetadata(_ent)
              : buildScaffold(_ent);
        });
  }

  buildScaffoldWithoutMetadata(Ent ent) {
    return ScaffoldWithImage(
        headerImageUrl: null,
        headerTag: null,
        forceHeader: true,
        appBarTitle: "Loading",
        avatarText: "",
        avatarHexSource: ent.entityReference.entityId,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
                delegate: SliverChildListDelegate(
              [
                buildTitleWithoutEntityMeta(ctx, ent),
                buildStatus(),
              ],
            ));
          },
        ));
  }

  Widget buildStatus() {
    if (_ent.entityMetadataDataState == DataState.CHECKING)
      return ListItem(
        mainText: "Updating details...",
        rightIcon: null,
        isSpinning: true,
      );
    if (_ent.entityMetadataDataState == DataState.ERROR)
      return ListItem(
        mainText: "Unable to load details",
        purpose: Purpose.DANGER,
        rightTextPurpose: Purpose.DANGER,
        onTap: refresh,
        rightIcon: FeatherIcons.refreshCw,
      );
    else if (_ent.feedDataState == DataState.ERROR)
      return ListItem(
        mainText: "Unable to load feed",
        purpose: Purpose.DANGER,
        rightTextPurpose: Purpose.DANGER,
        onTap: refresh,
        rightIcon: FeatherIcons.refreshCw,
      );
    else
      return Container();
  }

  buildScaffold(Ent ent) {
    return StateBuilder(
        viewModels: [_ent],
        tag: EntTags.ENTITY_METADATA,
        builder: (ctx, tagId) {
          return ScaffoldWithImage(
              headerImageUrl: ent.entityMetadata.media.header,
              headerTag: ent.entityReference.entityId +
                  ent.entityMetadata.media.header,
              forceHeader: true,
              appBarTitle:
                  ent.entityMetadata.name[ent.entityMetadata.languages[0]],
              avatarUrl: ent.entityMetadata.media.avatar,
              avatarText:
                  ent.entityMetadata.name[ent.entityMetadata.languages[0]],
              avatarHexSource: ent.entityReference.entityId,
              leftElement: buildRegisterButton(context, ent),
              actionsBuilder: actionsBuilder,
              builder: Builder(
                builder: (ctx) {
                  return SliverList(
                    delegate:
                        SliverChildListDelegate(getScaffoldChildren(ctx, ent)),
                  );
                },
              ));
        });
  }

  List<Widget> actionsBuilder(BuildContext context) {
    return [
      buildShareButton(context, _ent),
      SizedBox(height: 48, width: paddingPage),
      buildSubscribeButton(context, _ent),
      SizedBox(height: 48, width: paddingPage)
    ];
  }

  getScaffoldChildren(BuildContext context, Ent ent) {
    List<Widget> children = [];
    children.add(buildTitle(context, ent));
    children.add(buildStatus());
    children.add(buildFeedItem(context));
    children.add(buildParticipationItem(context, ent));
    children.add(buildActionList(context, ent));
    children.add(Section(text: "Details"));
    children.add(Summary(
      text: ent.entityMetadata.description[ent.entityMetadata.languages[0]],
      maxLines: 5,
    ));
    children.add(Section(text: "Manage"));
    children.add(buildShareItem(context, ent));
    children.add(buildSubscribeItem(context, ent));

    return children;
  }

  buildTitle(BuildContext context, Ent ent) {
    String title = ent.entityMetadata.name[ent.entityMetadata.languages[0]];
    return ListItem(
      mainTextTag: ent.entityReference.entityId + title,
      mainText: title,
      secondaryText: ent.entityReference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildTitleWithoutEntityMeta(BuildContext context, Ent ent) {
    return ListItem(
      mainText: "...",
      secondaryText: ent.entityReference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildFeedItem(BuildContext context) {
    return StateBuilder(
        viewModels: [_ent],
        tag: EntTags.FEED,
        builder: (ctx, tagId) {
          int postsNum = 0;
          if (_ent.feed != null) postsNum = _ent.feed.items.length;
          return ListItem(
            icon: FeatherIcons.rss,
            mainText: "Feed",
            rightText: postsNum.toString(),
            rightTextIsBadge: true,
            disabled: postsNum == 0,
            onTap: () {
              Navigator.pushNamed(context, "/entity/feed", arguments: _ent);
            },
          );
        });
  }

  buildParticipationItem(BuildContext context, Ent ent) {
    int processNum = 0;
    if (ent.processess != null) processNum = ent.processess.length;
    return ListItem(
      icon: FeatherIcons.mail,
      mainText: "Participation",
      rightText: processNum.toString(),
      rightTextIsBadge: true,
      disabled: processNum == 0,
      onTap: () {
        Navigator.pushNamed(context, "/entity/participation", arguments: ent.entityReference);
      },
    );
  }

  buildSubscribeItem(BuildContext context, Ent ent) {
    bool isSubscribed = account.isSubscribed(ent.entityReference);
    String subscribeText = isSubscribed ? "Following" : "Follow";
    return ListItem(
      mainText: subscribeText,
      icon: FeatherIcons.heart,
      disabled: _processingSubscription,
      isSpinning: _processingSubscription,
      rightIcon: isSubscribed ? FeatherIcons.check : null,
      rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, ent)
          : subscribeToEntity(context, ent),
    );
  }

  buildSubscribeButton(BuildContext context, Ent ent) {
    bool isSubscribed = account.isSubscribed(ent.entityReference);
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

  buildShareItem(BuildContext context, Ent ent) {
    return ListItem(
        mainText: "Share organization",
        icon: FeatherIcons.share2,
        rightIcon: null,
        onTap: () {
          onShare(ent);
        });
  }

  buildShareButton(BuildContext context, Ent ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          onShare(ent);
        });
  }

  onShare(Ent ent) {
    Clipboard.setData(ClipboardData(text: ent.entityReference.entityId));
    showMessage("Identity ID copied on the clipboard",
        context: context, purpose: Purpose.GUIDE);
  }

  EntityMetadata_Action getRegisterAction(EntityMetadata entity) {
    for (EntityMetadata_Action action in entity.actions) {
      if (action.register == true) return action;
    }
    return null;
  }

  Widget buildRegisterButton(BuildContext ctx, Ent ent) {
    return StateBuilder(
        viewModels: [_ent],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          if (_ent.registerAction == null) return Container();

          if (_ent.isRegistered)
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
                if (_ent.registerAction.type == "browser") {
                  onBrowserAction(ctx, _ent.registerAction, ent);
                }
              },
            );
        });
  }

  Widget buildActionList(BuildContext ctx, Ent ent) {
    return StateBuilder(
        viewModels: [_ent],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          final List<Widget> actionsToShow = [];

          actionsToShow.add(Section(text: "Actions"));

          if (_ent.visibleActions.length == 0 || _ent.registerAction == null) {
            return ListItem(
              mainText: "No actions defined",
              disabled: true,
              rightIcon: null,
              icon: FeatherIcons.helpCircle,
            );
          }

          bool actionsDisabled = false;
          if (!_ent.isRegistered) {
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

          for (EntityMetadata_Action action in _ent.visibleActions) {
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

          return ListView(children: actionsToShow);
        });
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
    await account.unsubscribe(ent.entityReference);
    showMessage(
        Lang.of(ctx)
            .get("You will no longer see this organization in your feed"),
        context: ctx,
        purpose: Purpose.NONE);
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _processingSubscription = false;
    });
  }

  refresh() async {
    _ent.update();
/*
    String errorMessage = "";
    bool fail = false;

    if (_ent.entityMetadataDataState == DataState.ERROR) {
      errorMessage = "Unable to retrieve details";
      fail = true;
    } else if (_ent.processessMetadataUpdated == false) {
      errorMessage = "Unable to retrieve processess";
      fail = true;
    } else if (_ent.feedUpdated == false) {
      errorMessage = "Unable to retrieve news feed";
      fail = true;
    }

    if (!mounted) return;
    setState(() {
      _ent = _ent;
      _status = fail ? "fail" : "ok";
      _errorMessage = errorMessage;
    });
*/

    if (account.isSubscribed(_ent.entityReference)) _ent.save();
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
