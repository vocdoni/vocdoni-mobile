import 'dart:developer' as developer;
import 'dart:io';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocdoni/constants/storage-names.dart';

final Logger _logger = Logger(LOG_STORE_FILE);

class Logger {
  String _filePath;
  String _sessionLogs;
  File _logFile;
  bool _init = false;
  Mutex _m = Mutex();

  Logger(this._filePath);

  init() async {
    if (_logFile?.existsSync() ?? false) return;
    final dir = await getApplicationDocumentsDirectory();
    _filePath = "${dir.path}/$_filePath";
    _sessionLogs = "";
    try {
      _logFile = new File(_filePath);
      _readLogFile();
    } catch (err) {
      log(err);
    }
    _init = true;
  }

  _readLogFile() {
    try {
      if (_logFile.existsSync()) {
        _logFile.readAsString().then((String contents) {
          if (contents.length > 0) {
            _sessionLogs = contents + "\n" + _sessionLogs;
            // Erase contents of file, begin writing new log messages for this session
            _m
                .acquire()
                .then((_) => _logFile.writeAsString("", mode: FileMode.write))
                .then((_) => _m.release());
            log("Restored previous session logs, starting new session");
          }
        });
      }
    } catch (err) {
      log("Error restoring session logs: $err");
    }
  }

  void log(dynamic contents) {
    String stringContents;
    try {
      stringContents = contents.toString();
    } catch (err) {
      developer.log(err.toString());
    }
    if (!_init) {
      developer.log(stringContents);
    } else {
      developer.log(stringContents);
      // Save to log cache
      _sessionLogs = _sessionLogs + "\n" + stringContents;
      // Acquire lock to prevent concurrent file access
      _m
          .acquire()
          .then((_) => _logFile.writeAsString(stringContents + "\n",
              mode: FileMode.append))
          .then((_) => _m.release());
    }
  }

  String get sessionLogs => _sessionLogs;
}

Logger get logger => _logger;
