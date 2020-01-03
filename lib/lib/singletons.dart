import "package:flutter/material.dart";
import 'package:vocdoni/data-models/account.dart';
import 'package:vocdoni/lib/analtyics.dart';
import 'package:vocdoni/data-models/vochain-model.dart';
import '../data-storage/feedBloc.dart';
import "../data-storage/app-state.dart";
import "../data-storage/identityBloc.dart";
import "../data-storage/entityMetadataBloc.dart";
import "../data-storage/processMetadataBloc.dart";

// Export classes
export "../data-storage/app-state.dart";
export "../data-storage/identityBloc.dart";
export "../data-storage/entityMetadataBloc.dart";
export "../data-storage/processMetadataBloc.dart";
export "../data-storage/feedBloc.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentityBloc identitiesBloc = IdentityBloc();
EntityMetadataBloc entitiesBloc = EntityMetadataBloc();
ProccessMetadataBloc processesBloc = ProccessMetadataBloc();
FeedBloc newsFeedsBloc = FeedBloc();
Account account = Account();
Analytics analytics = Analytics();
VochainModel vochainModel = VochainModel();

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();
