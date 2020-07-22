import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/util.dart';

import 'package:vocdoni/views/poll-packaging-page.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/summary.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:intl/intl.dart';

class PollPageArgs {
  EntityModel entity;
  ProcessModel process;
  final int index;
  PollPageArgs(
      {@required this.entity, @required this.process, @required this.index});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  EntityModel entity;
  ProcessModel process;
  int index;
  List<int> choices = [];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    final PollPageArgs args = ModalRoute.of(context).settings.arguments;
    if (args == null) {
      Navigator.of(context).pop();
      devPrint("Invalid parameters");
      return;
    } else if (!args.process.metadata.hasValue) {
      Navigator.of(context).pop();
      devPrint("Empty process metadata");
      return;
    } else if (entity == args.entity &&
        process == args.process &&
        index == args.index) return;

    entity = args.entity;
    process = args.process;
    index = args.index;

    choices = process.metadata.value.details.questions
        .map((question) => null)
        .cast<int>()
        .toList();

    globalAnalytics.trackPage("PollPage",
        entityId: entity.reference.entityId, processId: process.processId);

    await process
        .refreshHasVoted()
        .then((_) => process.refreshIsInCensus())
        .then((_) => globalAppState.refreshBlockInfo())
        .catchError((err) => devPrint(err)); // Values will refresh if not fresh
  }

  @override
  Widget build(context) {
    if (entity == null) return buildEmptyEntity(context);

    // By the constructor, this.process.metadata is guaranteed to exist

    return EventualBuilder(
      notifiers: [process.metadata, entity.metadata],
      builder: (context, _, __) {
        if (process.metadata.hasError && !process.metadata.hasValue)
          return buildErrorScaffold(process.metadata.errorMessage);

        final headerUrl =
            Uri.tryParse(process.metadata.value.details?.headerImage ?? "")
                ?.toString();

        return ScaffoldWithImage(
          headerImageUrl: headerUrl ?? "",
          headerTag: headerUrl == null
              ? null
              : makeElementTag(
                  entity.reference.entityId, process.processId, index),
          avatarHexSource: process.processId,
          appBarTitle: getText(context, "Poll"),
          actionsBuilder: (context) => [
            buildShareButton(context, process.processId),
          ],
          builder: Builder(
            builder: (ctx) => SliverList(
              delegate: SliverChildListDelegate(
                getScaffoldChildren(ctx, entity),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> getScaffoldChildren(BuildContext context, EntityModel entity) {
    List<Widget> children = [];
    if (!process.metadata.hasValue) return children;

    children.add(buildTitle(context, entity));
    children.add(buildSummary());
    children.add(buildPollItem(context));
    children.add(buildCensusItem(context));
    children.add(buildTimeItem(context));
    children.addAll(buildQuestions(context));
    children.add(Section(withDectoration: false));
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(context));

    return children;
  }

  Widget buildTitle(BuildContext context, EntityModel entity) {
    if (process.metadata.value == null) return Container();

    final title =
        process.metadata.value.details.title[globalAppState.currentLanguage];

    return EventualBuilder(
      notifier: entity.metadata,
      builder: (context, _, __) => ListItem(
        // mainTextTag: makeElementTag(entityId: ent.reference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
        mainText: title,
        mainTextMultiline: 3,
        secondaryText: entity.metadata.hasValue
            ? entity.metadata.value.name[globalAppState.currentLanguage]
            : "",
        isTitle: true,
        rightIcon: null,
        isBold: true,
        avatarUrl:
            entity.metadata.hasValue ? entity.metadata.value.media.avatar : "",
        avatarText: entity.metadata.hasValue
            ? entity.metadata.value.name[globalAppState.currentLanguage]
            : "",
        avatarHexSource: entity.reference.entityId,
        //avatarHexSource: entity.entitySummary.entityId,
        mainTextFullWidth: true,
      ),
    );
  }

  Widget buildSummary() {
    return Summary(
      text: process
          .metadata.value.details.description[globalAppState.currentLanguage],
      maxLines: 5,
    );
  }

  buildCensusItem(BuildContext context) {
    return EventualBuilder(
      notifier: process.isInCensus,
      builder: (ctx, _, __) {
        String text;
        Purpose purpose;
        IconData icon;

        if (process.isInCensus.isLoading) {
          text = getText(context, "Checking the census");
          purpose = Purpose.GUIDE;
        } else if (process.isInCensus.hasValue) {
          if (process.isInCensus.value) {
            text = getText(context, "You are in the census");
            purpose = Purpose.GOOD;
            icon = FeatherIcons.check;
          } else {
            text = getText(context, "You are not in the census");
            purpose = Purpose.DANGER;
            icon = FeatherIcons.x;
          }
        } else if (process.isInCensus.hasError) {
          text = process.isInCensus.errorMessage;
          purpose = Purpose.DANGER;
          icon = FeatherIcons.alertTriangle;
        } else {
          text = getText(context, "Check census state");
        }

        return ListItem(
          icon: FeatherIcons.users,
          mainText: text,
          isSpinning: process.isInCensus.isLoading,
          onTap: () => process.refreshIsInCensus(true),
          rightTextPurpose: purpose,
          rightIcon: icon,
          purpose: purpose ?? Purpose.NONE,
        );
      },
    );
  }

  buildPollItem(BuildContext context) {
    return ListItem(
      icon: FeatherIcons.barChart2,
      mainText: getText(context, "Public poll"),
      rightIcon: null,
      disabled: false,
    );
  }

  buildTimeItem(BuildContext context) {
    // Rebuild when the reference block changes
    return EventualBuilder(
      notifiers: [process.metadata, globalAppState.referenceBlockTimestamp],
      builder: (context, _, __) {
        String rowText;

        if (process.startDate is DateTime &&
            DateTime.now().isBefore(process.startDate)) {
          // TODO: Localize date formats
          final formattedTime =
              DateFormat("dd/MM HH:mm").format(process.startDate) + "h";
          rowText = getText(context, "Starting on {{DATE}}")
              .replaceFirst("{{DATE}}", formattedTime);
        } else if (process.endDate is DateTime) {
          // TODO: Localize date formats
          final formattedTime =
              DateFormat("dd/MM HH:mm").format(process.endDate) + "h";

          if (process.endDate.isBefore(DateTime.now()))
            rowText = getText(context, "Ended on {{DATE}}")
                .replaceFirst(("{{DATE}}"), formattedTime);
          else
            rowText = getText(context, "Ending on {{DATE}}")
                .replaceFirst(("{{DATE}}"), formattedTime);
        }

        if (rowText is String) {
          return ListItem(
            icon: FeatherIcons.clock,
            mainText: rowText,
            //secondaryText: "18/09/2019 at 19:00",
            rightIcon: null,
            disabled: false,
          );
        }

        return Container();
      },
    );
  }

  setChoice(int questionIndex, int value) {
    setState(() {
      choices[questionIndex] = value;
    });
  }

  /// Returns the 0-based index of the next unanswered question.
  /// Returns -1 if all questions have a valid choice
  int getNextPendingChoice() {
    int idx = 0;
    for (final choice in choices) {
      if (choice is int) {
        idx++;
        continue; // GOOD
      }
      return idx; // PENDING
    }
    return -1; // ALL GOOD
  }

  buildSubmitVoteButton(BuildContext ctx) {
    // rebuild when isInCensus or hasVoted change
    return EventualBuilder(
      notifiers: [process.hasVoted, process.isInCensus],
      builder: (ctx, _, __) {
        final nextPendingChoice = getNextPendingChoice();
        final cannotVote = nextPendingChoice >= 0 ||
            !process.isInCensus.hasValue ||
            !process.isInCensus.value ||
            process.hasVoted.value == true ||
            process.startDate.isAfter(DateTime.now()) ||
            process.endDate.isBefore(DateTime.now());

        if (cannotVote) {
          return Container();
        }

        return Padding(
          padding: EdgeInsets.all(paddingPage),
          child: BaseButton(
              text: getText(context, "Submit"),
              purpose: cannotVote ? Purpose.DANGER : Purpose.HIGHLIGHT,
              isDisabled: cannotVote,
              onTap: () => onSubmit(ctx, process.metadata)),
        );
      },
    );
  }

  onSubmit(BuildContext ctx, metadata) async {
    final newRoute = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            PollPackagingPage(process: process, choices: choices));
    await Navigator.push(ctx, newRoute);
  }

  buildSubmitInfo() {
    // rebuild when isInCensus or hasVoted change
    return EventualBuilder(
      notifiers: [process.hasVoted, process.isInCensus],
      builder: (ctx, _, __) {
        final nextPendingChoice = getNextPendingChoice();

        if (process.hasVoted.hasValue && process.hasVoted.value) {
          return ListItem(
            mainText: getText(context, 'Your vote is already registered'),
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (process.startDate.isAfter(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "The process is not active yet"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.endDate.isBefore(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "The process has already ended"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasValue && !process.isInCensus.value) {
          return ListItem(
            mainText: getText(context, "You are not in the census"),
            secondaryText: getText(context,
                "Register to this organization to participate in the future"),
            secondaryTextMultiline: 5,
            purpose: Purpose.DANGER,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasError) {
          return ListItem(
            mainText: getText(
                context, "Your identity cannot be checked within the census"),
            mainTextMultiline: 3,
            secondaryText: process.isInCensus.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (nextPendingChoice >= 0) {
          return ListItem(
            mainText: getText(
                    context, "Select your choice for question #{{NUM}}")
                .replaceFirst("{{NUM}}", (nextPendingChoice + 1).toString()),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.hasVoted.hasError) {
          return ListItem(
            mainText: getText(context, "Your vote status cannot be checked"),
            mainTextMultiline: 3,
            secondaryText: process.hasVoted.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.isLoading) {
          return ListItem(
            mainText: getText(context, "Checking the census"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else if (process.hasVoted.isLoading) {
          return ListItem(
            mainText: getText(context, "Checking your vote"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else {
          return Container(); // unknown error
        }
      },
    );
  }

  buildShareButton(BuildContext context, String processId) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: processId));
          showMessage(getText(context, "Poll ID copied on the clipboard"),
              context: context, purpose: Purpose.GOOD);
        });
  }

  Widget buildEmptyEntity(BuildContext ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text(getText(context, "(No entity)")),
        ));
  }

  List<Widget> buildQuestions(BuildContext ctx) {
    if (!process.metadata.hasValue ||
        process.metadata.value.details.questions.length == 0) {
      return [];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Details_Question question
        in process.metadata.value.details.questions) {
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
                  color: choices[questionIndex] == voteOption.value
                      ? Colors.white
                      : colorDescription),
            ),
            selected: choices[questionIndex] == voteOption.value,
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
      print("ERROR: Question type not supported: " + question.type);
      buildError(getText(context, "Question type not supported"));
    }
    return items;
  }

  buildError(String error) {
    return ListItem(
      mainText: getText(context, "Error") + " " + error,
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  Widget buildErrorScaffold(String error) {
    return Scaffold(
      body: Center(
        child: Text(
          getText(context, "Error") + ":\n" + error,
          style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  buildQuestionTitle(ProcessMetadata_Details_Question question, int index) {
    return ListItem(
      mainText: question.question['default'],
      mainTextMultiline: 3,
      secondaryText: question.description['default'],
      secondaryTextMultiline: 100,
      rightIcon: null,
    );
  }

  goBack(BuildContext ctx) {
    Navigator.pop(ctx, false);
  }
}
