import "package:flutter/material.dart";
import 'package:vocdoni/controllers/account.dart';
import '../data/feedBloc.dart';
import "../data/app-state.dart";
import "../data/identityBloc.dart";
import "../data/entityMetadataBloc.dart";
import "../data/processMetadataBloc.dart";

// Export classes
export "../data/app-state.dart";
export "../data/identityBloc.dart";
export "../data/entityMetadataBloc.dart";
export "../data/processMetadataBloc.dart";
export "../data/feedBloc.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentityBloc identitiesBloc = IdentityBloc();
EntityMetadataBloc entitiesBloc = EntityMetadataBloc();
ProccessMetadataBloc processesBloc = ProccessMetadataBloc();
FeedBloc newsFeedsBloc = FeedBloc();
Account  account;

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
