import 'package:dvote/dvote.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class EntityParticipationPage extends StatefulWidget {
  @override
  _EntityParticipationPageState createState() =>
      _EntityParticipationPageState();
}

class _EntityParticipationPageState extends State<EntityParticipationPage> {
  EntityModel entityModel;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      analytics.trackPage("EntityParticipationPage",
          entityId: entityReference.entityId);

      entityModel = ModalRoute.of(context).settings.arguments;
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    return StateBuilder(
        viewModels: [entModel],
        tag: [EntityStateTags.PROCESSES],
        builder: (ctx, tagId) {
          if (entModel == null ||
              !entModel.entityMetadata.hasValue ||
              !entModel.processes.hasValue) return buildNoProcessesess(context);

          return Scaffold(
            appBar: TopNavigation(
              title: entModel.entityMetadata.value
                  .name[entModel.entityMetadata.value.languages[0]],
            ),
            body: ListView.builder(
              itemCount: entModel.processes.value is List
                  ? entModel.processes.value.length
                  : 0,
              itemBuilder: (BuildContext ctx, int index) {
                if (!(entModel.processes.value is List))
                  return buildLoading(ctx);
                else if (entModel.processes.value.length == 0)
                  return buildNoProcessesess(ctx);

                final ProcessModel process = entModel.processes.value[index];

                return PollCard(ent: entModel, process: process, index: index);
              },
            ),
          );
        });
  }

  Widget buildNoProcessesess(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("No participation processess"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }
}
