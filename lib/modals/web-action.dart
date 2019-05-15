import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vocdoni/constants/colors.dart';
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
        .then(res => console.log("RESULT", res))
        .catch(err => console.error("ERROR", err));
    }, 5000)


    setTimeout(() => {
      sendHostRequest({ type: "does-not-exist" })
        .then(res => console.log("RESULT", res))
        .catch(err => console.error("ERROR", err));
    }, 10000)

    setTimeout(() => {
      sendHostRequest({ type: "closeWindow" })
        .then(res => console.log("RESULT", res))
        .catch(err => console.error("ERROR", err));
    }, 15000)
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
    print("GOT JS MESSAGE:\n> ${message.message}");

    if (webViewCtrl == null)
      return print("WebView not loaded");
    else if (!(message.message is String)) return print("Empty message");

    String responseCode = "";
    Map<String, dynamic> decodedMsg;

    try {
      decodedMsg = jsonDecode(message.message);
      responseCode = await handleIncomingMessage(decodedMsg);
      if (responseCode != null) {
        webViewCtrl.evaluateJavascript(responseCode);
      }
    } catch (err) {
      print("JSON decode error: $err");
      return;
    }
  }

  Future<String> handleIncomingMessage(Map<String, dynamic> message) async {
    final id = message["id"];
    if (!(id is int)) return null;

    final payload = message["payload"];
    if (!(payload is Map)) return null;

    String responseCode = "";
    switch (payload["type"]) {
      case "getPublicKey":
        // TODO: INJECT THE PUBLIC KEY
        responseCode =
            "handleHostResponse(JSON.stringify({id: $id, data: 'SOME PUBLIC KEY' }));";
        break;
      case "closeWindow":
        Navigator.pop(context);
        break;
      default:
        responseCode =
            "handleHostResponse(JSON.stringify({id: $id, error: 'Unsupported action type sent to the host: ${payload["type"]}' }));";
    }

    return '''
      try {
        $responseCode
      }
      catch(err) {
        console.error(err);
      }
    ''';
  }

  @override
  Future dispose() async {
    webViewCtrl.loadUrl(uriFromContent("<html></html>"));
    super.dispose();
    webViewCtrl = null;
  }
}
