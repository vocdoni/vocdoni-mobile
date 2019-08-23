import 'dart:convert';

import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/data/_processMock.dart';
import 'package:vocdoni/data/ent.dart';

import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import '../lang/index.dart';
import 'package:http/http.dart' as http;
import 'package:vocdoni/constants/colors.dart';

class PollPageArgs {
  Ent ent;
  ProcessMock process;

  PollPageArgs({this.ent, this.process});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    Ent ent = args.ent;
    ProcessMock process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl = process.details.headerImage == null
        ? fallbackImageUrlPoll
        : process.details.headerImage;
    return ScaffoldWithImage(
        headerImageUrl: headerUrl,
        appBarTitle: "Poll",
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(
                  getScaffoldChildren(ctx, ent, process)),
            );
          },
        ));
  }

  List<Widget> actionsBuilder(BuildContext context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    final Ent ent = args.ent;
    return [
      buildShareButton(context, ent),
    ];
  }

  buildTest() {
    double avatarHeight = 120;
    return Container(
      height: avatarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            constraints:
                BoxConstraints(minWidth: avatarHeight, minHeight: avatarHeight),
            child: CircleAvatar(
                backgroundColor: Colors.indigo,
                backgroundImage: NetworkImage(
                    "https://instagram.fmad5-1.fna.fbcdn.net/vp/564db12bde06a8cb360e31007fd049a6/5DDF1906/t51.2885-19/s150x150/13167299_1084444071617255_680456677_a.jpg?_nc_ht=instagram.fmad5-1.fna.fbcdn.net")),
          ),
        ],
      ),
    );
  }

  getScaffoldChildren(BuildContext context, Ent ent, ProcessMock process) {
    List<Widget> children = [];
    //children.add(buildTest());
    children.add(buildTitle(context, process));
    children.add(Summary(
      text: process.details.description['default'],
      maxLines: 5,
    ));
    children.add(buildRawItem(context, process));
    children.addAll(buildQuestions(context, process));
    children.add(Section(text: "Details"));

    return children;
  }

  buildTitle(BuildContext context, ProcessMock process) {
    return ListItem(
      mainText: process.details.title['default'],
      secondaryText: process.meta['entityId'],
      isTitle: true,
      rightIcon: null,
      isBold: true,
    );
  }

  buildRawItem(BuildContext context, ProcessMock process) {
    return ListItem(
      icon: FeatherIcons.code,
      mainText: "Raw details",
      onTap: () {
        Navigator.pushNamed(context, "/entity/participation/process/raw",
            arguments: process);
      },
      disabled: true,
    );
  }

  buildShareButton(BuildContext context, Ent ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: ent.entitySummary.entityId));
          showMessage("Identity ID copied on the clipboard",
              context: context, purpose: Purpose.GUIDE);
        });
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text("(No entity)"),
        ));
  }

  List<Widget> buildQuestions(BuildContext ctx, ProcessMock process) {
    if (process.details.questions.length == 0) {
      return [buildError("No questions defined")];
    }

    List<Widget> items = new List<Widget>();
    for (Question question in process.details.questions) {
      items.addAll(buildQuestion(question));
    }

    return items;
  }

  List<Widget> buildQuestion(Question question) {
    List<Widget> items = new List<Widget>();

    if (question.type == "single-choice") {
      items.add(buildQuestionTitle(question));
    } else {
      String questionType = question.type;
      buildError("Unknown question type: $questionType");
    }
    return items;
  }

  buildError(String error) {
    ListItem(
      mainText: "Error: $error",
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  buildQuestionTitle(Question question) {
    return ListItem(
        icon: FeatherIcons.arrowRightCircle,
        mainText: question.question['default'],
        secondaryText: question.description['default'],
        secondaryTextMultiline: true);
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
