import 'package:vocdoni/data/_processMock.dart';
import 'package:vocdoni/data/generic.dart';
import 'package:vocdoni/util/dev/populate.dart';
import 'package:vocdoni/util/singletons.dart';


class ProcessesBloc extends BlocComponent<List<ProcessMock>> {
  final String _storageFile = PROCESSES_STORE_FILE;

  ProcessesBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {

    state.add([makeFakeProcess()]);
    // File fd;
    // ProcessesStore store;

    // try {
    //   fd = File("${storageDir.path}/$_storageFile");
    //   if (!(await fd.exists())) {
    //     return;
    //   }
    // } catch (err) {
    //   print(err);
    //   throw BlocRestoreError(
    //       "There was an error while accessing the local data");
    // }

    // try {
    //   final bytes = await fd.readAsBytes();
    //   store = ProcessesStore.fromBuffer(bytes);
    //   state.add(store.items);
    // } catch (err) {
    //   print(err);
    //   throw BlocRestoreError(
    //       "There was an error while processing the local data");
    // }
  }

  @override
  Future<void> persist() {
    print("Unimplemented: processes > persist()");
    // TODO:
    throw BlocPersistError("There was an error while storing the changes");
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<ProcessMock> data) async {
    super.set(data);
    //await persist();
  }

  // CUSTOM OPERATIONS

 Future< ProcessMock> get(ProcessReference ref) async {

   return processesBloc.value[0];
  }


}

// TODO: Use a protobuf model
class Process {}

class ProcessesStore {}
