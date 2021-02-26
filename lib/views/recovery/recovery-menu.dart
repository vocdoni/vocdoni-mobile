import 'package:vocdoni/lib/extensions.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/recovery/recovery-link-input.dart';
import 'package:vocdoni/views/recovery/recovery-mnemonic-input.dart';

class RecoveryMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(context, "main.accountRecovery"),
        onBackButton: () => Navigator.pop(context, null),
      ),
      body: ListView(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              getText(context, "main.chooseARecoveryMethod"),
              maxLines: 3,
              style: TextStyle(
                fontSize: 18,
                fontWeight: fontWeightLight,
              ),
            ).withHPadding(spaceCard).withVPadding(paddingPage),
          ),
          ListItem(
            mainText: getText(context, "main.mnemonicPhraseRecovery"),
            mainTextMultiline: 3,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecoveryMnemonicInput()),
            ),
          ),
          ListItem(
            mainText: getText(context, "main.backupLinkRecovery"),
            mainTextMultiline: 3,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecoveryLinkInput()),
            ),
          ),
        ],
      ),
    );
  }
}
