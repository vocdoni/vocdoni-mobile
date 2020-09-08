import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/pattern.dart';
import 'package:vocdoni/lib/singletons.dart';
// import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/unlockPattern/drawPattern.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/constants/settings.dart';

enum PatternStep { READY, CONFIRMING, DONE }

/// This component prompts for a visual lock patten, which is transformed into a passphrase
/// and returned as a string via the router.
class PatternCreateModal extends StatefulWidget {
  final bool canGoBack;

  PatternCreateModal({this.canGoBack = true});

  @override
  _PatternCreateModalState createState() => _PatternCreateModalState();
}

class _PatternCreateModalState extends State<PatternCreateModal> {
  final minPatternDots = 5;
  final maxPatternDots = 100;
  final widthSize = 300.0;
  final dotRadius = 5.0;
  final hitRadius = 20.0;
  final toasterDuration = 3;
  final hitColor = Colors.transparent;
  Color patternColor = colorBlue;
  PatternStep patternStep = PatternStep.READY;
  List<int> setPattern = [];

  @override
  void initState() {
    super.initState();
    globalAnalytics.trackPage("PatternCreateModal");
  }

  @override
  Widget build(BuildContext context) {
    String message = "";
    switch (patternStep) {
      case PatternStep.READY:
        message =
            getText(context, "main.drawAPatternToLockYourIdentity") + ". ";
        message += getText(context,
                    "main.yourPatternShouldIncludeAtLeastNumDots")
                .replaceAll("{{NUM}}", minPatternDots.toString()) +
            ".";
        break;
      case PatternStep.CONFIRMING:
        message = getText(context,
            "main.confirmTheLockPatternYouEnteredToCreateYourIdentity");
        break;
      case PatternStep.DONE:
        message = getText(context,
            "main.yourPatternHasBeenSetYouWillNeedItToUnlockYourIdentity");
        break;
    }

    return Scaffold(
      appBar: TopNavigation(
        title: " ",
        showBackButton:
            widget.canGoBack || patternStep == PatternStep.CONFIRMING,
        onBackButton: onCancel,
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 3),
            Section(text: getText(context, "main.lockPattern")),
            SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: colorGuide, fontWeight: FontWeight.w400),
            ).withHPadding(24),
            Spacer(),
            Center(
              child: patternStep == PatternStep.READY
                  ? buildFirstPass()
                  : buildSecondPass(),
            ),
            // Spacer(),
            // SizedBox(
            //   height: 100,
            //   child: Center(
            //     child: Container(
            //       child: patternStep != PatternStep.WAIT_CONFIRM
            //           ? null
            //           : BaseButton(
            //               maxWidth: buttonDefaultWidth,
            //               text: getText(context, "main.continue"),
            //               // isDisabled:patternState != SetPatternState.waitingConfirmation,
            //               onTap: () => onApprovePattern(),
            //             ),
            //     ),
            //   ),
            // ),
            Spacer(flex: 3),
          ]),
    );
  }

  onCancel() {
    // if (patternStep == PatternStep.CONFIRMING) {
    //   resetToSetting();
    // } else {
    Navigator.pop(context, null);
    // }
  }

  onApprovePattern() {
    setState(() {
      patternStep = PatternStep.CONFIRMING;
    });
  }

  // resetToSetting() {
  //   setState(() {
  //     patternStep = PatternStep.READY;
  //     patternColor = colorBlue;
  //   });
  // }

  /// Builds the UI of a lock pattern that is entered for the first time
  DrawPattern buildFirstPass() {
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
        onPatternStarted: onFirstPassStart,
        onPatternStopped: onFirstPassDone);
  }

  /// Builds the UI of a lock pattern that is entered for the second time
  DrawPattern buildSecondPass() {
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
      onPatternStarted: onSecondPassStart,
      onPatternStopped: onSecondPassDone,
    );
  }

  void onFirstPassStart(BuildContext context) {
    setState(() {
      patternStep = PatternStep.READY;
      patternColor = colorBlue;
    });
  }

  void onFirstPassDone(BuildContext context, List<int> newPattern) {
    if (newPattern.length < minPatternDots) {
      final err =
          getText(context, "main.thePatternNeedsToHaveAtLeastNumDots")
              .replaceFirst("{{NUM}}", minPatternDots.toString());
      showMessage(err,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      setState(() {
        patternColor = colorRed;
      });
      return;
    } else if (newPattern.length >= maxPatternDots) {
      final err =
          getText(context, "main.thePatternShouldNotHaveMoreThanNumDots")
              .replaceFirst("{{NUM}}", maxPatternDots.toString());
      showMessage(err,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      return;
    }

    setState(() {
      patternColor = colorGreen;
      setPattern = newPattern;
      patternStep = PatternStep.CONFIRMING;
    });
  }

  void onSecondPassStart(BuildContext context) {
    setState(() {
      patternColor = colorBlue;
    });
  }

  void onSecondPassDone(BuildContext context, List<int> pattern) {
    // log(pattern.toString() + "==" + setPattern.toString());

    if (!listEquals(setPattern, pattern)) {
      setState(() {
        patternColor = colorRed;
      });

      final msg = getText(context, "main.thePatternsYouEnteredDoNotMatch");
      showMessage(msg,
          context: context, duration: toasterDuration, purpose: Purpose.DANGER);
      return;
    }

    this.setState(() {
      patternStep = PatternStep.DONE;
      patternColor = colorGreen;
    });
    showMessage(getText(context, "main.yourPatternHasBeenSet"),
        context: context, duration: toasterDuration, purpose: Purpose.GOOD);

    Future.delayed(Duration(seconds: 2)).then((_) {
      final strPattern = patternToString(pattern, gridSize: PATTERN_GRID_SIZE);
      Navigator.pop(context, strPattern);
    });
  }
}
