class FetchError implements Exception {
  final String msg;
  final String method;
  const FetchError(this.msg, [this.method]);
  String toString() => 'FetchError: [${method ?? "request"}] $msg';
}
