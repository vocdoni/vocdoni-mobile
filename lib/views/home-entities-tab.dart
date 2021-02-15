import 'dart:async';

import 'package:dvote_common/lib/common.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/views/org-details.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/card-loading.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import "package:vocdoni/lib/extensions.dart";

class HomeEntitiesTab extends StatefulWidget {
  HomeEntitiesTab();

  @override
  _HomeEntitiesTabState createState() => _HomeEntitiesTabState();
}

class _HomeEntitiesTabState extends State<HomeEntitiesTab> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    if (Globals.appState.currentAccount.entities.hasValue) {
      Globals.appState.currentAccount.entities.value
          .forEach((entity) => entity.refresh(force: false));
    }

    super.initState();
    Globals.analytics.trackPage("Orgs");
  }

  void _onRefresh() {
    final currentAccount = Globals.appState.currentAccount;

    currentAccount.refresh().then((_) {
      if (Globals.appState.currentAccount.entities.hasValue) {
        Globals.appState.currentAccount.entities.value
            .forEach((entity) => entity.refresh(force: false));
      }
    }).then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
  }

  @override
  Widget build(ctx) {
    return EventualBuilder(
      notifier: Globals.appState.selectedAccount,
      builder: (context, _, __) {
        final currentAccount = Globals.appState.currentAccount;
        if (currentAccount == null) return buildNoEntities(ctx);
        return EventualBuilder(
          notifiers: [
            currentAccount.entities,
            currentAccount.identity,
          ],
          builder: (context, _, __) {
            if (!currentAccount.entities.hasValue ||
                currentAccount.entities.value.length == 0) {
              return buildNoEntities(ctx);
            }

            return SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: WaterDropHeader(
                complete: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.done, color: Colors.grey),
                      Container(width: 10.0),
                      Text(getText(context, "main.refreshCompleted"),
                          style: TextStyle(color: Colors.grey))
                    ]),
                failed: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.close, color: Colors.grey),
                      Container(width: 10.0),
                      Text(getText(context, "main.couldNotRefresh"),
                          style: TextStyle(color: Colors.grey))
                    ]),
              ),
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: ListView.builder(
                  itemCount: currentAccount.entities.value.length,
                  itemBuilder: (BuildContext context, int index) {
                    final entity = currentAccount.entities.value[index];

                    if (entity.metadata.hasValue)
                      return buildCard(ctx, entity);
                    else if (entity.metadata.isLoading)
                      return CardLoading(
                          getText(context, "main.loadingEntity"));
                    return buildEmptyMetadataCard(ctx, entity);
                  }),
            );
          },
        );
      },
    );
  }

  Widget buildEmptyMetadataCard(BuildContext ctx, EntityModel entityModel) {
    return BaseCard(children: [
      ListItem(
          mainText: entityModel.reference.entityId,
          avatarHexSource: entityModel.reference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, entityModel))
    ]);
  }

  Widget buildCard(BuildContext ctx, EntityModel ent) {
    return BaseCard(children: [
      buildName(ctx, ent),
      buildFeedRow(ctx, ent),
      buildParticipationRow(ctx, ent),
    ]);
  }

  int getFeedPostCount(EntityModel entity) {
    if (!entity.feed.hasValue)
      return 0;
    else if (entity.feed.value.items is List)
      return entity.feed.value.items.length;
    return 0;
  }

  Widget buildName(BuildContext ctx, EntityModel entity) {
    String avatarUrl = entity.metadata.value.media.avatar;
    if (avatarUrl.startsWith("ipfs"))
      avatarUrl = processIpfsImageUrl(avatarUrl, ipfsDomain: IPFS_DOMAIN);
    String title =
        entity.metadata.value.name[entity.metadata.value.languages[0]];
    return ListItem(
        heroTag: entity.reference.entityId + title,
        mainText: title,
        avatarUrl: avatarUrl,
        avatarText: title,
        avatarHexSource: entity.reference.entityId,
        isBold: true,
        onTap: () => onTapEntity(ctx, entity));
  }

  Widget buildParticipationRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's process list changes
    return EventualBuilder(
      notifier: entity.processes,
      builder: (context, _, __) {
        int itemCount = 0;
        if (entity.processes.hasValue) {
          final availableProcesses = List<ProcessModel>();
          if (entity.processes.hasValue) {
            availableProcesses.addAll(
                entity.processes.value.where((item) => item.metadata.hasValue));
          }
          itemCount = availableProcesses.length;
        }

        return ListItem(
            mainText: getText(context, "main.participation"),
            icon: FeatherIcons.mail,
            rightText: itemCount.toString(),
            rightTextIsBadge: true,
            onTap: () => onTapParticipation(ctx, entity),
            disabled: itemCount == 0);
      },
    );
  }

  Widget buildFeedRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's news feed changes
    return EventualBuilder(
      notifier: entity.feed,
      builder: (context, _, __) {
        final feedPostAmount = getFeedPostCount(entity);
        return ListItem(
            mainText: getText(context, "main.feed"),
            icon: FeatherIcons.rss,
            rightText: feedPostAmount.toString(),
            rightTextIsBadge: true,
            onTap: () => onTapFeed(ctx, entity),
            disabled: feedPostAmount == 0);
      },
    );
  }

  Widget buildNoEntities(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              FeatherIcons.home,
              size: 50.0,
              color: Colors.black38,
            ),
            Text(getText(context, "main.noEntities")).withTopPadding(20),
          ],
        ));
  }

  onTapEntity(BuildContext ctx, EntityModel entity) {
    final route = MaterialPageRoute(builder: (context) => OrgDetails(entity));
    Navigator.push(ctx, route);
  }

  onTapParticipation(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: entity);
  }

  onTapFeed(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/feed", arguments: entity);
  }
}
