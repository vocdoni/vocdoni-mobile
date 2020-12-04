import 'dart:developer';
import 'dart:io';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/view-modals/action-account-select.dart';

import 'i18n.dart';

class Notifications {
  static FirebaseMessaging _firebaseMessaging;

  static const supportedNotificationEvents = [
    "post-new",
    "process-new",
    "process-results"
  ];

  static Map<String, dynamic> _unhandledMessage;
  static get unhandledMessage => _unhandledMessage;
  static get hasUnhandledMessage => _unhandledMessage != null;

  static void init() {
    _firebaseMessaging = FirebaseMessaging();

    try {
      _firebaseMessaging.configure(
        onMessage: onMessage,
        // onBackgroundMessage: Platform.isIOS ? null : onBackgroundMessageHandler,
        onLaunch: onLaunch,
        onResume: onResume,
      );
    } catch (err) {
      log("[App] Notifications.init failed: $err");
    }
  }

  // HANDLERS

  static Future<dynamic> onMessage(Map<String, dynamic> message) async {
    log("[App] onMessage: $message");

    if (!message.containsKey('uri')) {
      log("[App] onMessage: Received a message with no link");
      return;
    }

    if (Globals.appState.currentAccount != null) {
      // TODO: Show top banner
    } else {
      setUnhandled(message);
    }
  }

  static Future<dynamic> onLaunch(Map<String, dynamic> message) async {
    log("[App] onLaunch: $message");

    if (!message.containsKey('uri')) {
      log("[App] onLaunch: Received a message with no link");
      return;
    }

    setUnhandled(message);
  }

  static Future<dynamic> onResume(Map<String, dynamic> message) async {
    log("[App] onResume: $message");

    if (!message.containsKey('uri')) {
      log("[App] onResume: Received a message with no link");
      return;
    }

    if (Globals.appState.currentAccount != null) {
      _showTargetView(message);
    } else {
      setUnhandled(message);
    }
  }

  /// If there is a pending notification, it navigates to the
  static void handlePendingNotification() {
    if (_unhandledMessage == null) return;

    _showTargetView(_unhandledMessage);
    _unhandledMessage = null;
  }

  /// Displays the appropriate view to visualize the relevant data
  static void _showTargetView(Map<String, dynamic> message) {
    final context = Globals.navigatorKey.currentContext;
    // final messageData = message['data'];
    if (message["uri"] is! String) {
      log("[App] Notification body Error: uri is not a String");
      return;
    }
    try {
      final uri = Uri.parse(message["uri"]);
      if (uri == null || !Globals.accountPool.hasValue) return;
      if (Globals.accountPool.value.length == 1) {
        handleIncomingLink(uri, context, isInScaffold: false).catchError((err) {
          showAlert(getText(context, "error.thereWasAProblemHandlingTheLink"),
              title: getText(context, "main.error"), context: context);
        });
      } else {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => LinkAccountSelect()))
            .then((result) {
          if (result != null && result is int) {
            Globals.appState.selectAccount(result);
            handleIncomingLink(uri, context, isInScaffold: false)
                .catchError((err) {
              showAlert(
                  getText(context, "error.thereWasAProblemHandlingTheLink"),
                  title: getText(context, "main.error"),
                  context: context);
            });
          }
        });
      }
    } catch (err) {
      log("ERR: $err");
    }
  }

  // UNHANDLED MESSAGES

  static void setUnhandled(Map<String, dynamic> newMessage) {
    _unhandledMessage = newMessage;
  }

  static void cleanUnhandled() {
    _unhandledMessage = null;
  }

  // TOPICS

  /// Instructs the notifications service to notify about the given topic
  static Future<void> subscribe(String topic) {
    if (_firebaseMessaging == null) init();

    return _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Instructs the notifications service to stop notifying about the given topic
  static Future<void> unsubscribe(String topic) {
    if (_firebaseMessaging == null) init();

    return _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // GETTERS

  static Future<bool> requestNotificationPermissions() async {
    if (_firebaseMessaging == null) init();

    if (Platform.isIOS) {
      return _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: false),
      );
    }
    return true;
  }

  static Future<String> getPushToken() {
    if (_firebaseMessaging == null) init();

    return requestNotificationPermissions()
        .then((_) => _firebaseMessaging.getToken());
  }

  /// Returns the topic string to which the app should subscribe
  static getTopicForEntity(String entityId, String elementName) {
    if (!supportedNotificationEvents.contains(elementName))
      throw Exception("Invalid element name");

    return "${entityId}_default_$elementName";
  }

  /// Returns a canonical string to use as a key for annotating subscriptions
  /// on the `meta` field of an entity model > metadata
  static getMetaKeyForAccount(String address, String elementName) {
    if (!supportedNotificationEvents.contains(elementName))
      throw Exception("Invalid element name");

    return "push/$address/default/$elementName";
  }
}
