import "package:flutter/material.dart";
import '../data/news-feeds.dart';
import "../data/app-state.dart";
import "../data/identities.dart";
import "../data/entities.dart";
import "../data/processes.dart";

// Export classes
export "../data/app-state.dart";
export "../data/identities.dart";
export "../data/entities.dart";
export "../data/processes.dart";
export "../data/news-feeds.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentitiesBloc identitiesBloc = IdentitiesBloc();
EntitiesBloc entitiesBloc = EntitiesBloc();
ProcessesBloc processesBloc = ProcessesBloc();
NewsFeedsBloc newsFeedsBloc = NewsFeedsBloc();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
