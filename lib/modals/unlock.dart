import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/unlockPattern.dart';
import 'package:collection/collection.dart';

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
                text: patternState == SetPatternState.setting ||
                        patternState == SetPatternState.waitingConfirmation
                    ? "Set a a new pattern"
                    : "Confirm your pattern",
              ),
              Center(
                child: patternState == SetPatternState.setting ||
                        patternState == SetPatternState.waitingConfirmation
                    ? buildSetting()
                    : buildConfirming(),
              ),
              Padding(
                padding: EdgeInsets.all(elementSpacing * 4),
                child: patternState != SetPatternState.waitingConfirmation
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
        onPatternStarted: onSettingPatternStarted,
        onPatternStopped: onSettingPatternStopped);
  }

  void onSettingPatternStarted() {
    setState(() {
      patternState = SetPatternState.setting;
      patternColor = blueColor;
    });
  }

  void onSettingPatternStopped(List<int> pattern) {
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
      onPatternStarted: onConfirmingPatternStarted,
      onPatternStopped: onConfirmingPatternStopped,
    );
  }

  void onConfirmingPatternStarted() {
    setState(() {
      patternColor = blueColor;
    });
  }

  void onConfirmingPatternStopped(List<int> pattern) {
    debugPrint(pattern.toString() + "==" + setPattern.toString());

    if (!listEquals(setPattern, pattern)) {
      setState(() {
        canDraw = false;
        patternColor = redColor;
      });
      return;
    }
    onNewPattern(pattern);
  }

  onNewPattern(List<int> pattern) {}
}
