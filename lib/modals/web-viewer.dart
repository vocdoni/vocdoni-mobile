import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// FETCH RUNTIME DATA

String uriFromContent(String content) {
  return new Uri.dataFromString(content,
          mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
      .toString();
}

class WebViewer extends StatefulWidget {
  @override
  _WebViewerState createState() => _WebViewerState();
}

class _WebViewerState extends State<WebViewer> {
  WebViewController webViewCtrl;

  @override
  Widget build(BuildContext context) {
    final String html = ModalRoute.of(context).settings.arguments;
    if (html == null) return buildEmptyContent(context);

    final uri = uriFromContent(html);

    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
      ),
      body: WebView(
        initialUrl: uri,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          webViewCtrl = webViewController;
        },
      ),
    );
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

  Widget buildEmptyContent(BuildContext ctx) {
    return Center(
      child: Text("(No content)"),
    );
  }
}
