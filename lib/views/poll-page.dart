import 'package:dvote_common/lib/common.dart';
import 'package:dvote_common/widgets/htmlSummary.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'dart:async';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util/process-date-text.dart';
import 'package:vocdoni/views/poll-packaging-page.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/poll-question.dart';
import 'package:vocdoni/widgets/process-details.dart';
import 'package:vocdoni/widgets/process-status.dart';

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
  int refreshCounter = 0;
  GlobalKey voteButtonKey = GlobalKey();

  @override
  void initState() {
    refreshCheck = Timer.periodic(Duration(seconds: 1), (_) async {
      refreshCounter++;
      // Force date refresh if now < startDate < now + 1
      final isStarting =
          (process.startDate?.value?.isAfter(DateTime.now()) ?? false) &&
              (process.startDate?.value
                      ?.isBefore(DateTime.now().add(Duration(minutes: 1))) ??
                  false);
      // Refresh dates every second when process is near to starting time
      if (!(process.startDate.hasError || process.endDate.hasError))
        await process.refreshDates(force: isStarting);
      // Refresh everything else every 30 seconds
      if (refreshCounter % 30 == 0) {
        await process
            .refreshHasVoted()
            .then((_) => process.refreshResults())
            .then((_) => process.refreshCurrentParticipants())
            .catchError((err) => logger.log(err));
      }
    });

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
      logger.log("Invalid parameters");
      return;
    } else if (!args.process.metadata.hasValue) {
      Navigator.of(context).pop();
      logger.log("Empty process metadata");
      return;
    } else if (entity == args.entity &&
        process == args.process &&
        listIdx == args.listIdx) return;

    entity = args.entity;
    process = args.process;
    listIdx = args.listIdx;

    choices = process.metadata.value.questions
        .map((question) => null)
        .cast<int>()
        .toList();

    Globals.analytics.trackPage("Poll",
        entityId: entity.reference.entityId, processId: process.processId);

    await onRefresh();
  }

  Future<void> onRefresh() {
    return process
        .refreshHasVoted()
        .then((_) => process.refreshResults())
        // .then((_) => process.refreshIsInCensus())
        .then((_) => process.refreshCurrentParticipants())
        .then((_) => process.refreshDates())
        .catchError((err) => logger.log(err)); // Values will refresh if needed
  }

  @override
  Widget build(context) {
    if (entity == null) return buildEmptyPoll(context);

    // By the constructor, this.process.metadata is guaranteed to exist

    return EventualBuilder(
      notifiers: [
        entity.metadata,
        process.metadata,
      ],
      builder: (context, _, __) {
        if (process.metadata.hasError && !process.metadata.hasValue)
          return buildErrorScaffold(
              getText(context, "error.theMetadataIsNotAvailable"));

        String headerUrl = process.metadata.value.media["header"] ?? "";
        if (headerUrl.startsWith("ipfs"))
          headerUrl = processIpfsImageUrl(headerUrl, ipfsDomain: IPFS_DOMAIN);
        else
          headerUrl = Uri.tryParse(headerUrl).toString();
        String avatarUrl = entity.metadata.value.media.avatar;
        if (avatarUrl.startsWith("ipfs"))
          avatarUrl = processIpfsImageUrl(avatarUrl, ipfsDomain: IPFS_DOMAIN);

        String statusText = "";
        if (process.processData?.value?.getEnvelopeType != null)
          statusText =
              process.processData?.value?.getEnvelopeType?.hasEncryptedVotes ??
                      false
                  ? getText(context, "main.encryptedVote")
                  : getText(context, "main.publicVote");
        if (statusText.length > 1)
          statusText = statusText[0].toUpperCase() + statusText.substring(1);

        final scaffoldScrollController = ScrollController();

        return ScaffoldWithImage(
          headerImageUrl: headerUrl ?? "",
          headerTag: headerUrl == null
              ? null
              : makeElementTag(
                  entity.reference.entityId, process.processId, listIdx),
          leftOverlayText: statusText,
          avatarHexSource: process.processId,
          appBarTitle: getText(context, "main.vote"),
          actionsBuilder: (context) => [
            buildShareButton(context, process.processId),
          ],
          customScrollController: scaffoldScrollController,
          builder: Builder(
            builder: (ctx) => SliverList(
              delegate: SliverChildListDelegate(
                [
                  Column(
                    children: getScaffoldChildren(
                        ctx, entity, scaffoldScrollController),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> getScaffoldChildren(BuildContext ctx, EntityModel entity,
      ScrollController scaffoldScrollController) {
    List<Widget> children = [];
    if (!process.metadata.hasValue) return children;

    children.add(buildTitle(ctx, entity));
    children.add(ProcessStatusBar(
        process, entity, onScrollToBottom(scaffoldScrollController)));
    children.add(ProcessDetails(
        process, onScrollToSelectedContent(scaffoldScrollController)));
    children.add(buildSummary());
    if (process.processData?.value?.getEnvelopeType?.hasEncryptedVotes ?? false)
      children.add(buildEncryptedItem(ctx));
    children.addAll(buildQuestions(
        ctx, onScrollToSelectedContent(scaffoldScrollController)));
    children.add(Section(withDectoration: false));
    children.add(buildSubmitInfo());
    children.add(buildSubmitVoteButton(ctx));

    return children;
  }

  Widget buildTitle(BuildContext context, EntityModel entity) {
    if (process.metadata.value == null) return Container();

    final title =
        process.metadata.value.title[Globals.appState.currentLanguage] ?? "";
    String avatarUrl =
        entity.metadata.hasValue ? entity.metadata.value.media.avatar : "";
    if (avatarUrl.startsWith("ipfs"))
      avatarUrl = processIpfsImageUrl(avatarUrl, ipfsDomain: IPFS_DOMAIN);
    return EventualBuilder(
      notifier: entity.metadata,
      builder: (context, _, __) => ListItem(
        // mainTextTag: makeElementTag(entityId: ent.reference.entityId, cardId: _process.meta[META_PROCESS_ID], elementId: _process.details.headerImage)
        mainText: title,
        rightText: parseProcessDate(process, context),
        mainTextMultiline: 3,
        secondaryText: entity.metadata.hasValue
            ? entity.metadata.value.name[Globals.appState.currentLanguage]
            : "",
        isTitle: true,
        rightIcon: null,
        isBold: true,
        avatarUrl: avatarUrl,
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
    return HtmlSummary(
        htmlString: process
            .metadata.value.description[Globals.appState.currentLanguage]);
  }

  buildEncryptedItem(BuildContext context) {
    // Rebuild when the reference block changes
    return EventualBuilder(
      notifiers: [process.metadata, process.startDate, process.endDate],
      builder: (context, _, __) {
        String rowText;
        Purpose purpose;
        final now = DateTime.now();

        if (process.startDate.hasValue) {
          if (process.startDate.value.isAfter(now)) {
            return SizedBox.shrink();
          }
        }

        if (process.endDate.hasValue) {
          if (process.endDate.value.isBefore(now)) {
            return SizedBox.shrink();
          }
        } else {
          return SizedBox.shrink();
        }

        rowText = getText(context, "main.resultsAvailableOnceProcessEnds");
        purpose = Purpose.WARNING;
        if (rowText is! String) return Container();

        return ListItem(
          icon: FeatherIcons.lock,
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
    return Container(
      key: voteButtonKey,
      child: EventualBuilder(
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
      ),
    );
  }

  onSubmit(BuildContext ctx, metadata) async {
    final newRoute = MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) =>
            PollPackagingPage(process: process, choices: choices));
    await Navigator.push(ctx, newRoute);
    process.refreshResults(force: true);
    process.refreshCurrentParticipants(force: true); // Refresh percentage
  }

  onSetChoice(int questionIndex, int value) {
    setState(() {
      choices[questionIndex] = value;
    });
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

  List<Widget> buildQuestions(BuildContext ctx, Function() onScroll) {
    if (!process.metadata.hasValue ||
        process.metadata.value.questions.length == 0) {
      return [];
    }

    List<Widget> items = new List<Widget>();
    int questionIndex = 0;

    for (ProcessMetadata_Question question
        in process.metadata.value.questions) {
      items.add(PollQuestion(question, questionIndex, choices[questionIndex],
          process, onSetChoice, onScroll));
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

  Function() onScrollToBottom(ScrollController controller) {
    return () =>
        _scrollToSelectedContent(controller, expansionTileKey: voteButtonKey);
  }

  Function({GlobalKey expansionTileKey}) onScrollToSelectedContent(
      ScrollController controller) {
    return ({GlobalKey expansionTileKey}) {
      _scrollToSelectedContent(controller, expansionTileKey: expansionTileKey);
    };
  }

  void _scrollToSelectedContent(ScrollController controller,
      {GlobalKey expansionTileKey}) {
    final keyContext = expansionTileKey.currentContext;
    // if (keyContext != null) {
    Future.delayed(Duration(milliseconds: 200)).then((value) {
      Scrollable.ensureVisible(keyContext,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
    });
    // }
  }
}
