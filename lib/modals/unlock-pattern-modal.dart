import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseButton.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';

class UnlockPatternModal extends StatefulWidget {


  UnlockPatternModal();

  @override
  _UnlockPatternModalState createState() => _UnlockPatternModalState();
}

class _UnlockPatternModalState extends State<UnlockPatternModal> {
  int minLength = 5;
  int maxLength = 100;
  double widthSize = 300;
  int gridSize = 3;
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
  Color hitColor = Colors.transparent;
  Color patternColor = blueColor;
  List<int> setPattern = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TopNavigation(
          title: " ",
          showBackButton:true,
          onBackButton: onCancel,
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(flex: 3),
              Section(
                withDectoration: false,
                text: "Unlock",
              ),
              Spacer(),
              Center(
                child: buildConfirming(),
              ),
              Spacer(),
            ]));
  }

  onCancel() { 
      Navigator.pop(context, null);
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

    String stringPattern = '';
    if (listEquals(setPattern, pattern)) {
      for (int i = 0; i < pattern.length - 1; i++) {
        stringPattern += (pattern[i].toRadixString(gridSize * gridSize));
      }
      Navigator.pop(context, stringPattern);
      return;
    }

    setState(() {
      patternColor = redColor;
    });

    showErrorMessage("Patterns don't match",
        context: context, duration: toasterDuration);
    return;
  }
}
