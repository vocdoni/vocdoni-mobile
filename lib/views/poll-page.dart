import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/controllers/ent.dart';
import 'package:vocdoni/controllers/process.dart';
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
  Ent ent;
  Process process;
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
  bool _hasVoted = false;
  bool _checkingCensus = false;
  Process _process;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PollPageArgs args = ModalRoute.of(context).settings.arguments;

    _process = args.process;
    if (_answers.length == 0)
      _process.processMetadata.details.questions.forEach((question) {
        _answers.add("");
      });

    checkResponseState();
    if (_process.censusState == CensusState.UNKNOWN) checkCensusState();
  }

  @override
  Widget build(context) {
    PollPageArgs args = ModalRoute.of(context).settings.arguments;
    Ent ent = args.ent;
    //Process process = args.process;

    if (ent == null) return buildEmptyEntity(context);

    String headerUrl =
        validUriOrNull(_process.processMetadata.details.headerImage);
    return ScaffoldWithImage(
        headerImageUrl: headerUrl,
        headerTag: headerUrl == null
            ? null
            : makeElementTag(
                entityId: ent.entityReference.entityId,
                cardId: _process.processMetadata.meta[META_PROCESS_ID],
                elementId: headerUrl),
        avatarHexSource: _process.processMetadata.meta['processId'],
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

  getScaffoldChildren(BuildContext context, Ent ent) {
    List<Widget> children = [];
    //children.add(buildTest());
    children.add(buildTitle(context, ent));
    children.add(Summary(
      text: _process.processMetadata.details.description['default'],
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

  buildTitle(BuildContext context, Ent ent) {
    String title = _process.processMetadata.details.title['default'];
    return ListItem(
      // mainTextTag: makeElementTag(entityId: ent.entityReference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
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

  buildCensusItem(BuildContext context) {
    String text;
    Purpose purpose;
    IconData icon;

    if (_process.censusState == CensusState.UNKNOWN) {
      text = "Check census state";
    }

    if (_process.censusState == CensusState.IN) {
      text = "You are in the census";
      purpose = Purpose.GOOD;
      icon = FeatherIcons.check;
    }

    if (_process.censusState == CensusState.OUT) {
      text = "You are not in this census";
      purpose = Purpose.DANGER;
      icon = FeatherIcons.x;
    }

    if (_process.censusState == CensusState.ERROR) {
      text = "Unable to check census";
      icon = FeatherIcons.alertTriangle;
    }

    if (_checkingCensus) {
      text = "Checking census";
    }

    return ListItem(
      icon: FeatherIcons.users,
      mainText: text,
      isSpinning: _checkingCensus,
      onTap: () {
        checkCensusState();
      },
      rightTextPurpose: purpose,
      rightIcon: icon,
      purpose: _process.censusState == CensusState.ERROR
          ? Purpose.DANGER
          : Purpose.NONE,
    );
  }

  checkCensusState() async {
    setState(() {
      _checkingCensus = true;
    });
    await _process.checkCensusState();
    if (!mounted) return;
    setState(() {
      _process = _process;
      _checkingCensus = false;
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
    final dat = _process.getEndDate();
    String formattedTime =
        dat != null ? DateFormat("dd/MM, H:m:s").format(dat) : "";
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
    if (_process.censusState != CensusState.IN) return Container();
    return Padding(
      padding: EdgeInsets.all(paddingPage),
      child: BaseButton(
          text: "Submit",
          isSmall: false,
          style: BaseButtonStyle.FILLED,
          purpose: Purpose.HIGHLIGHT,
          isDisabled: _responsesAreValid == false ||
              _process.censusState != CensusState.IN,
          onTap: () {
            onSubmit(ctx, _process.processMetadata);
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
                processMetadata: processMetadata,
                answers: intAnswers)));
  }

  buildSubmitInfo() {
    if (_process.censusState == CensusState.IN) {
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
    } else if (_process.censusState == CensusState.OUT) {
      return ListItem(
        mainText: "You are not part of this census",
        secondaryText:
            "Register to this organization to participate in the future",
        secondaryTextMultiline: 5,
        purpose: Purpose.HIGHLIGHT,
        rightIcon: null,
      );
    } else if (_process.censusState == CensusState.ERROR) {
      return ListItem(
        mainText: "Unable to check if you are part of the census",
        mainTextMultiline: 3,
        secondaryText: "Please, try to validate again.",
        secondaryTextMultiline: 5,
        purpose: Purpose.WARNING,
        rightIcon: null,
      );
    }
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

  List<Widget> buildQuestions(BuildContext ctx) {
    if (_process.processMetadata.details.questions.length == 0) {
      return [buildError("No questions defined")];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in _process.processMetadata.details.questions) {
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
