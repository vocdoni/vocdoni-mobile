import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:dvote/blockchain/ens.dart';
import 'package:dvote/dvote.dart';
import 'package:dvote/models/build/dart/vochain/vochain.pb.dart';
import 'package:dvote/wrappers/process-keys.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/logger.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';
// import 'package:convert/convert.dart';
// import 'dart:convert';

class PollPackagingPage extends StatefulWidget {
  final ProcessModel process;
  final List<int> choices;

  PollPackagingPage({@required this.process, @required this.choices});

  @override
  _PollPackagingPageState createState() => _PollPackagingPageState();
}

class _PollPackagingPageState extends State<PollPackagingPage> {
  int _currentStep;
  SignedTx _signedTx;

  @override
  void initState() {
    super.initState();

    Globals.analytics.trackPage("PollVote",
        entityId: widget.process.entityId, processId: widget.process.processId);

    _currentStep = 0;
  }

  void stepMakeEnvelope(BuildContext context) async {
    final currentAccount = Globals.appState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    final mnemonic = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PinPromptModal(currentAccount)));

    if (!mounted)
      return;
    else if (mnemonic == null) {
      setState(() => _currentStep = 0);
      return;
    } else if (mnemonic is InvalidPatternError) {
      setState(() => _currentStep = 0);
      showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
          context: context, purpose: Purpose.DANGER);
      return;
    }

    setState(() => _currentStep = 1);

    // PREPARE DATA
    String merkleProof;
    EthereumWallet wallet;

    try {
      // Derive per-entity key
      final entityAddress =
          widget.process.processData.value.entityAddress.hexNo0x;

      if (!mounted) return;

      wallet = EthereumWallet.fromMnemonic(mnemonic,
          hdPath: currentAccount.identity.value.wallet.hdPath,
          entityAddressHash:
              ensHashAddress(Uint8List.fromList(hex.decode(entityAddress))));

      // Merkle Proof

      final publicKey = (await wallet.publicKeyAsync()).replaceAll("0x", "");
      final base64RawClaim = base64.encode(hex.decode(publicKey));
      final alreadyDigested = false;

      // TODO: Revert back to digested

      // final publicKey = await wallet.publicKeyAsync();
      // final b64DigestedClaim = Hashing.digestHexClaim(publicKey);
      // final alreadyDigested = true;

      merkleProof = await generateProof(
          widget.process.processData.value.censusRoot,
          base64RawClaim, // b64DigestedClaim,
          alreadyDigested,
          AppNetworking.pool);

      if (!mounted)
        return;
      else if (!(merkleProof is String)) throw Exception("Empty census proof");
    } catch (err) {
      logger.log(err);

      showMessage(getText(context, "main.theCensusCouldNotBeChecked"),
          context: context);
      setState(() => _currentStep = 0);
      return;
    }

    assert(merkleProof is String);
    assert(wallet is EthereumWallet);

    try {
      // CHECK IF THE VOTE IS ALREADY REGISTERED
      await widget.process.refreshHasVoted(force: true);
      if (!mounted) return;

      if (widget.process.hasVoted.hasValue && widget.process.hasVoted.value) {
        setState(() => _currentStep = 0);
        showMessage(getText(context, "main.yourVoteHasAlreadyBeenRegistered"),
            context: context, purpose: Purpose.GUIDE);
        return;
      }

      // PREPARE THE VOTE ENVELOPE
      ProcessKeys processKeys;
      if (widget.process.processData.value.envelopeType.hasEncryptedVotes) {
        processKeys =
            await getProcessKeys(widget.process.processId, AppNetworking.pool);
      }

      if (!mounted) return;

      final envelope = await packageEnvelope(
          widget.choices,
          merkleProof,
          widget.process.processId,
          widget.process.processData.value.censusOrigin,
          processKeys: processKeys);

      final signedTx = await packageVoteTx(
        envelope,
        await wallet.privateKeyAsync,
      );

      if (!mounted) return;

      setState(() {
        _signedTx = signedTx;
      });

      stepSendVote(context);
    } catch (err) {
      logger.log("stepMakeEnvelope error: $err");
      showMessage(getText(context, "error.theVoteDataCouldNotBePrepared"),
          context: context);
      setState(() {
        _currentStep = 0;
      });
    }
  }

  void stepSendVote(BuildContext context) async {
    try {
      setState(() => _currentStep = 2);
      final txBytes = _signedTx.writeToBuffer();
      await submitRawTx(txBytes, AppNetworking.pool);

      if (!mounted) return;

      setState(() => _currentStep++);

      return stepConfirm(context);
    } catch (error) {
      logger.log("stepSendVote error: $error");
      if (!mounted) return;

      setState(() => _currentStep = 0);
      showMessage(getText(context, "error.theVoteCouldNotBeDelivered"),
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
            getText(context, "error.theStatusOfTheEnvelopeCouldNotBeValidated"),
            context: context,
            purpose: Purpose.WARNING);
        return;
      }

      // DONE!
      setState(() => _currentStep = 4);
    } catch (err) {
      showMessage(getText(context, "error.theVoteDeliveryCouldNotBeChecked"),
          purpose: Purpose.DANGER, context: context);

      if (mounted) setState(() => _currentStep = 0);
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(context, "main.participation"),
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
                        ? getText(context, "main.readyWhenYouAre")
                        : getText(context, "main.deliveringTheVote"),
                    withDectoration: true,
                  ),
                  /*Summary(
                    maxLines: 10,
                    text:
                        "This may take some time, please do not close this screen"),*/
                  buildStep(getText(context, "main.sigining"),
                      getText(context, "main.signed"), 1),
                  // buildStep("Generating proof", "Proof generated", 2),
                  buildStep(getText(context, "main.delivering"),
                      getText(context, "main.sent"), 2),
                  buildStep(getText(context, "main.waitingConfirmation"),
                      getText(context, "main.confirmed"), 3),
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
                              text: getText(context, "main.confirm"),
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
                              text: getText(context, "main.close"),
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
