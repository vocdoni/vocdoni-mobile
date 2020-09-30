import 'dart:convert';
import 'dart:io';
import "dart:developer";
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";

final String _storageFile = SETTINGS_STORE_FILE;

class SettingsPersistence extends BasePersistenceSingle<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> read() async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set(Map<String, dynamic>());
        return value;
      }

      final strSettings = await fd.readAsString();
      Map<String, dynamic> settings = jsonDecode(strSettings);
      if (settings is! Map) {
        log("[App] Settings error: $_storageFile does not contain a JSON object. Using an empty one.");
        settings = {};
      }

      // Update the in-memory current value
      set(settings);

      return settings;
    } catch (err) {
      log("[App] Settings error: $err");
      throw RestoreError("There was an error while reading the local data");
    }
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      await fd.writeAsString(jsonEncode(value));

      // Update the in-memory current value
      set(value);
    } catch (err) {
      log("[App] Settings error: $err");
      throw PersistError("There was an error while storing the changes");
    }
  }
}
