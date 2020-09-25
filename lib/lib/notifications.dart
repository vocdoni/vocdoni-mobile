import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/globals.dart';

/// Example to simulate notifications locally
///
/// onResume({
///   "notification": {},
///   "data": {
///     // "uri": "https://vocdoni.link/entities/0xed3d915bc2181286635a802e5e0e133cc3baed2234ca7a68a5649f95a38aed96",
///     // "event": "entity-updated",
///     // "uri": "https://vocdoni.link/posts/view/0xe030cbdcf1c6d67ca78b5eb3e066a3d594486330c66ae29250d2e9fc577c51b2/1598862833292",
///     // "event": "new-post",
///     "uri": "https://vocdoni.link/processes/0xed3d915bc2181286635a802e5e0e133cc3baed2234ca7a68a5649f95a38aed96/0xef0642cbcd83a3cb27bc05c0576251b65a0416a40b6ad7e22ce48c822761806a",
///     "event": "new-process",
///     "message": "This is a replica of the message",
///   }
/// });
///
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

    if (!message.containsKey('data')) {
      log("[App] onResume: Received a message with no data");
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

    // TODO: In future versions, handle immediately, without waiting for the user to unlock an account

    if (!message.containsKey('data')) {
      log("[App] onResume: Received a message with no data");
      return;
    }

    setUnhandled(message);
  }

  static Future<dynamic> onResume(Map<String, dynamic> message) async {
    log("[App] onResume: $message");

    if (!message.containsKey('data')) {
      log("[App] onResume: Received a message with no data");
      return;
    }

    // TODO: In future versions, handle immediately, without waiting for the user to unlock an account
    if (Globals.appState.currentAccount != null) {
      _showTargetView(message);
    } else {
      setUnhandled(message);
    }
  }

  // static Future<dynamic> onBackgroundMessageHandler(Map<String, dynamic> message) async {
  //   log("[App] onBackgroundMessageHandler: $message");

  //   if (message.containsKey('data')) {
  //     // Handle data message
  //     final dynamic data = message['data'];
  //     log("[App] [onBackgroundMessageHandler] Data: $data");
  //   }

  //   if (message.containsKey('notification')) {
  //     // Handle notification message
  //     final dynamic notification = message['notification'];
  //     log("[App] [onBackgroundMessageHandler] Notification: $notification");
  //   }
  // }

  /// If there is a pending notification, it navigates to the
  static void handlePendingNotification() {
    if (_unhandledMessage == null) return;

    _showTargetView(_unhandledMessage);
    _unhandledMessage = null;
  }

  /// Displays the appropriate view to visualize the relevant data
  static void _showTargetView(Map<String, dynamic> message) {
    final messageData = message['data'];
    if (messageData["uri"] is! String) {
      log("[App] Notification body Error: uri is not a String");
      return;
    } else if (messageData["event"] is! String) {
      log("[App] Notification body Error: event is not a String");
      return;
    } else if (messageData["message"] is! String) {
      log("[App] Notification body Error: message is not a String");
      return;
    }

    final linkSegments = extractLinkSegments(Uri.parse(messageData['uri']));

    switch (messageData["event"]) {
      case "entity-updated":
        handleEntityLink(linkSegments,
            context: Globals.navigatorKey.currentContext);
        break;
      case "new-post":
        handleNewsLink(linkSegments,
            context: Globals.navigatorKey.currentContext);
        break;
      case "new-process":
      case "process-ended":
        handleProcessLink(linkSegments,
            context: Globals.navigatorKey.currentContext);
        break;
      // case "process-results":
      //   break;
      default:
        log("[App] Notification body Error: unsupported event: " +
            messageData["event"]);
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

  static Future<void> subscribe(String topic) {
    if (_firebaseMessaging == null) init();

    return _firebaseMessaging.subscribeToTopic(topic);
  }

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
