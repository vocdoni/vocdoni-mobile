// import 'dart:io';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class Notifications {
  static FirebaseMessaging _firebaseMessaging;

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
    // _showItemDialog(message);
  }

  static Future<dynamic> onLaunch(Map<String, dynamic> message) async {
    log("[App] onLaunch: $message");
    // _navigateToItemDetail(message);
  }

  static Future<dynamic> onResume(Map<String, dynamic> message) async {
    log("[App] onResume: $message");
    // _navigateToItemDetail(message);
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

  static void subscribe(String topic) {
    if (_firebaseMessaging == null) init();

    _firebaseMessaging.subscribeToTopic(topic);
  }

  static void unsubscribe(String topic) {
    if (_firebaseMessaging == null) init();

    _firebaseMessaging.unsubscribeFromTopic(topic);
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
}
