import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/unlockPattern.dart';

enum SetPatternState { setting, waitingConfirmation, confirming }

class Unlock extends StatefulWidget {
  @override
  _UnlockState createState() => _UnlockState();
}

class _UnlockState extends State<Unlock> {
  int minLength = 5;
  int maxLength = 10;
  double widthSize = 250;
  int gridSize = 4;
  double dotRadius = 10;
  bool canDraw = true;
  Color patternColor = blueColor;
  SetPatternState patternState = SetPatternState.setting;
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
                text: patternState==SetPatternState.setting? "Set a a new pattern":"Confirm your pattern",
              ),
              Center(
                child: patternState == SetPatternState.setting ||
                        patternState == SetPatternState.waitingConfirmation
                    ? buildSetting()
                    : buildConfirming(),
              ),
              Padding(
                padding: EdgeInsets.all(elementSpacing * 4),
                child: BaseButton(
                    text: "Looks good",
                    //isDisabled:patternState != SetPatternState.waitingConfirmation,
                    secondary: false,
                    onTap: () => onApprovePattern()),
              )
            ]));
  }

  onApprovePattern() {
    setState(() {
      patternState = SetPatternState.confirming;
      debugPrint("confirmed");
    });
  }

  UnlockPattern buildSetting() {
    return UnlockPattern(
        key: Key("SetPattern"),
        gridSize: gridSize,
        widthSize: widthSize,
        dotRadius: dotRadius,
        canRepeatDot: false,
        patternColor: patternColor,
        dotsColor: descriptionColor,
        canDraw: canDraw,
        onPatternStopped: onSettingPatternStopped);
  }

  void onSettingPatternStopped(List<int> pattern) {
    if (pattern.length < minLength) {
      //show "to short"
    }
    debugPrint(pattern.toString());

    setState(() {
      canDraw = true;
      patternColor = greenColor;
      setPattern = pattern;
      patternState = SetPatternState.waitingConfirmation;
    });
  }

  UnlockPattern buildConfirming() {
    return UnlockPattern(
        key: Key("ConfirmPattern"),
        gridSize: gridSize,
        widthSize: widthSize,
        dotRadius: dotRadius,
        canRepeatDot: false,
        patternColor: patternColor,
        dotsColor: descriptionColor,
        canDraw: true,
        onPatternStopped: onConfirmingPatternStopped);
  }

  void onConfirmingPatternStopped(List<int> pattern) {
    if (pattern.length < minLength) {
      //show "to short"
    }

    setState(() {
      canDraw = false;
      patternColor = greenColor;
    });
  }
}
