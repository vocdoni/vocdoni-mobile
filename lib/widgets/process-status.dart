import 'dart:typed_data';

import 'package:dvote/blockchain/ens.dart';
import 'package:eventual/eventual-notifier.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/lib/logger.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';
import 'package:convert/convert.dart';
import 'package:dvote/api/voting.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/htmlSummary.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';

class ProcessStatusDigest {
  String mainText;
  String secondaryText;
  Widget rightWidget;
  IconData leftIcon;
  EventualNotifier<bool> loading = EventualNotifier<bool>(false);

  ProcessStatusDigest();
}

class ProcessStatusBar extends StatefulWidget {
  final ProcessModel process;
  final EntityModel entity;
  final Function() onScrollToVote;

  ProcessStatusBar(this.process, this.entity, this.onScrollToVote);

  @override
  _ProcessStatusState createState() => _ProcessStatusState();
}

class _ProcessStatusState extends State<ProcessStatusBar> {
  DateTime cachedStartDate;
  DateTime cachedEndDate;
  @override
  Widget build(BuildContext context) {
    return EventualBuilder(
      notifiers: [
        widget.process.metadata,
        widget.process.isInCensus,
        widget.process.startDate,
        widget.process.endDate
      ],
      builder: (ctx, _, __) {
        final processStatus = _digestProcessStatus(context);
        return EventualBuilder(
          notifier: processStatus.loading,
          builder: (ctx, _, __) {
            return ListItem(
              icon: processStatus.leftIcon,
              mainText: processStatus.mainText,
              secondaryText: processStatus.secondaryText,
              isSpinning: processStatus.loading.value,
              rightWidget: processStatus.rightWidget,
              secondaryTextMultiline: 3,
              secondaryTextVerticalSpace: 4,
              verticalPadding: 5,
              // purpose: Purpose.DANGER,
            );
          },
        );
      },
    );
  }

