import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/i18n.dart';
import "dart:developer";
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/card-loading.dart';
import 'package:vocdoni/widgets/card-post.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class EntityFeedPage extends StatefulWidget {
  @override
  _EntityFeedPageState createState() => _EntityFeedPageState();
}

class _EntityFeedPageState extends State<EntityFeedPage> {
  EntityModel entityModel;
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      entityModel = ModalRoute.of(context).settings.arguments;
      if (entityModel is EntityModel) {
        globalAnalytics.trackPage("EntityFeedPage",
            entityId: entityModel.reference.entityId);
      }
    } catch (err) {
      log(err);
    }
  }

  void _onRefresh() {
    if (entityModel == null) {
      _refreshController.refreshFailed();
      return;
    }

    entityModel.refresh().then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
  }

  @override
  Widget build(context) {
    if (entityModel == null) return buildEmptyEntity();

    return EventualBuilder(
        notifiers: [
          entityModel.metadata,
          entityModel.feed
        ], // rebuild upon updates on these value
        builder: (context, _, __) {
          if (!entityModel.metadata.hasValue)
            return buildEmptyEntity();
          else if (!entityModel.feed.hasValue)
            return buildEmptyPosts();
          else if ((!entityModel.metadata.hasValue &&
                  entityModel.metadata.isLoading) ||
              (!entityModel.feed.hasValue && entityModel.feed.isLoading))
            return buildLoading();
          else if ((!entityModel.metadata.hasValue &&
                  entityModel.metadata.hasError) ||
              (!entityModel.feed.hasValue && entityModel.feed.hasError))
            return buildError(
                getText(context, "error.theMetadataIsNotAvailable"));

          final lang = entityModel.metadata.value.languages[0] ??
              globalAppState.currentLanguage;

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: Builder(builder: (context) {
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
                  itemCount: entityModel.feed.value.items.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    final post = entityModel.feed.value.items[index];

                    return CardPost(entityModel, post, index);
                  },
                ),
              );
            }),
          );
        });
  }

  Widget buildEmptyEntity() {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "main.newsFeed")),
        body: Center(
          child: Text(getText(context, "main.noEntity")),
        ));
  }

  Widget buildEmptyPosts() {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "main.newsFeed")),
        body: Center(
          child: Text(getText(context, "main.noPosts")),
        ));
  }

  Widget buildLoading() {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "main.newsFeed")),
        body: Center(
          child: SizedBox(
              height: 140.0,
              child: CardLoading(getText(context, "main.loadingPosts"))),
        ));
  }

  Widget buildError(String message) {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "main.newsFeed")),
        body: Center(
          child: Text(getText(context, "main.error") + ": " + message),
        ));
  }
}
