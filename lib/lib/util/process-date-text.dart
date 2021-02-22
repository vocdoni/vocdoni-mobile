import 'package:flutter/material.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/i18n.dart';

String parseProcessDate(ProcessModel process, BuildContext context) {
  final now = DateTime.now();

  if (process.startDate.hasValue && process.startDate.value.isAfter(now)) {
    Duration diff = process.startDate.value.difference(DateTime.now());
    if (diff.isNegative)
      diff = DateTime.now().difference(process.startDate.value);
    if (diff.inSeconds < 1) return getText(context, "main.starting");
    return getText(context, "main.startsIn").replaceAll("{{DATE}}",
        getFriendlyWordTimeDifference(process.startDate.value, context));
  } else if (process.endDate.hasValue && process.endDate.value.isAfter(now))
    return getText(context, "main.endsIn").replaceAll("{{DATE}}",
        getFriendlyWordTimeDifference(process.endDate.value, context));
  else if (process.endDate.hasValue &&
      process.endDate.value.isAtSameMomentAs(now))
    return getText(context, "main.ending");
  else if (process.endDate.hasValue && process.endDate.value.isBefore(now))
    return getText(context, "main.endedDateAgo").replaceAll("{{DATE}}",
        getFriendlyWordTimeDifference(process.endDate.value, context));
  else
    return "";
}

/// getFriendlyTimeDifference prints a friendly difference between two times (eg. 3d) If secondDate is not set, defaults to now
String getFriendlyTimeDifference(DateTime date, BuildContext context,
    {DateTime secondDate}) {
  if (!(date is DateTime)) return throw Exception("Invalid date");
  if (secondDate == null) secondDate = DateTime.now();
  Duration diff = date.difference(secondDate);
  if (diff.isNegative) diff = secondDate.difference(date);

  if (diff.inSeconds <= 0)
    return getText(context, "main.now");
  else if (diff.inDays >= 365)
    return getText(context, "main.numY")
        .replaceFirst("{{NUM}}", (diff.inDays / 365).floor().toString());
  else if (diff.inDays >= 30)
    return getText(context, "main.numMo")
        .replaceFirst("{{NUM}}", (diff.inDays / 28).floor().toString());
  else if (diff.inDays >= 1)
    return getText(context, "main.numD")
        .replaceFirst("{{NUM}}", diff.inDays.toString());
  else if (diff.inHours >= 1)
    return getText(context, "main.numH")
        .replaceFirst("{{NUM}}", diff.inHours.toString());
  else if (diff.inMinutes >= 1)
    return getText(context, "main.numMin")
        .replaceFirst("{{NUM}}", (diff.inMinutes + 1).toString());
  else
    return getText(context, "main.numS")
        .replaceFirst("{{NUM}}", "~" + diff.inSeconds.toString());
}

String getFriendlyWordTimeDifference(DateTime date, BuildContext context) {
  if (!(date is DateTime)) return throw Exception("Invalid date");

  Duration diff = date.difference(DateTime.now());
  if (diff.isNegative) diff = DateTime.now().difference(date);

  if (diff.inSeconds <= 0)
    return getText(context, "main.now");
  else if (diff.inDays >= 730)
    return getText(context, "main.numYears")
        .replaceFirst("{{NUM}}", (diff.inDays / 365).floor().toString());
  else if (diff.inDays >= 365)
    return getText(context, "main.numYear")
        .replaceFirst("{{NUM}}", (diff.inDays / 365).floor().toString());
  else if (diff.inDays >= 60)
    return getText(context, "main.numMonths")
        .replaceFirst("{{NUM}}", (diff.inDays / 28).floor().toString());
  else if (diff.inDays >= 30)
    return getText(context, "main.numMonth")
        .replaceFirst("{{NUM}}", (diff.inDays / 28).floor().toString());
  else if (diff.inDays >= 2)
    return getText(context, "main.numDays")
        .replaceFirst("{{NUM}}", diff.inDays.toString());
  else if (diff.inDays >= 1)
    return getText(context, "main.numDay")
        .replaceFirst("{{NUM}}", diff.inDays.toString());
  else if (diff.inHours >= 2)
    return getText(context, "main.numHours")
        .replaceFirst("{{NUM}}", diff.inHours.toString());
  else if (diff.inHours >= 1)
    return getText(context, "main.numHour")
        .replaceFirst("{{NUM}}", diff.inHours.toString());
  else if (diff.inMinutes >= 2)
    return getText(context, "main.numMinutes")
        .replaceFirst("{{NUM}}", (diff.inMinutes + 1).toString());
  else if (diff.inMinutes >= 1)
    return getText(context, "main.numMinutes")
        .replaceFirst("{{NUM}}", (diff.inMinutes + 1).toString());
  else if (diff.inSeconds >= 1)
    return getText(context, "main.numSeconds")
        .replaceFirst("{{NUM}}", "~" + diff.inSeconds.toString());
  else
    return getText(context, "main.numSecond")
        .replaceFirst("{{NUM}}", "~" + diff.inSeconds.toString());
}
