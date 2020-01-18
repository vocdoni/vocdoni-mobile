import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/postCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

class EntityFeedPage extends StatefulWidget {
  @override
  _EntityFeedPageState createState() => _EntityFeedPageState();
}

class _EntityFeedPageState extends State<EntityFeedPage> {
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      EntityModel ent = ModalRoute.of(super.context).settings.arguments;
      globalAnalytics.trackPage("EntityFeedPage",
          entityId: ent.reference.entityId);
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    final EntityModel entModel = ModalRoute.of(context).settings.arguments;
    if (loading)
      return buildLoading(context);
    else if (entModel == null) return buildEmptyEntity(context);

    return StateBuilder(
        viewModels: [entModel],
        tag: [EntityStateTags.FEED],
        builder: (ctx, tagId) {
          return Scaffold(
            appBar: TopNavigation(
              title: entModel.entityMetadata.value
                  .name[entModel.entityMetadata.value.languages[0]],
            ),
            body: ListView.builder(
              itemCount: entModel.feed.value?.items?.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final FeedPost post = entModel.feed.value.items[index];

                return PostCard(entModel, post, index);
              },
            ),
          );
        });
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("(No entity)"),
    ));
  }

  Widget buildEmptyPosts(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("(No posts)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    // TODO: UI
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }
}
