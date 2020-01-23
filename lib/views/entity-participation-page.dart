import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/data-models/entity.dart';
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
  void initState() {
    super.initState();

    try {
      entityModel = ModalRoute.of(context).settings.arguments;

      if (entityModel is EntityModel) {
        globalAnalytics.trackPage("EntityParticipationPage",
            entityId: entityModel.reference.entityId);
      }
    } catch (err) {
      devPrint(err);
    }
  }

  @override
  Widget build(context) {
    if (entityModel == null) return buildNoProcessesess(context);

    return ChangeNotifierProvider.value(
        value: entityModel.processes, // rebuild upon updates on this value
        child: Builder(builder: (context) {
          if (!entityModel.metadata.hasValue || !entityModel.processes.hasValue)
            return buildNoProcessesess(context);
          else if (entityModel.metadata.isLoading ||
              entityModel.processes.isLoading)
            return buildLoading(context);
          else if (entityModel.metadata.hasError ||
              entityModel.processes.hasError)
            return buildError(
                context,
                entityModel.metadata.errorMessage ??
                    entityModel.processes.errorMessage);

          final lang = entityModel.metadata.value.languages[0] ??
              globalAppState.currentLanguage;

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: ListView.builder(
              itemCount: entityModel.processes.value.length,
              itemBuilder: (BuildContext ctx, int index) {
                final process = entityModel.processes.value[index];

                return CardPoll(
                    entity: entityModel, process: process, index: index);
              },
            ),
          );
        }));
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

  Widget buildError(BuildContext ctx, String message) {
    return Scaffold(
        body: Center(
      child: Text("ERROR: $message"),
    ));
  }
}
