import 'package:dvote/dvote.dart';
import 'package:dvote/models/dart/process.pb.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';

class PollPackaging extends StatefulWidget {
  final String privateKey;
  final ProcessMetadata processMetadata;
  final List<int> answers;

  PollPackaging({this.privateKey, this.processMetadata, this.answers});

  @override
  _PollPackagingState createState() => _PollPackagingState();
}

class _PollPackagingState extends State<PollPackaging> {
  int _currentStep;
  Map<String, String> _envelope;

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    makeEnvelop();
  }

  void makeEnvelop() async {
    Map<String, String> envelope = await generatePollVoteEnvelope(
        widget.answers,
        widget.processMetadata.census.merkleRoot,
        widget.processMetadata.meta[META_PROCESS_ID],
        widget.privateKey);

    setState(() {
      _envelope = envelope;
      _currentStep = _currentStep + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 350),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              Section(
                text: "Preparing vote " + _currentStep.toString(),
                withDectoration: false,
              ),
              /*Summary(
                  maxLines: 10,
                  text:
                      "This may take some time, please do not close this screen"),*/
              buildStep("Sigining", "Signed", 0),
              buildStep("Generating proof", "Proof generated", 1),
              buildStep("Sending", "Sent", 2),
              buildStep("Waiting confirmation", "Confirmed", 3),
              Spacer(),
              Padding(
                padding: EdgeInsets.all(48),
                child: BaseButton(
                    text: "Submit",
                    isSmall: true,
                    style: BaseButtonStyle.OUTLINE,
                    maxWidth: buttonDefaultWidth,
                    //purpose: Purpose.HIGHLIGHT,
                    //isDisabled: true,
                    onTap: () {
                      setState(() {
                        _currentStep++;
                      });
                      if (_currentStep == 5) Navigator.pop(context, false);
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStep(String presentText, String pastText, int step) {
    String text = presentText;
    if (_currentStep == step)
      text = presentText;
    else if (_currentStep > step) text = pastText;
    return ListItem(
      mainText: text,
      rightIcon: _currentStep > step ? FeatherIcons.check : null,
      isSpinning: _currentStep == step,
      rightTextPurpose: Purpose.GOOD,
      isBold: _currentStep == step,
      disabled: _currentStep < step,
    );
  }
}
