import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/lib/net.dart';

class PollPackaging extends StatefulWidget {
  final ProcessModel process;
  final List<int> choices;

  PollPackaging({@required this.process, @required this.choices});

  @override
  _PollPackagingState createState() => _PollPackagingState();
}

class _PollPackagingState extends State<PollPackaging> {
  int _currentStep;
  Map<String, String> _envelope;

  @override
  void initState() {
    super.initState();

    globalAnalytics.trackPage("PollPackaging",
        entityId: widget.process.entityId, processId: widget.process.processId);

    _currentStep = 0;
  }

  void stepMakeEnvelope(BuildContext context) async {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    var patternLockKey = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PatternPromptModal(currentAccount)));

    if (!mounted)
      return;
    else if (patternLockKey == null) {
      setState(() => _currentStep = 0);
      return;
    } else if (patternLockKey is InvalidPatternError) {
      setState(() => _currentStep = 0);
      showMessage("The pattern you entered is not valid",
          context: context, purpose: Purpose.DANGER);
      return;
    }
    setState(() => _currentStep = 1);

    // PREPARE DATA
    final dvoteGw = getDVoteGateway();
    String merkleProof;

    try {
      final publicKey = currentAccount.identity.value.keys[0].publicKey;
      final publicKeyClaim = await digestHexClaim(publicKey);
      merkleProof = await generateProof(
          widget.process.metadata.value.census.merkleRoot,
          publicKeyClaim,
          dvoteGw);

      if (!mounted) return;
    } catch (err) {
      // continue below
      devPrint(err);
    }

    if (!(merkleProof is String)) {
      showMessage("The vote data could not be signed", context: context);
      setState(() => _currentStep = 0);
      return;
    }

    try {
      // CHECK IF THE VOTE IS ALREADY REGISTERED
      await widget.process.refreshHasVoted(true);
      if (!mounted) return;

      if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value) {
        setState(() => _currentStep = 0);
        showMessage("Your vote has already been registered",
            context: context, purpose: Purpose.GUIDE);
        return;
      }

      // PREPARE THE VOTE ENVELOPE
      final privateKey = await decryptString(
          currentAccount.identity.value.keys[0].encryptedPrivateKey,
          patternLockKey);

      if (!mounted) return;

      Map<String, String> envelope = await packagePollEnvelope(
          widget.choices, merkleProof, widget.process.processId, privateKey);

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
      final dvoteGw = getDVoteGateway();
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
      const RETRIES = 4;
      for (int i = 0; i < RETRIES; i++) {
        await widget.process.refreshHasVoted(true);
        if (!mounted) return;

        if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value)
          break; // done!

        if (i < (RETRIES - 1))
          await Future.delayed(Duration(seconds: 5)); // wait and try again
      }

      if (widget.process.hasVoted.hasError ||
          widget.process.hasVoted.value == false) {
        setState(() => _currentStep = 0);
        showMessage("The status of the envelope could not be validated",
            context: context, purpose: Purpose.WARNING);
        return;
      }

      // DONE!
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
