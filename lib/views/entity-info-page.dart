import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/lib/state-model.dart';
import 'package:vocdoni/view-modals/web-action.dart';
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
    globalAnalytics.trackPage("EntityInfoPage",
        entityId: entityReference.entityId);
  }

  @override
  _EntityInfoPageState createState() => _EntityInfoPageState();
}

class _EntityInfoPageState extends State<EntityInfoPage> {
  bool _processingSubscription = false;
  EntityModel entityModel;

  @override
  void initState() async {
    super.initState();

    entityModel = EntityModel(widget.entityReference);

    try {
      // fetch data from reference
      await entityModel.refresh(true);

      final currentAccount = globalAppState.currentAccount;
      if (currentAccount == null) throw Exception("Internal error");

      // subscribe if not already
      if (!currentAccount.isSubscribed(widget.entityReference)) {
        await currentAccount.subscribe(entityModel);
      }
    } catch (err) {
      entityModel.metadata.setError("Could not fetch");
    }
  }

  @override
  Widget build(context) {
    // Rebuild when the metadata updates
    return ChangeNotifierProvider.value(
      value: entityModel.metadata,
      child: Builder(
        builder: (BuildContext context) {
          return entityModel.metadata.hasValue
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
        avatarHexSource: entityModel.reference.entityId,
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
    if (entityModel.metadata.isLoading)
      return ListItem(
        mainText: "Fetching details...",
        rightIcon: null,
        isSpinning: true,
      );
    if (entityModel.metadata.hasError)
      return ListItem(
        mainText: entityModel.metadata.errorMessage,
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

  Widget buildScaffold(BuildContext context) {
    return ScaffoldWithImage(
        headerImageUrl: entityModel.metadata.value.media.header,
        headerTag: entityModel.reference.entityId +
            entityModel.metadata.value.media.header,
        forceHeader: true,
        appBarTitle:
            entityModel.metadata.value.name[globalAppState.currentLanguage],
        avatarUrl: entityModel.metadata.value.media.avatar,
        avatarText:
            entityModel.metadata.value.name[globalAppState.currentLanguage],
        avatarHexSource: entityModel.reference.entityId,
        leftElement: buildRegisterButton(context),
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(getScaffoldChildren(ctx)),
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
    children.add(Summary(
      text: entityModel
          .metadata.value.description[globalAppState.currentLanguage],
      maxLines: 5,
    ));
    children.add(Section(text: "Manage"));
    children.add(buildShareItem(context));
    children.add(buildSubscribeItem(context));

    return children;
  }

  buildTitle(BuildContext context) {
    String title =
        entityModel.metadata.value.name[globalAppState.currentLanguage];
    return ListItem(
      heroTag: entityModel.reference.entityId + title,
      mainText: title,
      secondaryText: entityModel.reference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildTitleWithoutMetadata(BuildContext context) {
    return ListItem(
      mainText: "...",
      secondaryText: entityModel.reference.entityId,
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildFeedRow(BuildContext context) {
    // Rebuild when the feed updates
    return ChangeNotifierProvider.value(
        value: entityModel.feed,
        child: Builder(builder: (context) {
          String postCount = "0";
          if (entityModel.feed.isLoading ||
              (entityModel.feed.hasValue &&
                  entityModel.feed.value.feed.isLoading))
            postCount = "-";
          else if (entityModel.feed.hasError ||
              (entityModel.feed.hasValue &&
                  entityModel.feed.value.feed.hasError))
            postCount = "!";
          else if (entityModel.feed.hasValue &&
              (entityModel.feed.hasValue &&
                  entityModel.feed.value.feed.hasValue))
            postCount =
                entityModel.feed.value.feed.value.items.length.toString();
          else
            throw Exception("Internal error");

          return ListItem(
            icon: FeatherIcons.rss,
            mainText: "Feed",
            rightText: postCount,
            rightTextIsBadge: true,
            rightTextPurpose: entityModel.feed.hasError ? Purpose.DANGER : null,
            disabled: postCount == "0",
            onTap: () => onShowFeed(context),
          );
        }));
  }

  buildParticipationRow(BuildContext context) {
    // Rebuild when the process list updates (not the items)
    ChangeNotifierProvider.value(
      value: entityModel.processes,
      child: Builder(
        builder: (context) {
          int processCount = 0;
          if (entityModel.processes.hasValue)
            processCount = entityModel.processes.value.length;

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

    bool isSubscribed = currentAccount.isSubscribed(entityModel.reference);
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

    bool isSubscribed = currentAccount.isSubscribed(entityModel.reference);
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
        onTap: () => onShare());
  }

  buildShareButton(BuildContext context) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () => onShare());
  }

  buildRegisterButton(BuildContext ctx) {
    // Rebuild if `isRegistered` changes
    return ChangeNotifierProvider.value(
      value: entityModel.isRegistered,
      child: Builder(
        builder: (context) {
          if (entityModel.isRegistered.hasError ||
              entityModel.registerAction.hasError)
            return Container();
          else if (!entityModel.isRegistered.hasValue ||
              !entityModel.registerAction.hasValue)
            return Container();
          else if (!entityModel.isRegistered.value) {
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
      value: entityModel.visibleActions,
      child: Builder(
        builder: (context) {
          final List<Widget> actionsToShow = [];

          actionsToShow.add(Section(text: "Actions"));

          if (entityModel.visibleActions.hasError) {
            return ListItem(
              mainText: entityModel.visibleActions.errorMessage,
              purpose: Purpose.DANGER,
              rightTextPurpose: Purpose.DANGER,
            );
          } else if (entityModel.visibleActions.value.length == 0) {
            return ListItem(
              mainText: "No actions defined",
              disabled: true,
              rightIcon: null,
              icon: FeatherIcons.helpCircle,
            );
          }

          // Unregistered warning
          if (!entityModel.isRegistered.value) {
            final entityName =
                entityModel.metadata.value.name[globalAppState.currentLanguage];
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
              in entityModel.visibleActions.value) {
            ListItem item;
            if (action.type == "browser") {
              if (!(action.name is Map) ||
                  !(action.name[globalAppState.currentLanguage] is String))
                return null;

              item = ListItem(
                icon: FeatherIcons.arrowRightCircle,
                mainText: action.name[globalAppState.currentLanguage],
                secondaryText: action.visible,
                disabled: !entityModel.isRegistered.value,
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

  onShare() {
    Clipboard.setData(ClipboardData(text: entityModel.reference.entityId))
        .then((_) => showMessage("Identity ID copied on the clipboard",
            context: context, purpose: Purpose.GUIDE))
        .catchError((err) {
      if (!foundation.kReleaseMode) print(err);

      showMessage("Could not copy the Entity ID",
          context: context, purpose: Purpose.DANGER);
    });
  }

  onShowFeed(BuildContext context) {
    Navigator.pushNamed(context, "/entity/feed", arguments: entityModel);
  }

  onShowParticipation(BuildContext context) {
    Navigator.pushNamed(context, "/entity/participation",
        arguments: entityModel);
  }

  onTapRegister(BuildContext context) {
    if (entityModel.registerAction.value.type == "browser") {
      onBrowserAction(context, entityModel.registerAction.value);
    }
  }

  onBrowserAction(BuildContext ctx, EntityMetadata_Action action) {
    final url = action.url;
    final title = action.name[globalAppState.currentAccount] ??
        entityModel.metadata.value.name[globalAppState.currentAccount];

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

      await currentAccount.subscribe(entityModel);

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

      await currentAccount.unsubscribe(entityModel.reference);
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
    await entityModel.refresh();

/*
    String errorMessage = "";
    bool fail = false;

    if (entityModel.metadata == DataState.ERROR) {
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
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
