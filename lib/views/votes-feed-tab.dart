import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/listItem.dart';

class VotesFeedTab extends StatelessWidget {
  final List votes;

  VotesFeedTab({this.votes});

  @override
  Widget build(ctx) {
    if (votes == null || votes.length == 0) return buildNoVotes(ctx);

    // TODO: UI

    return ListView.builder(
        itemCount: votes.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final vote = votes[index];
          return ListItem(text: vote.name, onTap: () => onTapVote(ctx, vote));
        });
  }

  Widget buildNoVotes(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("(No votes available)"),
    );
  }

  onTapVote(BuildContext ctx, dynamic vote) {
    // TODO: CREATE PAGE
    Navigator.pushNamed(ctx, "/votes/info", arguments: vote);
  }
}
