class FetchError implements Exception {
  final String msg;
  final String method;
  const FetchError(this.msg, [this.method]);
  String toString() => 'FetchError: [${method ?? "request"}] $msg';
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
