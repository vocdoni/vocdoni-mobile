import 'dart:async';
import 'package:mixpanel_analytics/mixpanel_analytics.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/singletons.dart';

class Analytics {
  final _user$ = StreamController<String>.broadcast();
  MixpanelAnalytics _mixpanel;
  MixpanelAnalytics _mixpanelBatch;
  String _mixpanelToken = "3e46daca80e0263f0fc5a5e5e9bc76ea";

  void init() {
    _mixpanel = MixpanelAnalytics(
      token: _mixpanelToken,
      userId$: _user$.stream,
      verbose: true,
      shouldAnonymize: true,
      shaFn: (value) => value,
      onError: (e) => () {},
    );

    _mixpanelBatch = MixpanelAnalytics.batch(
        token: _mixpanelToken,
        userId$: _user$.stream,
        uploadInterval: Duration(seconds: 30),
        shouldAnonymize: true,
        shaFn: (value) => value,
        verbose: true,
        onError: (e) => () {});
  }

  void setUser() {
    _user$.add(getUserId());
  }

  getUserId() {
    final currentAccount = globalAppState.currentAccount;
    if (!(currentAccount is AccountModel))
      return null;
    else if (!currentAccount.identity.hasValue)
      return null;
    else if (currentAccount.identity.value.keys.length == 0) return null;

    return currentAccount.identity.value.keys[0].rootAddress;
  }

  // OS, OS version, screen size...
  getSystem() {}

  // lang, preferences...
  getProfile() {}

  // version, enviroment...
  getAppDetails() {}

  trackError(Error error) {}

  trackPage(String pageId,
      {String entityId, String processId, String postTitle}) {
    Map<String, String> properties = {"pageId": pageId};
    if (entityId is String) properties['entityId'] = entityId;
    if (processId is String) properties['processId'] = processId;
    if (postTitle is String) properties['postTitle'] = postTitle;

    _mixpanel.track(event: pageId, properties: properties);
  }

  trackAction({String actionId}) {}

  trackEvent({String eventId}) {}
}
