import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:webview_flutter/webview_flutter.dart';

// FETCH RUNTIME DATA

String uriFromContent(String content) {
  return new Uri.dataFromString(content,
          mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
      .toString();
}

/// ACTUAL STATE

class WebAction extends StatefulWidget {
  final String url;

  WebAction({this.url});

  @override
  _WebActionState createState() => _WebActionState();
}

class _WebActionState extends State<WebAction> {
  WebViewController webViewCtrl;
  bool hasPublicReadPermission = false;

  @override
  Widget build(BuildContext context) {
    final Set<JavascriptChannel> javascriptChannels = Set.from([
      JavascriptChannel(name: 'HostApp', onMessageReceived: onMessageReceived)
    ]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainBackgroundColor,
        title: Text("Vocdoni"),
      ),
      body: WebView(
        navigationDelegate: (NavigationRequest req) {
          // Forget any premissions that the user may have granted before
          hasPublicReadPermission = false;
          return NavigationDecision.navigate;
        },
        initialUrl: widget.url,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          webViewCtrl = webViewController;
        },
        // TODO(iskakaushik): Remove this when collection literals makes it to stable.
        // ignore: prefer_collection_literals
        javascriptChannels: javascriptChannels,
      ),
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

    switch (payload["type"]) {
      case "getPublicKey":
        // ASK FOR PERMISSION
        // hasPublicReadPermission may be null
        if (hasPublicReadPermission != true) {
          hasPublicReadPermission = await showPrompt(
              title: Lang.of(context).get("Permission"),
              text: Lang.of(context).get(
                  "The current service is requesting access to your public information.\nDo you want to continue?"),
              context: context);
        }

        if (hasPublicReadPermission != true) // may be null as well
          return respondError(id, "Permission declined");

        // GET THE PUBLIC KEY
        final publicKey = identitiesBloc
            .current[appStateBloc.current.selectedIdentity].publicKey;

        return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$publicKey" }));
        ''');
        break;

      case "closeWindow":
        Navigator.pop(context);
        return null;

      default:
        return respondError(id,
            "Unsupported action type sent to the host: '${payload["type"]}'");
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
    super.dispose();
  }
}
