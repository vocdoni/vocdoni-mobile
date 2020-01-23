import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/web-action.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart' as summary;
import 'package:vocdoni/widgets/toast.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';
import 'package:vocdoni/constants/colors.dart';

class EntityInfoPage extends StatefulWidget {
  final EntityModel entityModel;

  EntityInfoPage(this.entityModel) {
    globalAnalytics.trackPage("EntityInfoPage",
        entityId: entityModel.reference.entityId);
  }

  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  bool _processingSubscription = false;

  @override
  void initState() {
    super.initState();

    // detached async
    widget.entityModel.refresh().catchError((err) {
      if (!kReleaseMode) print(err);
    });
  }

  @override
  Widget build(context) {
    // Rebuild when the metadata updates
    return ChangeNotifierProvider.value(
      value: widget.entityModel.metadata,
      child: Builder(
        builder: (BuildContext context) {
          return widget.entityModel.metadata.hasValue
              ? buildScaffold(context)
              : buildScaffoldWithoutMetadata(context);
        },
      ),
    );
  }

  Widget buildScaffoldWithoutMetadata(BuildContext context) {
    return ScaffoldWithImage(
        headerImageUrl: null,
        headerTag: null,
        forceHeader: true,
        appBarTitle: "Loading",
        avatarText: "",
        avatarHexSource: widget.entityModel.reference.entityId,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
                delegate: SliverChildListDelegate(
              [
                buildTitleWithoutMetadata(ctx),
                buildLoadingStatus(),
              ],
            ));
          },
        ));
  }

  Widget buildLoadingStatus() {
    return ChangeNotifierProvider.value(
      value: widget.entityModel.metadata,
      child: ChangeNotifierProvider.value(
        value: widget.entityModel.processes,
        child: ChangeNotifierProvider.value(
          value: widget.entityModel.feed,
          child: Builder(builder: (context) {
            if (widget.entityModel.metadata.isLoading)
              return ListItem(
                mainText: "Fetching details...",
                rightIcon: null,
                isSpinning: true,
              );
            else if (widget.entityModel.processes.isLoading)
              return ListItem(
                mainText: "Fetching participation...",
                rightIcon: null,
                isSpinning: true,
              );
            else if (widget.entityModel.feed.isLoading)
              return ListItem(
                mainText: "Fetching news...",
                rightIcon: null,
                isSpinning: true,
              );
            else if (widget.entityModel.metadata.hasError)
              return ListItem(
                mainText: widget.entityModel.metadata.errorMessage,
                purpose: Purpose.DANGER,
                rightTextPurpose: Purpose.DANGER,
                onTap: refresh,
                rightIcon: FeatherIcons.refreshCw,
              );
            else if (widget.entityModel.feed.hasError)
              return ListItem(
                mainText: widget.entityModel.feed.errorMessage,
                purpose: Purpose.DANGER,
                rightTextPurpose: Purpose.DANGER,
                onTap: refresh,
                rightIcon: FeatherIcons.refreshCw,
              );
            else
              return Container();
          }),
        ),
      ),
    );
  }

  Widget buildScaffold(BuildContext context) {
    return ScaffoldWithImage(
        headerImageUrl: widget.entityModel.metadata.value.media.header,
        headerTag: widget.entityModel.reference.entityId +
            widget.entityModel.metadata.value.media.header,
        forceHeader: true,
        appBarTitle: widget
            .entityModel.metadata.value.name[globalAppState.currentLanguage],
        avatarUrl: widget.entityModel.metadata.value.media.avatar,
        avatarText: widget
            .entityModel.metadata.value.name[globalAppState.currentLanguage],
        avatarHexSource: widget.entityModel.reference.entityId,
        leftElement: buildRegisterButton(context),
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            final children = getScaffoldChildren(ctx);
            return SliverList(
              delegate: SliverChildListDelegate(children),
            );
          },
        ));
  }

  List<Widget> actionsBuilder(BuildContext context) {
    return [
      buildShareButton(context),
      SizedBox(height: 48, width: paddingPage),
      //buildSubscribeButton(context),
      //SizedBox(height: 48, width: paddingPage)
    ];
  }

  getScaffoldChildren(BuildContext context) {
    List<Widget> children = [];

    children.add(buildTitle(context));
    children.add(buildLoadingStatus());
    children.add(buildFeedRow(context));
    children.add(buildParticipationRow(context));
    children.add(buildActionList(context));
    children.add(Section(text: "Details"));
    children.add(summary.Summary(
      text: widget.entityModel.metadata.value
          .description[globalAppState.currentLanguage],
      maxLines: 5,
    ));
    children.add(Section(text: "Manage"));
    children.add(buildShareItem(context));
    children.add(buildSubscribeItem(context));

    return children;
  }

  buildTitle(BuildContext context) {
    String title =
        widget.entityModel.metadata.value.name[globalAppState.currentLanguage];
    return ListItem(
      heroTag: widget.entityModel.reference.entityId + title,
      mainText: title,
      secondaryText: widget.entityModel.reference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildTitleWithoutMetadata(BuildContext context) {
    return ListItem(
      mainText: "...",
      secondaryText: widget.entityModel.reference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildFeedRow(BuildContext context) {
    // Rebuild when the feed updates
    return ChangeNotifierProvider.value(
        value: widget.entityModel.feed,
        child: Builder(builder: (context) {
          String postCount = "0";
          if (widget.entityModel.feed.isLoading ||
              (widget.entityModel.feed.hasValue &&
                  widget.entityModel.feed.value.feed.isLoading))
            postCount = "-";
          else if (widget.entityModel.feed.hasError ||
              (widget.entityModel.feed.hasValue &&
                  widget.entityModel.feed.value.feed.hasError))
            postCount = "!";
          else if (widget.entityModel.feed.hasValue &&
              (widget.entityModel.feed.hasValue &&
                  widget.entityModel.feed.value.feed.hasValue))
            postCount = widget.entityModel.feed.value.feed.value.items.length
                .toString();

          return ListItem(
            icon: FeatherIcons.rss,
            mainText: "Feed",
            rightText: postCount,
            rightTextIsBadge: true,
            rightTextPurpose:
                widget.entityModel.feed.hasError ? Purpose.DANGER : null,
            disabled: postCount == "0",
            onTap: () => onShowFeed(context),
          );
        }));
  }

  buildParticipationRow(BuildContext context) {
    // Rebuild when the process list updates (not the items)
    return ChangeNotifierProvider.value(
      value: widget.entityModel.processes,
      child: Builder(
        builder: (context) {
          int processCount = 0;
          if (widget.entityModel.processes.hasValue)
            processCount = widget.entityModel.processes.value.length;

          return ListItem(
              icon: FeatherIcons.mail,
              mainText: "Participation",
              rightText: processCount.toString(),
              rightTextIsBadge: true,
              disabled: processCount == 0,
              onTap: () => onShowParticipation(context));
        },
      ),
    );
  }

  buildSubscribeItem(BuildContext context) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    bool isSubscribed =
        currentAccount.isSubscribed(widget.entityModel.reference);
    String subscribeText = isSubscribed ? "Following" : "Follow";

    // Rebuild when the selected account's identity updates
    return ChangeNotifierProvider.value(
        value: currentAccount
            .identity, // when peers > entities are updated, identity emits an event
        child: ListItem(
          mainText: subscribeText,
          icon: FeatherIcons.heart,
          disabled: _processingSubscription,
          isSpinning: _processingSubscription,
          rightIcon: isSubscribed ? FeatherIcons.check : null,
          rightTextPurpose: isSubscribed ? Purpose.GOOD : null,
          onTap: () => isSubscribed
              ? unsubscribeFromEntity(context)
              : subscribeToEntity(context),
        ));
  }

  buildSubscribeButton(BuildContext context) {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    // No need to use ChangeNotifierProvider here, since the only place that can change the subscription status is here.
    // Hence, we don't need to worry about rebuilding on external updates

    bool isSubscribed =
        currentAccount.isSubscribed(widget.entityModel.reference);
    String subscribeText = isSubscribed ? "Following" : "Follow";

    return BaseButton(
        text: subscribeText,
        leftIconData: isSubscribed ? FeatherIcons.check : FeatherIcons.plus,
        isDisabled: _processingSubscription,
        isSmall: true,
        style: BaseButtonStyle.OUTLINE_WHITE,
        onTap: () {
          if (isSubscribed)
            unsubscribeFromEntity(context);
          else
            subscribeToEntity(context);
        });
  }

  buildShareItem(BuildContext context) {
    return ListItem(
        mainText: "Share organization",
        icon: FeatherIcons.share2,
        rightIcon: null,
        onTap: () => onShare(context));
  }

  buildShareButton(BuildContext context) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () => onShare(context));
  }

  buildRegisterButton(BuildContext ctx) {
    // Rebuild if `isRegistered` changes
    return ChangeNotifierProvider.value(
      value: widget.entityModel.isRegistered,
      child: Builder(
        builder: (context) {
          if (widget.entityModel.isRegistered.hasError ||
              widget.entityModel.registerAction.hasError)
            return Container();
          else if (!widget.entityModel.isRegistered.hasValue ||
              !widget.entityModel.registerAction.hasValue)
            return Container();
          else if (!widget.entityModel.isRegistered.value) {
            // Not yet
            return BaseButton(
              purpose: Purpose.HIGHLIGHT,
              leftIconData: FeatherIcons.feather,
              text: "Register",
              isSmall: true,
              onTap: () => onTapRegister(context),
            );
          }

          // Already registered
          return BaseButton(
            purpose: Purpose.GUIDE,
            leftIconData: FeatherIcons.check,
            text: "Registered",
            isSmall: true,
            style: BaseButtonStyle.FILLED,
            isDisabled: true,
          );
        },
      ),
    );
  }

  Widget buildActionList(BuildContext ctx) {
    // Rebuild if `isRegistered` changes
    return ChangeNotifierProvider.value(
      value: widget.entityModel.visibleActions,
      child: Builder(
        builder: (context) {
          final List<Widget> actionsToShow = [];

          actionsToShow.add(Section(text: "Actions"));

          if (widget.entityModel.visibleActions.hasError) {
            return ListItem(
              mainText: widget.entityModel.visibleActions.errorMessage,
              purpose: Purpose.DANGER,
              rightTextPurpose: Purpose.DANGER,
            );
          } else if (widget.entityModel.visibleActions.hasValue &&
              widget.entityModel.visibleActions.value.length == 0) {
            return ListItem(
              mainText: "No actions defined",
              disabled: true,
              rightIcon: null,
              icon: FeatherIcons.helpCircle,
            );
          }

          // Unregistered warning
          if (!widget.entityModel.isRegistered.value) {
            final entityName = widget.entityModel.metadata.value
                .name[globalAppState.currentLanguage];
            ListItem noticeItem = ListItem(
              mainText: "Regsiter to $entityName first",
              // secondaryText: null,
              // rightIcon: null,
              disabled: false,
              purpose: Purpose.HIGHLIGHT,
            );
            actionsToShow.add(noticeItem);
          }

          // disabled if not registered
          for (EntityMetadata_Action action
              in widget.entityModel.visibleActions.value) {
            ListItem item;
            if (action.type == "browser") {
              if (action.name == null ||
                  !(action.name[globalAppState.currentLanguage] is String))
                return Container();

              item = ListItem(
                icon: FeatherIcons.arrowRightCircle,
                mainText: action.name[globalAppState.currentLanguage],
                secondaryText: action.visible,
                disabled: !widget.entityModel.isRegistered.value,
                onTap: () => onBrowserAction(ctx, action),
              );
            } else {
              item = ListItem(
                mainText: action.name[globalAppState.currentLanguage],
                secondaryText: "Action not yet supported: " + action.type,
                icon: FeatherIcons.helpCircle,
                disabled: true,
              );
            }

            actionsToShow.add(item);
          }

          return ListView(children: actionsToShow);
        },
      ),
    );
  }

  // EVENTS

  onShare(BuildContext context) {
    Clipboard.setData(
            ClipboardData(text: widget.entityModel.reference.entityId))
        .then((_) => showMessage("Identity ID copied on the clipboard",
            context: context, purpose: Purpose.GOOD))
        .catchError((err) {
      if (!kReleaseMode) print(err);

      showMessage("Could not copy the Entity ID",
          context: context, purpose: Purpose.DANGER);
    });
  }

  onShowFeed(BuildContext context) {
    Navigator.pushNamed(context, "/entity/feed", arguments: widget.entityModel);
  }

  onShowParticipation(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation",
        arguments: widget.entityModel);
  }

  onTapRegister(BuildContext context) {
    if (widget.entityModel.registerAction.value.type == "browser") {
      onBrowserAction(context, widget.entityModel.registerAction.value);
    }
  }

  onBrowserAction(BuildContext ctx, EntityMetadata_Action action) {
    final url = action.url;
    final title = action.name[globalAppState.currentAccount] ??
        widget.entityModel.metadata.value.name[globalAppState.currentAccount];

    final route = MaterialPageRoute(
        builder: (context) => WebAction(
              url: url,
              title: title,
            ));
    Navigator.push(ctx, route);
  }

  subscribeToEntity(BuildContext ctx) async {
    setState(() {
      _processingSubscription = true;
    });

    try {
      final currentAccount = globalAppState.currentAccount;
      if (currentAccount == null)
        throw Exception("Internal error: null account");

      await currentAccount.subscribe(widget.entityModel);

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

  unsubscribeFromEntity(BuildContext ctx) async {
    setState(() {
      _processingSubscription = true;
    });
    try {
      final currentAccount = globalAppState.currentAccount;
      if (currentAccount == null)
        throw Exception("Internal error: null account");

      await currentAccount.unsubscribe(widget.entityModel.reference);
      showMessage(
          Lang.of(ctx)
              .get("You will no longer see this organization in your feed"),
          context: ctx,
          purpose: Purpose.NONE);
      if (!mounted) return;
      setState(() {
        _processingSubscription = false;
      });
    } catch (err) {
      showMessage(Lang.of(ctx).get("The subscription could not be canceled"),
          context: ctx, purpose: Purpose.DANGER);
    }
  }

  refresh() async {
    await widget.entityModel.refresh();

/*
    String errorMessage = "";
    bool fail = false;

    if (widget.entityModel.metadata == DataState.ERROR) {
      errorMessage = "Unable to retrieve details";
      fail = true;
    } else if (widget.entityModel.processessMetadataUpdated == false) {
      errorMessage = "Unable to retrieve processess";
      fail = true;
    } else if (widget.entityModel.feedUpdated == false) {
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
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
