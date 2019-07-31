import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';

enum PatternStep { setting, waitingApproval, confirming }

class PatternCreateModal extends StatefulWidget {
  final bool canGoBack;

  PatternCreateModal({this.canGoBack = true});

  @override
  _PatternCreateModalState createState() => _PatternCreateModalState();
}

class _PatternCreateModalState extends State<PatternCreateModal> {
  int minPatternDots = 5;
  int maxPatternDots = 100;
  double widthSize = 300;
  int gridSize = 5;
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
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
            Spacer(flex: 3),
            Section(
              withDectoration: false,
              text: patternStep == PatternStep.setting ||
                      patternStep == PatternStep.waitingApproval
                  ? "Set a a new pattern"
                  : "Confirm your pattern",
            ),
            Spacer(),
            Center(
              child: patternStep == PatternStep.setting ||
                      patternStep == PatternStep.waitingApproval
                  ? buildSetting()
                  : buildConfirming(),
            ),
            Spacer(),
            SizedBox(
              height: 100,
              child: Center(
                child: Container(
                  child: patternStep != PatternStep.waitingApproval
                      ? null
                      : BaseButton(
                          text: "Continue",
                          //isDisabled:patternState != SetPatternState.waitingConfirmation,
                          secondary: false,
                          onTap: () => onApprovePattern(),
                        ),
                ),
              ),
            ),
            Spacer(),
          ]),
    );
  }

  onCancel() {
    if (patternStep == PatternStep.confirming) {
      resetToSetting();
    } else {
      Navigator.pop(context, null);
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

  /// Builds the UI of a lock pattern that is entered for the first time
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
        onPatternStarted: onSettingPatternStart,
        onPatternStopped: onSettingPatternStop);
  }

  void onSettingPatternStart(BuildContext context) {
    setState(() {
      patternStep = PatternStep.setting;
      patternColor = blueColor;
    });
  }

  void onSettingPatternStop(BuildContext context, List<int> pattern) {
    debugPrint(pattern.length.toString());
    if (pattern.length < minPatternDots) {
      showErrorMessage("The pattern must have at least $minPatternDots points",
          context: context, duration: toasterDuration, buttonText: "");
      setState(() {
        patternColor = redColor;
      });
      return;
    }

    if (pattern.length >= maxPatternDots) {
      showErrorMessage("The pattern should not exceed $maxPatternDots points",
          context: context, duration: toasterDuration);
      return;
    }
    debugPrint(pattern.toString());

    setState(() {
      patternColor = greenColor;
      setPattern = pattern;
      patternStep = PatternStep.waitingApproval;
    });
  }

  /// Builds the UI of a lock pattern that is entered for the second time
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
      onPatternStarted: onConfirmingPatternStart,
      onPatternStopped: onConfirmingPatternStop,
    );
  }

  void onConfirmingPatternStart(BuildContext context) {
    setState(() {
      patternColor = blueColor;
    });
  }

  void onConfirmingPatternStop(BuildContext context, List<int> pattern) {
    debugPrint(pattern.toString() + "==" + setPattern.toString());

    if (!listEquals(setPattern, pattern)) {
      setState(() {
        patternColor = redColor;
      });

      showErrorMessage("The patterns you entered don't match",
          context: context, duration: toasterDuration);
      return;
    }

    String stringPattern = '';
    for (int i = 0; i < pattern.length - 1; i++) {
      stringPattern += (pattern[i].toRadixString(gridSize * gridSize));
    }
    Navigator.pop(context, stringPattern);
  }
}
