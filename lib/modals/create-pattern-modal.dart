import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';

enum PatternStep { setting, waitingApproval, confirming }

class CreatePatternModal extends StatefulWidget {
  @override
  _CreatePatternModalState createState() => _CreatePatternModalState();
}

class _CreatePatternModalState extends State<CreatePatternModal> {
  int minLength = 5;
  int maxLength = 10;
  double widthSize = 250;
  int gridSize = 4;
  double dotRadius = 10;
  bool canDraw = true;
  Color patternColor = blueColor;
  PatternStep patternState = PatternStep.setting;
  List<int> setPattern = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Vocdoni"),
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Section(
                text: patternState == PatternStep.setting ||
                        patternState == PatternStep.waitingApproval
                    ? "Set a a new pattern"
                    : "Confirm your pattern",
              ),
              Center(
                child: patternState == PatternStep.setting ||
                        patternState == PatternStep.waitingApproval
                    ? buildSetting()
                    : buildConfirming(),
              ),
              Padding(
                padding: EdgeInsets.all(elementSpacing * 4),
                child: patternState != PatternStep.waitingApproval
                    ? null
                    : BaseButton(
                        text: "Looks good",
                        //isDisabled:patternState != SetPatternState.waitingConfirmation,
                        secondary: false,
                        onTap: () => onApprovePattern()),
              )
            ]));
  }

  onApprovePattern() {
    setState(() {
      patternState = PatternStep.confirming;
      debugPrint("confirmed");
    });
  }

  DrawPattern buildSetting() {
    return DrawPattern(
        key: Key("SetPattern"),
        gridSize: gridSize,
        widthSize: widthSize,
        dotRadius: dotRadius,
        canRepeatDot: false,
        patternColor: patternColor,
        dotsColor: descriptionColor,
        canDraw: canDraw,
        onPatternStarted: onSettingPatternStarted,
        onPatternStopped: onSettingPatternStopped);
  }

  void onSettingPatternStarted(BuildContext context) {
    setState(() {
      patternState = PatternStep.setting;
      patternColor = blueColor;
    });
  }

  void onSettingPatternStopped(BuildContext context, List<int> pattern) {
    debugPrint(pattern.length.toString());
    if (pattern.length < minLength) {
      //show "to short"
      setState(() {
        canDraw = true;
        patternColor = redColor;
        //setPattern = [];
        //patternState = SetPatternState.waitingConfirmation;
      });
      return;
    }

    if (pattern.length > maxLength) {
      //show "to long"
    }
    debugPrint(pattern.toString());

    setState(() {
      canDraw = true;
      patternColor = greenColor;
      setPattern = pattern;
      patternState = PatternStep.waitingApproval;
    });
  }

  DrawPattern buildConfirming() {
    return DrawPattern(
      key: Key("ConfirmPattern"),
      gridSize: gridSize,
      widthSize: widthSize,
      dotRadius: dotRadius,
      canRepeatDot: false,
      patternColor: patternColor,
      dotsColor: descriptionColor,
      canDraw: true,
      onPatternStarted: onConfirmingPatternStarted,
      onPatternStopped: onConfirmingPatternStopped,
    );
  }

  void onConfirmingPatternStarted(BuildContext context) {
    setState(() {
      patternColor = blueColor;
    });
  }

  void onConfirmingPatternStopped(BuildContext context, List<int> pattern) {
    debugPrint(pattern.toString() + "==" + setPattern.toString());

    if (listEquals(setPattern, pattern)) {
      Navigator.pop(context, pattern);
      return;
    }

    setState(() {
      canDraw = false;
      patternColor = redColor;
    });
    return;
  }

}
