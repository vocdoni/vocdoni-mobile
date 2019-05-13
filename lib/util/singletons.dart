import './web-runtime.dart';
import "../bloc/app-state.dart";
import "../bloc/identities.dart";
import "../bloc/elections.dart";

// export './web-runtime.dart';
export "../bloc/app-state.dart";
export "../bloc/identities.dart";
export "../bloc/elections.dart";

// EXPORTED SINGLETON INSTANCES

WebRuntime webRuntime = new WebRuntime();

AppStateBloc appStateBloc = AppStateBloc();
IdentitiesBloc identitiesBloc = IdentitiesBloc();
ElectionsBloc electionsBloc = ElectionsBloc();
