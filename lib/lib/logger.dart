import 'dart:developer' as developer;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocdoni/constants/storage-names.dart';

final Logger _logger = Logger(LOG_STORE_FILE);

class Logger {
  String _filePath;
  String _sessionLogs;
  File _logFile;
  bool _init = false;

  Logger(this._filePath);

  init() async {
    final dir = await getApplicationDocumentsDirectory();
    _filePath = "${dir.path}/$_filePath";
    _sessionLogs = "";
    _logFile = new File(_filePath);
    _readLogFile();
    _init = true;
  }

  _readLogFile() {
    try {
      if (_logFile.existsSync()) {
        _logFile.readAsString().then((String contents) {
          print("Log contents: $contents");
          if (contents.length > 0) {
            _sessionLogs = contents + "\n" + _sessionLogs;
            // Erase contents of file, begin writing new log messages for this session
            _logFile.writeAsString("", mode: FileMode.write);
            this.log("Restored previous session logs");
          }
        });
      }
    } catch (err) {
      this.log("Error restoring session logs: $err");
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
      _logFile.writeAsString(stringContents + "\n", mode: FileMode.append);
    }
  }

  String get sessionLogs => _sessionLogs;
}

Logger get logger => _logger;
