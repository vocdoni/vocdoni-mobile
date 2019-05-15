import 'dart:convert';
import 'package:flutter/services.dart';
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
    setInterval(() => {
      HostApp.postMessage("I AM A MESSAGE: " + Date.now());
    }, 3000);

    function handleResponse(type, data){
      console.log(type, data);
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

Future<String> getRuntimeUri() async {
  String fileText = await rootBundle.loadString('assets/runtime.html');
  return Uri.dataFromString(fileText,
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
  final Set<JavascriptChannel> javascriptChannels = Set.from([
    JavascriptChannel(
        name: 'HostApp',
        onMessageReceived: (JavascriptMessage message) {
          print("GOT JS MESSAGE:\n> ${message.message}");
        })
  ]);

  @override
  Widget build(BuildContext context) {
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
}
