import 'package:dvote/wrappers/process-results.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'dart:async';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/extensions.dart';
import "dart:developer";
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:rainbow_color/rainbow_color.dart';
import 'package:vocdoni/views/poll-packaging-page.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:dvote_common/widgets/summary.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:mdi/mdi.dart';
import 'package:intl/intl.dart';

class PollPageArgs {
  EntityModel entity;
  ProcessModel process;
  final int listIdx;
  PollPageArgs(
      {@required this.entity, @required this.process, this.listIdx = 0});
}

class PollPage extends StatefulWidget {
  @override
  _PollPageState createState() => _PollPageState();
}

class _PollPageState extends State<PollPage> {
  Timer refreshCheck;
  EntityModel entity;
  ProcessModel process;
  int listIdx;
  List<int> choices = [];

  @override
  void initState() {
    // Try to update every 10 seconds (only if needed)
    refreshCheck = Timer.periodic(Duration(seconds: 10), (_) {});

    super.initState();
  }

  @override
  void dispose() {
    if (refreshCheck is Timer) refreshCheck.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    final PollPageArgs args = ModalRoute.of(context).settings.arguments;
    if (args == null) {
      Navigator.of(context).pop();
      log("Invalid parameters");
      return;
    } else if (!args.process.metadata.hasValue) {
      Navigator.of(context).pop();
      log("Empty process metadata");
      return;
    } else if (entity == args.entity &&
        process == args.process &&
        listIdx == args.listIdx) return;

    entity = args.entity;
    process = args.process;
    listIdx = args.listIdx;

    choices = process.metadata.value.details.questions
        .map((question) => null)
        .cast<int>()
        .toList();

    Globals.analytics.trackPage("PollPage",
        entityId: entity.reference.entityId, processId: process.processId);

    await onRefresh();
  }

  Future<void> onRefresh() {
    return process
        .refreshHasVoted()
        .then((_) => process.refreshResults())
        .then((_) => process.refreshIsInCensus())
        .then((_) => process.refreshDates())
        .catchError((err) => log(err)); // Values will refresh if needed
  }

  Future<void> onCheckCensus(BuildContext context) async {
    if (Globals.appState.currentAccount == null) {
      // NOTE: Keep the comment to force i18n key parsing
      // getText(context, "main.cannotCheckTheCensus")
      process.isInCensus.setError("main.cannotCheckTheCensus");
      return;
    }
    final account = Globals.appState.currentAccount;

    // Ensure that we have the public key
    if (!Globals.appState.currentAccount
        .hasPublicKeyForEntity(entity.reference.entityId)) {
      // Ask the pattern
      final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PatternPromptModal(account));
      final patternEncryptionKey = await Navigator.push(context, route);

      if (patternEncryptionKey == null)
        return;
      else if (patternEncryptionKey is InvalidPatternError) {
        showMessage(getText(context, "main.thePatternYouEnteredIsNotValid"),
            context: context, purpose: Purpose.DANGER);
        return;
      }

      // Good
      final mnemonic = SymmetricNative.decryptString(
          account.identity.value.keys[0].encryptedMnemonic,
          patternEncryptionKey);
      if (mnemonic == null) {
        // NOTE: Keep the comment to force i18n key parsing
        // getText(context, "main.cannotAccessTheWallet")
        process.isInCensus.setError("main.cannotAccessTheWallet");
        return;
      }

      final wallet = EthereumNativeWallet.fromMnemonic(mnemonic,
          entityAddressHash: entity.reference.entityId);

      account.setPublicKeyForEntity(
          await wallet.publicKeyAsync(uncompressed: true),
          entity.reference.entityId);
    }

