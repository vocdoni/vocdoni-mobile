import 'dart:io';
import 'package:vocdoni/data/generic.dart';
import 'package:dvote/dvote.dart';

class ProcessesBloc extends BlocComponent<List<Process>> {
  ProcessesBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() {
    // TODO: Unimplemented
    print("Unimplemented: processes > restore()");
    return readState();
  }

  @override
  Future<void> persist() {
    print("Unimplemented: processes > persist()");
    // TODO:
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<Process> data) async {
    super.set(data);
    await persist();
  }

  // CUSTOM OPERATIONS

  /// Read and construct the data structures
  Future readState() async {
    // File fd;
    // VotesStore store;

    // try {
    //   fd = File(VOTES_STORE_PATH);
    //   if (!(await fd.exists())) {
    //     super.state.add([]);
    //     return;
    //   }
    // } catch (err) {
    //   print(err);
    //   super.state.add([]);
    //   throw "There was an error while accessing the local data";
    // }

    // try {
    //   final bytes = await fd.readAsBytes();
    //   store = VotesStore.fromBuffer(bytes);
    //   super.state.add(store.identities);
    // } catch (err) {
    //   print(err);
    //   super.state.add([]);
    //   throw "There was an error processing the local data";
    // }
  }
}

// TODO: Use a protobuf model
class Process {}
