import 'dart:io';
import 'package:vocdoni/data/generic.dart';
import 'package:dvote/dvote.dart';

class ProcessesBloc extends BlocComponent<List<Process>> {
  final String _storageFile = PROCESSES_STORE_FILE;

  ProcessesBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
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
  Future<void> set(List<Process> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

}

// TODO: Use a protobuf model
class Process {}

class ProcessesStore {}
