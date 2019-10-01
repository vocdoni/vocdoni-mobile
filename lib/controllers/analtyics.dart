import 'dart:async';

import 'package:mixpanel_analytics/mixpanel_analytics.dart';
import 'package:vocdoni/util/singletons.dart';

class Analytics {
  final _user$ = StreamController<String>.broadcast();
  MixpanelAnalytics _mixpanel;
  MixpanelAnalytics _mixpanelBatch;
  String _mixpanelToken = "3e46daca80e0263f0fc5a5e5e9bc76ea";

  Analytics() {
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

    _user$.add(getUserId());
  }

  getUserId() {
    //Todo: Do not use public key
    return account.identity.keys[0].publicKey;
  }

  track(String eventId) {
    _mixpanel.track(event: eventId, properties: {'prop1': 'value1'});
  }
}
