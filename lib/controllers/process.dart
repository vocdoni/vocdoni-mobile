import 'package:dvote/dvote.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/util/singletons.dart';

// Watchout changing this
enum CensusState { IN, OUT, UNKNOWN, CHECKING, ERROR }

class Process {
  ProcessMetadata processMetadata;
  String lang = "default";
  CensusState censusState;

  Process(ProcessMetadata processMetadata) {
    this.processMetadata = processMetadata;
  }

  

  update() async {
    // Sync process times
    // Check if active?
    // Check census
    // Check if voted
    // Fetch results
    // Fetch private key
  }

  save() async {
    await processesBloc.add(this.processMetadata);

    // Save metadata
    // Save census_state
    // Save census_size
    // Save if voted
    // Save results
  }

  syncLocal(){
    syncCensusState();
  }

  syncCensusState() {
    censusState = CensusState.values.firstWhere(
        (e) =>
            e.toString() ==
            'CensusState.' +
                this.processMetadata.meta[META_PROCESS_CENSUS_STATE],
        orElse: () => censusState = CensusState.UNKNOWN);
  }

  saveCensusState() {
    this.processMetadata.meta[META_PROCESS_CENSUS_STATE] =
        censusState.toString();
  }

  checkCensusState() async {
    censusState = CensusState.CHECKING;

    final gwInfo = selectRandomGatewayInfo();
    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);

    String base64Claim =
        await digestHexClaim(account.identity.keys[0].publicKey);
    try {
      final proof = await generateProof(
          processMetadata.census.merkleRoot, base64Claim, dvoteGw);
      if (proof == "GOOD")
        censusState = CensusState.IN;
      else
        censusState = CensusState.OUT;
    } catch (error) {
      censusState = CensusState.OUT;
    }
  }
}
