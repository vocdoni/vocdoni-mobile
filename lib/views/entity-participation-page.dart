import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/state-notifier-listener.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/loading-spinner.dart';
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
      if (entityModel is EntityModel) {
        globalAnalytics.trackPage("EntityParticipationPage",
            entityId: entityModel.reference.entityId);
      } else {
        entityModel = ModalRoute.of(context).settings.arguments;
      }
    } catch (err) {
      devPrint(err);
    }
  }

  @override
  Widget build(context) {
    if (entityModel == null) return buildNoProcessesess(context);

    return StateNotifierListener(
        values: [entityModel.processes], // rebuild upon updates on this value
        builder: (context) {
          if (!entityModel.metadata.hasValue ||
              !entityModel.processes.hasValue) {
            return buildNoProcessesess(context);
          } else if (entityModel.metadata.isLoading ||
              entityModel.processes.isLoading) {
            return buildLoading(context);
          } else if ((!entityModel.metadata.hasValue &&
                  entityModel.metadata.hasError) ||
              (!entityModel.processes.hasValue &&
                  entityModel.processes.hasError)) {
            return buildError(
                context,
                entityModel.metadata.errorMessage ??
                    entityModel.processes.errorMessage);
          }

          final lang = entityModel.metadata.value.languages[0] ??
              globalAppState.currentLanguage;

          final availableProcesses = List<ProcessModel>();
          if (entityModel.processes.hasValue) {
            availableProcesses.addAll(entityModel.processes.value
                .where((item) => item.metadata.hasValue));
          }

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: ListView.builder(
              itemCount: availableProcesses.length ?? 0,
              itemBuilder: (BuildContext ctx, int index) {
                final process = availableProcesses[index];

                return CardPoll(
                    entity: entityModel, process: process, index: index);
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
