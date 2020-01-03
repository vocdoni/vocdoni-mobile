import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/data-storage/genericBloc.dart';
import "package:vocdoni/constants/meta.dart";

class ProccessMetadataBloc extends GenericBloc<List<ProcessMetadata>> {
  final String _storageFile = PROCESSES_STORE_FILE;

  ProccessMetadataBloc() {
    state.add([]);
  }

  // GENERIC OVERRIDES

  /// Read and construct the data structures
  @override
  Future<void> restore() async {
    state.add([]);
    File fd;
    ProcessMetadataStore store;

    try {
      fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        return;
      }
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while accessing the local data");
    }

    try {
      final bytes = await fd.readAsBytes();
      store = ProcessMetadataStore.fromBuffer(bytes);
      state.add(store.items);
    } catch (err) {
      print(err);
      throw BlocRestoreError(
          "There was an error while processing the local data");
    }
  }

  @override
  Future<void> persist() async {
    try {
      File fd = File("${storageDir.path}/$_storageFile");
      ProcessMetadataStore store = ProcessMetadataStore();
      store.items.addAll(state.value);
      await fd.writeAsBytes(store.writeToBuffer());
    } catch (err) {
      print(err);
      throw BlocPersistError("There was an error while storing the changes");
    }
  }

  /// Sets the given value as the current one and persists the new data
  @override
  Future<void> set(List<ProcessMetadata> data) async {
    super.set(uniqueProcesses(data));
    await persist();
  }

  Future<void> add(
    ProcessMetadata processMetadata,
  ) async {
    if (processMetadata == null) return;
    final currentIndex = value.indexWhere((e) =>
        e.meta[META_PROCESS_ID] == processMetadata.meta[META_PROCESS_ID]);
    // Already exists
    if (currentIndex >= 0) {
      final currentProcessess = value;
      currentProcessess[currentIndex] = processMetadata;
      await set(currentProcessess);
    } else {
      value.add(processMetadata);
      await set(value);
    }

    // CUSTOM OPERATIONS
  }
}

List<ProcessMetadata> uniqueProcesses(List<ProcessMetadata> items) {
  List<String> ids = [];

  return items
      .where((item) {
        if (ids.contains(item.meta[META_PROCESS_ID])) return false;
        ids.add(item.meta[META_PROCESS_ID]);
        return true;
      })
      .cast<ProcessMetadata>()
      .toList();
}
