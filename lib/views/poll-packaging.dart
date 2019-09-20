import 'package:dvote/models/dart/process.pb.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/summary.dart';

class PollPackaging extends StatefulWidget {
  final String privateKey;
  final ProcessMetadata processMetadata;
  final List<String> answers;

  PollPackaging({this.privateKey, this.processMetadata, this.answers});

  @override
  _PollPackagingState createState() => _PollPackagingState();
}

class _PollPackagingState extends State<PollPackaging> {
  int _current_step = 0;
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
                text: "Preparing vote",
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
                        _current_step++;
                      });
                      if(_current_step==5)
                       Navigator.pop(context, false);
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
    if (_current_step == step)
      text = presentText;
    else if (_current_step > step) text = pastText;
    return ListItem(
      mainText: text,
      rightIcon: _current_step > step ? FeatherIcons.check : null,
      isSpinning: _current_step == step,
      rightTextPurpose: Purpose.GOOD,
      isBold: _current_step == step,
      disabled: _current_step < step,
    );
  }
}
