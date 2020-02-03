// import 'dart:math';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import "package:vocdoni/lib/singletons.dart";
import "package:vocdoni/constants/meta-keys.dart";
import "package:dvote/dvote.dart";
import 'package:dvote/util/parsers.dart';

/// INTENDED FOR INTERNAL TESTING PURPOSES

Future populateSampleData() async {
  List<EntityModel> entityModels = new List<EntityModel>();
  List<Feed> feeds = new List<Feed>();
  List<ProcessModel> processess = new List<ProcessModel>();

  final entitySummaries = makeEntitySummaries();

  entitySummaries.forEach((entityReference) {
    final entityMetadata = makeEntityMetadata(entityReference);
    final entityModel = EntityModel(entityReference, entityMetadata);
    entityModels.add(entityModel);

    final newFeeds = makeFeeds(entityMetadata);
    entityModel.feed.setValue(newFeeds[0]);
    feeds.addAll(newFeeds);

    entityMetadata.votingProcesses.active.forEach((processId) {
      final fakeProcess = makeFakeProcess(entityReference, processId);
      entityModel.processes.value.add(fakeProcess);
      processess.add(fakeProcess);
    });
  });

  globalEntityPool.setValue(entityModels);
  globalFeedPool.setValue(feeds);
  globalProcessPool.setValue(processess);

  final currentAccount = globalAppState.currentAccount;
  if (!(currentAccount is AccountModel))
    throw Exception("No account is currently selected");

  entityModels.forEach((entityModel) {
    if (!currentAccount.isSubscribed(entityModel.reference))
      currentAccount.subscribe(entityModel);
  });

  await globalEntityPool.writeToStorage();
  await globalFeedPool.writeToStorage();
  await globalProcessPool.writeToStorage();
}

List<EntityReference> makeEntitySummaries() {
  final ids = ["0x123459", "0x543210", "0x9312341"];
  return ids.map((id) {
    EntityReference entityRef = EntityReference();
    entityRef.entityId = id;
    return entityRef;
  }).toList();
}

EntityMetadata makeEntityMetadata(EntityReference entitySummary) {
  String entityId = entitySummary.entityId;
  String strEntity = getEntityMetadataString("Entity #$entityId");
  final entityMetadata = parseEntityMetadata(strEntity);
  entityMetadata.meta["entityId"] = entitySummary.entityId;
  return entityMetadata;
}

List<Feed> makeFeeds(EntityMetadata entityMetadata) {
  return entityMetadata.languages.map((lang) {
    final result = parseFeed(getFeedString(entityMetadata));
    result.meta[META_ENTITY_ID] = entityMetadata.meta[META_ENTITY_ID];
    result.meta[META_LANGUAGE] = lang;
    return result;
  }).toList();
}

ProcessModel makeFakeProcess(EntityReference entitySummary, String processId) {
  ProcessMetadata process = parseProcessMetadata(getProcessString());
  process.meta[META_PROCESS_ID] = processId;
  process.meta[META_ENTITY_ID] = entitySummary.entityId;

  final processModel =
      ProcessModel.fromMetadata(process, processId, entitySummary.entityId);
  return processModel;
}

String getEntityMetadataString(String name) {
  String entityId = "0xinvalid";

  return '''{
    "version": "1.0",
    "entityId":"$entityId",
    "languages": [
        "default"
    ],
    "name": {
        "default": "$name",
        "fr": "Mon organisation officielle"
    },
    "description": {
        "default": "The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. The description of $name goes here. ",
        "fr": "La description officielle de $name est ici"
    },
    "contracts": {
        "resolverAddress": "0x21f7DcCd9D1ce4C3685A5c50096265A8db4103b4",
        "votingAddress": "0x1234567890123456789012345678901234567890",
        "networkId": "goerli"
    },
    "votingProcesses": {
        "active": ["0x5534523452", "0x435363453", "0x8544344"],
        "ended": ["processId03"]
    },
    "newsFeed": {
        "default": "https://hipsterpixel.co/feed.json",
        "fr": "https://feed2json.org/convert?url=http://www.intertwingly.net/blog/index.atom"
    },
    "media": {
        "avatar": "https://hipsterpixel.co/assets/favicons/apple-touch-icon.png",
        "header": "https://images.unsplash.com/photo-1557518016-299b3b3c2e7f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=80"
    },
    "actions": [
        {
            "type": "browser",
            "name": {
                "default": "Register",
                "fr": "Register"
            },
            "url": "https://cloudflare-ipfs.com/ipfs/QmUNZNB1u31eoAw1ooqXRGxGvSQg4Y7MdTTLUwjEp86WnE",
            "visible": "true",
            "register":true
        },
        {
            "type": "browser",
            "name": {
                "default": "Frist action",
                "fr": "S'inscrire à $name"
            },
            "url": "https://cloudflare-ipfs.com/ipfs/QmUNZNB1u31eoAw1ooqXRGxGvSQg4Y7MdTTLUwjEp86WnE",
            "visible": "false",
            "register":false
        },
        {
            "type": "browser",
            "name": {
                "default": "Second action",
                "fr": "S'inscrire à $name"
            },
            "url": "https://cloudflare-ipfs.com/ipfs/QmUNZNB1u31eoAw1ooqXRGxGvSQg4Y7MdTTLUwjEp86WnE",
            "visible": "true",
            "register":false
        }
    ],
    "gatewayBootNodes": [
        {
            "fetchUri": "https://bootnode:port/gateways.json",
            "heartbeatMessagingUri": "pss://publicKey@0x0"
        }
    ],
    "gatewayUpdate": {
        "timeout": 60000,
        "topic": "vocdoni-gateway-update",
        "difficulty": 1000
    },
    "relays": [
        {
            "publicKey": "04875204f7b0bd9dfcf9af89b4fa0c44016f4b0372646c2142f55136973bd0d660565755341e4c583d49f9d607d08d40e3558de7e6f14f34aa83b7436ac70dc958",
            "messagingUri": "<messaging-uri>"
        }
    ],
    "bootEntities": [],
    "fallbackBootNodeEntities": [],
    "trustedEntities": [],
    "censusServiceManagedEntities": []
}''';
}

