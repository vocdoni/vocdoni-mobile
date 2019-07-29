import "package:flutter/material.dart";
import '../data/news-feeds.dart';
import "../data/app-state.dart";
import "../data/identities.dart";
import "../data/votes.dart";

// Export classes
export "../data/app-state.dart";
export "../data/identities.dart";
export "../data/votes.dart";
export "../data/news-feeds.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentitiesBloc identitiesBloc = IdentitiesBloc();
VotesBloc votesBloc = VotesBloc();
NewsFeedsBloc newsFeedsBloc = NewsFeedsBloc();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
