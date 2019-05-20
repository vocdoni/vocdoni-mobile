import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:native_widgets/native_widgets.dart';
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
  bool canGoBack = false;
  bool canGoForward = false;
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    final String htmlBody = ModalRoute.of(context).settings.arguments;
    if (htmlBody == null) return buildEmptyContent(context);

    final String html = wrapHtmlBody(htmlBody);
    final uri = uriFromContent(html);

    return Scaffold(
      appBar: AppBar(
        title: Text("Vocdoni"),
      ),
      body: WebView(
        initialUrl: uri,
        javascriptMode: JavascriptMode.disabled,
        onWebViewCreated: (WebViewController webViewController) {
          setState(() {
            webViewCtrl = webViewController;
          });
        },
        navigationDelegate: (NavigationRequest request) {
          setState(() {
            loading = true;
          });
          return NavigationDecision.navigate;
        },
        onPageFinished: (String url) async {
          bool back = await webViewCtrl.canGoBack();
          bool fwd = await webViewCtrl.canGoForward();
          setState(() {
            canGoBack = back;
            canGoForward = fwd;
            loading = false;
          });
        },
      ),
      bottomNavigationBar: BottomAppBar(
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
                              child: NativeLoadingIndicator(),
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

/// Returns a full HTML page containing the given body
/// It tries to normalize the appearence of any unstyled element
String wrapHtmlBody(String content) {
  return '''<!DOCTYPE html>
<html>
		<head>
				<meta charset="utf-8">
				<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0'/>

				<style>
            body {
							background-color: #f7f7f7;
            }
						.container {
							font-family: 'Helvetica Neue', Helvetica, Sans-serif, Arial;
							margin: 0;
							padding: 7px;

							user-select: none;
              -webkit-user-select: none;
						}
						.box {
							background-color: white;
							padding: 10px 20px;
							border-radius: 2px;

							-webkit-box-shadow: 0px 2px 5px 1px rgba(210,210,210,1);
							-moz-box-shadow: 0px 2px 5px 1px rgba(210,210,210,1);
							box-shadow: 0px 2px 5px 1px rgba(210,210,210,1);
						}
						img {
								margin: 15px 0 8px;
								/*display: none;*/
								max-width: 100% !important;
						}
				</style>
		</head>
		<body>
				<div class="container">
					<div class="box">
						$content
					</div>
				</div>
		</body>
</html>''';
}
