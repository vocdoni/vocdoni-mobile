import 'package:dvote/dvote.dart' as dvote;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/section.dart';
import 'package:vocdoni/widgets/topNavigation.dart';
import 'package:vocdoni/widgets/unlockPattern/drawPattern.dart';
import 'package:vocdoni/lib/pattern.dart';
import 'package:vocdoni/constants/settings.dart';

/// This component prompts for a visual lock patten, which is transformed into a passphrase.
/// The component will attempt to decrypt `encryptedText`. If it succeeds, the
/// passphrase will be returned via the router as a string.
class PaternPromptModal extends StatefulWidget {
  final String encryptedText;

  PaternPromptModal(this.encryptedText);

  @override
  _PaternPromptModalState createState() => _PaternPromptModalState();
}

class _PaternPromptModalState extends State<PaternPromptModal> {
  int minLength = 5;
  int maxLength = 100;
  double widthSize = 300;
  double dotRadius = 5;
  double hitRadius = 20;
  int toasterDuration = 3;
  Color hitColor = Colors.transparent;
  Color patternColor = colorBlue;

  @override
  void initState() {
    super.initState();
    analytics.trackPage("PatternPrompModal");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: TopNavigation(
          title: " ",
          showBackButton: true,
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
    // TODO: Implement exponential back-off

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
      onPatternStarted: onPatternStart,
      onPatternStopped: onPatternStop,
    );
  }

  void onPatternStart(BuildContext context) {
    setState(() {
      patternColor = colorBlue;
    });
  }

  onPatternStop(BuildContext context, List<int> pattern) async {
    try {
      String passphrase = patternToString(pattern, gridSize: PATTERN_GRID_SIZE);
      String decryptedPayload =
          await dvote.decryptString(widget.encryptedText, passphrase);
      if (decryptedPayload == null)
        throw InvalidPatternError("The decryption key is invalid");

      // OK
      await appStateBloc.trackAuthAttemp(true);
      Navigator.pop(context, passphrase);
    } catch (err) {
      await appStateBloc.trackAuthAttemp(false);
      if (!mounted) return;

      setState(() {
        patternColor = colorRed;
      });

      // TODO: Do not use this instance of context, because it does not
      // come from a Scaffold right now
      Navigator.pop(
          context, InvalidPatternError("The pattern you entered is not valid"));
    }
  }
}

class InvalidPatternError implements Exception {
  final String msg;
  const InvalidPatternError(this.msg);
  String toString() => 'InvalidPatternError: $msg';
}
