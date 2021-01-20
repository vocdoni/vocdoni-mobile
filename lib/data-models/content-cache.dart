import 'dart:developer';

import 'package:dvote/dvote.dart';
import 'package:eventual/eventual-notifier.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/widgets/card-poll.dart';
import 'package:vocdoni/widgets/card-post.dart';

import 'entity.dart';

// Used to merge and sort feed items
class Bloc {
  final EntityModel entity;
  final ProcessModel process;
  final FeedPost post;
  final DateTime date;

  Bloc({@required this.entity, @required this.date, this.process, this.post});

  Bloc.fromProcess(ProcessModel process)
      : entity = process.entity,
        date = process.sortDate,
        process = process,
        post = null;

  Bloc.fromPost(EntityModel entity, FeedPost post)
      : entity = entity,
        date = DateTime.tryParse(post.datePublished),
        post = post,
        process = null;

  Widget toWidget(listIdx) {
    if (this.process != null)
      return CardPoll(this.process, this.entity, listIdx);
    else if (this.post != null)
      return CardPost(this.post, this.entity, listIdx);
    return Container();
  }
}

class StoredContent {
  final storedBlocs =
      EventualNotifier<List<Bloc>>().setDefaultValue(List<Bloc>());
  int _nextBlocIndex = 0;

  resetIndex() => _nextBlocIndex = 0;

  bool get hasNextItem =>
      storedBlocs != null &&
      storedBlocs.hasValue &&
      storedBlocs.value.length > _nextBlocIndex &&
      storedBlocs.value[_nextBlocIndex] != null;

  // DateTime getNextDate() {
  //   if (!processes.hasValue || processes.value.length <= _nextProcessIndex)
  //     return null;
  //   if (!processes.value[_nextProcessIndex].startDate.hasValue)
  //     return DateTime.fromMillisecondsSinceEpoch(0);
  //   return processes.value[_nextProcessIndex].startDate.value;
  // }

  Bloc getNextBloc() {
    print("proces index $_nextBlocIndex");
    if (!storedBlocs.hasValue || storedBlocs.value.length <= _nextBlocIndex)
      return null;
    return storedBlocs.value[_nextBlocIndex++];
  }

  void loadBlocsFromStorage() {
    print("load blocs from storage");
    // Get a filtered list of the Entities of the current user
    final entities = Globals.appState.currentAccount.entities.value;

    final processes = getStoredProcesses(
        entities.map((entity) => entity.reference.entityId).toList());
    final posts = getStoredPosts(entities);
    final blocs = processes + posts;
    blocs.sort(_sortBlocs);
    storedBlocs.setValue(blocs);
    print("${storedBlocs.value.length} blocs");
    print("${blocs.map((e) => e.date).toList()}");
  }

  List<Bloc> getStoredProcesses(List<String> entityIds) {
    try {
      // This will get all processes for the current user which are in the process pool
      final storedProcesses = Globals.processPool.value
          .where((processModel) => entityIds.contains(processModel.entityId))
          .map((processModel) => Bloc.fromProcess(processModel))
          .toList();
      return storedProcesses;
    } catch (err) {
      log(err.toString());
      throw RestoreError("There was an error loading processes from the pool");
    }
  }

  List<Bloc> getStoredPosts(List<EntityModel> entities) {
    try {
      final storedPosts = List<Bloc>();
      for (final entity in entities) {
        if (entity.feed.hasValue) {
          entity.feed.value.items.forEach((post) {
            if (!(post is FeedPost)) return;
            storedPosts.add(Bloc.fromPost(entity, post));
          });
        }
      }
      return storedPosts;
    } catch (err) {
      log(err.toString());
      throw RestoreError("There was an error loading processes from the pool");
    }
  }

  int _sortBlocs(Bloc a, Bloc b) {
    if (!(a.date is DateTime) && !(b.date is DateTime))
      return 0;
    else if (!(a.date is DateTime))
      return -1;
    else if (!(b.date is DateTime)) return 1;
    return b.date.compareTo(a.date);
  }
}
