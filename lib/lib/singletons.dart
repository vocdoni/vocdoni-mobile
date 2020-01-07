import "package:flutter/material.dart";

import 'package:vocdoni/data-models/app-state.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/news-feed.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/data-models/vochain.dart';

import 'package:vocdoni/lib/analtyics.dart';

// EXPORTED SINGLETON INSTANCES

// The global variables below contain the full state of the app in memory.
// They are the single source of truth when updating and persisting data.

final globalAppState = AppStateModel();
final globalVochain = VochainModel();  // TODO: Can it be merged with AppStateModel?

final globalAccountPool = AccountPoolModel();
final globalEntityPool = EntityPoolModel();
final globalProcessPool = ProcessPoolModel();
final globalNewsFeedPool = NewsFeedPoolModel();

final Analytics globalAnalytics = Analytics();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
