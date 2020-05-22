import 'package:vocdoni/data-models/process.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/card-loading.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:dvote_common/widgets/topNavigation.dart';

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
    if (entityModel == null) return buildNoProcessesess();

    return EventualBuilder(
        notifier: entityModel.processes, // rebuild upon updates on this value
        builder: (context, _, __) {
          if (!entityModel.metadata.hasValue ||
              !entityModel.processes.hasValue) {
            return buildNoProcessesess();
          } else if (entityModel.metadata.isLoading ||
              entityModel.processes.isLoading) {
            return buildLoading();
          } else if ((!entityModel.metadata.hasValue &&
                  entityModel.metadata.hasError) ||
              (!entityModel.processes.hasValue &&
                  entityModel.processes.hasError)) {
            return buildError(entityModel.metadata.errorMessage ??
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

  Widget buildNoProcessesess() {
    return Scaffold(
        body: Center(
      child: Text(getText(context, "No participation processess")),
    ));
  }

  Widget buildLoading() {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "Participation")),
        body: Center(
          child: SizedBox(
              height: 140.0,
              child: CardLoading(getText(context, "Loading processes..."))),
        ));
  }

  Widget buildError(String message) {
    return Scaffold(
        body: Center(
      child: Text(getText(context, "Error") + ": " + message),
    ));
  }
}
