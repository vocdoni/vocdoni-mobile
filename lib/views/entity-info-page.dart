import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
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
  final EntityReference entityReference;
  EntModel entModel;

  EntityInfoPage(this.entityReference) {
    analytics.trackPage(
        pageId: "EntityInfoPage", entityId: entityReference.entityId);
    entModel = account.getEnt(entityReference);
    entModel.updateWithDelay();
  }

  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  bool _processingSubscription = false;

  @override
  void initState() {
    super.initState();
    //refresh();
  }

  @override
  Widget build(context) {
    return StateBuilder(
        viewModels: [widget.entModel],
        tag: [EntTags.ENTITY_METADATA],
        builder: (ctx, tagId) {
          return widget.entModel.entityMetadata.isValid
              ? buildScaffold(widget.entModel)
              : buildScaffoldWithoutMetadata(widget.entModel);
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
    if (widget.entModel.entityMetadata.isUpdating)
      return ListItem(
        mainText: "Updating details...",
        rightIcon: null,
        isSpinning: true,
      );
    if (widget.entModel.entityMetadata.isError)
      return ListItem(
        mainText: widget.entModel.entityMetadata.errorMessage,
        purpose: Purpose.DANGER,
        rightTextPurpose: Purpose.DANGER,
        onTap: refresh,
        rightIcon: FeatherIcons.refreshCw,
      );
    else if (widget.entModel.feed.isError)
      return ListItem(
        mainText: widget.entModel.feed.errorMessage,
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
        viewModels: [widget.entModel],
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
      buildShareButton(context, widget.entModel),
      SizedBox(height: 48, width: paddingPage),
      //buildSubscribeButton(context, widget.entModel),
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
      mainTextTag: ent.entityReference.entityId + title,
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
        viewModels: [widget.entModel],
        tag: EntTags.FEED,
        builder: (ctx, tagId) {
          String postsNum = "0";
          if (widget.entModel.feed.isValid) {
            if (widget.entModel.feed.hasError) {
              postsNum =
                  widget.entModel.feed.value.items.length.toString() + " !";
            } else {
              postsNum = widget.entModel.feed.value.items.length.toString();
            }
          } else {
            if (widget.entModel.feed.hasError) {
              postsNum ="!";
            } else {
              postsNum = "0";
            }
          }

          return ListItem(
            icon: FeatherIcons.rss,
            mainText: "Feed",
            rightText: postsNum,
            rightTextIsBadge: true,
            rightTextPurpose:
                widget.entModel.feed.hasError ? Purpose.DANGER : null,
            disabled: postsNum == "0",
            onTap: () {
              Navigator.pushNamed(context, "/entity/feed",
                  arguments: widget.entModel);
            },
          );
        });
  }

  buildParticipationItem(BuildContext context) {
    return StateBuilder(
        viewModels: [widget.entModel],
        tag: EntTags.PROCESSES,
        builder: (ctx, tagId) {
          int processNum = 0;
          if (widget.entModel.processes.isValid)
            processNum = widget.entModel.processes.value.length;
          return ListItem(
              icon: FeatherIcons.mail,
              mainText: "Participation",
              rightText: processNum.toString(),
              rightTextIsBadge: true,
              disabled: processNum == 0,
              onTap: () {
                Navigator.pushNamed(context, "/entity/participation",
                    arguments: widget.entModel.entityReference);
              });
        });
  }

  buildSubscribeItem(BuildContext context) {
    bool isSubscribed = account.isSubscribed(widget.entModel.entityReference);
    String subscribeText = isSubscribed ? "Following" : "Follow";
    return ListItem(
      mainText: subscribeText,
      icon: FeatherIcons.heart,
      disabled: _processingSubscription,
      isSpinning: _processingSubscription,
      rightIcon: isSubscribed ? FeatherIcons.check : null,
      rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
      onTap: () => isSubscribed
          ? unsubscribeFromEntity(context, widget.entModel)
          : subscribeToEntity(context, widget.entModel),
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
        viewModels: [widget.entModel],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          if (widget.entModel.isRegistered.isNotValid ||
              widget.entModel.registerAction.isNotValid) return Container();

          if (widget.entModel.isRegistered.isValid) {
            if (widget.entModel.isRegistered.value)
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
                  if (widget.entModel.registerAction.value.type == "browser") {
                    onBrowserAction(
                        ctx, widget.entModel.registerAction.value, ent);
                  }
                },
              );
          }
        });
  }

  Widget buildActionList(BuildContext ctx, EntModel ent) {
    return StateBuilder(
        viewModels: [widget.entModel],
        tag: [EntTags.ACTIONS],
        builder: (ctx, tagId) {
          final List<Widget> actionsToShow = [];

          actionsToShow.add(Section(text: "Actions"));

          if (widget.entModel.visibleActions.isError) {
            return ListItem(
              mainText: widget.entModel.visibleActions.errorMessage,
              purpose: Purpose.DANGER,
              rightTextPurpose: Purpose.DANGER,
            );
          }

          if (widget.entModel.visibleActions.isNotValid) {
            return Container();
          }

          if (widget.entModel.visibleActions.value.length == 0) {
            return ListItem(
              mainText: "No actions defined",
              disabled: true,
              rightIcon: null,
              icon: FeatherIcons.helpCircle,
            );
          }

          if (widget.entModel.isRegistered == false) {
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
              in widget.entModel.visibleActions.value) {
            ListItem item;
            if (action.type == "browser") {
              if (!(action.name is Map) ||
                  !(action.name[ent.entityMetadata.value.languages[0]]
                      is String)) return null;

              item = ListItem(
                icon: FeatherIcons.arrowRightCircle,
                mainText: action.name[ent.entityMetadata.value.languages[0]],
                secondaryText: action.visible,
                disabled: widget.entModel.isRegistered.value == false,
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
    await widget.entModel.update();
/*
    String errorMessage = "";
    bool fail = false;

    if (widget.entModel.entityMetadata == DataState.ERROR) {
      errorMessage = "Unable to retrieve details";
      fail = true;
    } else if (widget.entModel.processessMetadataUpdated == false) {
      errorMessage = "Unable to retrieve processess";
      fail = true;
    } else if (widget.entModel.feedUpdated == false) {
      errorMessage = "Unable to retrieve news feed";
      fail = true;
    }

    if (!mounted) return;
    setState(() {
      widget.entModel = widget.entModel;
      _status = fail ? "fail" : "ok";
      _errorMessage = errorMessage;
    });
*/

    //if (account.isSubscribed(widget.entModel.entityReference)) widget.entModel.save();
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
