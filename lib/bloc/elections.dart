import 'package:rxdart/rxdart.dart';

class ElectionsBloc {
  BehaviorSubject<List<Election>> _state =
      BehaviorSubject<List<Election>>.seeded(List<Election>());

  Observable<List<Election>> get stream => _state.stream;
  List<Election> get current => _state.value;

  // Constructor
  ElectionsBloc() {
    // TODO: FETCH CACHED DATA
  }

  // Operations
  update(List<Election> entities) {
    _state.add(entities);
    // TODO: PERSIST CHANGES
  }
}

class Election {
  final String name;
  final String description;

  Election(this.name, this.description);

  Election.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        description = json['description'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}
