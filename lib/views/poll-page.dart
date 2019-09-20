import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/controllers/ent.dart';
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

enum CensusState { IN, OUT, UNKNOWN, CHECKING, ERROR }

class PollPageArgs {
  Ent ent;
  ProcessMetadata process;

  PollPageArgs({this.ent, this.process});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  List<String> _answers = [];
  String _responsesStateMessage = '';
  bool _responsesAreValid = false;
  CensusState _censusState = CensusState.UNKNOWN;
  bool _isCheckingCensus = true;
  bool _hasVoted = false;

  @override
  void didChangeDependencies() {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;

    ProcessMetadata process = args.process;
    process.details.questions.forEach((question) {
      _answers.add("");
    });

    checkResponseState();
    super.didChangeDependencies();
  }

  @override
  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    Ent ent = args.ent;
    ProcessMetadata process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl = process.details.headerImage == null
        ? null
        : process.details.headerImage;
    return ScaffoldWithImage(
        headerImageUrl: headerUrl,
        headerTag: headerUrl == null
            ? null
            : makeElementTag(
                entityId: ent.entityReference.entityId,
                cardId: process.meta[META_PROCESS_ID],
                elementId: headerUrl),
        avatarHexSource: process.meta['processId'],
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

  getScaffoldChildren(BuildContext context, Ent ent, ProcessMetadata process) {
    List<Widget> children = [];
    //children.add(buildTest());
    children.add(buildTitle(context, ent, process));
    children.add(Summary(
      text: process.details.description['default'],
      maxLines: 5,
    ));
    children.add(buildPollItem(context, process));
    children.add(buildCensusItem(context, process));
    children.add(buildTimeItem(context, process));
    children.addAll(buildQuestions(context, process));
    children.add(Section());
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(context, process));

    return children;
  }

  buildTitle(BuildContext context, Ent ent, ProcessMetadata process) {
    String title = process.details.title['default'];
    return ListItem(
      // mainTextTag: makeElementTag(entityId: ent.entityReference.entityId, cardId: process.meta[META_PROCESS_ID], elementId: process.details.headerImage)
      mainText: title,
      secondaryText: ent.entityMetadata.name['default'],
      isTitle: true,
      rightIcon: null,
      isBold: true,
      avatarUrl: ent.entityMetadata.media.avatar,
      avatarText: ent.entityMetadata.name['default'],
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

  buildCensusItem(BuildContext context, ProcessMetadata process) {
    String text = "Checking census";
    Purpose purpose = null;
    IconData icon = null;

    if (_censusState == CensusState.UNKNOWN) {
      text = "Check census state";
    }

    if (_censusState == CensusState.CHECKING) {
      text = "Checking census";
    }

    if (_censusState == CensusState.IN) {
      text = "You are in the census";
      purpose = Purpose.GOOD;
      icon = FeatherIcons.check;
    }

    if (_censusState == CensusState.OUT) {
      text = "You are in the census";
      purpose = Purpose.DANGER;
      icon = FeatherIcons.x;
    }

    if (_censusState == CensusState.ERROR) {
      text = "Unable to check census";
      icon = FeatherIcons.alertTriangle;
    }

    return ListItem(
      icon: FeatherIcons.users,
      mainText: text,
      isSpinning: _isCheckingCensus,
      onTap: () {
        setState(() {
          _isCheckingCensus = true;
        });
      },
      rightTextPurpose: purpose,
      rightIcon: icon,
      purpose: _censusState == CensusState.ERROR ? Purpose.DANGER : null,
    );
  }

  buildPollItem(BuildContext context, ProcessMetadata process) {
    return ListItem(
      icon: FeatherIcons.barChart2,
      mainText: "Not anonymous poll",
      rightIcon: null,
      disabled: false,
    );
  }

  buildTimeItem(BuildContext context, ProcessMetadata process) {
    return ListItem(
      icon: FeatherIcons.clock,
      mainText: "This process ends in 3h",
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

  buildSubmitVoteButton(BuildContext ctx, ProcessMetadata processMetadata) {
    return Padding(
      padding: EdgeInsets.all(paddingPage),
      child: BaseButton(
          text: "Submit",
          isSmall: false,
          style: BaseButtonStyle.FILLED,
          purpose: Purpose.HIGHLIGHT,
          isDisabled: _responsesAreValid == false,
          onTap: () {
            onSubmit(ctx, processMetadata);
          }),
    );
  }

  onSubmit(ctx, processMetadata) async {
    var privateKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(
                account.identity.keys[0].encryptedPrivateKey)));
    if (privateKey == null || privateKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PollPackaging(
                privateKey: privateKey,
                processMetadata: processMetadata,
                answers: _answers)));
    if (privateKey == null || privateKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }
  }

  buildSubmitInfo() {
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
  }

  buildShareButton(BuildContext context, Ent ent) {
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

  List<Widget> buildQuestions(BuildContext ctx, ProcessMetadata process) {
    if (process.details.questions.length == 0) {
      return [buildError("No questions defined")];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in process.details.questions) {
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
