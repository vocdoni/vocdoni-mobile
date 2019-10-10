import 'package:dvote/models/dart/entity.pb.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
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
  EntModel ent;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final EntityReference entityReference =
          ModalRoute.of(context).settings.arguments;
      ent = account.getEnt(entityReference);
      analytics.trackPage(
          pageId: "EntityParticipationPage",
          entityId: entityReference.entityId);
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(context) {
    if (ent == null || ent.processess == null) return buildNoProcessesess(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      ),
      body: ListView.builder(
        itemCount: ent.processess.length,
        itemBuilder: (BuildContext ctx, int index) {
          final ProcessModel process = ent.processess[index];
          return PollCard(ent: ent, process: process);
        },
      ),
    );
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
