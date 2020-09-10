import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'dart:async';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/util.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/views/poll-packaging-page.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/summary.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
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
  Timer refreshCheck;
  EntityModel entity;
  ProcessModel process;
  int index;
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

    await onRefresh();
  }

  Future<void> onRefresh() {
    return process
        .refreshHasVoted()
        .then((_) => process.refreshIsInCensus())
        .then((_) => process.refreshDates())
        .catchError((err) => devPrint(err)); // Values will refresh if needed
  }

  Future<void> onCheckCensus(BuildContext context) async {
    if (globalAppState.currentAccount == null) {
      process.isInCensus
          .setError(getText(context, "main.cannotCheckTheCensus"));
      return;
    }
    final account = globalAppState.currentAccount;

    // Ensure that we have the public key
    if (!globalAppState.currentAccount
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
        process.isInCensus
            .setError(getText(context, "main.cannotAccessTheWallet"));
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
          avatarUrl: entity.metadata.value.media.avatar,
          avatarText:
              entity.metadata.value.name[globalAppState.currentLanguage],
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

        if (!globalAppState.currentAccount
            .hasPublicKeyForEntity(entity.reference.entityId)) {
          // We don't have the user's public key, probably because the entity was unknown when all
          // public keys were precomputed. Ask for the pattern.
          text = getText(context, "main.checkTheCensus");
        } else if (process.isInCensus.isLoading) {
          text = getText(context, "main.checkingTheCensus");
          purpose = Purpose.GUIDE;
        } else if (process.isInCensus.hasValue) {
          if (process.isInCensus.value) {
            text = getText(context, "main.youAreInTheCensus");
            purpose = Purpose.GOOD;
            icon = FeatherIcons.check;
          } else {
            text = getText(context, "main.youAreNotInTheCensus");
            purpose = Purpose.DANGER;
            icon = FeatherIcons.x;
          }
        } else if (process.isInCensus.hasError) {
          text = process.isInCensus.errorMessage;
          purpose = Purpose.DANGER;
          icon = FeatherIcons.alertTriangle;
        } else {
          text = getText(context, "main.checkCensusState");
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
              text: getText(context, "main.submit"),
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
            mainText: getText(context, "main.yourVoteIsAlreadyRegistered"),
            purpose: Purpose.GOOD,
            rightIcon: null,
          );
        } else if (!process.startDate.hasValue || !process.endDate.hasValue) {
          return ListItem(
            mainText:
                getText(context, "main.theProcessDatesCannotBeDetermined"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.startDate.value.isAfter(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "main.theProcessIsNotActiveYet"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.endDate.value.isBefore(DateTime.now())) {
          return ListItem(
            mainText: getText(context, "main.theProcessHasAlreadyEnded"),
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (!process.isInCensus.value) {
          return ListItem(
            mainText: getText(context, "main.youAreNotInTheCensus"),
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
            secondaryText: process.isInCensus.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (!process.isInCensus.hasValue) {
          return ListItem(
            mainText: getText(context, "main.theCensusCannotBeChecked"),
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
            mainText: getText(context, "main.yourVoteStatusCannotBeChecked"),
            mainTextMultiline: 3,
            secondaryText: process.hasVoted.errorMessage,
            purpose: Purpose.WARNING,
            rightIcon: null,
          );
        } else if (process.isInCensus.isLoading) {
          return ListItem(
            mainText: getText(context, "main.checkingTheCensus"),
            purpose: Purpose.GUIDE,
            rightIcon: null,
          );
        } else if (process.hasVoted.isLoading) {
          return ListItem(
            mainText: getText(context, "main.checkingYourVote"),
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
      buildError(getText(context, "main.questionTypeNotSupported"));
    }
    return items;
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
