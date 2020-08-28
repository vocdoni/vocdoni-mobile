import 'package:dvote/dvote.dart';
import 'package:dvote/wrappers/process-keys.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/util.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:convert/convert.dart';
import 'dart:convert';
import 'package:dvote/crypto/encryption.dart';

class PollPackagingPage extends StatefulWidget {
  final ProcessModel process;
  final List<int> choices;

  PollPackagingPage({@required this.process, @required this.choices});

  @override
  _PollPackagingPageState createState() => _PollPackagingPageState();
}

class _PollPackagingPageState extends State<PollPackagingPage> {
  int _currentStep;
  Map<String, dynamic> _envelope;

  @override
  void initState() {
    super.initState();

    globalAnalytics.trackPage("PollPackagingPage",
        entityId: widget.process.entityId, processId: widget.process.processId);

    _currentStep = 0;
  }

  void stepMakeEnvelope(BuildContext context) async {
    final currentAccount = globalAppState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    final patternLockKey = await Navigator.push(
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
      showMessage(getText(context, "The pattern you entered is not valid"),
          context: context, purpose: Purpose.DANGER);
      return;
    }

    setState(() => _currentStep = 1);

    // PREPARE DATA
    String merkleProof;
    EthereumNativeWallet wallet;

    final dvoteGw = await getDVoteGateway();
    if (dvoteGw == null) throw Exception("No DVote gateway is available");

    try {
      // Derive per-entity key
      final entityAddressHash = widget.process.metadata.value.details.entityId;

      final mnemonic = await Symmetric.decryptStringAsync(
          currentAccount.identity.value.keys[0].encryptedMnemonic,
          patternLockKey);

      if (!mounted) return;

      wallet = EthereumNativeWallet.fromMnemonic(mnemonic,
          entityAddressHash: entityAddressHash);

      // Merkle Proof

      // final publicKey = (await wallet.publicKeyAsync(uncompressed: true)).replaceAll("0x", "");
      // final base64Claim = base64.encode(hex.decode(publicKey));

      final publicKey = await wallet.publicKeyAsync(uncompressed: true);
      final b64DigestedClaim = await digestHexClaim(publicKey);
      final alreadyDigested = true;

      merkleProof = await generateProof(
          widget.process.metadata.value.census.merkleRoot,
          b64DigestedClaim,
          alreadyDigested,
          dvoteGw);

      if (!mounted)
        return;
      else if (!(merkleProof is String)) throw Exception("Empty census proof");
    } catch (err) {
      devPrint(err);

      showMessage(getText(context, "The census could not be checked"),
          context: context);
      setState(() => _currentStep = 0);
      return;
    }

    assert(merkleProof is String);
    assert(wallet is EthereumNativeWallet);

    try {
      // CHECK IF THE VOTE IS ALREADY REGISTERED
      await widget.process.refreshHasVoted(force: true);
      if (!mounted) return;

      if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value) {
        setState(() => _currentStep = 0);
        showMessage(getText(context, "Your vote has already been registered"),
            context: context, purpose: Purpose.GUIDE);
        return;
      }

      // PREPARE THE VOTE ENVELOPE
      ProcessKeys processKeys;
      if (widget.process.metadata.value.type == "encrypted-poll") {
        processKeys = await getProcessKeys(widget.process.processId, dvoteGw);
      }

      if (!mounted) return;

      Map<String, dynamic> envelope = await packagePollEnvelope(widget.choices,
          merkleProof, widget.process.processId, await wallet.privateKeyAsync,
          processKeys: processKeys);

      if (!mounted) return;

      setState(() {
        _envelope = envelope;
      });

      stepSendVote(context);
    } catch (err) {
      devPrint("stepMakeEnvelope error: $err");
      showMessage(getText(context, "The vote data could not be prepared"),
          context: context);
      setState(() {
        _currentStep = 0;
      });
    }
  }

  void stepSendVote(BuildContext context) async {
    try {
      setState(() => _currentStep = 2);
      final dvoteGw = await getDVoteGateway();
      if (dvoteGw == null) throw Exception("No DVote gateway is available");

      await submitEnvelope(_envelope, dvoteGw);

      if (!mounted) return;

      setState(() => _currentStep++);

      return stepConfirm(context);
    } catch (error) {
      if (!mounted) return;

      setState(() => _currentStep = 0);
      showMessage(getText(context, "The vote could not be delivered"),
          purpose: Purpose.DANGER, context: context);
    }
  }

  void stepConfirm(BuildContext context) async {
    setState(() => _currentStep = 3);
    try {
      const RETRIES = 4;
      for (int i = 0; i < RETRIES; i++) {
        await widget.process.refreshHasVoted(force: true);
        if (!mounted) return;

        if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value)
          break; // done!

        if (i < (RETRIES - 1))
          await Future.delayed(Duration(seconds: 5)); // wait and try again
      }

      if (widget.process.hasVoted.hasError ||
          widget.process.hasVoted.value == false) {
        setState(() => _currentStep = 0);
        showMessage(
            getText(
                context, "The status of the envelope could not be validated"),
            context: context,
            purpose: Purpose.WARNING);
        return;
      }

      // DONE!
      setState(() => _currentStep = 4);
    } catch (err) {
      showMessage(getText(context, "The vote delivery could not be checked"),
          purpose: Purpose.DANGER, context: context);

      if (mounted) setState(() => _currentStep = 0);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(context, "Participation"),
        showBackButton: true,
        onBackButton: () {
          Navigator.of(context).pop();
        },
      ),
      body: Builder(
        builder: (BuildContext context) => SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(),
                  Section(
                    text: _currentStep == 0
                        ? getText(context, "Ready when you are")
                        : getText(context, "Delivering the vote"),
                    withDectoration: true,
                  ),
                  /*Summary(
                    maxLines: 10,
                    text:
                        "This may take some time, please do not close this screen"),*/
                  buildStep(getText(context, "Sigining"),
                      getText(context, "Signed"), 1),
                  // buildStep("Generating proof", "Proof generated", 2),
                  buildStep(getText(context, "Delivering"),
                      getText(context, "Sent"), 2),
                  buildStep(getText(context, "Waiting confirmation"),
                      getText(context, "Confirmed"), 3),
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
                              text: getText(context, "Confirm"),
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
                              text: getText(context, "Close"),
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
