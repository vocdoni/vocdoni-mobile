import 'dart:io';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/data-persistence/base-persistence.dart";
import "package:vocdoni/constants/storage-names.dart";
import 'package:vocdoni/lib/logger.dart';

final String _storageFile = BOOTNODES_STORE_FILE;

class BootnodesPersistence extends BasePersistenceSingle<BootNodeGateways> {
  @override
  Future<BootNodeGateways> read() async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      if (!(await fd.exists())) {
        set(BootNodeGateways());
        return value;
      }

      final bytes = await fd.readAsBytes();
      final gwList = BootNodeGateways.fromBuffer(bytes);

      // Update the in-memory current value
      set(gwList);

      return gwList;
    } catch (err) {
      logger.log(err);
      throw RestoreError(
          "There was an error while reading the local bootnode data");
    }
  }

  @override
  Future<void> write(BootNodeGateways value) async {
    await super.init();

    try {
      final fd = File("${storageDir.path}/$_storageFile");
      await fd.writeAsBytes(value.writeToBuffer());

      // Update the in-memory current value
      set(value);
    } catch (err) {
      logger.log(err);
      throw PersistError("There was an error while storing the changes");
    }
  }
}
