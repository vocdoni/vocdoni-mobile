import 'dart:async';
import 'dart:ui';

import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:vocdoni/lib/util/process-date-text.dart';

class ProcessDetails extends StatefulWidget {
  final ProcessModel process;
  final Function({GlobalKey expansionTileKey}) scrollToSelectedContent;
  final GlobalKey expansionKey = GlobalKey();

  ProcessDetails(this.process, this.scrollToSelectedContent);

  @override
  _ProcessDetailsState createState() => _ProcessDetailsState();
}

class _ProcessDetailsState extends State<ProcessDetails> {
  DateTime startDateCache;
  DateTime endDateCache;
  Timer refreshCheck;

  @override
  void initState() {
    widget.process.refreshCensusSize();
    refreshCheck = Timer.periodic(Duration(seconds: 30), (_) async {
      await widget.process
          .refreshCensusSize()
          .catchError((err) => logger.log(err));
    });
    super.initState();
  }

  @override
  void dispose() {
    if (refreshCheck is Timer) refreshCheck.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EventualBuilder(
      notifiers: [
        widget.process.censusSize,
        widget.process.startDate,
        widget.process.endDate,
        widget.process.processData
      ],
      builder: (context, _, __) {
        List<Widget> items = List<Widget>();

        // Setup cached variables (for when dates are loading)
        if (widget.process.startDate.hasValue)
          startDateCache = widget.process.startDate.value;
        if (widget.process.endDate.hasValue)
          endDateCache = widget.process.endDate.value;

        items.add(buildDurationItem());
        items.add(buildRealTimeResults());
        items.add(buildAnonymous());
        items.add(buildParticipants());
        items.add(buildUniqueIdentifier());

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: colorBaseBackground),
          child: ExpansionTile(
            maintainState: true,
            key: widget.expansionKey,
            onExpansionChanged: (value) {
              if (value) {
                widget.scrollToSelectedContent(
                    expansionTileKey: widget.expansionKey);
              }
            },
            title: buildDetailsTitle(),
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [
                        0,
                        0.006,
                        0.994,
                        1
                      ],
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.1)
                      ]),
                ),
                child: Column(
                  children: items,
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildDurationItem() {
    final loading = (startDateCache == null || endDateCache == null);
    String text = "";
    String rightText;
    if (!loading) {
      text = getText(context, "main.dateAtTime")
              .replaceFirst(
                  "{{DATE}}",
                  getText(context,
                          "main.shortMonth" + startDateCache.month.toString()) +
                      " " +
                      startDateCache.day.toString())
              .replaceFirst(
                  "{{TIME}}",
                  startDateCache.hour.toString() +
                      ":" +
                      startDateCache.minute.toString().padLeft(2, "0")) +
          " → " +
          getText(context, "main.dateAtTime")
              .replaceFirst(
                  "{{DATE}}",
                  getText(context,
                          "main.shortMonth" + endDateCache.month.toString()) +
                      " " +
                      startDateCache.day.toString())
              .replaceFirst(
                  "{{TIME}}",
                  endDateCache.hour.toString() +
                      ":" +
                      endDateCache.minute.toString().padLeft(2, "0"));
      rightText = getFriendlyTimeDifference(startDateCache, context,
          secondDate: endDateCache);
    }
    return ListItem(
      icon: FeatherIcons.calendar,
      mainText: text,
      isSpinning: loading,
      rightText: rightText,
    );
  }

  buildRealTimeResults() {
    final loading = !widget.process.processData.hasValue;
    bool realTime = false;
    String secondaryText = "";
    if (!loading) {
      realTime =
          !widget.process.processData.value.getEnvelopeType.hasEncryptedVotes;
      if (realTime)
        secondaryText =
            getText(context, "main.resultsWillBeDisplayedAsVotesAreCast");
      else
        secondaryText = getText(context,
            "main.resultsAreEncryptedAndWillBeDisplayedOnceTheProcessHasFinished");
    }
    return ListItem(
      icon: FeatherIcons.activity,
      forceSmallIcon: true,
      mainText: getText(context, "main.realTimeResults"),
      secondaryText: secondaryText,
      secondaryTextMultiline: 5,
      isSpinning: loading,
      rightIcon: realTime ? FeatherIcons.check : FeatherIcons.x,
      rightIconColor: realTime ? colorGreen : colorRed,
    );
  }

  buildAnonymous() {
    final loading = !widget.process.processData.hasValue;
    bool anonymous = false;
    String secondaryText = "";
    if (!loading) {
      anonymous =
          widget.process.processData.value.getEnvelopeType.hasAnonymousVoters;
      if (anonymous)
        secondaryText =
            getText(context, "main.userIdentitiesAreDecoupledFromTheirVotes");
      else
        secondaryText =
            getText(context, "main.voterAnonymityCannotBeGuaranteed");
    }
    return ListItem(
      icon: anonymous ? FeatherIcons.eye : FeatherIcons.eyeOff,
      forceSmallIcon: true,
      mainText: getText(context, "main.anonymous"),
      secondaryText: secondaryText,
      secondaryTextMultiline: 5,
      isSpinning: loading,
      rightIcon: anonymous ? FeatherIcons.check : FeatherIcons.x,
      rightIconColor: anonymous ? colorGreen : colorRed,
    );
  }

  buildParticipants() {
    final loading = !widget.process.censusSize.hasValue;
    return ListItem(
      icon: FeatherIcons.users,
      mainText: getText(context, "main.censusSize"),
      secondaryText:
          getText(context, "main.numberOfParticipantsWhoCanVoteInThisProcess"),
      secondaryTextMultiline: 3,
      isSpinning: loading,
      forceSmallIcon: true,
      rightText: loading ? "" : widget.process.censusSize.value.toString(),
    );
  }

  buildUniqueIdentifier() {
    return ListItem(
      icon: FeatherIcons.hash,
      mainText: getText(context, "main.uniqueProcessIdentifier"),
      secondaryText: widget.process.processId,
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.process.processId));
        showMessage(getText(context, "main.identifierCopiedToTheClipboard"),
            context: context, purpose: Purpose.GOOD);
      },
      forceSmallIcon: true,
      rightIcon: FeatherIcons.copy,
    );
  }

  buildDetailsTitle() {
    return Row(
      children: [
        Icon(FeatherIcons.info),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Text(
            getText(context, "main.details"),
            textAlign: TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(
                fontSize: fontSizeBase,
                color: colorDescription,
                fontWeight: fontWeightRegular),
          ),
        ),
      ],
    );
  }
}
