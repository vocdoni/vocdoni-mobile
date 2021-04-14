import 'dart:convert';

import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/unlockPattern/enterPin.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/pattern.dart';

/// This component prompts for a visual lock patten, which is transformed into a passphrase.
/// The component will attempt to decrypt `encryptedText`. If it succeeds, the
/// passphrase will be returned via the router as a string.
/// tryDecrypt attemps to decrypt the given account's private key. If false, pin is returned
/// returnPin causes the pin to be returned, even if the mnemonic is decrypted.
class PinPromptModal extends StatefulWidget {
  final AccountModel account; // to unlock
  final bool tryDecrypt;
  final bool returnPin;
  final String accountName;

  PinPromptModal(this.account,
      {this.tryDecrypt = true, this.accountName, this.returnPin = false});

  @override
  _PinPromptModalState createState() => _PinPromptModalState();
}

class _PinPromptModalState extends State<PinPromptModal> {
  int pinLength = PIN_LENGTH;

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("PinPrompModal");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: " ",
        showBackButton: true,
        onBackButton: onCancel,
      ),
      body: Builder(
        builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Section(
                withDectoration: false,
                text: getText(context, "main.unlockName").replaceFirst(
                    "{{NAME}}",
                    widget.accountName == null
                        ? widget.account.identity.value.name
                        : widget.accountName),
              ),
              Spacer(),
              EnterPin(
                totalDigits: pinLength,
                onPinHaptic: () => HapticFeedback.mediumImpact(),
                onPinStopped: onPinEntered,
                padding: EdgeInsets.symmetric(horizontal: paddingPage),
                indicatorSpace: spaceCard * 3,
              ),
              Spacer(),
            ]),
      ),
    );
  }

  onCancel() {
    Navigator.pop(context, null);
  }

  onPinEntered(BuildContext context, List<int> pin) async {
    final passphrase = pinToString(pin);
    try {
      // Don't try to decrypt (used for prompting a pin without decrypting)
      if (!widget.tryDecrypt) {
        Navigator.pop(context, passphrase);
        return;
      }
      final encryptedText =
          widget.account.identity.value.wallet.encryptedMnemonic;
      // check if we can decrypt it
      final loading = showLoading(getText(context, "main.generatingIdentity"),
          context: context);

      final decryptedPayload = await Symmetric.decryptStringAsync(
          base64.encode(encryptedText), passphrase);
      loading.close();

      if (decryptedPayload == null)
        throw InvalidPatternError("The decryption key is invalid");

      // Even if we only want pin, still needs to ensure decryption key is valid
      if (widget.returnPin) {
        Navigator.pop(context, passphrase);
        return;
      }

      // OK
      Navigator.pop(context, decryptedPayload);
      widget.account.trackSuccessfulAuth().catchError((_) {});
    } catch (err) {
      await widget.account.trackFailedAuth();
      if (!mounted) return;

      Navigator.pop(
          context, InvalidPatternError("main.thePinYouEnteredIsNotValid"));
    }
  }
}
