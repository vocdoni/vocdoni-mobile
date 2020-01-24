import "package:flutter/material.dart";

import 'package:vocdoni/data-persistence/bootnodes-persistence.dart';
import 'package:vocdoni/data-persistence/entities-persistence.dart';
import 'package:vocdoni/data-persistence/identities-persistence.dart';
import 'package:vocdoni/data-persistence/processes-persistence.dart';
import 'package:vocdoni/data-persistence/feed-persistence.dart';

import 'package:vocdoni/data-models/app-state.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/feed.dart';
import 'package:vocdoni/data-models/process.dart';

import 'package:vocdoni/lib/analtyics.dart';

// EXPORTED SINGLETON STORAGE INSTANCES

final globalBootnodesPersistence = BootnodesPersistence();
final globalIdentitiesPersistence = IdentitiesPersistence();
final globalEntitiesPersistence = EntitiesPersistence();
final globalProcessesPersistence = ProcessesPersistence();
final globalFeedPersistence = NewsFeedPersistence();

// EXPORTED SINGLETON GLOBAL MODEL INSTANCES

// The global variables below contain the full state of the app in memory.
// They are the single source of truth when updating and persisting data.

final globalAppState = AppStateModel();

final globalAccountPool = AccountPoolModel();
final globalEntityPool = EntityPoolModel();
final globalProcessPool = ProcessPoolModel();
final globalFeedPool = FeedPool();

final globalAnalytics = Analytics();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
