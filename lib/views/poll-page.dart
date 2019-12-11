import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/modals/pattern-prompt-modal.dart';
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
  PollPageArgs({this.ent, this.processId, this.index});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  List<String> _answers = [];
  String _responsesStateMessage = '';
  bool _responsesAreValid = false;
  ProcessModel processModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PollPageArgs args = ModalRoute.of(context).settings.arguments;

    analytics.trackPage(
        pageId: "PollPage",
        entityId: args.ent.entityReference.entityId,
        processId: args.processId);

    processModel = args.ent.getProcess(args.processId);
    if (_answers.length == 0)
      processModel.processMetadata.value.details.questions.forEach((question) {
        _answers.add("");
      });

    checkResponseState();
    processModel.updateCensusState();
  }

  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    EntModel ent = args.ent;
    final int index = args.index ?? 0;
    //Process process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl =
        validUriOrNull(processModel.processMetadata.value.details.headerImage);
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

          if (processModel.censusIsIn.isUpdating) {
            text = "Checking census";
          } else if (processModel.censusIsIn.isValid) {
            if (processModel.censusIsIn.value) {
              text = "You are in the census";
              purpose = Purpose.GOOD;
              icon = FeatherIcons.check;
            } else {
              text = "You are not in this census";
              purpose = Purpose.DANGER;
              icon = FeatherIcons.x;
            }
          } else if (processModel.censusIsIn.isError) {
            text = processModel.censusIsIn.errorMessage;
            icon = FeatherIcons.alertTriangle;
          } else {
            text = "Check census state";
          }

          return ListItem(
            icon: FeatherIcons.users,
            mainText: text,
            isSpinning: processModel.censusIsIn.isUpdating,
            onTap: () {
              processModel.updateCensusState();
            },
            rightTextPurpose: purpose,
            rightIcon: icon,
            purpose: processModel.censusIsIn.isNotValid
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
    String formattedTime = "";
    if (processModel.endDate.isValid) {
      formattedTime =
          DateFormat("dd/MM, H:m:s").format(processModel.endDate.value);
    }

    return ListItem(
      icon: FeatherIcons.clock,
      mainText: "Process ends on " + formattedTime,
      //secondaryText: "18/09/2019 at 19:00",
      rightIcon: null,
      disabled: false,
    );
  }

  setResponse(int questionIndex, String value) {
    setState(() {
      _answers[questionIndex] = value;
    });

    checkResponseState();
  }

  checkResponseState() {
    bool allGood = true;
    int idx = 1;
    for (final response in _answers) {
      if (response == '') {
        allGood = false;
        setState(() {
          _responsesAreValid = false;
          _responsesStateMessage = 'Question #$idx needs to be answered';
        });
        break;
      }
      idx++;
    }

    if (allGood) {
      setState(() {
        _responsesAreValid = true;
        _responsesStateMessage = '';
      });
    }
  }

  buildSubmitVoteButton(BuildContext ctx) {
    if (processModel.censusIsIn.isNotValid) return Container();

    if (processModel.censusIsIn.isValid)
      return Padding(
        padding: EdgeInsets.all(paddingPage),
        child: BaseButton(
            text: "Submit",
            isSmall: false,
            style: BaseButtonStyle.FILLED,
            purpose: Purpose.HIGHLIGHT,
            isDisabled:
                _responsesAreValid == false || processModel.censusIsIn == false,
            onTap: () {
              onSubmit(ctx, processModel.processMetadata);
            }),
      );
  }

  onSubmit(ctx, processMetadata) async {
    var encryptionKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(
                account.identity.keys[0].encryptedPrivateKey)));
    if (encryptionKey == null || encryptionKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    var intAnswers = _answers.map(int.parse).toList();

    final privateKey = await decryptString(
        account.identity.keys[0].encryptedPrivateKey, encryptionKey);

    await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PollPackaging(
                privateKey: privateKey,
                processModel: processModel,
                answers: intAnswers)));
  }

  buildSubmitInfo() {
    return StateBuilder(
      viewModels: [processModel],
      tag: ProcessTags.CENSUS_STATE,
      builder: (ctx, tagId) {
        if (processModel.censusIsIn.isValid) {
          if (processModel.censusIsIn.value) {
            return _responsesAreValid == false
                ? ListItem(
                    mainText: _responsesStateMessage,
                    purpose: Purpose.WARNING,
                    rightIcon: null,
                  )
                : ListItem(
                    mainText: _responsesStateMessage,
                    rightIcon: null,
                  );
          } else {
            return ListItem(
              mainText: "You are not part of this census",
              secondaryText:
                  "Register to this organization to participate in the future",
              secondaryTextMultiline: 5,
              purpose: Purpose.HIGHLIGHT,
              rightIcon: null,
            );
          }
        } else {
          return ListItem(
            mainText: "Unable to check if you are part of the census",
            mainTextMultiline: 3,
            secondaryText: "Please, try to validate again.",
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

  List<Widget> buildQuestions(BuildContext ctx) {
    if (processModel.processMetadata.value.details.questions.length == 0) {
      return [buildError("No questions defined")];
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
                  color: _answers[questionIndex] == voteOption.value
                      ? Colors.white
                      : colorDescription),
            ),
            selected: _answers[questionIndex] == voteOption.value,
            onSelected: (bool selected) {
              if (selected) {
                setResponse(questionIndex, voteOption.value);
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
