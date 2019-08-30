import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

class EntityParticipation extends StatefulWidget {
  @override
  _EntityParticipationState createState() => _EntityParticipationState();
}

class _EntityParticipationState extends State<EntityParticipation> {

  @override
  Widget build(context) {
    final Ent ent = ModalRoute.of(context).settings.arguments;
    if (ent.processess == null) return buildNoProcessesess(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      ),
      body: ListView.builder(
        itemCount: ent.processess.length,
        itemBuilder: (BuildContext ctx, int index) {
          final ProcessMetadata process = ent.processess[index];
          return buildProcessCard(ctx:ctx,ent: ent, process:process);
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
