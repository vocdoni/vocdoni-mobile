import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import "package:vocdoni/util/singletons.dart";

// TODO: REMOVE THIS FILE

/// INTENDED FOR INTERNAL TESTING PURPOSES
Future populateSampleData() async {
  final List<Organization> orgs = await _populateOrganizations();

  await _populateNewsFeeds(orgs);
}

Future<List<Organization>> _populateOrganizations() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  Identity currentIdent = identitiesBloc.current
      ?.elementAt(appStateBloc.current?.selectedIdentity ?? 0);
  if (currentIdent == null) throw ("No current identity");

  final ids = ["1", "2", "3"];
  List<String> strOrganizations = ids.map((id) {
    String newOrganization = _makeOrganization("Organization #$id");
    return newOrganization;
  }).toList();

  await prefs.setStringList(
      "${currentIdent.address}/organizations", strOrganizations);

  return strOrganizations
      .map((strOrg) => Organization.fromJson(jsonDecode(strOrg))).toList();
}

Future _populateNewsFeeds(List<Organization> orgs) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (orgs?.length == 0 ?? false) throw ("No orgs");

  // Indeed, all 3 organizations have the same entity ID...
  await Future.wait(orgs.map((org) async {
      final strFeed = _makeFeed(org);
      await prefs.setString(
          NEWS_FEEDS_KEY_PREFIX + "${org.entityId}/${org.languages[0] ?? "en"}", strFeed);
  }));
}

String _makeOrganization(String name) {
  return '''{
    "version": "1.0",
    "languages": [
        "en",
        "fr"
    ],
    "entity-name": "$name",
    "entity-description": {
        "en": "The description of $name goes here",
        "fr": "La description officielle de $name est ici"
    },
    "voting-contract": "0x0",
    "gateway-update": {
        "timeout": 60000,
        "topic": "vocdoni-gateway-update",
        "difficulty": 1000
    },
    "process-ids": {
        "active": [],
        "ended": []
    },
    "news-feed": {
        "en": "https://hipsterpixel.co/feed.json",
        "fr": "https://feed2json.org/convert?url=http://www.intertwingly.net/blog/index.atom"
    },
    "avatar": "https://hipsterpixel.co/assets/favicons/apple-touch-icon.png",
    "gateway-boot-nodes": [
        {
            "update": "pss://publicKey@0x0",
            "fetch": "https://hostname:port/route"
        }
    ],
    "relays": [
        {
            "publicKey": "0x23456...",
            "messagingUri": "<messaging-uri>"
        }
    ],
    "actions": [
        {
            "type": "browser",
            "name": {
                "en": "Sign up to $name",
                "fr": "S'inscrire à $name"
            },
            "url": "https://cloudflare-ipfs.com/ipfs/QmZ56Z2kpG5QjJcWfhxFD4ac3DhfX21hrQ2gCTrWxzTAse",
            "visible": true
        }
    ]
}''';
}

