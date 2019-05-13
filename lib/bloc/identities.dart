import 'package:rxdart/rxdart.dart';

class IdentitiesBloc {
  BehaviorSubject<List<Identity>> _state =
      BehaviorSubject<List<Identity>>.seeded(List<Identity>());

  Observable<List<Identity>> get stream => _state.stream;
  List<Identity> get current => _state.value;

  // Constructor
  IdentitiesBloc() {
    // TODO: FETCH STORED DATA
  }

  Future restore() async {
    // TODO: Fetch the last selected identity
  }

  // Operations
  create() {
    // TODO: CREATE
    // TODO: ENCRYPT
    // TODO: PERSIST CHANGES
  }

  subscribe(Organization org) {
    // TODO: PERSIST CHANGES
  }

  unsubscribe(Organization org) {
    // TODO: PERSIST CHANGES
  }
}

class Identity {
  final String name;
  final String description;
  final List<Organization> organizations;

  Identity(this.name, this.description, this.organizations);

  Identity.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        description = json['description'],
        organizations = [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
      };
}

class Organization {
  final String name;

  Organization({this.name});

  Organization.fromJson(Map<String, dynamic> json) : name = json['name'];

  Map<String, dynamic> toJson() => {
        'name': name,
      };
}
