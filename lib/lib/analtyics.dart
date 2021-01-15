import 'dart:async';
import 'dart:developer';
import 'package:mixpanel_analytics/mixpanel_analytics.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/globals.dart';

import 'logger.dart';

class Events {
  static const PAGE_VIEW = "pageView";
  static const APP_START = "appStart";
  static const APP_END = "appEnd";
  static const TAP = "tap";
  static const BACK_TAP = "backTap";
  static const APP_IN = "appIn";
  static const APP_OUT = "appOut";
  static const SCROLL_END_REACH = "scrollEndReach";
  static const WARNING_DISPLAY = "warningDisplay";
  static const PULL_TO_REFRESH = "pullToRefresh";
  static const FETCH = "fetch";
}

class Analytics {
  final _user$ = StreamController<String>.broadcast();
  MixpanelAnalytics _mixpanel;
  MixpanelAnalytics _mixpanelBatch;
  String _mixpanelToken = "3e46daca80e0263f0fc5a5e5e9bc76ea";

  void init() async {
    // If there's no default analytics key, generate one. The first identity created should have this key.
    if (Globals.appState.analyticsKey == "")
      Globals.appState.analyticsKey = generateAnalyticsKey();
    _mixpanel = MixpanelAnalytics(
      token: _mixpanelToken,
      userId$: _user$.stream,
      verbose: true,
      shouldAnonymize: true,
      shaFn: (value) => value,
      useIp: false,
      onError: (e) => logger.log(e.toString()),
    );

    _mixpanelBatch = MixpanelAnalytics.batch(
      token: _mixpanelToken,
      userId$: _user$.stream,
      uploadInterval: Duration(seconds: 30),
      shouldAnonymize: true,
      shaFn: (value) => value,
      ip: false,
      verbose: true,
      onError: (e) => logger.log(e.toString()),
    );

// Set pre-login profile
    _user$.add(getUserId());
    await _mixpanel.engage(
      operation: MixpanelUpdateOperations.$set,
      value: {
        "AppVersion": getAppVersion(),
        "OsVersion": getOsVersion(),
        "Environment": getEnvironment(),
        "SelectedLanguage": getSelectedLanguage(),
        "DeviceLanguage": getDeviceLanguage(),
        "Resolution": getResolution()
      },
      ip: getTruncatedIp(),
      time: getDateTime(),
    );
    logger.log("[Analytics] added user ${getUserId()}: " +
        {
          "AppVersion": getAppVersion(),
          "OsVersion": getOsVersion(),
          "Environment": getEnvironment(),
          "SelectedLanguage": getSelectedLanguage(),
          "DeviceLanguage": getDeviceLanguage(),
          "Resolution": getResolution()
        }.toString());
  }

  void setUser() {
    Globals.appState.analyticsKey = getUserId();
    Globals.appState.writeToStorage();
    _user$.add(getUserId());
    _mixpanel.engage(
      operation: MixpanelUpdateOperations.$set,
      value: {
        "AppVersion": getAppVersion(),
        "OsVersion": getOsVersion(),
        "Environment": getEnvironment(),
        "Subscriptions": getSubscriptions(),
        "BackupDone": getBackupDone(),
        "SelectedLanguage": getSelectedLanguage(),
        "AccountIndex": getAccountIndex(),
        "DeviceLanguage": getDeviceLanguage(),
        "Resolution": getResolution()
      },
      ip: getTruncatedIp(),
      time: getDateTime(),
    );
    logger.log("[Analytics] added user ${getUserId()}: " +
        {
          "AppVersion": getAppVersion(),
          "OsVersion": getOsVersion(),
          "Environment": getEnvironment(),
          "Subscriptions": getSubscriptions(),
          "BackupDone": getBackupDone(),
          "SelectedLanguage": getSelectedLanguage(),
          "AccountIndex": getAccountIndex(),
          "DeviceLanguage": getDeviceLanguage(),
          "Resolution": getResolution()
        }.toString());
  }

  trackError(String error) {}

  trackPage(String pageId,
      {String entityId, String processId, String postTitle}) {
    Map<String, String> properties = {'pageId': pageId};
    if (entityId is String) properties['entityId'] = entityId;
    if (postTitle is String) properties['blocId'] = postTitle;
    if (processId is String) properties['blocId'] = processId;
    _mixpanelBatch.track(event: Events.PAGE_VIEW, properties: properties);
  }

  trackAction({String actionId}) {}

  trackEvent(String eventId) {
    _mixpanelBatch.track(event: eventId, properties: {});
  }

  getUserId() {
    final currentAccount = Globals.appState.currentAccount;
    if (!(currentAccount is AccountModel))
      return ((Globals.appState?.analyticsKey?.length ?? 0) > 0)
          ? Globals.appState.analyticsKey
          : null;
    // If current account is not set, use default analytics key in app state
    else if (!currentAccount.identity.hasValue)
      return ((Globals.appState?.analyticsKey?.length ?? 0) > 0)
          ? Globals.appState.analyticsKey
          : null;
    else if (currentAccount.identity.value.analyticsID == null ||
        currentAccount.identity.value.analyticsID == "")
      return ((Globals.appState?.analyticsKey?.length ?? 0) > 0)
          ? Globals.appState.analyticsKey
          : null;

    return currentAccount.identity.value.analyticsID;
  }

  String getAppVersion() {
    try {
      return (AppConfig?.packageInfo?.version ?? "") +
              "+" +
              AppConfig?.packageInfo?.buildNumber ??
          "";
    } catch (err) {
      log(err.toString());
      return "";
    }
  }

  String getOsVersion() {
    return AppConfig.osVersion();
  }

  String getEnvironment() {
    return AppConfig.APP_MODE;
  }

  List<String> getSubscriptions() {
    if (!(Globals.appState?.currentAccount?.entities?.hasValue ?? false))
      return [];
    return Globals.appState.currentAccount.entities.value
        .map((entity) => entity.reference.entityId)
        .toList();
  }

  bool getBackupDone() {
    // if (!(Globals.appState?.currentAccount?.backedUp?.hasValue ?? false))
    //   return "";
    return false;
    //TODO implement
  }

  String getSelectedLanguage() {
    if (!(Globals.appState?.locale?.hasValue ?? false)) return "";
    return Globals.appState.locale.value.languageCode;
  }

  int getAccountIndex() {
    if (!(Globals.appState?.selectedAccount?.hasValue ?? false)) return null;
    return Globals.appState.selectedAccount.value;
  }

  String getDeviceLanguage() {
    return "";
    //TODO implement
  }

  String getResolution() {
    return "";
    // TODO implement
  }

  String getTruncatedIp() {
    // TODO implement
    return "";
  }

  DateTime getDateTime() {
    return DateTime.now();
  }
}
