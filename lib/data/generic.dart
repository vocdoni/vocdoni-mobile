import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';

const IDENTITIES_STORE_FILE = "identities.dat";
const ENTITIES_STORE_FILE = "entities.dat";
const BOOTNODES_STORE_FILE = "bootnodes.dat";
const PROCESSES_STORE_FILE = "processes.dat";
const NEWSFEED_STORE_FILE = "feed.dat";

abstract class BlocComponent<T> {
  // Data stream
  @protected
  BehaviorSubject<T> state = BehaviorSubject<T>.seeded(null);
  Directory storageDir;

  /// Determines the current application Document directory and
  /// restores the data previously stored
  Future<void> init() async {
    storageDir = await getApplicationDocumentsDirectory();
    await restore();
  }

  // Getters

  /// Provides the current stream
  Observable<T> get stream => state.stream;

  /// Provides the latest value sent to the stream
  T get value => state.value;

  // Setters

  /// Read and construct the data structures
  Future<void> restore();

  /// Write the current state to persistent storage
  Future<void> persist();

  /// Send the given value to the stream
  set(T data) {
    state.add(data);
  }
}

class BlocRestoreError implements Exception {
  final String msg;
  const BlocRestoreError(this.msg);
  String toString() => 'BlocRestoreError: $msg';
}

class BlocPersistError implements Exception {
  final String msg;
  const BlocPersistError(this.msg);
  String toString() => 'BlocPersistError: $msg';
}
