import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/lib/errors.dart';
import "package:vocdoni/constants/meta-keys.dart";
import 'package:vocdoni/lib/net.dart';
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// ////////////////////////////////////////////////////////////////////////////
// METHODS
// ////////////////////////////////////////////////////////////////////////////

Future<EntityMetadata> fetchEntityData(EntityReference entityReference) async {
  if (!(entityReference is EntityReference)) return null;

  try {
    final DVoteGateway dvoteGw = getDVoteGateway();
    final Web3Gateway web3Gw = getWeb3Gateway();

    final EntityMetadata entityMetadata =
        await fetchEntity(entityReference, dvoteGw, web3Gw);
    entityMetadata.meta[META_ENTITY_ID] = entityReference.entityId;

    return entityMetadata;
  } catch (err) {
    if (!kReleaseMode) print(err);
    throw FetchError("The entity's data cannot be fetched", "fetchEntity");
  }
}

Future<Feed> fetchEntityNewsFeed(EntityReference entityReference,
    EntityMetadata entityMetadata, String lang) async {
  // Attempt for every node available
  if (!(entityMetadata is EntityMetadata))
    return null;
  else if (!(entityMetadata.newsFeed is Map<String, String>))
    return null;
  else if (!(entityMetadata.newsFeed[lang] is String)) return null;

  final DVoteGateway dvoteGw = getDVoteGateway();
  final String contentUri = entityMetadata.newsFeed[lang];

  // Attempt for every node available
  try {
    final ContentURI cUri = ContentURI(contentUri);

    final result = await fetchFileString(cUri, dvoteGw);
    final Feed feed = parseFeed(result);
    feed.meta[META_ENTITY_ID] = entityReference.entityId;
    feed.meta[META_LANGUAGE] = lang;

    return feed;
  } catch (err) {
    print(err);
    throw FetchError(err, "fetchFileString");
  }
}
