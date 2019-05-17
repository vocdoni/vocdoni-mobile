import 'dart:async';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

// MAIN CLASS

class WebRuntime extends InAppBrowser {
  Completer _init;
  List<RequestItem> requests = new List<RequestItem>();
  int requestCounter = 0;

  Future init() async {
    if (_init == null) {
      _init = new Completer();
    } else if (_init.isCompleted) {
      return;
    }

    await this.openFile("assets/runtime.html",
        options: {"useShouldOverrideUrlLoading": true, "hidden": true});
    await _init.future;

    // listen for post messages coming from the JavaScript side
    this.webViewController.addJavaScriptHandler("JS_REQUEST_RESPONSE_CHANNEL",
        (arguments) => onMessageReceived(arguments));
  }

  @override
  onLoadStop(String url) {
    // The HTML asset has completed loading
    _init.complete();
  }

  @override
  void onLoadError(String url, int code, String message) {
    // The asset could not load
    _init.completeError("Unable to initialize the Web Runtime");
  }

  @override
  void shouldOverrideUrlLoading(String url) {
    // IGNORE ALL NAVIGATION REQUESTS
    print("Refusing to navigate to $url");
  }

  // TRIGGERING CALLS

  Future<dynamic> call(String jsExpression, {int timeout = 30}) async {
    await this.init();

    requestCounter++;
    final id = requestCounter;
    final requestCompleter = new Completer();
    final timeoutTimer = Timer(Duration(seconds: timeout), () {
      if (requestCompleter.isCompleted)
        return;
      else
        requestCompleter.completeError("The request timed out");
    });

    requests.add(new RequestItem(
        id: id, completer: requestCompleter, timeout: timeoutTimer));

    final code = '''
      call(() => { return $jsExpression })
        .then(result => {
          return replyMessage($id, result)
        })
        .catch(error => {
          return replyError($id, error)
        })
    ''';
    await this.webViewController.injectScriptCode(code);

    return requestCompleter.future;
  }

  // GOT A MESSAGE FROM THE BROWSER

  onMessageReceived(List<dynamic> arguments) async {
    // Expected:
    //  arguments[0] = { id: <int>, error: <bool> }
    //  arguments[1] = <data>

    if (!(arguments is List)) {
      return print(
          "ERROR: Got a response from the WebRuntime that is not an argument list");
    }

    final Map meta = arguments[0];
    final dynamic data = arguments[1];

    if (!(meta is Map)) {
      return print(
          "ERROR: Got a response from the WebRuntime that is not an object");
    } else if (!(meta["id"] is int)) {
      return print("ERROR: Got an invalid request ID from the WebRuntime");
    }

    final item = requests.firstWhere((req) => req.id == meta["id"]);
    if (item == null) {
      return print("ERROR: Got a non-existing request ID from the Web Runtime");
    } else if (meta["error"] == true ||
        (!(meta["error"] is bool) && meta["error"] != null)) {
      item.completer.completeError(data);
    } else {
      item.completer.complete(data);
    }
    item.timeout.cancel();

    await Future.delayed(Duration(milliseconds: 100));
    requests.removeWhere((req) => req.id == item.id);
  }
}

class RequestItem {
  int id;
  Completer completer;
  Timer timeout;

  RequestItem({this.id, this.completer, this.timeout});
}
