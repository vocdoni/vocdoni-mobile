import './web-runtime.dart';
import "../data/app-state.dart";
import "../data/identities.dart";
import "../data/elections.dart";

// export './web-runtime.dart';
export "../data/app-state.dart";
export "../data/identities.dart";
export "../data/elections.dart";

// EXPORTED SINGLETON INSTANCES

WebRuntime webRuntime = new WebRuntime();

AppStateBloc appStateBloc = AppStateBloc();
IdentitiesBloc identitiesBloc = IdentitiesBloc();
ElectionsBloc electionsBloc = ElectionsBloc();
