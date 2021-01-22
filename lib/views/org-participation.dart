import 'package:vocdoni/data-models/process.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote_common/widgets/card-loading.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class EntityParticipationPage extends StatefulWidget {
  @override
  _EntityParticipationPageState createState() =>
      _EntityParticipationPageState();
}

class _EntityParticipationPageState extends State<EntityParticipationPage> {
  EntityModel entityModel;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      if (entityModel is EntityModel) {
        Globals.analytics.trackPage("OrgParticipation",
            entityId: entityModel.reference.entityId);
      } else {
        entityModel = ModalRoute.of(context).settings.arguments;
      }
    } catch (err) {
      logger.log(err);
    }
  }

  void _onRefresh() {
    if (entityModel == null) {
      _refreshController.refreshFailed();
      return;
    }

    entityModel.refresh().then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
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
            return buildError(
                getText(context, "error.theMetadataIsNotAvailable"));
          }

          final lang = entityModel.metadata.value.languages[0] ??
              Globals.appState.currentLanguage;

          final availableProcesses = List<ProcessModel>();
          if (entityModel.processes.hasValue) {
            availableProcesses.addAll(entityModel.processes.value
                .where((item) => item.metadata.hasValue));
          }

          return Scaffold(
            appBar: TopNavigation(title: entityModel.metadata.value.name[lang]),
            body: SmartRefresher(
              enablePullDown: true,
              enablePullUp: false,
              header: WaterDropHeader(
                complete: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.done, color: Colors.grey),
                      Container(width: 10.0),
                      Text(getText(context, "main.refreshCompleted"),
                          style: TextStyle(color: Colors.grey))
                    ]),
                failed: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.close, color: Colors.grey),
                      Container(width: 10.0),
                      Text(getText(context, "main.couldNotRefresh"),
                          style: TextStyle(color: Colors.grey))
                    ]),
              ),
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: ListView.builder(
                itemCount: availableProcesses.length ?? 0,
                itemBuilder: (BuildContext ctx, int idx) {
                  final process = availableProcesses[idx];

                  return CardPoll(process, entityModel, idx);
                },
              ),
            ),
          );
        });
  }

  Widget buildNoProcessesess() {
    return Scaffold(
        body: Center(
      child: Text(getText(context, "main.noParticipationProcessess")),
    ));
  }

  Widget buildLoading() {
    return Scaffold(
        appBar: TopNavigation(title: getText(context, "main.participation")),
        body: Center(
          child: SizedBox(
              height: 140.0,
              child: CardLoading(getText(context, "main.loadingProcesses"))),
        ));
  }

  Widget buildError(String message) {
    return Scaffold(
        body: Center(
      child: Text(getText(context, "main.error") + ": " + message),
    ));
  }
}