String _makeFeed(Organization org){
  return '''{
  "version": "https://jsonfeed.org/version/1",
  "title": "${org.name}",
  "home_page_url": "https://hipsterpixel.co/",
  "description": "${org.description}",
  "feed_url": "https://hipsterpixel.co/feed.json",
  "icon": "https://hipsterpixel.co/assets/favicons/apple-touch-icon.png",
  "favicon": "https://hipsterpixel.co/assets/favicons/favicon.ico",
  "expired": false,
  "items": [
    {
      "id": "900e5aa6896c53a40745acac8ca00c3c0ae4f7c3",
      "title": "SmallHD FOCUS OLED 5.5-inch Monitor Review",
      "summary": "A 5-inch OLED display for your camera is what SmallHD offers with the FOCUS OLED and I've put it through its paces!",
      "content_text": "Many cameras nowadays come with a nice screen, often high resolution with a high brightness, but not always swivelling and always too small to fully rely on. I cannot tell how many times a bad picture on the small camera display was actually pretty decent once I opened it on the computer. And when you’re doing video, you really need to get that focus right, at all times. This is hard, but I have a solution that will help you out tremendously!",
      "content_html": "<p>Many cameras nowadays come with a nice screen, often high resolution with a high brightness, but not always swivelling and always too small to fully rely on. I cannot tell how many times a bad picture on the small camera display was actually pretty decent once I opened it on the computer. And when you’re doing video, you really need to get that focus right, at all times. This is hard, but I have a solution that will help you out tremendously!</p>",
      "url": "https://hipsterpixel.co/2019/05/10/smallhd-5-5-focus-oled-monitor-review/",
      "image": "https://ad3d98360fa0de008220-e893b890b8e259a099f8456bf1578245.ssl.cf5.rackcdn.com/smallhd-focus-oled-monitor-review-819-c-m3w0c-q6801.jpg",
      "tags": [
        "smallhd",
        "oled",
        "monitor",
        "camera",
        "review",
        "test",
        "videography",
        "photography",
        "filmmaking",
        "sonycamera",
        "workflow",
        "gearhead"
      ],
      "date_published": "2019-05-10T19:10:00+00:00",
      "date_modified": "2019-05-10T19:10:00+00:00",
      "author": {
        "name": "Alexandre Vallières-Lagacé",
        "url": "http://vallier.es"
      }
    },
    {
      "id": "962e46254d1527862c1d81574000e58b295aca8b",
      "title": "Logi Circle 2 Camera and Ecosystem Review",
      "summary": "The Logi Circle 2 security camera has a ton of features and a great accessory ecosystem that could make it the most versatile camera on the market!",
      "content_text": "There I am reviewing another security camera, but this one is peculiar. Most of the time a security camera is a standalone, all-inclusive thing that you set and forget. It has a single precise function and does it on day one until its last day. But what if you could get something modular? Something that can be moved around the house. This is where the Logi Circle 2 camera comes in the picture!DesignThis camera is as small as a hockey puck albeit with a conical shape, ...",
      "content_html": "<p>There I am reviewing another security camera, but this one is peculiar. Most of the time a security camera is a standalone, all-inclusive thing that you set and forget. It has a single precise function and does it on day one until its last day. But what if you could get something modular? Something that can be moved around the house. This is where the <a href=\\"https://hipsterpixel.co/r/az/B0711V3LSQ/logi+circle+2+wired\\">Logi Circle 2 camera</a> comes in the picture!</p>",
      "url": "https://hipsterpixel.co/2019/04/29/logi-circle-2-camera-and-ecosystem-review/",
      "image": "https://ad3d98360fa0de008220-e893b890b8e259a099f8456bf1578245.ssl.cf5.rackcdn.com/logi-circle-2-camera-review-573-c-3nsh3.jpg",
      "tags": [
        "logi",
        "logitech",
        "circle 2",
        "security camera",
        "camera",
        "video recording",
        "thieves",
        "caught on camera",
        "ecosystem",
        "accessories",
        "review",
        "test",
        "benchmark"
      ],
      "date_published": "2019-04-29T12:12:00+00:00",
      "date_modified": "2019-04-29T12:12:00+00:00",
      "author": {
        "name": "Alexandre Vallières-Lagacé",
        "url": "http://vallier.es"
      }
    },
    {
      "id": "946429b6cf42bd1691c3d2da50a9bceaa3aaa452",
      "title": "ElevationLab BatteryPro, a Battery Pack With Integrated Apple Watch Charger [Review]",
      "summary": "Take a battery pack, add a nice design and sprinkle original features on top, you get the BatteryPro by ElevationLab, let's see the result!",
      "content_text": "When we are talking about great design and battery pack, well, we are never mixing both. Most battery packs on the market are what they are, energy in a pack. But never, or extremely rarely, is it a work of product design. That was until, ElevationLab took a crack at it! With the BatteryPro, ElevationLab are cramming a big 8,000 mAh inside a nicely designed power brick with the added touch of having an Apple Watch charger built-in.",
      "content_html": "<p>When we are talking about great design and battery pack, well, we are never mixing both. Most battery packs on the market are what they are, energy in a pack. But never, or extremely rarely, is it a work of product design. That was until, ElevationLab took a crack at it! With the <a href=\\"https://www.elevationlab.com/products/battery-pro-for-iphone-apple-watch\\">BatteryPro</a>",
      "url": "https://hipsterpixel.co/2019/04/23/elevationlab-batterypro-a-battery-pack-with-integrated-apple-watch-charger-review/",
      "image": "https://ad3d98360fa0de008220-e893b890b8e259a099f8456bf1578245.ssl.cf5.rackcdn.com/elevationlab-batterypro-battery-pack-apple-watch-iphone-review-859-6i7yf.jpg",
      "tags": [
        "elevationlab",
        "batterypro",
        "battery pack",
        "external battery",
        "review",
        "test",
        "apple watch",
        "made for iphone"
      ],
      "date_published": "2019-04-23T12:20:00+00:00",
      "date_modified": "2019-04-23T12:20:00+00:00",
      "author": {
        "name": "Alexandre Vallières-Lagacé",
        "url": "http://vallier.es"
      }
    }
  ]
}''';
}