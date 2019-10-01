import 'dart:async';

import 'package:mixpanel_analytics/mixpanel_analytics.dart';
import 'package:vocdoni/util/singletons.dart';

class Analytics {
  final _user$ = StreamController<String>.broadcast();
  MixpanelAnalytics _mixpanel;
  MixpanelAnalytics _mixpanelBatch;

  Analytics() {
    _mixpanel = MixpanelAnalytics(
      token: 'XXXX',
      userId$: _user$.stream,
      verbose: true,
      shouldAnonymize: true,
      shaFn: (value) => value,
      onError: (e) => () {},
    );

    _mixpanelBatch = MixpanelAnalytics.batch(
        token: 'XXXX',
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
