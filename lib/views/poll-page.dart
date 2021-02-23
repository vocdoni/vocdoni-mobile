import 'package:dvote_common/lib/common.dart';
import 'package:dvote_common/widgets/htmlSummary.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/makers.dart';
import 'dart:async';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util/process-date-text.dart';
import 'package:vocdoni/lib/util/scroll.dart';
import 'package:dvote_common/widgets/ScaffoldWithImage.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/widgets/multiple-choice-poll.dart';
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
    children.add(buildVoting(ctx, scaffoldScrollController));

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
      notifiers: [entity.metadata, process.startDate, process.endDate],
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

  Widget buildVoting(
      BuildContext ctx, ScrollController scaffoldScrollController) {
    if (!process.processData.hasValue)
      return ListItem(
        mainText: getText(context, "main.fetchingDetails"),
        rightIcon: null,
        isSpinning: true,
      );

    if (process.processData.value.getEnvelopeType.hasAnonymousVoters)
      return buildUnsupportedProcess(getText(ctx, "main.anonymousVoting"));
    if (process.processData.value.getEnvelopeType.hasSerialVoting)
      return buildUnsupportedProcess(getText(ctx, "main.serialVoting"));
    if (process.processData.value.getEnvelopeType.hasUniqueValues)
      return buildUnsupportedProcess(getText(ctx, "main.uniqueValueVoting"));
    if (process.processData.value.getCensusOrigin.isOffChainCA)
      return buildUnsupportedProcess(
          getText(ctx, "main.certificateAuthorityVerification"));
    if (!(process.processData.value.getCensusOrigin.isOffChain ||
        process.processData.value.getCensusOrigin.isOffChainWeighted))
      return buildUnsupportedProcess(getText(ctx, "main.onChainVoting"));
    if (process.processData.value.getMode.hasDynamicCensus)
      return buildUnsupportedProcess(getText(ctx, "main.dynamicCensus"));
    if (process.processData.value.getMode.hasEncryptedMetadata)
      return buildUnsupportedProcess(getText(ctx, "main.encryptedMetadata"));
    if (process.processData.value.getCostExponent != 1)
      return buildUnsupportedProcess(getText(ctx, "main.quadraticVoting"));

    if (process.processData.value.getMaxTotalCost > 0)
      return MultipleChoicePoll(
          entity, process, scaffoldScrollController, voteButtonKey);
    return buildUnsupportedProcess(getText(ctx, "main.thisProcessType"));
  }

  Widget buildUnsupportedProcess(String processType) {
    return ListItem(
      mainText: getText(context, "main.TYPEIsNotYetSupported")
          .replaceAll("{{TYPE}}", processType),
      mainTextMultiline: 5,
      rightIcon: null,
      purpose: Purpose.WARNING,
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
        scrollToSelectedContent(controller, expansionTileKey: voteButtonKey);
  }
}
