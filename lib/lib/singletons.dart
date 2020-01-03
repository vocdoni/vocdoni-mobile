import "package:flutter/material.dart";

import "package:vocdoni/data-persistence/identities-persistence.dart";
import "package:vocdoni/data-persistence/entities-persistence.dart";
import "package:vocdoni/data-persistence/processes-persistence.dart";

// import 'package:vocdoni/data-models/account.dart';
// import 'package:vocdoni/lib/analtyics.dart';
// import 'package:vocdoni/data-models/vochain.dart';
// import '../data-storage/feedBloc.dart';
// import "../data-storage/app-state.dart";
// import "../data-storage/identityBloc.dart";
// import "../data-storage/entityMetadataBloc.dart";
// import "../data-storage/processMetadataBloc.dart";

// EXPORTED SINGLETON INSTANCES

final globalIdentitiesPersistence = IdentitiesPersistence();
final globalEntitiesPersistence = EntitiesPersistence();
final globalProcessesPersistence = ProcessesPersistence();

// // Bloc entities
// AppStateBloc appStateBloc = AppStateBloc();
// FeedBloc newsFeedsBloc = FeedBloc();
// Account account = Account();
// Analytics analytics = Analytics();
// VochainModel vochainModel = VochainModel();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
