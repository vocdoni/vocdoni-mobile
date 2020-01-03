import 'package:flutter/foundation.dart';

/// DATA MODEL USAGE:
///
/// - Create a class to store your state
///   - Derive it from "DataModel"
///   - They can be used as a global singleton
///   - Using them as a local data manager is possible but persistent operations
///     should only be made on the **global** ones
/// - Collections
///   - Use standard classes to contain an element's data
///   - Use "pool" versions to contain an array of standard instances
///   - "Consume" from the nearest provider to the actual data
/// - Storage
///   - A data model is the source of truth
///   - Persistence is made upon request of the data model
///   - Data initialization is done from the data model perspective
///   - Operations are made on the data model instance
/// - Provider
///   - Provide an instance or your data models to the root of the widget tree
///   - Use MultiProvider if you have many
///   - Consume them using `Provider.of` of the `Consume` widget
///
/// More info:
/// - https://pub.dev/packages/provider
/// - https://www.youtube.com/watch?v=d_m5csmrf7I
///

/// Abstract class for data models that can be listened
/// using provider's. Memory-only.
abstract class DataModel extends ChangeNotifier {
  /// Read relevant Persistent data and notify the listeners
  /// Tell any submodels to do the same.
  Future<void> readFromStorage() async {}

  /// Write any serializable data to Persistence. 
  /// Tell any submodels to do the same.
  Future<void> writeToStorage() async {}

  /// Fetch any relevent items that might have become outdated and notify
  /// the listeners. Care should be taken to avoid refetching when not really
  /// necessary.
  Future<void> refresh() async {}
}
