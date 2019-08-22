import "dart:async";
import "package:flutter/material.dart";
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/data/_processMock.dart';
import 'package:vocdoni/data/ent.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/BaseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';

import 'activity-post.dart';

class EntityParticipation extends StatefulWidget {
  @override
  _EntityParticipationState createState() => _EntityParticipationState();
}

class _EntityParticipationState extends State<EntityParticipation> {
  List<ProcessMock> _processess = new List<ProcessMock>();
  bool _loading = true;

  @override
  Widget build(context) {
    final Ent ent = ModalRoute.of(context).settings.arguments;
    if (_loading) {
      fetchProcessess(context, ent.entityMetadata);
      return buildLoading(context);
    } else if (ent == null) return buildEmptyEntity(context);

    return Scaffold(
      appBar: TopNavigation(
        title: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
      ),
      body: ListView.builder(
        itemCount: _processess.length,
        itemBuilder: (BuildContext context, int index) {
          final ProcessMock process = _processess[index];
          return BaseCard(
            image: process.details.headerImage,
            children: <Widget>[
              ListItem(
                mainText: process.details.title[ent.entityMetadata.languages[0]],
                mainTextFullWidth: true,
                secondaryText: ent.entityMetadata.name[ent.entityMetadata.languages[0]],
                avatarUrl: ent.entityMetadata.media.avatar,
                /*rightText: DateFormat('MMMM dd')
                    .format(DateTime.parse(process.datePublished).toLocal()),
                onTap: () => onTapItem(context, process),*/
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("(No entity)"),
    ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Scaffold(
        body: Center(
      child: Text("Loading..."),
    ));
  }

  /*onTapItem(BuildContext ctx, FeedPost post) {
    Navigator.of(ctx).pushNamed("/entity/participation/post",
        arguments: ActivityPostArguments(post));
  }
*/
  Future<List<ProcessMock>> fetchProcessess(
      BuildContext context, Entity entity) async {
    List<ProcessMock> processess = new List<ProcessMock>();
    List<String> active = entity.votingProcesses.active;
    for (String processId in active) {
      ProcessReference ref = new ProcessReference();
      ref.processId = processId;
      processess.add(await processesBloc.get(ref));
    }

    setState(() {
      _processess = processess;
      _loading = false;
    });
  }
}
