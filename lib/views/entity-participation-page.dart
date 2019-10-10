import 'package:dvote/models/dart/entity.pb.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pollCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class EntityParticipationPage extends StatefulWidget {
  @override
  _EntityParticipationPageState createState() =>
      _EntityParticipationPageState();
}

class _EntityParticipationPageState extends State<EntityParticipationPage> {
  EntModel entModel;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final EntityReference entityReference =
          ModalRoute.of(context).settings.arguments;
      entModel = account.getEnt(entityReference);
      analytics.trackPage(
          pageId: "EntityParticipationPage",
          entityId: entityReference.entityId);
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    return StateBuilder(
        viewModels: [entModel],
        tag: ProcessTags.CENSUS_STATE,
        builder: (ctx, tagId) {
          if (entModel == null || entModel.processess == null)
            return buildNoProcessesess(context);

          return Scaffold(
            appBar: TopNavigation(
              title: entModel
                  .entityMetadata.name[entModel.entityMetadata.languages[0]],
            ),
            body: ListView.builder(
              itemCount: entModel.processess.length,
              itemBuilder: (BuildContext ctx, int index) {
                final ProcessModel process = entModel.processess[index];
                return PollCard(ent: entModel, process: process);
              },
            ),
          );
        });
  }

  Widget buildNoProcessesess(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("(No processess)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }
}
