import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
export 'package:vocdoni/constants/storage-names.dart';
export 'package:vocdoni/lib/errors.dart';

abstract class GenericBloc<T> {
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
