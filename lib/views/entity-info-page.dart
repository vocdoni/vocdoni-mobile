import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/data-models/entModel.dart';
import 'package:vocdoni/view-modals/web-action.dart';
import 'package:vocdoni/lib/singletons.dart';
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
  final EntityReference entityReference;

  EntityInfoPage(this.entityReference) {
    analytics.trackPage("EntityInfoPage", entityId: entityReference.entityId);
  }

  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  bool _processingSubscription = false;
  EntModel entityModel;

  @override
  void initState() {
    super.initState();

    entityModel = account.findEntity(widget.entityReference);
    // Ensure subscribtion as we visit it
    if (!account.isSubscribed(widget.entityReference))
      account.subscribe(entityModel);
      
    entityModel.updateWithDelay();
  }

  @override
  Widget build(context) {
    return StateBuilder(
        viewModels: [entityModel],
        tag: [EntTags.ENTITY_METADATA],
        builder: (ctx, tagId) {
          return entityModel.entityMetadata.hasValue
              ? buildScaffold(entityModel)
              : buildScaffoldWithoutMetadata(entityModel);
        });
  }

  buildScaffoldWithoutMetadata(EntModel ent) {
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
    if (entityModel.entityMetadata.isLoading)
      return ListItem(
        mainText: "Fetching details...",
        rightIcon: null,
        isSpinning: true,
      );
    if (entityModel.entityMetadata.hasError)
      return ListItem(
        mainText: entityModel.entityMetadata.errorMessage,
        purpose: Purpose.DANGER,
        rightTextPurpose: Purpose.DANGER,
        onTap: refresh,
        rightIcon: FeatherIcons.refreshCw,
      );
    else if (entityModel.feed.hasError)
      return ListItem(
        mainText: entityModel.feed.errorMessage,
        purpose: Purpose.DANGER,
        rightTextPurpose: Purpose.DANGER,
        onTap: refresh,
        rightIcon: FeatherIcons.refreshCw,
      );
    else
      return Container();
  }

  buildScaffold(EntModel ent) {
    return StateBuilder(
        viewModels: [entityModel],
        tag: EntTags.ENTITY_METADATA,
        builder: (ctx, tagId) {
          return ScaffoldWithImage(
              headerImageUrl: ent.entityMetadata.value.media.header,
              headerTag: ent.entityReference.entityId +
                  ent.entityMetadata.value.media.header,
              forceHeader: true,
              appBarTitle: ent.entityMetadata.value
                  .name[ent.entityMetadata.value.languages[0]],
              avatarUrl: ent.entityMetadata.value.media.avatar,
              avatarText: ent.entityMetadata.value
                  .name[ent.entityMetadata.value.languages[0]],
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
      buildShareButton(context, entityModel),
      SizedBox(height: 48, width: paddingPage),
      //buildSubscribeButton(context, entityModel),
      //SizedBox(height: 48, width: paddingPage)
    ];
  }

  getScaffoldChildren(BuildContext context, EntModel ent) {
    List<Widget> children = [];
    children.add(buildTitle(context, ent));
    children.add(buildStatus());
    children.add(buildFeedItem(context));
    children.add(buildParticipationItem(context));
    children.add(buildActionList(context, ent));
    children.add(Section(text: "Details"));
    children.add(Summary(
      text: ent.entityMetadata.value
          .description[ent.entityMetadata.value.languages[0]],
      maxLines: 5,
    ));
    children.add(Section(text: "Manage"));
    children.add(buildShareItem(context, ent));
    children.add(buildSubscribeItem(context));

    return children;
  }

  buildTitle(BuildContext context, EntModel ent) {
    String title =
        ent.entityMetadata.value.name[ent.entityMetadata.value.languages[0]];
    return ListItem(
      heroTag: ent.entityReference.entityId + title,
      mainText: title,
      secondaryText: ent.entityReference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildTitleWithoutEntityMeta(BuildContext context, EntModel ent) {
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
        viewModels: [entityModel],
        tag: EntTags.FEED,
        builder: (ctx, tagId) {
          String postsNum = "0";
          if (entityModel.feed.hasValue) {
            if (entityModel.feed.hasError) {
              postsNum =
                  (entityModel.feed.value?.items?.length.toString() ?? "0") +
                      " !";
            } else {
              postsNum = entityModel.feed.value.items.length.toString();
            }
          } else {
            if (entityModel.feed.hasError) {
              postsNum = "!";
            } else {
              postsNum = "0";
            }
          }

          return ListItem(
            icon: FeatherIcons.rss,
            mainText: "Feed",
            rightText: postsNum,
            rightTextIsBadge: true,
            rightTextPurpose: entityModel.feed.hasError ? Purpose.DANGER : null,
            disabled: postsNum == "0",
            onTap: () {
              Navigator.pushNamed(context, "/entity/feed",
                  arguments: entityModel);
            },
          );
        });
  }

  buildParticipationItem(BuildContext context) {
    return StateBuilder(
        viewModels: [entityModel],
        tag: EntTags.PROCESSES,
        builder: (ctx, tagId) {
          int processNum = 0;
          if (entityModel.processes.hasValue)
            processNum = entityModel.processes.value.length;
          return ListItem(
              icon: FeatherIcons.mail,
              mainText: "Participation",
              rightText: processNum.toString(),
              rightTextIsBadge: true,
              disabled: processNum == 0,
              onTap: () {
                Navigator.pushNamed(context, "/entity/participation",
                    arguments: entityModel.entityReference);
              });
        });
  }

  buildSubscribeItem(BuildContext context) {
    bool isSubscribed = account.isSubscribed(entityModel.entityReference);
    String subscribeText = isSubscribed ? "Following" : "Follow";
    return ListItem(
      mainText: subscribeText,
      icon: FeatherIcons.heart,
      disabled: _processingSubscription,
      isSpinning: _processingSubscription,
      rightIcon: isSubscribed ? FeatherIcons.check : null,
      rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, entityModel)
          : subscribeToEntity(context, entityModel),
    );
  }

  buildSubscribeButton(BuildContext context, EntModel ent) {
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

  buildShareItem(BuildContext context, EntModel ent) {
    return ListItem(
        mainText: "Share organization",
        icon: FeatherIcons.share2,
        rightIcon: null,
        onTap: () {
          onShare(ent);
        });
  }

  buildShareButton(BuildContext context, EntModel ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          onShare(ent);
        });
  }

  onShare(EntModel ent) {
    Clipboard.setData(ClipboardData(text: ent.entityReference.entityId));
    showMessage("Identity ID copied on the clipboard",
        context: context, purpose: Purpose.GUIDE);
  }

  Widget buildRegisterButton(BuildContext ctx, EntModel ent) {
    return StateBuilder(
        viewModels: [entityModel],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          if (entityModel.isRegistered.hasError ||
              entityModel.registerAction.hasError) return Container();

          if (entityModel.isRegistered.hasValue) {
            if (entityModel.isRegistered.value)
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
                  if (entityModel.registerAction.value.type == "browser") {
                    onBrowserAction(ctx, entityModel.registerAction.value, ent);
                  }
                },
              );
          }
        });
  }

  Widget buildActionList(BuildContext ctx, EntModel ent) {
    return StateBuilder(
        viewModels: [entityModel],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          final List<Widget> actionsToShow = [];

          actionsToShow.add(Section(text: "Actions"));

          if (entityModel.visibleActions.hasError) {
            return ListItem(
              mainText: entityModel.visibleActions.errorMessage,
              purpose: Purpose.DANGER,
              rightTextPurpose: Purpose.DANGER,
            );
          }

          if (entityModel.visibleActions.hasError) {
            return Container();
          }

          if (entityModel.visibleActions.value.length == 0) {
            return ListItem(
              mainText: "No actions defined",
              disabled: true,
              rightIcon: null,
              icon: FeatherIcons.helpCircle,
            );
          }

          if (entityModel.isRegistered == false) {
            final entityName = ent.entityMetadata.value
                .name[ent.entityMetadata.value.languages[0]];
            ListItem noticeItem = ListItem(
              mainText: "Regsiter to $entityName first",
              secondaryText: null,
              rightIcon: null,
              disabled: false,
              purpose: Purpose.HIGHLIGHT,
            );
            actionsToShow.add(noticeItem);
          }

          for (EntityMetadata_Action action
              in entityModel.visibleActions.value) {
            ListItem item;
            if (action.type == "browser") {
              if (!(action.name is Map) ||
                  !(action.name[ent.entityMetadata.value.languages[0]]
                      is String)) return null;

              item = ListItem(
                icon: FeatherIcons.arrowRightCircle,
                mainText: action.name[ent.entityMetadata.value.languages[0]],
                secondaryText: action.visible,
                disabled: entityModel.isRegistered.value == false,
                onTap: () {
                  onBrowserAction(ctx, action, ent);
                },
              );
            } else {
              item = ListItem(
                mainText: action.name[ent.entityMetadata.value.languages[0]],
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

  onBrowserAction(
      BuildContext ctx, EntityMetadata_Action action, EntModel ent) {
    final String url = action.url;
    final String title = action.name[ent.entityMetadata.value.languages[0]] ??
        ent.entityMetadata.value.name[ent.entityMetadata.value.languages[0]];

    final route = MaterialPageRoute(
        builder: (context) => WebAction(
              url: url,
              title: title,
            ));
    Navigator.push(ctx, route);
  }

  unsubscribeFromEntity(BuildContext ctx, EntModel ent) async {
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

  subscribeToEntity(BuildContext ctx, EntModel ent) async {
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
    await entityModel.update();
/*
    String errorMessage = "";
    bool fail = false;

    if (entityModel.entityMetadata == DataState.ERROR) {
      errorMessage = "Unable to retrieve details";
      fail = true;
    } else if (entityModel.processessMetadataUpdated == false) {
      errorMessage = "Unable to retrieve processess";
      fail = true;
    } else if (entityModel.feedUpdated == false) {
      errorMessage = "Unable to retrieve news feed";
      fail = true;
    }

    if (!mounted) return;
    setState(() {
      entityModel = entityModel;
      _status = fail ? "fail" : "ok";
      _errorMessage = errorMessage;
    });
*/

    //if (account.isSubscribed(entityModel.entityReference)) entityModel.save();
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
