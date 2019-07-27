import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

const IDENTITIES_STORE_PATH = "identities.dat";
const ENTITIES_STORE_PATH = "entities.dat";
const BOOTNODES_STORE_PATH = "bootnodes.dat";
const VOTES_STORE_PATH = "votes.dat";

abstract class BlocComponent<T> {
  // Data stream
  @protected
  BehaviorSubject<T> state = BehaviorSubject<T>.seeded(null);

  // Getters
  Observable<T> get stream => state.stream;
  T get current => state.value;

  // Setters
  Future<void> restore();
  Future<void> persist();
  void set(T data) {
    state.add(data);
  }
}
