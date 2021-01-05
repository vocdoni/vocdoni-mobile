import 'package:flutter/material.dart';
import 'package:vocdoni/data-persistence/bootnodes-persistence.dart';
import 'package:vocdoni/data-persistence/entities-persistence.dart';
import 'package:vocdoni/data-persistence/identities-persistence.dart';
import 'package:vocdoni/data-persistence/processes-persistence.dart';
import 'package:vocdoni/data-persistence/feed-persistence.dart';
import 'package:vocdoni/data-persistence/settings-persistence.dart';

import 'package:vocdoni/data-models/app-state.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/data-models/process.dart';

import 'package:vocdoni/lib/analytics.dart';

class Globals {
  // STORAGE INSTANCES
  static final bootnodesPersistence = BootnodesPersistence();
  static final identitiesPersistence = IdentitiesPersistence();
  static final entitiesPersistence = EntitiesPersistence();
  static final processesPersistence = ProcessesPersistence();
  static final feedPersistence = NewsFeedPersistence();
  static final settingsPersistence = SettingsPersistence();

  // MODEL INSTANCES

  // The global variables below contain the full state of the app in memory.
  // They are the single source of truth when updating and persisting data.

  static final appState = AppStateModel();

  static final accountPool = AccountPoolModel();
  static final entityPool = EntityPoolModel();
  static final processPool = ProcessPoolModel();
  static final feedPool = FeedPool();

  // UI HELPER INSTANCES
  static final navigatorKey = GlobalKey<NavigatorState>();

  static final analytics = Analytics();

  static final oldProcessFeed = OldProcessFeed();
}
