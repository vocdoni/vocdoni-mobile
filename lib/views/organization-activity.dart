import "package:flutter/material.dart";
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/feedItemCard.dart';
import 'package:vocdoni/widgets/listItem.dart';
import 'package:vocdoni/widgets/bottomNavigation.dart';
import 'package:vocdoni/widgets/pageTitle.dart';
import 'package:vocdoni/widgets/section.dart';

class OrganizationActivity extends StatelessWidget {
  final Organization organization;

  OrganizationActivity({this.organization});



  makeFakeFeed() {
    return FeedItem(
        author: "John Stark",
        title: "The Bells",
        id: "one",
        image:
            "https://vignette.wikia.nocookie.net/gameofthrones/images/5/5e/S8_E6_Daenerys.jpg/revision/latest?cb=20190515191839",
        contentHtml:
            "<p>We — Manton Reece and Brent Simmons — have noticed that JSON has become the developers’ choice for APIs, and that developers will often go out of their way to avoid XML. JSON is simpler to read and write, and it’s less prone to bugs.</p>\n\n<p>So we developed JSON Feed, a format similar to <a href=\"http://cyber.harvard.edu/rss/rss.html\">RSS</a> and <a href=\"https://tools.ietf.org/html/rfc4287\">Atom</a> but in JSON. It reflects the lessons learned from our years of work reading and publishing feeds.</p>\n\n<p><a href=\"https://jsonfeed.org/version/1\">See the spec</a>. It’s at version 1, which may be the only version ever needed. If future versions are needed, version 1 feeds will still be valid feeds.</p>\n\n<h4>Notes</h4>\n\n<p>We have a <a href=\"https://github.com/manton/jsonfeed-wp\">WordPress plugin</a> and, coming soon, a JSON Feed Parser for Swift. As more code is written, by us and others, we’ll update the <a href=\"https://jsonfeed.org/code\">code</a> page.</p>\n\n<p>See <a href=\"https://jsonfeed.org/mappingrssandatom\">Mapping RSS and Atom to JSON Feed</a> for more on the similarities between the formats.</p>\n\n<p>This website — the Markdown files and supporting resources — <a href=\"https://github.com/brentsimmons/JSONFeed\">is up on GitHub</a>, and you’re welcome to comment there.</p>\n\n<p>This website is also a blog, and you can subscribe to the <a href=\"https://jsonfeed.org/xml/rss.xml\">RSS feed</a> or the <a href=\"https://jsonfeed.org/feed.json\">JSON feed</a> (if your reader supports it).</p>\n\n<p>We worked with a number of people on this over the course of several months. We list them, and thank them, at the bottom of the <a href=\"https://jsonfeed.org/version/1\">spec</a>. But — most importantly — <a href=\"http://furbo.org/\">Craig Hockenberry</a> spent a little time making it look pretty. :)</p>\n");
  }

  @override
  Widget build(context) {
    return Scaffold(
        body: ListView.builder(
      itemCount: 3,//organization.newsFeed.length,
      itemBuilder: (BuildContext context, int index) {
        return FeedItemCard(
          organization: organization,
          feedItem: makeFakeFeed(),
        );
      },
    ));
  }
}
