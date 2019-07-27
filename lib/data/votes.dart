import 'dart:io';
import 'package:vocdoni/data/generic.dart';
import 'package:dvote/dvote.dart';

class ElectionsBloc extends BlocComponent<List<Election>> {
  ElectionsBloc() {
    state.add([]);
  }

  @override
  Future<void> restore() {
    return readState();
  }

  @override
  Future<void> persist() {
    // TODO:
  }

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

class Election {}
