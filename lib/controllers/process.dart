import 'package:dvote/dvote.dart';
import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

class Process {
 
  ProcessMetadata processMetadata;
  String lang = "default";

  Process(ProcessMetadata processMetadata) {
    this.processMetadata = processMetadata;
    syncLocal();
  }

  update() async {
    syncLocal();
    // Sync process times
    // Check if active?
    // Check census
    // Check if voted
    // Fetch results
    // Fetch private key

  }

  save() async {
    // Save metadata
    // Save census_state
    // Save census_size
    // Save if voted
    // Save results
  }

  syncLocal() async {
   // Recover processMetadata
   // Recover 
  }
}
