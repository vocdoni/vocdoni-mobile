import "package:flutter/material.dart";
import 'package:vocdoni/data/news-feeds.dart';
import "../data/app-state.dart";
import "../data/identities.dart";
import "../data/elections.dart";

export "../data/app-state.dart";
export "../data/identities.dart";
export "../data/elections.dart";
export "../data/news-feeds.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentitiesBloc identitiesBloc = IdentitiesBloc();
ElectionsBloc electionsBloc = ElectionsBloc();
NewsFeedsBloc newsFeedsBloc = NewsFeedsBloc();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
