import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/card-post.dart';
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

    return ChangeNotifierProvider.value(
        value: entityModel.feed, // rebuild upon updates on this value
        child: Builder(builder: (context) {
          if (!entityModel.metadata.hasValue) return buildEmptyEntity(context);
          if (!entityModel.feed.hasValue ||
              !entityModel.feed.value.content.hasValue)
            return buildEmptyPosts(context);
          else if (entityModel.metadata.isLoading ||
              entityModel.feed.isLoading ||
              entityModel.feed.value.content.isLoading)
            return buildLoading(context);
          else if (entityModel.metadata.hasError ||
              entityModel.feed.hasError ||
              entityModel.feed.hasError)
            return buildError(
                context,
                entityModel.metadata.errorMessage ??
                    entityModel.feed.errorMessage ??
                    entityModel.feed.value.content.errorMessage);

          final lang = entityModel.metadata.value.languages[0] ??
              globalAppState.currentLanguage;

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: ListView.builder(
              itemCount: entityModel.feed.value.content.value.items.length ?? 0,
              itemBuilder: (BuildContext context, int index) {
                final post = entityModel.feed.value.content.value.items[index];

                return CardPost(entityModel, post, index);
              },
            ),
          );
        }));
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
      child: Text("Loading..."),
    ));
  }

  Widget buildError(BuildContext ctx, String message) {
    return Scaffold(
        body: Center(
      child: Text("ERROR: $message"),
    ));
  }
}
