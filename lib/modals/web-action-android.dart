import 'dart:io';
import 'dart:convert';
// import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:vocdoni/util/singletons.dart';

class WebActionAndroid extends InAppBrowser {
  // NOTE:  By using the in-app version, the app can't request anything
  // unless requested the dialog is open
  bool hasPublicReadPermission = true;

  WebActionAndroid() {
    // super();

    this.webViewController.addJavaScriptHandler("HostAppAndroid",
        (arguments) async {
      String message = arguments[0];

      if (this.webViewController == null)
        return print("WebView not loaded");
      else if (!(message is String)) return print("Empty message");

      try {
        Map<String, dynamic> decodedMsg = jsonDecode(message);
        String responseCode = await digestIncomingMessage(decodedMsg);
        if (responseCode != null) {
          this.webViewController.injectScriptCode(responseCode);
        }
      } catch (err) {
        print("JSON decode error: $err");
        return;
      }
    });
  }

  @override
  Future onLoadStop(String url) async {
    await this.webViewController.injectScriptCode('''
        window.requestCounter = 0;
        window.requestQueue = [];

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
            // HostApp.postMessage(message);
            window.flutter_inappbrowser.callHandler('HostAppAndroid', message);
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
    ''');
  }

  Future<String> digestIncomingMessage(Map<String, dynamic> message) async {
    final id = message["id"];
    if (!(id is int)) return null;

    try {
      final payload = message["payload"];
      if (!(payload is Map)) return null;

      switch (payload["type"]) {
        case "getPublicKey":
          // // ASK FOR PERMISSION
          // if (hasPublicReadPermission != true) {
          //   hasPublicReadPermission = await showPrompt(
          //       title: Lang.of(context).get("Permission"),
          //       text: Lang.of(context).get(
          //           "The current service is requesting access to your public information.\nDo you want to continue?"),
          //       context: context);
          // }

          if (hasPublicReadPermission != true) // may be null as well
            return respondError(id, "Permission declined");

          if (identitiesBloc.current == null ||
              identitiesBloc.current.length == 0) {
            return respondError(id, "No identities available");
          }

          // GET THE PUBLIC KEY
          final publicKey = identitiesBloc
              .current[appStateBloc.current.selectedIdentity].publicKey;

          return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$publicKey" }));
        ''');

        case "getLanguage":
          String lang = Platform.localeName.substring(0, 2);
          return respond(id, '''
            handleHostResponse(JSON.stringify({id: $id, data: "$lang" }));
        ''');

        case "closeWindow":
          this.close();
          return null;

        default:
          return respondError(
              id, "Unsupported action type: '${payload["type"]}'");
      }
    } catch (err) {
      return respondError(id, err);
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
}
