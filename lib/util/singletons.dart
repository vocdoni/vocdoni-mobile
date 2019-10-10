import "package:flutter/material.dart";
import 'package:vocdoni/models/account.dart';
import 'package:vocdoni/models/analtyics.dart';
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
export "../data/data-state.dart";

// EXPORTED SINGLETON INSTANCES

// Bloc entities
AppStateBloc appStateBloc = AppStateBloc();
IdentityBloc identitiesBloc = IdentityBloc();
EntityMetadataBloc entitiesBloc = EntityMetadataBloc();
ProccessMetadataBloc processesBloc = ProccessMetadataBloc();
FeedBloc newsFeedsBloc = FeedBloc();
Account  account = Account();
Analytics analytics = Analytics();
int vochainBlockRef;
DateTime vochainTimeRef;

// Global scaffold key for snackbars
GlobalKey<ScaffoldState> homePageScaffoldKey = new GlobalKey<ScaffoldState>();


// Const
const META_ENTITY_ID = "entityId";
const META_PROCESS_ID = "processId";
const META_PROCESS_CENSUS_IS_IN = "processCensusState";
const META_PROCESS_PARTICIPANTS_TOTAL ="processParticipantsTotal";
const META_PROCESS_PARTICIPANTS_CURRENT ="processParticipantsCurrent";
const META_LANGUAGE = "language";