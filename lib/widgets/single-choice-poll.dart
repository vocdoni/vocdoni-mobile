import 'package:dvote/dvote.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/util/scroll.dart';
import 'package:vocdoni/views/poll-packaging-page.dart';
import 'package:vocdoni/widgets/poll-question.dart';

class SingleChoicePoll extends StatefulWidget {
  final EntityModel entity;
  final ProcessModel process;
  final ScrollController scaffoldScrollController;
  final GlobalKey voteButtonKey;

  SingleChoicePoll(this.entity, this.process, this.scaffoldScrollController,
      this.voteButtonKey);

  @override
  _SingleChoicePollState createState() => _SingleChoicePollState();
}

class _SingleChoicePollState extends State<SingleChoicePoll> {
  List<int> choices = [];

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    choices = widget.process.metadata.value.questions
        .map((question) => null)
        .cast<int>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = List<Widget>();
    children.addAll(buildQuestions(
        context, onScrollToSelectedContent(widget.scaffoldScrollController)));
    children.add(Section(withDectoration: false));
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(context));
    return Column(children: children);
  }

  List<Widget> buildQuestions(BuildContext ctx, Function() onScroll) {
    if (!widget.process.metadata.hasValue ||
        widget.process.metadata.value.questions.length == 0) {
      return [];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Question question
        in widget.process.metadata.value.questions) {
      items.add(PollQuestion(question, questionIndex, widget.process,
          onSetChoice, onUnsetChoice, isSelected, onScroll, !canNotVote()));
      questionIndex++;
    }

    return items;
  }

  buildQuestionTitle(ProcessMetadata_Question question, int index) {
    return ListItem(
      mainText: question.title['default'],
      mainTextMultiline: 3,
      secondaryText: question.description['default'],
      secondaryTextMultiline: 100,
      rightIcon: null,
    );
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

  bool canNotVote() {
    final nextPendingChoice = getNextPendingChoice();
    final cannotVote = nextPendingChoice >= 0 ||
        !widget.process.isInCensus.hasValue ||
        !widget.process.isInCensus.value ||
        widget.process.hasVoted.value == true ||
        !widget.process.startDate.hasValue ||
        !widget.process.endDate.hasValue ||
        widget.process.startDate.value.isAfter(DateTime.now()) ||
        widget.process.endDate.value.isBefore(DateTime.now());
    return cannotVote;
  }

  buildSubmitVoteButton(BuildContext ctx) {
    // rebuild when isInCensus or hasVoted change
    return Container(
      key: widget.voteButtonKey,
      child: EventualBuilder(
        notifiers: [widget.process.hasVoted, widget.process.isInCensus],
        builder: (ctx, _, __) {
          if (canNotVote()) {
            return Container();
          }

          return Padding(
            padding: EdgeInsets.all(paddingPage),
            child: BaseButton(
                text: getText(context, "action.submit"),
                purpose: Purpose.HIGHLIGHT,
                // purpose: cannotVote ? Purpose.DANGER : Purpose.HIGHLIGHT,
                // isDisabled: cannotVote,
                onTap: () => onSubmit(ctx, widget.process.metadata)),
          );
        },
      ),
    );
  }

  onSubmit(BuildContext ctx, metadata) async {
    final newRoute = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            PollPackagingPage(process: widget.process, choices: choices));
    await Navigator.push(ctx, newRoute);
    widget.process.refreshResults(force: true);
    widget.process
        .refreshCurrentParticipants(force: true); // Refresh percentage
  }

  onSetChoice(int questionIndex, int value) {
    setState(() {
      choices[questionIndex] = value;
    });
  }

// Choices automatically unset when new option selected
  onUnsetChoice(int questionIndex, int value) {}

  bool isSelected(int questionIndex, int value) {
    return choices[questionIndex] == value;
  }

  Widget buildSubmitInfo() {
    // rebuild when isInCensus or hasVoted change
    return EventualBuilder(
      notifiers: [widget.process.hasVoted, widget.process.isInCensus],
      builder: (ctx, _, __) {
        final nextPendingChoice = getNextPendingChoice();

        if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value) {
          return ListItem(
            mainText: getText(context, "status.yourVoteIsAlreadyRegistered"),
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (!widget.process.startDate.hasValue ||
            !widget.process.endDate.hasValue) {
          return ListItem(
            mainText:
                getText(context, "error.theProcessDatesCannotBeDetermined"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (widget.process.startDate.value.isAfter(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "status.theProcessIsNotActiveYet"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (widget.process.endDate.value.isBefore(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "status.theProcessHasAlreadyEnded"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (widget.process.isInCensus.hasValue &&
            !widget.process.isInCensus.value) {
          return ListItem(
            mainText: getText(context, "error.youAreNotInTheCensus"),
            secondaryText: getText(context,
                "main.registerToThisOrganizationToParticipateInTheFuture"),
            secondaryTextMultiline: 5,
            purpose: Purpose.DANGER,
            rightIcon: null,
          );
        } else if (widget.process.isInCensus.hasError) {
          return ListItem(
            mainText: getText(
                context, "main.yourIdentityCannotBeCheckedWithinTheCensus"),
            mainTextMultiline: 3,
            // translate the key from setError()
            secondaryText:
                getText(context, widget.process.isInCensus.errorMessage),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (!widget.process.isInCensus.hasValue) {
          return ListItem(
            mainText: getText(context, "error.theCensusCannotBeChecked"),
            secondaryText:
                getText(context, "main.tapAboveOnCheckTheCensusAndTryAgain"),
            secondaryTextMultiline: 5,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (nextPendingChoice >= 0) {
          return ListItem(
            mainText: getText(context, "main.selectYourChoiceForQuestionNum")
                .replaceFirst("{{NUM}}", (nextPendingChoice + 1).toString()),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (widget.process.hasVoted.hasError) {
          return ListItem(
            mainText: getText(context, "error.yourVoteStatusCannotBeChecked"),
            mainTextMultiline: 3,
            // translate the key from setError()
            secondaryText:
                getText(context, widget.process.hasVoted.errorMessage),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (widget.process.isInCensus.isLoading) {
          return ListItem(
            mainText: getText(context, "status.checkingTheCensus"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else if (widget.process.hasVoted.isLoading) {
          return ListItem(
            mainText: getText(context, "status.checkingYourVote"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else {
          return Container(); // unknown error
        }
      },
    );
  }
}
