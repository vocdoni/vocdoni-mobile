import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Abstract class to persist collections of objects
abstract class BasePersistence<T> {
  @protected
  Directory storageDir;

  @protected
  List<T> value;

  /// Sets the current application Document directory and
  /// restores the data previously stored
  @protected
  Future<void> init() async {
    if (!(storageDir is Directory))
      storageDir = await getApplicationDocumentsDirectory();
  }

  /// Read the current data from the data storage.
  /// `init()` must be called before the rest.
  Future<List<T>> readAll();

  /// Write the given state to persistent storage.
  /// `init()` must be called before the rest.
  Future<void> writeAll(List<T> value);

  /// Gets the current global value. Note that this does not read from storage,
  /// only from memory.
  List<T> get() => value;

  /// Sets a new global value, but does not write it to persistence storage.
  set(List<T> newValue) {
    value = newValue;
  }
}

/// Abstract class to persist single instances of objects
abstract class BasePersistenceSingle<T> {
  @protected
  Directory storageDir;

  @protected
  T value;

  /// Sets the current application Document directory and
  /// restores the data previously stored
  @protected
  Future<void> init() async {
    if (!(storageDir is Directory))
      storageDir = await getApplicationDocumentsDirectory();
  }

  /// Read the current data from the data storage.
  /// `init()` must be called before the rest.
  Future<T> read();

  /// Write the given state to persistent storage.
  /// `init()` must be called before the rest.
  Future<void> write(T value);

  /// Gets the current global value. Note that this does not read from storage,
  /// only from memory.
  T get() => value;

  /// Sets a new global value, but does not write it to persistence storage.
  set(T newValue) {
    value = newValue;
  }
}