String getFeedString(EntityMetadata org) {
  return '''{
  "version": "https://jsonfeed.org/version/1",
  "title": "${org.name["default"] ?? "Entity"}",
  "home_page_url": "https://hipsterpixel.co/",
  "description": "${org.description["default"] ?? "The description of an entity"}",
  "feed_url": "https://hipsterpixel.co/feed.json",
  "icon": "https://hipsterpixel.co/assets/favicons/apple-touch-icon.png",
  "favicon": "https://hipsterpixel.co/assets/favicons/favicon.ico",
  "expired": false,
  "items": [
    {
      "id": "900e5aa6896c53a40745acac8ca00c3c0ae4f7c3",
      "title": "China's latest weapon in the trade war: Karaoke",
      "summary": "A Chinese propaganda song about the ongoing Sino-US trade war is getting a lot of interest - and raising a few eyebrows - on Chinese social media.",
      "content_text": "Many cameras nowadays come with a nice screen, often high resolution with a high brightness, but not always swivelling and always too small to fully rely on. I cannot tell how many times a bad picture on the small camera display was actually pretty decent once I opened it on the computer. And when you’re doing video, you really need to get that focus right, at all times. This is hard, but I have a solution that will help you out tremendously!",
      "content_html": "<h1>I'm an H1</h1> <h2>I'm an H2</h2> <h3>I'm an H3</h3> <img src=\\"https://i.udemycdn.com/course/750x422/59535_1f48_6.jpg\\" alt=\\"Girl in a jacket\\">",
      "url": "https://hipsterpixel.co/2019/05/10/smallhd-5-5-focus-oled-monitor-review/",
      "image": "https://ichef.bbci.co.uk/news/768/cpsprodpb/E24F/production/_107053975_tradewar.png",
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

String getProcessString() {
  return '''
  {
    "version": "1.0",
    "type": "snark-vote",
    "startBlock": 10000,
    "numberOfBlocks": 400,
    "census": {
        "id": "0x1234...",
        "merkleRoot": "0x1234...",
        "messagingUri": "<messaging uri>"
    },
    "details": {
        "entityId": "0x123",
        "encryptionPublicKey": " 0x1123",
        "title": {
            "default": "Universal Basic Income",
            "ca": "Renda Bàsica Universal"
        },
        "description": {
            "default": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
            "ca": "## El markdown va aquí ### Resum"
        },
        "headerImage": "https://images.unsplash.com/photo-1489533119213-66a5cd877091?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1502&q=80",
        "questions": [
            {
                "type": "single-choice", 
                "question": {
                    "default": "Should universal basic income become a human right?",
                    "ca": "Estàs d'acord amb que la renda bàsica universal sigui un dret humà?"
                },
                "description": {
                    "default": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                    "ca": "## El markdown va aquí ### Resum"
                },
                "voteOptions": [
                    {
                        "title": {
                            "default": "Likley yes, but not super sure about it",
                            "ca": "Sí"
                        },
                        "value": "0"
                    },
                    {
                        "title": {
                            "default": "I like cheese",
                            "ca": "Sí"
                        },
                        "value": "1"
                    },
                    {
                        "title": {
                            "default": "Very long ansser Very long ansserVery long ansser Very long ansserVery long ansser Very long ansser",
                            "ca": "Sí"
                        },
                        "value": "2"
                    },
                    {
                        "title": {
                            "default": "BLANK",
                            "ca": "No"
                        },
                        "value": "3"
                    }
                ]
            },
            {
                "type": "single-choice", 
                "question": {
                    "default": "Should universal basic income become a human right?",
                    "ca": "Estàs d'acord amb que la renda bàsica universal sigui un dret humà?"
                },
                "description": {
                    "default": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                    "ca": "## El markdown va aquí ### Resum"
                },
                "voteOptions": [
                    {
                        "title": {
                            "default": "Yes",
                            "ca": "Sí"
                        },
                        "value": "1"
                    },
                    {
                        "title": {
                            "default": "No",
                            "ca": "No"
                        },
                        "value": "2"
                    }
                ]
            }
        ]
    }
}
  ''';
}
