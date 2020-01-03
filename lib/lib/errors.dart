class FetchError implements Exception {
  final String msg;
  final String method;
  const FetchError(this.msg, [this.method]);
  String toString() => 'FetchError: [${method ?? "request"}] $msg';
}

class RestoreError implements Exception {
  final String msg;
  const RestoreError(this.msg);
  String toString() => 'RestoreError: $msg';
}

class PersistError implements Exception {
  final String msg;
  const PersistError(this.msg);
  String toString() => 'PersistError: $msg';
}
