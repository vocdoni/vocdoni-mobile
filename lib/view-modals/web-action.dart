import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dvote/dvote.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:vocdoni/widgets/loading-spinner.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vocdoni/lib/net.dart';

/// ACTUAL STATE

class WebAction extends StatefulWidget {
  final String url;
  final String title;

  WebAction({this.url, this.title});

  @override
  _WebActionState createState() => _WebActionState();
}

class _WebActionState extends State<WebAction> {
  bool hasPublicReadPermission = false;

  WebViewController webViewCtrl;
  bool canGoBack = false;
  bool canGoForward = false;
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    final Set<JavascriptChannel> javascriptChannels = Set.from([
      JavascriptChannel(name: 'HostApp', onMessageReceived: onMessageReceived)
    ]);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "Vocdoni"),
      ),
      body: Builder(
          builder: (context) => WebView(
                navigationDelegate: (NavigationRequest request) {
                  // Forget any premissions that the user may have granted before
                  hasPublicReadPermission = false;
                  setState(() {
                    loading = true;
                  });
                  return NavigationDecision.navigate;
                },
                initialUrl: widget.url,
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (WebViewController webViewController) {
                  setState(() {
                    webViewCtrl = webViewController;
                  });
                },
                onPageFinished: (String url) async {
                  if (webViewCtrl == null) return;

                  bool back = await webViewCtrl.canGoBack();
                  bool fwd = await webViewCtrl.canGoForward();
                  setState(() {
                    canGoBack = back;
                    canGoForward = fwd;
                    loading = false;
                  });

                  // DID IT LOAD?
                  final currentUrl = await webViewCtrl
                      .evaluateJavascript("window.location.href");
                  if (currentUrl == "\"about:blank\"") {
                    Navigator.of(context).pop();

                    await showAlert(
                        Lang.of(context).get("The page cannot be loaded"),
                        title: Lang.of(context).get("Error"),
                        context: context);
                  }
                },
                // TODO(iskakaushik): Remove this when collection literals makes it to stable.
                // ignore: prefer_collection_literals
                javascriptChannels: javascriptChannels,
              )),
      bottomNavigationBar: buildBottomBar(context),
    );
  }

  Widget buildBottomBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
          height: 50.0,
          child: webViewCtrl == null
              ? Container()
              : Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      color: canGoBack ? Colors.black54 : Colors.black26,
                      onPressed: () async {
                        if (!canGoBack) return;
                        webViewCtrl.goBack();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: canGoForward ? Colors.black54 : Colors.black26,
                      onPressed: () async {
                        if (!canGoForward) return;
                        webViewCtrl.goForward();
                      },
                    ),
                    Spacer(),
                    loading
                        ? Padding(
                            child: LoadingSpinner(),
                            padding: EdgeInsets.only(right: 12),
                          )
                        : IconButton(
                            icon: const Icon(Icons.replay),
                            color: Colors.black54,
                            onPressed: () {
                              webViewCtrl.reload();
                            },
                          ),
                  ],
                )),
    );
  }

  onMessageReceived(JavascriptMessage message) async {
    if (webViewCtrl == null)
      return print("WebView not loaded");
    else if (!(message.message is String)) return print("Empty message");

    try {
      Map<String, dynamic> decodedMsg = jsonDecode(message.message);
      String responseCode = await digestIncomingMessage(decodedMsg);
      if (responseCode != null) {
        webViewCtrl.evaluateJavascript(responseCode);
      }
    } catch (err) {
      print("JSON decode error: $err");
      return;
    }
  }

  Future<String> digestIncomingMessage(Map<String, dynamic> message) async {
    final id = message["id"];
    if (!(id is int)) return null;

    final payload = message["payload"];
    if (!(payload is Map)) return null;

    switch (payload["method"]) {
      case "getPublicKey":
        // ASK FOR PERMISSION
        // hasPublicReadPermission may be null
        if (hasPublicReadPermission != true) {
          hasPublicReadPermission = await showPrompt(
              Lang.of(context).get(
                  "The current service is requesting access to your public information.\nDo you want to continue?"),
              title: Lang.of(context).get("Permission"),
              context: context);
        }

        // TODO: ADAPT THE CODE FOR USE WITH I3

        if (hasPublicReadPermission != true) // may be null as well
          return respondError(id, "Permission declined");

        final selectedAccount = globalAppState.currentAccount;
        if (!(selectedAccount is AccountModel))
          return respondError(id, "The current account cannot be accessed");
        else if (!selectedAccount.identity.hasValue ||
            selectedAccount.identity.value.keys.length < 1)
          return respondError(
              id, "The current identity doesn't have a public key");

        final identity = selectedAccount.identity.value;
        final publicKey = identity.keys[0].publicKey;

        return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$publicKey" }));
        ''');

      case "signPayload":
        final selectedAccount = globalAppState.currentAccount;
        if (!(selectedAccount is AccountModel))
          return respondError(id, "The current account cannot be accessed");
        else if (!selectedAccount.identity.hasValue ||
            selectedAccount.identity.value.keys.length < 1)
          return respondError(
              id, "The current identity doesn't have a key to sign");

        final identity = selectedAccount.identity.value;
        final encryptedPrivateKey = identity.keys[0].encryptedPrivateKey;

        var patternStr = await Navigator.push(
            context,
            MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => PatternPromptModal(selectedAccount)));
        if (patternStr == null || patternStr is InvalidPatternError) {
          return respondError(id, "The pattern you entered is not valid");
        }

        String privateKey =
            await decryptString(encryptedPrivateKey, patternStr);
        final signature = await signString(payload["payload"], privateKey);
        privateKey = "";

        return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$signature" }));
        ''');

      case "getLanguage":
        String lang = Localizations.localeOf(context).languageCode;
        return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$lang" }));
        ''');

      case "closeWindow":
        Navigator.pop(context);
        return null;

      default:
        return respondError(
            id, "Unsupported action type: '${payload["method"]}'");
    }
  }

  String respond(int id, String responseCode) {
    return '''
      try {
        $responseCode
      }
      catch(err) {
        console.error(err);
      }
    ''';
  }

  String respondError(int id, String message) {
    return '''
      try {
        handleHostResponse(JSON.stringify({id: $id, error: "$message" }));
      }
      catch(err) {
        console.error(err);
      }
    ''';
  }

  @override
  Future dispose() async {
    super.dispose();

    // unload the web
    try {
      if (Platform.isIOS) {
        await webViewCtrl.loadUrl(uriFromContent("<html></html>"));
      }
    } catch (err) {
      try {
        await webViewCtrl
            .evaluateJavascript('window.location.href = "about:blank"');
      } catch (err) {}
    }

    webViewCtrl = null;
  }
}
