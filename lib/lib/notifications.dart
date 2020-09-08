// import 'dart:io';
import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';

FirebaseMessaging _firebaseMessaging;

void initNotifications() {
  _firebaseMessaging = FirebaseMessaging();

  try {
    _firebaseMessaging.configure(
      onMessage: onMessage,
      // onBackgroundMessage: Platform.isIOS ? null : onBackgroundMessageHandler,
      onLaunch: onLaunch,
      onResume: onResume,
    );
  } catch (err) {
    log("[App] initNotifications failed: $err");
  }
}

// HANDLERS

Future<dynamic> onMessage(Map<String, dynamic> message) async {
  log("[App] onMessage: $message");
  // _showItemDialog(message);
}

Future<dynamic> onLaunch(Map<String, dynamic> message) async {
  log("[App] onLaunch: $message");
  // _navigateToItemDetail(message);
}

Future<dynamic> onResume(Map<String, dynamic> message) async {
  log("[App] onResume: $message");
  // _navigateToItemDetail(message);
}

// Future<dynamic> onBackgroundMessageHandler(Map<String, dynamic> message) async {
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

// GETTERS

Future<bool> requestNotificationPermissions() {
  return _firebaseMessaging.requestNotificationPermissions(
    const IosNotificationSettings(
        sound: true, badge: true, alert: true, provisional: false),
  );
}

Future<String> getPushToken() {
  return requestNotificationPermissions()
      .then((_) => _firebaseMessaging.getToken());
}
