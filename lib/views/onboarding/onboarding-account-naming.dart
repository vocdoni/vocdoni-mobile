import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/text-input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/set-pin.dart';

class OnboardingAccountNamingPage extends StatefulWidget {
  @override
  _OnboardingAccountNamingPageState createState() =>
      _OnboardingAccountNamingPageState();
}

class _OnboardingAccountNamingPageState
    extends State<OnboardingAccountNamingPage> {
  bool confirmsTermsOfService;
  String accountName;

  @override
  void initState() {
    confirmsTermsOfService = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        appBar: TopNavigation(
          title: "",
          onBackButton: () => Navigator.pop(context, null),
        ),
        body: Builder(
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Spacer(),
              TextInput(
                hintText: getText(context, "main.whatWillYouCallThisAccount"),
                textCapitalization: TextCapitalization.words,
                onChanged: (name) {
                  setState(() {
                    accountName = name;
                  });
                },
              ).withHPadding(spaceCard),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24.0,
                    width: 24.0,
                    child: Checkbox(
                      value: confirmsTermsOfService,
                      onChanged: (newVal) => {
                        setState(() {
                          confirmsTermsOfService = newVal;
                        })
                      },
                    ),
                  ).withRightPadding(4),
                  Flexible(child: _getTermsOfServiceText()),
                ],
              ).withHPadding(spaceCard).withTopPadding(paddingPage),
              // CheckboxListTile(
              //   dense: true,
              //   controlAffinity: ListTileControlAffinity.leading,
              //   title: _getTermsOfServiceText(),
              //   value: confirmsTermsOfService,
              //   onChanged: (newVal) => {
              //     setState(() {
              //       confirmsTermsOfService = newVal;
              //     })
              //   },
              // ),
              Spacer(),
              Spacer(),
              Row(
                children: [
                  Spacer(),
                  NavButton(
                    isDisabled: !confirmsTermsOfService || accountName == null,
                    text: getText(context, "action.createAccount"),
                    style: NavButtonStyle.NEXT,
                    onTap: () {
                      accountName = accountName.trim();
                      if (!(accountName is String) || accountName == "")
                        return;
                      else if (accountName.length < 2) {
                        showMessage(getText(context, "main.theNameIsTooShort"),
                            context: context, purpose: Purpose.WARNING);
                        return;
                      } else if (RegExp(r"[<>/\\|%=^*`´]")
                          .hasMatch(accountName)) {
                        showMessage(
                            getText(
                                context, "main.theNameContainsInvalidSymbols"),
                            context: context,
                            purpose: Purpose.WARNING);
                        return;
                      }
                      final repeated = Globals.accountPool.value.any((item) {
                        if (!item.identity.hasValue) return false;
                        return item.identity.value.alias == accountName;
                      });
                      if (repeated) {
                        showMessage(
                            getText(context,
                                "main.youAlreadyHaveAnAccountWithThisName"),
                            context: context,
                            purpose: Purpose.WARNING);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetPinPage(
                            accountName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ).withPadding(spaceCard),
            ],
          ),
        ),
      ),
    );
  }

  _getTermsOfServiceText() {
    String rawText =
        getText(context, "main.iAgreeWithTheTermsOfServiceAndThePrivacyPolicy");
    rawText = rawText.replaceFirst(
        "{{TOS}}",
        "<a href=\"${AppConfig.termsOfServiceURL}\">" +
            getText(context, "main.theTermsOfService") +
            "</a>");
    rawText = rawText.replaceFirst(
        "{{PRIV}}",
        "<a href=\"${AppConfig.privacyPolicyURL}\">" +
            getText(context, "main.thePrivacyPolicy") +
            "</a>");
    return Html(
      padding: EdgeInsets.zero,
      data: rawText,
      useRichText: true,
      onLinkTap: (url) => _launchUrl(url),
    );
  }

  _launchUrl(String url) async {
    await launch(url);
  }
}