    process.refreshIsInCensus(force: true);
  }

  @override
  Widget build(context) {
    if (entity == null) return buildEmptyPoll(context);

    // By the constructor, this.process.metadata is guaranteed to exist

    return EventualBuilder(
      notifiers: [process.metadata, entity.metadata],
      builder: (context, _, __) {
        if (process.metadata.hasError && !process.metadata.hasValue)
          return buildErrorScaffold(
              getText(context, "error.theMetadataIsNotAvailable"));

        final headerUrl =
            Uri.tryParse(process.metadata.value.details?.headerImage ?? "")
                ?.toString();

        return ScaffoldWithImage(
          headerImageUrl: headerUrl ?? "",
          headerTag: headerUrl == null
              ? null
              : makeElementTag(
                  entity.reference.entityId, process.processId, listIdx),
          avatarUrl: entity.metadata.value.media.avatar,
          avatarText:
              entity.metadata.value.name[Globals.appState.currentLanguage],
          avatarHexSource: process.processId,
          appBarTitle: getText(context, "main.vote"),
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
        process.metadata.value.details.title[Globals.appState.currentLanguage];

    return EventualBuilder(
      notifier: entity.metadata,
      builder: (context, _, __) => ListItem(
        // mainTextTag: makeElementTag(entityId: ent.reference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
        mainText: title,
        mainTextMultiline: 3,
        secondaryText: entity.metadata.hasValue
            ? entity.metadata.value.name[Globals.appState.currentLanguage]
            : "",
        isTitle: true,
        rightIcon: null,
        isBold: true,
        avatarUrl:
            entity.metadata.hasValue ? entity.metadata.value.media.avatar : "",
        avatarText: entity.metadata.hasValue
            ? entity.metadata.value.name[Globals.appState.currentLanguage]
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
          .metadata.value.details.description[Globals.appState.currentLanguage],
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

        if (!Globals.appState.currentAccount
            .hasPublicKeyForEntity(entity.reference.entityId)) {
          // We don't have the user's public key, probably because the entity was unknown when all
          // public keys were precomputed. Ask for the pattern.
          text = getText(context, "action.checkTheCensus");
        } else if (process.isInCensus.isLoading) {
          text = getText(context, "status.checkingTheCensus");
          purpose = Purpose.GUIDE;
        } else if (process.isInCensus.hasValue) {
          if (process.isInCensus.value) {
            text = getText(context, "status.youAreInTheCensus");
            purpose = Purpose.GOOD;
            icon = FeatherIcons.check;
          } else {
            text = getText(context, "error.youAreNotInTheCensus");
            purpose = Purpose.DANGER;
            icon = FeatherIcons.x;
          }
        } else if (process.isInCensus.hasError) {
          // translate the key from setError()
          text = getText(context, process.isInCensus.errorMessage);
          purpose = Purpose.DANGER;
          icon = FeatherIcons.alertTriangle;
        } else {
          text = getText(context, "action.checkCensusState");
        }

        return ListItem(
          icon: FeatherIcons.users,
          mainText: text,
          isSpinning: process.isInCensus.isLoading,
          onTap: () => onCheckCensus(context),
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
      mainText: getText(context, "main.publicVote"),
      rightIcon: null,
      disabled: false,
    );
  }

  buildTimeItem(BuildContext context) {
    // Rebuild when the reference block changes
    return EventualBuilder(
      notifiers: [process.metadata, process.startDate, process.endDate],
      builder: (context, _, __) {
        String rowText;
        Purpose purpose;
        final now = DateTime.now();

        if (process.startDate.hasValue &&
            now.isBefore(process.startDate.value)) {
          // TODO: Localize date formats
          final formattedTime =
              DateFormat("dd/MM HH:mm").format(process.startDate.value) + "h";
          rowText = getText(context, "main.startingOnDate")
              .replaceFirst("{{DATE}}", formattedTime);
          purpose = Purpose.WARNING;
        } else if (process.endDate.hasValue) {
          // TODO: Localize date formats
          final formattedTime =
              DateFormat("dd/MM HH:mm").format(process.endDate.value) + "h";

          if (process.endDate.value.isBefore(now)) {
            rowText = getText(context, "main.endedOnDate")
                .replaceFirst(("{{DATE}}"), formattedTime);
            purpose = Purpose.WARNING;
          } else {
            rowText = getText(context, "main.endingOnDate")
                .replaceFirst(("{{DATE}}"), formattedTime);
            purpose = Purpose.GOOD;
          }
        }

        if (rowText is! String) return Container();

        return ListItem(
          icon: FeatherIcons.clock,
          purpose: purpose,
          mainText: rowText,
          //secondaryText: "18/09/2019 at 19:00",
          rightIcon: null,
          disabled: false,
        );
      },
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
        !process.isInCensus.hasValue ||
        !process.isInCensus.value ||
        process.hasVoted.value == true ||
        !process.startDate.hasValue ||
        !process.endDate.hasValue ||
        process.startDate.value.isAfter(DateTime.now()) ||
        process.endDate.value.isBefore(DateTime.now());
    return cannotVote;
  }

  buildSubmitVoteButton(BuildContext ctx) {
    // rebuild when isInCensus or hasVoted change
    return EventualBuilder(
      notifiers: [process.hasVoted, process.isInCensus],
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

  Widget buildSubmitInfo() {
    // rebuild when isInCensus or hasVoted change
    return EventualBuilder(
      notifiers: [process.hasVoted, process.isInCensus],
      builder: (ctx, _, __) {
        final nextPendingChoice = getNextPendingChoice();

        if (process.hasVoted.hasValue && process.hasVoted.value) {
          return ListItem(
            mainText: getText(context, "status.yourVoteIsAlreadyRegistered"),
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (!process.startDate.hasValue || !process.endDate.hasValue) {
          return ListItem(
            mainText:
                getText(context, "error.theProcessDatesCannotBeDetermined"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.startDate.value.isAfter(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "status.theProcessIsNotActiveYet"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.endDate.value.isBefore(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "status.theProcessHasAlreadyEnded"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasValue && !process.isInCensus.value) {
          return ListItem(
            mainText: getText(context, "error.youAreNotInTheCensus"),
            secondaryText: getText(context,
                "main.registerToThisOrganizationToParticipateInTheFuture"),
            secondaryTextMultiline: 5,
            purpose: Purpose.DANGER,
            rightIcon: null,
          );
        } else if (process.isInCensus.hasError) {
          return ListItem(
            mainText: getText(
                context, "main.yourIdentityCannotBeCheckedWithinTheCensus"),
            mainTextMultiline: 3,
            // translate the key from setError()
            secondaryText: getText(context, process.isInCensus.errorMessage),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (!process.isInCensus.hasValue) {
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
        } else if (process.hasVoted.hasError) {
          return ListItem(
            mainText: getText(context, "error.yourVoteStatusCannotBeChecked"),
            mainTextMultiline: 3,
            // translate the key from setError()
            secondaryText: getText(context, process.hasVoted.errorMessage),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.isLoading) {
          return ListItem(
            mainText: getText(context, "status.checkingTheCensus"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else if (process.hasVoted.isLoading) {
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

  Widget buildShareButton(BuildContext context, String processId) {
    return BaseButton(
        leftIconData: FeatherIcons.share2,
        isSmall: false,
        style: BaseButtonStyle.NO_BACKGROUND_WHITE,
        onTap: () {
          Clipboard.setData(ClipboardData(text: processId));
          showMessage(getText(context, "main.pollIdCopiedOnTheClipboard"),
              context: context, purpose: Purpose.GOOD);
        });
  }

  Widget buildEmptyPoll(BuildContext ctx) {
    return Scaffold(
        appBar: TopNavigation(
          title: "",
        ),
        body: Center(
          child: Text(getText(context, "main.noPoll")),
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
      items.add(PollQuestion(
          question, questionIndex, choices, process, process.isInCensus.value));
      questionIndex++;
    }

    return items;
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

  buildError(String error) {
    return ListItem(
      mainText: getText(context, "main.error") + " " + error,
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  Widget buildErrorScaffold(String error) {
    return Scaffold(
      body: Center(
        child: Text(
          getText(context, "main.error") + ":\n" + error,
          style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class PollQuestion extends StatefulWidget {
  final ProcessMetadata_Details_Question question;
  final ProcessModel process;
  final List<int> choices;
  final int questionIndex;
  final bool isInCensus;
  final rb = Rainbow(spectrum: [
    colorRedPale.withOpacity(0.9),
    colorBluePale,
    colorGreenPale,
  ], rangeStart: 0, rangeEnd: 1);

  PollQuestion(this.question, this.questionIndex, this.choices, this.process,
      this.isInCensus);

  @override
  _PollQuestionState createState() => _PollQuestionState();
}

class _PollQuestionState extends State<PollQuestion> {
  ProcessResultsDigested results;
  Timer refreshCheck;
  int selectedTab = 0;
  int totalVotes = 0;
  int maxVotes = 0;
  int minVotes = 0;
  bool canVote;
  bool canSeeResults;

  @override
  void initState() {
    widget.process.refreshResults();
    refreshCheck = Timer.periodic(Duration(seconds: 10), (_) {});
    super.initState();
    setResultsState();
  }

  void setResultsState() {
    results = widget.process.results.value;
    // If results are available, process must be decrypted or unencrypted, so results can be displayed
    if (results?.questions?.isEmpty ?? true) {
      canSeeResults = false;
    } else {
      canSeeResults = true;
    }
    // If poll is open, and voter is in census, canVote is true
    if ((results?.state?.contains("open") ?? false) && widget.isInCensus) {
      canVote = true;
    } else {
      canVote = false;
    }
    if (!canVote) {
      selectedTab = 1;
    }
  }

  @override
  void dispose() {
    if (refreshCheck is Timer) refreshCheck.cancel();

    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await onRefresh();
  }

  Future<void> onRefresh() {
    return widget.process
        .refreshResults()
        .catchError((err) => log(err)); // Values will refresh if needed
  }

  @override
  Widget build(context) {
    return EventualBuilder(
        notifier: widget.process.results,
        builder: (context, _, __) {
          List<Widget> items = new List<Widget>();
          setResultsState();

          if (widget.question.type == "single-choice") {
            items.add(Section(text: (widget.questionIndex + 1).toString()));
            items
                .add(buildQuestionTitle(widget.question, widget.questionIndex));
            items.add(buildTabSelect(context));

            List<Widget> options = new List<Widget>();
            if (!canVote && !canSeeResults) {
              widget.question.voteOptions.forEach((voteOption) {
                options.add(buildDisabledPollOption(voteOption));
              });
            } else if (selectedTab > 1) {
              print("ERROR: Tab index not supported: $selectedTab");
              buildError(getText(context, "main.questionTypeNotSupported"));
            } else if (selectedTab == 0) {
              widget.question.voteOptions.forEach((voteOption) {
                options.add(buildPollOption(voteOption));
              });
            } else if (selectedTab == 1) {
              totalVotes = 0;
              maxVotes = 0;
              minVotes = results
                      .questions[widget.questionIndex].voteResults[0]?.votes ??
                  0;
              results.questions[widget.questionIndex].voteResults
                  .forEach((element) {
                totalVotes += element.votes;
                maxVotes = element.votes > maxVotes ? element.votes : maxVotes;
                minVotes = element.votes < minVotes ? element.votes : minVotes;
              });
              widget.question.voteOptions.asMap().forEach((index, voteOption) {
                options.add(buildPollResultsOption(index, voteOption));
              });
            }

            items.add(
              Column(
                children: options,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            );
          } else {
            print(
                "ERROR: Question type not supported: " + widget.question.type);
            buildError(getText(context, "main.questionTypeNotSupported"));
          }
          return Column(
            children: items,
            crossAxisAlignment: CrossAxisAlignment.start,
          );
        });
  }

  onTabSelect(int idx) {
    setState(() {
      selectedTab = idx;
    });
  }

  onNullSelect(int idx) {
    if (idx == 1) {
      widget.process.refreshResults();
    }
  }

  Widget buildTabSelect(BuildContext context) {
    return ProcessNavigation(
      canVote,
      canSeeResults,
      onTabSelect: onTabSelect,
      onNullSelect: onNullSelect,
      selectedTab: selectedTab,
    );
  }

  String getTabName(int idx) {
    if (idx == 0)
      return getText(context, "main.vote");
    else if (idx == 1)
      return getText(context, "main.pollResults");
    else
      return "";
  }

  Widget buildDisabledPollOption(
      ProcessMetadata_Details_Question_VoteOption voteOption) {
    return Padding(
        padding: EdgeInsets.fromLTRB(paddingPage, 0, paddingPage, 0),
        child: Chip(
          backgroundColor: colorLightGuide,
          padding: EdgeInsets.fromLTRB(10, 6, 10, 6),
          label: Text(
            voteOption.title[Globals.appState.currentLanguage],
            overflow: TextOverflow.ellipsis,
            maxLines: 5,
            style: TextStyle(
              fontSize: fontSizeSecondary,
              fontWeight: fontWeightRegular,
              color: colorDescription,
            ),
          ),
        ));
  }

  Widget buildPollOption(
      ProcessMetadata_Details_Question_VoteOption voteOption) {
    return Padding(
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
              color: widget.choices[widget.questionIndex] == voteOption.value
                  ? Colors.white
                  : colorDescription),
        ),
        selected: widget.choices[widget.questionIndex] == voteOption.value,
        onSelected: (bool selected) {
          if (selected) {
            setChoice(widget.questionIndex, voteOption.value);
          }
        },
      ),
    );
  }

  Widget buildPollResultsOption(
      int index, ProcessMetadata_Details_Question_VoteOption voteOption) {
    final myVotes =
        results.questions[widget.questionIndex]?.voteResults[index]?.votes ?? 0;
    final totalPerc = myVotes > 0 ? myVotes / totalVotes : 0.0;
    double relativePerc =
        myVotes - minVotes > 0 ? myVotes - minVotes / maxVotes - minVotes : 0.0;
    // Weight relative win/loss ratio between options based on max share of total votes
    relativePerc +=
        maxVotes > 0 ? (1 - (maxVotes / totalVotes)) * (1 - relativePerc) : 0;
    final myColor = totalVotes > 0
        ? widget.rb[relativePerc]
        : colorBluePale.withOpacity(0.1);
    return LinearPercentIndicator(
      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      center: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                voteOption.title['default'],
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    fontSize: fontSizeSecondary,
                    fontWeight: fontWeightSemiBold,
                    color: colorDescription),
              ).withLeftPadding(10),
            ),
            Text(
              myVotes == 1
                  ? "$myVotes " + getText(context, "main.vote")
                  : "$myVotes " + getText(context, "main.votes"),
              maxLines: 1,
              textAlign: TextAlign.right,
              overflow: TextOverflow.fade,
              // style: TextStyle(fontWeight: FontWeight.bold),
            ).withRightPadding(5).withLeftPadding(20)
          ]),
      animation: false,
      // trailing: Expanded(
      //   child: Text(
      //     "$myVotes " + getText(context, "votacions"),
      //     maxLines: 2,
      //     textAlign: TextAlign.center,
      //     overflow: TextOverflow.fade,
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ).withRightPadding(1),
      // ),
      alignment: MainAxisAlignment.start,
      backgroundColor: myColor.withOpacity(0.1),
      fillColor: Colors.transparent,
      linearGradient: LinearGradient(
          colors: [myColor, myColor.withOpacity(0.3)],
          begin: Alignment.topLeft),
      lineHeight: 30.0,
      percent: totalPerc,
      // width: MediaQuery.of(context).size.width * 0.7,
      linearStrokeCap: LinearStrokeCap.butt,
    )
        .withTopPadding(1)
        .withLeftPadding(paddingPage)
        .withRightPadding(paddingPage);
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

  setChoice(int questionIndex, int value) {
    setState(() {
      widget.choices[questionIndex] = value;
    });
  }

  buildError(String error) {
    return ListItem(
      mainText: getText(context, "main.error") + " " + error,
      rightIcon: null,
      icon: FeatherIcons.alertCircle,
      purpose: Purpose.DANGER,
    );
  }

  Widget buildErrorScaffold(String error) {
    return Scaffold(
      body: Center(
        child: Text(
          getText(context, "main.error") + ":\n" + error,
          style: new TextStyle(fontSize: 26, color: Color(0xff888888)),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ProcessNavigation extends StatelessWidget {
  final int selectedTab;
  final Function onTabSelect;
  final Function onNullSelect;
  final bool canVote;
  final bool canSeeResults;

  ProcessNavigation(this.canVote, this.canSeeResults,
      {this.selectedTab, this.onTabSelect, this.onNullSelect});

  @override
  Widget build(context) {
    return BottomNavigationBar(
      elevation: 0,
      backgroundColor: colorBaseBackground,
      onTap: (canVote && canSeeResults)
          ? (index) {
              if (onTabSelect is Function) onTabSelect(index);
            }
          : (index) {
              if (onNullSelect is Function) onNullSelect(index);
            },
      currentIndex: selectedTab,
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          title: Text(''),
          icon: Icon(
            Mdi.voteOutline,
            size: 29.0,
            color: canVote ? null : Colors.grey[400],
          ),
        ),
        BottomNavigationBarItem(
          title: Text(''),
          icon: Icon(
            FeatherIcons.pieChart,
            size: 24.0,
            color: canSeeResults ? null : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
