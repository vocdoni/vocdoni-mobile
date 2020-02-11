import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/card-post.dart';
import 'package:vocdoni/widgets/loading-spinner.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

class EntityFeedPage extends StatefulWidget {
  @override
  _EntityFeedPageState createState() => _EntityFeedPageState();
}

class _EntityFeedPageState extends State<EntityFeedPage> {
  EntityModel entityModel;
  Feed remoteNewsFeed;
  bool loading = false;
  bool remoteFetched = false;

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
      devPrint(err);
    }
  }

  @override
  Widget build(context) {
    if (entityModel == null) return buildEmptyEntity(context);

    return EventualBuilder(
        notifiers: [
          entityModel.metadata,
          entityModel.feed
        ], // rebuild upon updates on these value
        builder: (context, _, __) {
          if (!entityModel.metadata.hasValue)
            return buildEmptyEntity(context);
          else if (!entityModel.feed.hasValue)
            return buildEmptyPosts(context);
          else if ((!entityModel.metadata.hasValue &&
                  entityModel.metadata.isLoading) ||
              (!entityModel.feed.hasValue && entityModel.feed.isLoading))
            return buildLoading(context);
          else if (entityModel.metadata.hasError ||
              entityModel.feed.hasError ||
              entityModel.feed.hasError)
            return buildError(
                context,
                entityModel.metadata.errorMessage ??
                    entityModel.feed.errorMessage);

          final lang = entityModel.metadata.value.languages[0] ??
              globalAppState.currentLanguage;

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: ListView.builder(
              itemCount: entityModel.feed.value.items.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final post = entityModel.feed.value.items[index];

                return CardPost(entityModel, post, index);
              },
            ),
          );
        });
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("(No entity)"),
    ));
  }

  Widget buildEmptyPosts(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("(No posts)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Column(children: [
        Text("Loading..."),
        LoadingSpinner(),
      ]),
    ));
  }

  Widget buildError(BuildContext ctx, String message) {
    return Scaffold(
        body: Center(
      child: Text("ERROR: $message"),
    ));
  }
}