  ProcessStatusDigest _digestProcessStatus(BuildContext context) {
    // Initialized process status params
    final processStatus = ProcessStatusDigest();
    processStatus.mainText = getText(context, "main.loading") + "...";
    processStatus.leftIcon = Icons.people_alt_outlined;

    // Cache start / end date values to display the proper status while they are loading
    if (widget.process.startDate.hasValue)
      cachedStartDate = widget.process.startDate.value;
    if (widget.process.endDate.hasValue)
      cachedEndDate = widget.process.endDate.value;

    // TODO implement registration phase

// If census is loading, set status & return
    if (widget.process.isInCensus.isLoading &&
        (!(widget.process.hasVoted?.value ?? false))) {
      processStatus.mainText = getText(context, "status.checkingTheCensus");
      processStatus.loading.setValue(true);
      return processStatus;
    }

    // If census loaded but isInCensus has not value, ask to check census & return
    if (!Globals.appState.currentAccount
            .hasPublicKeyForEntity(widget.entity.reference.entityId) ||
        !widget.process.isInCensus.hasValue) {
      // We don't have the user's public key. Ask for the pattern.
      processStatus.mainText = getText(context, "main.unknownCensusStatus");
      processStatus.secondaryText =
          getText(context, "action.tapToSeeIfYouAreInThisProcessCensus");
      processStatus.rightWidget = FlatButton(
        onPressed: () => onCheckCensus(context),
        child: Text(getText(context, "action.check")),
        textColor: Colors.white,
        color: colorDescription,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      );
      return processStatus;
    }

    // If isInCensus has an error, set error status & return
    if (widget.process.isInCensus.hasError) {
      // translate the key from setError()
      processStatus.mainText =
          getText(context, widget.process.isInCensus.errorMessage);
      processStatus.secondaryText =
          getText(context, "action.tapToSeeIfYouAreInThisProcessCensus");
      processStatus.rightWidget = FlatButton(
        onPressed: () => onCheckCensus(context),
        child: Text(getText(context, "action.check")),
        textColor: Colors.white,
        color: colorDescription,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      );
      return processStatus;
    }

    // If user is not in census, set status & return
    if (!widget.process.isInCensus.value) {
      processStatus.mainText = getText(context, "status.notInTheCensus");
      processStatus.secondaryText =
          getText(context, "main.youCantVoteInThisProcess");
      processStatus.rightWidget = FlatButton(
        onPressed: () {
          try {
            launchUrl(VOCDONI_FAQ_NOT_IN_CENSUS_URL);
          } catch (err) {
            showMessage(getText(context, "error.invalidUrl"),
                context: context, purpose: Purpose.DANGER);
          }
        },
        child: Icon(FeatherIcons.xCircle, color: colorRedPale),
      );
      return processStatus;
    }

    // Otherwise, user must be in census. proceed.

// If process.startDate has no value or is loading, set spinner and try to refresh dates.
    if (!widget.process.startDate.hasValue ||
        widget.process.startDate.isLoading) {
      // start date is loading: display spinner, but still try using cached dates
      widget.process.refreshDates();
    }

    // If cached start date does not exist, refresh dates & return loading status
    if (cachedStartDate == null) {
      widget.process.refreshDates();
      processStatus.loading.setValue(true);
      return processStatus;
    }

// Otherwise, the start date is cached. set now and proceed.
    final now = DateTime.now();

// If start date is in the future, return status
    if (cachedStartDate.isAfter(now)) {
      processStatus.mainText = getText(context, "status.youAreInTheCensus");
      processStatus.secondaryText =
          getText(context, "status.youWillBeAbleToVoteOnceTheProcessStarts");
      processStatus.rightWidget = FlatButton(
        onPressed: () => {},
        child: Icon(FeatherIcons.check, color: colorGreenPale),
      );
      return processStatus;
    }

// Otherwise, process has already started. Proceed
    processStatus.leftIcon = FeatherIcons.mail;

// If process.endDate has no value or is loading, set spinner and try to refresh dates.
    if (!widget.process.endDate.hasValue || widget.process.endDate.isLoading) {
      // end date is loading: display spinner, but still try using cached dates
      widget.process.refreshDates();
    }

    // If cached end date does not exist, refresh dates & return loading status
    if (cachedEndDate == null) {
      widget.process.refreshDates();
      processStatus.loading.setValue(true);
      return processStatus;
    }

    // If hasVoted doesn't have a value, refresh & set loading spinner & return
    if (!widget.process.hasVoted.hasValue ||
        widget.process.hasVoted.isLoading) {
      widget.process.refreshHasVoted();
      processStatus.mainText = getText(context, "status.checkingVoteStatus");
      processStatus.loading.setValue(true);
      return processStatus;
    }

// If process active and user has not voted, set votable status & return
    if (cachedEndDate.isAfter(now) && !widget.process.hasVoted.value) {
      processStatus.mainText = getText(context, "status.notVotedYet");
      processStatus.secondaryText = getText(context, "action.scrollDownToVote");
      processStatus.rightWidget = FlatButton(
        onPressed: () {
          try {
            if (widget.onScrollToVote != null) widget.onScrollToVote();
          } catch (err) {
            logger.log(err.toString());
          }
        },
        child: Icon(
          FeatherIcons.xCircle,
          color: colorOrangePale,
        ),
      );
      return processStatus;
    }

    // Otherwise, either the process has already ended or the user has voted. check voted status.

    // If process active and user has voted, set vote counted status & return
    if (widget.process.hasVoted.value) {
      processStatus.mainText = getText(context, "status.voted");
      processStatus.secondaryText =
          getText(context, "main.voteCorrectlyCounted");
      processStatus.rightWidget = FlatButton(
        onPressed: () async {
          try {
            processStatus.loading.setValue(true);
            final userAddress = getUserAddressFromPubKey(Globals
                .appState.currentAccount
                .getPublicKeyForEntity(widget.process.entityId));
            final pollNullifier = await getSignedVoteNullifier(
                userAddress, widget.process.processId);
            processStatus.loading.setValue(false);
            launchUrl(
                AppConfig.vochainExplorerUrl + "/envelope/" + pollNullifier);
          } catch (err) {
            processStatus.loading.setValue(false);
            showMessage(getText(context, "error.invalidUrl"),
                context: context, purpose: Purpose.DANGER);
          }
        },
        child: Icon(
          FeatherIcons.check,
          color: colorGreenPale,
        ),
      );
      return processStatus;
    }

// Otherwise, the process has ended and the user did not vote. Set status and return.
    processStatus.mainText = getText(context, "status.processHasEnded");
    processStatus.secondaryText = getText(context, "main.youDidNotCastAVote");
    processStatus.rightWidget = FlatButton(
      onPressed: () => {},
      child: Icon(
        FeatherIcons.xCircle,
        color: colorOrangePale,
      ),
    );
    return processStatus;
    // TODO add not voted
    // TODO add vote sent, not confirmed (only applicable if voting screen changes)
  }

  Future<void> onCheckCensus(BuildContext context) async {
    if (Globals.appState.currentAccount == null) {
      // NOTE: Keep the comment to force i18n key parsing
      // getText(context, "main.cannotCheckTheCensus")
      widget.process.isInCensus.setError("main.cannotCheckTheCensus");
      return;
    }
    final account = Globals.appState.currentAccount;

    // Ensure that we have the public key
    if (!Globals.appState.currentAccount
        .hasPublicKeyForEntity(widget.entity.reference.entityId)) {
      // Ask the pattern
      final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => PinPromptModal(account));
      final mnemonic = await Navigator.push(context, route);
      if (mnemonic == null) {
        // NOTE: Keep the comment to force i18n key parsing
        // getText(context, "main.cannotAccessTheWallet")
        widget.process.isInCensus.setError("main.cannotAccessTheWallet");
        return;
      } else if (mnemonic is InvalidPatternError) {
        showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
            context: context, purpose: Purpose.DANGER);
        return;
      }

      final wallet = EthereumWallet.fromMnemonic(mnemonic,
          entityAddressHash: ensHashAddress(Uint8List.fromList(hex.decode(
              widget.entity.reference.entityId.replaceFirst("0x", "")))));

      account.setPublicKeyForEntity(
          await wallet.publicKeyAsync(uncompressed: false),
          widget.entity.reference.entityId);
    }

    widget.process.refreshIsInCensus(force: true);
  }
}
