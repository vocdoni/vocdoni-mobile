import 'package:dvote/dvote.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/modals/pattern-prompt-modal.dart';
import 'package:vocdoni/models/processModel.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/util/api.dart';

class PollPackaging extends StatefulWidget {
  final ProcessModel processModel;
  final List<int> answers;

  PollPackaging({this.processModel, this.answers});

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
        pageId: "PollPackaging",
        entityId: widget.processModel.entityReference.entityId,
        processId: widget.processModel.processId);

    _currentStep = 0;
  }

  void stepMakeEnvelope(BuildContext ctx) async {
    var patternLockKey = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PaternPromptModal(
                account.identity.keys[0].encryptedPrivateKey)));

    // TODO: ERROR => THIS IS NOT A SCAFFOLD
    if (patternLockKey == null || patternLockKey is InvalidPatternError) {
      showMessage("The pattern you entered is not valid",
          context: ctx, purpose: Purpose.DANGER);
      return;
    }

    final privateKey = await decryptString(
        account.identity.keys[0].encryptedPrivateKey, patternLockKey);

    Map<String, String> envelope = await packagePollEnvelope(
        widget.answers,
        widget.processModel.processMetadata.value.census.merkleRoot,
        widget.processModel.processId,
        privateKey);

    setState(() {
      _envelope = envelope;
      _currentStep = _currentStep + 1;
    });

    stepSend(ctx);
  }

  void stepSend(BuildContext ctx) async {
    final gwInfo = selectRandomGatewayInfo();

    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    try {
      bool success = false;
      // DateTime now = new DateTime.now();
      // String nowstr = now.toString();
      // int timestamp = now.millisecondsSinceEpoch;

      await submitEnvelope(_envelope, dvoteGw);

      if (success) {
        setState(() => _currentStep++);

        return stepConfirm(ctx);
      } else {
        debugPrint("failed to send the vote");
      }
    } catch (error) {
      //Todo: handle timeut
      dvoteGw.disconnect();
      showMessage("The vote could not be delivered",
          purpose: Purpose.DANGER, context: context);
    }
  }

  void stepConfirm(BuildContext ctx) async {
    final gwInfo = selectRandomGatewayInfo();

    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    String pollNullifier = "";
    await getEnvelopeStatus(
        widget.processModel.processId, pollNullifier, dvoteGw);

    dvoteGw.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext ctx) => Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 350),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Spacer(),
                Section(
                  text: _currentStep == 0
                      ? "Vote delivery"
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
                //         if (_currentStep == 5) Navigator.pop(ctx, false);
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
                            onTap: () => stepMakeEnvelope(ctx)),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStep(String presentText, String pastText, int stepValue) {
    String text = presentText;

    if (_currentStep == stepValue)
      text = presentText;
    else if (_currentStep > stepValue) text = pastText;

    return ListItem(
      mainText: text,
      rightIcon: _currentStep > stepValue ? FeatherIcons.check : null,
      isSpinning: _currentStep == stepValue,
      rightTextPurpose: Purpose.GOOD,
      isBold: _currentStep == stepValue,
      disabled: _currentStep < stepValue,
    );
  }
}
