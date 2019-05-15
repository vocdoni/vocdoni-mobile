import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/alerts.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String kRuntimeContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charSet="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  
  <script>
    // STATE VARIABLES
    // They should be on the global scope so that handleHostResponse
    // can match requests and responses

    window.requestCounter = 0;
    window.requestQueue = [];

    // SENDING REQUESTS

    /**
     * Call this function anywhere in your code to request certain actions to the host
     * 
     * Returns a promise that resolves when the hosts replies
     */
    window.sendHostRequest = function(payload) {
      return new Promise((resolve, reject) => {
        const id = window.requestCounter++;
        const newRequest = {
          id,
          resolve,
          reject,
          timeout: setTimeout(() => window.expireRequest(id), 30000)
        };
        window.requestQueue.push(newRequest);

        const message = JSON.stringify({ id, payload });
        HostApp.postMessage(message);
      });
    }

    // Handling timeout
    window.expireRequest = function(id) {
      const idx = window.requestQueue.findIndex(r => r.id === id);
      if (idx < 0) return;
      window.requestQueue[idx].reject(new Error('Timeout'));

      delete window.requestQueue[idx].resolve;
      delete window.requestQueue[idx].reject;
      delete window.requestQueue[idx].timeout;
      window.requestQueue.splice(idx, 1);
    }

    // INCOMING RESPONSE HANDLER

    window.handleHostResponse = function(message) {
      try {
        const msgPayload = JSON.parse(message);
        const { id, data, error } = msgPayload;

        const idx = window.requestQueue.findIndex(r => r.id === id);
        if (idx < 0) return;
        else if (error) {
          if (typeof window.requestQueue[idx].reject === 'function') {
            window.requestQueue[idx].reject(new Error(error));
          }
          else {
            console.error("Could not report a response error:", error);
          }
        }
        else if (typeof window.requestQueue[idx].resolve === 'function') {
          window.requestQueue[idx].resolve(data);
        }
        else {
          console.error("Could not report a response:", data);
        }

        // clean
        clearTimeout(window.requestQueue[idx].timeout);
        delete window.requestQueue[idx].resolve;
        delete window.requestQueue[idx].reject;
        window.requestQueue.splice(idx, 1);
      }
      catch (err) {
        console.error (err);
      }
    }
    
    // CUSTOM

    setTimeout(() => {
      sendHostRequest({ type: "getPublicKey" })
        .then(res => showResponse("Public Key: " + res))
        .catch(showError);
    }, 5000)

    setTimeout(() => {
      sendHostRequest({ type: "getPublicKey" })
        .then(res => showResponse("Public Key: " + res))
        .catch(showError);
    }, 10000)


    setTimeout(() => {
      sendHostRequest({ type: "does-not-exist" })
        .then(res => showResponse(res))
        .catch(showError);
    }, 12000)

    setTimeout(() => {
      sendHostRequest({ type: "closeWindow" })
        .then(res => showResponse(res))
        .catch(showError);
    }, 15000)

    // UTIL

    function showResponse(res) {
      const node = document.querySelector("body").appendChild(document.createElement("p"));
      node.innerText = res;
    }

    function showError(err) {
      const node = document.querySelector("body").appendChild(document.createElement("p"));
      node.innerText = "Error: " + err.message;
    }
  </script>
</head>
<body>
  <h1>WEB ACTION TEST</h1>
</body>
</html>
''';

// FETCH RUNTIME DATA

String uriFromContent(String content) {
  return new Uri.dataFromString(content,
          mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
      .toString();
}

/// ACTUAL STATE

class WebAction extends StatefulWidget {
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
          hasPublicReadPermission = false;
          return NavigationDecision.navigate;
        },
        initialUrl: uriFromContent(kRuntimeContent),
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
    webViewCtrl.loadUrl(uriFromContent("<html></html>"));
    super.dispose();
    webViewCtrl = null;
  }
}
