import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/process.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/pollCard.dart';
import 'package:vocdoni/widgets/topNavigation.dart';

class EntityParticipationPage extends StatefulWidget {
  @override
  _EntityParticipationPageState createState() => _EntityParticipationPageState();
}

class _EntityParticipationPageState extends State<EntityParticipationPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      Ent ent = ModalRoute.of(super.context).settings.arguments;
      analytics.trackPage(
          pageId: "EntityParticipationPage", entityId: ent.entityReference.entityId);
    } catch (err) {
      print(err);
    }
  }

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
          final Process process = ent.processess[index];
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
