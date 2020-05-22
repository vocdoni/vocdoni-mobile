import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/pattern.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/unlockPattern/drawPattern.dart';
import 'package:vocdoni/constants/settings.dart';

enum PatternStep {
  PATTERN_SETTING,
  PATTERN_WAITING_CONFIRM,
  PATTERN_CONFIRMING
}

/// This component prompts for a visual lock patten, which is transformed into a passphrase
/// and returned as a string via the router.
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
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
  Color hitColor = Colors.transparent;
  Color patternColor = colorBlue;
  PatternStep patternStep = PatternStep.PATTERN_SETTING;
  List<int> setPattern = [];

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("PatternCreateModal");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: " ",
        showBackButton:
            widget.canGoBack || patternStep == PatternStep.PATTERN_CONFIRMING,
        onBackButton: onCancel,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 3),
            Section(
              withDectoration: false,
              text: patternStep == PatternStep.PATTERN_SETTING ||
                      patternStep == PatternStep.PATTERN_WAITING_CONFIRM
                  ? getText(context, "Set a new pattern")
                  : getText(context, "Confirm your pattern"),
            ),
            Spacer(),
            Center(
              child: patternStep == PatternStep.PATTERN_SETTING ||
                      patternStep == PatternStep.PATTERN_WAITING_CONFIRM
                  ? buildSetting()
                  : buildConfirming(),
            ),
            Spacer(),
            SizedBox(
              height: 100,
              child: Center(
                child: Container(
                  child: patternStep != PatternStep.PATTERN_WAITING_CONFIRM
                      ? null
                      : BaseButton(
                          maxWidth: buttonDefaultWidth,
                          text: getText(context, "Continue"),
                          // isDisabled:patternState != SetPatternState.waitingConfirmation,
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
    if (patternStep == PatternStep.PATTERN_CONFIRMING) {
      resetToSetting();
    } else {
      Navigator.pop(context, null);
    }
  }

  onApprovePattern() {
    setState(() {
      patternStep = PatternStep.PATTERN_CONFIRMING;
    });
  }

  resetToSetting() {
    setState(() {
      patternStep = PatternStep.PATTERN_SETTING;
      patternColor = colorBlue;
    });
  }

  /// Builds the UI of a lock pattern that is entered for the first time
  DrawPattern buildSetting() {
    return DrawPattern(
        key: Key("SetPattern"),
        gridSize: PATTERN_GRID_SIZE,
        widthSize: widthSize,
        dotRadius: dotRadius,
        hitRadius: hitRadius,
        hitColor: hitColor,
        canRepeatDot: false,
        patternColor: patternColor,
        dotColor: colorDescription,
        canDraw: true,
        onPatternStarted: onSettingPatternStart,
        onPatternStopped: onSettingPatternStop);
  }

  void onSettingPatternStart(BuildContext context) {
    setState(() {
      patternStep = PatternStep.PATTERN_SETTING;
      patternColor = colorBlue;
    });
  }

  void onSettingPatternStop(BuildContext context, List<int> pattern) {
    if (pattern.length < minPatternDots) {
      final err =
          getText(context, "The pattern must have at least {{NUM}} points")
              .replaceFirst("{{NUM}}", minPatternDots.toString());
      showMessage(err,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      setState(() {
        patternColor = colorRed;
      });
      return;
    }

    if (pattern.length >= maxPatternDots) {
      final err =
          getText(context, "The pattern should not exceed {{NUM}} points")
              .replaceFirst("{{NUM}}", maxPatternDots.toString());
      showMessage(err,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      return;
    }

    setState(() {
      patternColor = colorGreen;
      setPattern = pattern;
      patternStep = PatternStep.PATTERN_WAITING_CONFIRM;
    });
  }

  /// Builds the UI of a lock pattern that is entered for the second time
  DrawPattern buildConfirming() {
    return DrawPattern(
      key: Key("ConfirmPattern"),
      gridSize: PATTERN_GRID_SIZE,
      widthSize: widthSize,
      dotRadius: dotRadius,
      hitRadius: hitRadius,
      hitColor: hitColor,
      canRepeatDot: false,
      patternColor: patternColor,
      dotColor: colorDescription,
      canDraw: true,
      onPatternStarted: onConfirmingPatternStart,
      onPatternStopped: onConfirmingPatternStop,
    );
  }

  void onConfirmingPatternStart(BuildContext context) {
    setState(() {
      patternColor = colorBlue;
    });
  }

  void onConfirmingPatternStop(BuildContext context, List<int> pattern) {
    // devPrint(pattern.toString() + "==" + setPattern.toString());

    if (!listEquals(setPattern, pattern)) {
      setState(() {
        patternColor = colorRed;
      });

      final err = getText(context, "The patterns you entered don't match");
      showMessage(err,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      return;
    }

    String stringPattern =
        patternToString(pattern, gridSize: PATTERN_GRID_SIZE);
    Navigator.pop(context, stringPattern);
  }
}
