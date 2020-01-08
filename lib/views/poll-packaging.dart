import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/lib/net.dart';

class PollPackaging extends StatefulWidget {
  final ProcessModel processModel;
  final List<int> choices;

  PollPackaging({this.processModel, this.choices});

  @override
  _PollPackagingState createState() => _PollPackagingState();
}

class _PollPackagingState extends State<PollPackaging> {
  int _currentStep;
  Map<String, String> _envelope;
  ProcessModel processModel;

  @override
  void initState() {
    super.initState();

    analytics.trackPage(
        "PollPackaging",
        entityId: widget.processModel.entityReference.entityId,
        processId: widget.processModel.processId);

    _currentStep = 0;
  }

  void stepMakeEnvelope(BuildContext context) async {
    var patternLockKey = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(
                account.identity.keys[0].encryptedPrivateKey)));

    if (!mounted) return;

    // TODO: ERROR => THIS IS NOT A SCAFFOLD
    if (patternLockKey == null || patternLockKey is InvalidPatternError) {
      setState(() => _currentStep = 0);
      showMessage("The pattern you entered is not valid",
          context: context, purpose: Purpose.DANGER);
      return;
    }
    setState(() => _currentStep = 1);

    // PREPARE DATA
    final DVoteGateway dvoteGw = getDVoteGateway();
    String merkleProof;

    try {
      final publicKey = identitiesBloc.getCurrentIdentity().keys[0].publicKey;
      final publicKeyClaim = await digestHexClaim(publicKey);
      merkleProof = await generateProof(
          widget.processModel.processMetadata.value.census.merkleRoot,
          publicKeyClaim,
          dvoteGw);

      if (!mounted) return;
    } catch (err) {
      // continue below
      if (!kReleaseMode) print(err);
    }

    if (!(merkleProof is String)) {
      showMessage("The vote data could not be signed", context: context);
      setState(() => _currentStep = 0);

      return;
    }

    final privateKey = await decryptString(
        account.identity.keys[0].encryptedPrivateKey, patternLockKey);

    if (!mounted) return;

    try {
      // CHECK IF THE VOTE IS ALREADY REGISTERED
      final String pollNullifier = getPollNullifier(
          identitiesBloc.getCurrentIdentity().keys[0].address,
          widget.processModel.processId);

      final success = await getEnvelopeStatus(
              widget.processModel.processId, pollNullifier, dvoteGw)
          .catchError((_) {});
      if (!mounted) return;

      if (success == true) {
        setState(() => _currentStep = 0);
        showMessage("Your vote has already been registered",
            context: context, purpose: Purpose.GUIDE);
        return;
      }

      // PREPARE THE VOTE ENVELOPE
      Map<String, String> envelope = await packagePollEnvelope(widget.choices,
          merkleProof, widget.processModel.processId, privateKey);

      if (!mounted) return;

      setState(() {
        _envelope = envelope;
      });

      stepSendVote(context);
    } catch (err) {
      showMessage("The vote data could not be prepared", context: context);
      setState(() {
        _currentStep = 0;
      });
    }
  }

  void stepSendVote(BuildContext context) async {
    try {
      setState(() => _currentStep = 2);
      final DVoteGateway dvoteGw = getDVoteGateway();
      // final Web3Gateway web3Gw = getWeb3Gateway();

      await submitEnvelope(_envelope, dvoteGw);

      if (!mounted) return;

      setState(() => _currentStep++);

      return stepConfirm(context);
    } catch (error) {
      if (!mounted) return;

      setState(() => _currentStep = 0);
      showMessage("The vote could not be delivered",
          purpose: Purpose.DANGER, context: context);
    }
  }

  void stepConfirm(BuildContext context) async {
    setState(() => _currentStep = 3);
    try {
      final DVoteGateway dvoteGw = getDVoteGateway();

      final String pollNullifier = getPollNullifier(
          identitiesBloc.getCurrentIdentity().keys[0].address,
          widget.processModel.processId);

      final success = await getEnvelopeStatus(
          widget.processModel.processId, pollNullifier, dvoteGw);
      if (!mounted) return;

      if (success != true) {
        setState(() => _currentStep = 0);
        showMessage("The status of the envelope could not be validated",
            context: context, purpose: Purpose.WARNING);
        return;
      }

      setState(() => _currentStep = 4);
    } catch (err) {
      showMessage("The vote delivery could not be checked",
          purpose: Purpose.DANGER, context: context);

      if (mounted) setState(() => _currentStep = 0);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) => Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 350),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Spacer(),
                Section(
                  text: _currentStep == 0
                      ? "Ready when you are"
                      : "Delivering the vote",
                  withDectoration: false,
                ),
                /*Summary(
                  maxLines: 10,
                  text:
                      "This may take some time, please do not close this screen"),*/
                buildStep("Sigining", "Signed", 1),
                // buildStep("Generating proof", "Proof generated", 2),
                buildStep("Delivering", "Sent", 2),
                buildStep("Waiting confirmation", "Confirmed", 3),
                Spacer(),
                // Padding(
                //   padding: EdgeInsets.all(48),
                //   child: BaseButton(
                //       text: "Return",
                //       isSmall: true,
                //       style: BaseButtonStyle.OUTLINE,
                //       maxWidth: buttonDefaultWidth,
                //       //purpose: Purpose.HIGHLIGHT,
                //       //isDisabled: true,
                //       onTap: () {
                //         setState(() {
                //           _currentStep++;
                //         });
                //         if (_currentStep == 5) Navigator.pop(context, false);
                //       }),
                // ),

                _currentStep != 0
                    ? Container()
                    : Padding(
                        padding: EdgeInsets.all(paddingPage),
                        child: BaseButton(
                            text: "Confirm",
                            isSmall: false,
                            style: BaseButtonStyle.FILLED,
                            purpose: Purpose.HIGHLIGHT,
                            onTap: () => stepMakeEnvelope(context)),
                      ),
                _currentStep != 4
                    ? Container()
                    : Padding(
                        padding: EdgeInsets.all(paddingPage),
                        child: BaseButton(
                            text: "Close",
                            isSmall: false,
                            style: BaseButtonStyle.FILLED,
                            purpose: Purpose.HIGHLIGHT,
                            onTap: () => Navigator.of(context).pop()),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStep(String doingText, String doneText, int stepIndex) {
    String text = doingText;

    if (_currentStep == stepIndex)
      text = doingText;
    else if (_currentStep > stepIndex) text = doneText;

    return ListItem(
      mainText: text,
      rightIcon: _currentStep > stepIndex ? FeatherIcons.check : null,
      isSpinning: _currentStep == stepIndex,
      rightTextPurpose: Purpose.GOOD,
      isBold: _currentStep == stepIndex,
      disabled: _currentStep < stepIndex,
    );
  }
}
