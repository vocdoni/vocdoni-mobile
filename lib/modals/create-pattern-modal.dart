import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';

enum PatternStep { setting, waitingApproval, confirming }

class CreatePatternModal extends StatefulWidget {
  bool canGoBack;

  CreatePatternModal({this.canGoBack = true});

  @override
  _CreatePatternModalState createState() => _CreatePatternModalState();
}

class _CreatePatternModalState extends State<CreatePatternModal> {
  int minLength = 5;
  int maxLength = 10;
  double widthSize = 250;
  int gridSize = 4;
  double dotRadius = 5;
  double hitRadius = 20;
  Color hitColor = Colors.transparent;
  Color patternColor = blueColor;
  PatternStep patternStep = PatternStep.setting;
  List<int> setPattern = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TopNavigation(
          title: " ",
          showBackButton:
              widget.canGoBack || patternStep == PatternStep.confirming,
          onBackButton: onCancel,
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Section(
                withDectoration: false,
                text: patternStep == PatternStep.setting ||
                        patternStep == PatternStep.waitingApproval
                    ? "Set a a new pattern"
                    : "Confirm your pattern",
              ),
              Center(
                child: patternStep == PatternStep.setting ||
                        patternStep == PatternStep.waitingApproval
                    ? buildSetting()
                    : buildConfirming(),
              ),
              Padding(
                padding: EdgeInsets.all(elementSpacing * 4),
                child: patternStep != PatternStep.waitingApproval
                    ? null
                    : BaseButton(
                        text: "Looks good",
                        //isDisabled:patternState != SetPatternState.waitingConfirmation,
                        secondary: false,
                        onTap: () => onApprovePattern()),
              )
            ]));
  }

  onCancel() {
    if (patternStep == PatternStep.confirming) {
      resetToSetting();
      return;
    } else {
      Navigator.pop(context, []);
      return;
    }
  }

  onApprovePattern() {
    setState(() {
      patternStep = PatternStep.confirming;
      debugPrint("confirmed");
    });
  }

  resetToSetting() {
    setState(() {
      patternStep = PatternStep.setting;
      patternColor = blueColor;
    });
  }

  DrawPattern buildSetting() {
    return DrawPattern(
        key: Key("SetPattern"),
        gridSize: gridSize,
        widthSize: widthSize,
        dotRadius: dotRadius,
        hitRadius: hitRadius,
        hitColor: hitColor,
        canRepeatDot: false,
        patternColor: patternColor,
        dotColor: descriptionColor,
        canDraw: true,
        onPatternStarted: onSettingPatternStarted,
        onPatternStopped: onSettingPatternStopped);
  }

  void onSettingPatternStarted(BuildContext context) {
    setState(() {
      patternStep = PatternStep.setting;
      patternColor = blueColor;
    });
  }

  void onSettingPatternStopped(BuildContext context, List<int> pattern) {
    debugPrint(pattern.length.toString());
    if (pattern.length < minLength) {
      //show "to short"
      setState(() {
        patternColor = redColor;
      });
      return;
    }

    if (pattern.length > maxLength) {
      //show "to long"
    }
    debugPrint(pattern.toString());

    setState(() {
      patternColor = greenColor;
      setPattern = pattern;
      patternStep = PatternStep.waitingApproval;
    });
  }

  DrawPattern buildConfirming() {
    return DrawPattern(
      key: Key("ConfirmPattern"),
      gridSize: gridSize,
      widthSize: widthSize,
      dotRadius: dotRadius,
      hitRadius: hitRadius,
      hitColor: hitColor,
      canRepeatDot: false,
      patternColor: patternColor,
      dotColor: descriptionColor,
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
      patternColor = redColor;
    });
    return;
  }
}
