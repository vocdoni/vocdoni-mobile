import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/factories.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/views/poll-packaging.dart';
import 'package:vocdoni/widgets/ScaffoldWithImage.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:intl/intl.dart';

class PollPageArgs {
  EntModel ent;
  String processId;
  final int index;
  PollPageArgs(
      {@required this.ent, @required this.processId, @required this.index});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  List<String> _choices = [];
  ProcessModel processModel;

  @override
  void didChangeDependencies() {
    // TODO: Really needed?
    super.didChangeDependencies();
    PollPageArgs args = ModalRoute.of(context).settings.arguments;

    processModel = args.ent.getProcess(args.processId);
    if (!processModel.processMetadata.isValid) return;

    if (_choices.length == 0) {
      _choices = processModel.processMetadata.value.details.questions
          .map((question) => null)
          .cast<String>()
          .toList();
    }

    analytics.trackPage(
        pageId: "PollPage",
        entityId: args.ent.entityReference.entityId,
        processId: args.processId);

    if (processModel.isInCensus.hasError ||
        processModel.isInCensus.isNotValid ||
        !(processModel.isInCensus.currentValue is bool)) {
      processModel.updateCensusState(); // TODO: DEBOUNCE THIS CALL
    }
    if (!processModel.startDate.isValid || !processModel.endDate.isValid) {
      processModel.updateDates();
    }
    processModel.updateHasVoted();
  }

  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    EntModel ent = args.ent;
    final int index = args.index ?? 0;
    //Process process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl = validUriOrNull(
        processModel.processMetadata.value?.details?.headerImage);
    return ScaffoldWithImage(
        headerImageUrl: headerUrl,
        headerTag: headerUrl == null
            ? null
            : makeElementTag(
                ent.entityReference.entityId,
                processModel.processMetadata.value.meta[META_PROCESS_ID],
                index),
        avatarHexSource: processModel.processMetadata.value.meta['processId'],
        appBarTitle: "Poll",
        actionsBuilder: actionsBuilder,
        builder: Builder(
          builder: (ctx) {
            return SliverList(
              delegate: SliverChildListDelegate(getScaffoldChildren(ctx, ent)),
            );
          },
        ));
  }

  List<Widget> actionsBuilder(BuildContext context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    final EntModel ent = args.ent;
    return [
      buildShareButton(context, ent),
    ];
  }

  // buildTest() {
  //   double avatarHeight = 120;
  //   return Container(
  //     height: avatarHeight,
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.stretch,
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: <Widget>[
  //         Container(
  //           constraints:
  //               BoxConstraints(minWidth: avatarHeight, minHeight: avatarHeight),
  //           child: CircleAvatar(
  //               backgroundColor: Colors.indigo,
  //               backgroundImage: NetworkImage(
  //                   "https://instagram.fmad5-1.fna.fbcdn.net/vp/564db12bde06a8cb360e31007fd049a6/5DDF1906/t51.2885-19/s150x150/13167299_1084444071617255_680456677_a.jpg?_nc_ht=instagram.fmad5-1.fna.fbcdn.net")),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  getScaffoldChildren(BuildContext context, EntModel ent) {
    List<Widget> children = [];
    if (processModel.processMetadata.value == null) return children;

    //children.add(buildTest());
    children.add(buildTitle(context, ent));
    children.add(Summary(
      text: processModel.processMetadata.value.details.description['default'],
      maxLines: 5,
    ));
    children.add(buildPollItem(context));
    children.add(buildCensusItem(context));
    children.add(buildTimeItem(context));
    children.addAll(buildQuestions(context));
    children.add(Section());
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(context));

    return children;
  }

  buildTitle(BuildContext context, EntModel ent) {
    if (processModel.processMetadata.value == null) return Container();

    String title = processModel.processMetadata.value.details.title['default'];
    return ListItem(
      // mainTextTag: makeElementTag(entityId: ent.entityReference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
      mainText: title,
      secondaryText: ent.entityMetadata.value.name['default'],
      isTitle: true,
      rightIcon: null,
      isBold: true,
      avatarUrl: ent.entityMetadata.value.media.avatar,
      avatarText: ent.entityMetadata.value.name['default'],
      avatarHexSource: ent.entityReference.entityId,
      //avatarHexSource: ent.entitySummary.entityId,
      mainTextFullWidth: true,
    );
  }

  buildRawItem(BuildContext context, ProcessMetadata process) {
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

  buildCensusItem(BuildContext context) {
    return StateBuilder(
        viewModels: [processModel],
        tag: ProcessTags.CENSUS_STATE,
        builder: (ctx, tagId) {
          String text;
          Purpose purpose;
          IconData icon;

          if (processModel.isInCensus.isUpdating) {
            text = "Checking census";
          } else if (processModel.isInCensus.isValid) {
            if (processModel.isInCensus.value) {
              text = "You are in the census";
              purpose = Purpose.GOOD;
              icon = FeatherIcons.check;
            } else {
              text = "You are not in this census";
              purpose = Purpose.DANGER;
              icon = FeatherIcons.x;
            }
          } else if (processModel.isInCensus.isError) {
            text = processModel.isInCensus.errorMessage;
            icon = FeatherIcons.alertTriangle;
          } else {
            text = "Check census state";
          }

          return ListItem(
            icon: FeatherIcons.users,
            mainText: text,
            isSpinning: processModel.isInCensus.isUpdating,
            onTap: () {
              processModel.updateCensusState();
            },
            rightTextPurpose: purpose,
            rightIcon: icon,
            purpose: processModel.isInCensus.isNotValid
                ? Purpose.DANGER
                : Purpose.NONE,
          );
        });
  }

  buildPollItem(BuildContext context) {
    return ListItem(
      icon: FeatherIcons.barChart2,
      mainText: "Not anonymous poll",
      rightIcon: null,
      disabled: false,
    );
  }

  buildTimeItem(BuildContext context) {
    if (!processModel.endDate.isValid) return Container();

    String formattedTime =
        DateFormat("dd/MM H:mm").format(processModel.endDate.value) + "h";

    return ListItem(
      icon: FeatherIcons.clock,
      mainText: "Ending on " + formattedTime,
      //secondaryText: "18/09/2019 at 19:00",
      rightIcon: null,
      disabled: false,
    );
  }

  setChoice(int questionIndex, String value) {
    setState(() {
      _choices[questionIndex] = value;
    });
  }

  /// Returns the 0-based index of the next unanswered question.
  /// Returns -1 if all questions have a valid choice
  int getNextPendingChoice() {
    int idx = 0;
    for (final response in _choices) {
      if (response is String && response.length > 0) {
        idx++;
        continue; // GOOD
      }
      return idx; // PENDING
    }
    return -1; // ALL GOOD
  }

  buildSubmitVoteButton(BuildContext ctx) {
    if (processModel.isInCensus.isNotValid) return Container();

    if (processModel.isInCensus.isValid != true ||
        processModel.hasVoted.value == true) {
      return Container();
    }
    final nextPendingChoice = getNextPendingChoice();

    return Padding(
      padding: EdgeInsets.all(paddingPage),
      child: BaseButton(
          text: "Submit",
          isSmall: false,
          style: BaseButtonStyle.FILLED,
          purpose: Purpose.HIGHLIGHT,
          isDisabled:
              nextPendingChoice >= 0 || processModel.isInCensus.value == false,
          onTap: () {
            onSubmit(ctx, processModel.processMetadata);
          }),
    );
  }

  onSubmit(BuildContext ctx, processMetadata) async {
    var intAnswers = _choices.map(int.parse).toList();

    await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PollPackaging(
                processModel: processModel, answers: intAnswers)));
  }

  buildSubmitInfo() {
    return StateBuilder(
      viewModels: [processModel],
      tag: ProcessTags.CENSUS_STATE,
      builder: (ctx, tagId) {
        final nextPendingChoice = getNextPendingChoice();

        if (processModel.hasVoted.value == true) {
          return ListItem(
            mainText: 'Your vote is already registered',
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (processModel.isInCensus.isValid) {
          if (processModel.isInCensus.value) {
            return nextPendingChoice >= 0 // still pending
                ? ListItem(
                    mainText:
                        'Select your choice for question #${nextPendingChoice + 1}',
                    purpose: Purpose.WARNING,
                    rightIcon: null,
                  )
                : Container();
          } else {
            return ListItem(
              mainText: "You are not in the census",
              secondaryText:
                  "Register to this organization to participate in the future",
              secondaryTextMultiline: 5,
              purpose: Purpose.HIGHLIGHT,
              rightIcon: null,
            );
          }
        } else {
          return ListItem(
            mainText: "Your identity cannot be checked against the census",
            mainTextMultiline: 3,
            secondaryText: "Please, try to check again",
            secondaryTextMultiline: 5,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        }
      },
    );
  }

  buildShareButton(BuildContext context, EntModel ent) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: ent.entityReference.entityId));
          showMessage("Entity ID copied on the clipboard",
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

  List<Widget> buildQuestions(BuildContext ctx) {
    if (!processModel.processMetadata.isValid ||
        processModel.processMetadata.value.details.questions.length == 0) {
      return [];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in processModel.processMetadata.value.details.questions) {
      items.addAll(buildQuestion(question, questionIndex));
      questionIndex++;
    }

    return items;
  }

  List<Widget> buildQuestion(
      ProcessMetadata_Details_Question question, int questionIndex) {
    List<Widget> items = new List<Widget>();

    if (question.type == "single-choice") {
      items.add(Section(text: (questionIndex + 1).toString()));
      items.add(buildQuestionTitle(question, questionIndex));

      List<Widget> options = new List<Widget>();
      question.voteOptions.forEach((voteOption) {
        options.add(Padding(
          padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, 0),
          child: ChoiceChip(
            backgroundColor: colorLightGuide,
            selectedColor: colorBlue,
            padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
            label: Text(
              voteOption.title['default'],
              overflow: TextOverflow.ellipsis,
              maxLines: 5,
              style: TextStyle(
                  fontSize: fontSizeSecondary,
                  fontWeight: fontWeightRegular,
                  color: _choices[questionIndex] == voteOption.value
                      ? Colors.white
                      : colorDescription),
            ),
            selected: _choices[questionIndex] == voteOption.value,
            onSelected: (bool selected) {
              if (selected) {
                setChoice(questionIndex, voteOption.value);
              }
            },
          ),
        ));
      });

      items.add(
        Column(
          children: options,
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    } else {
      String questionType = question.type;
      buildError("Question type not supported: $questionType");
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

  buildQuestionTitle(ProcessMetadata_Details_Question question, int index) {
    return ListItem(
      mainText: question.question['default'],
      secondaryText: question.description['default'],
      secondaryTextMultiline: 100,
      rightIcon: null,
    );
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
