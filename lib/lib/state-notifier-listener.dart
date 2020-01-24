import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocdoni/lib/state-notifier.dart';

// --------------------------------------------------------------------------
// NOTIFIER LISTENERS
// ---------------------------------------------------------------------------

/// StateNotifierListener allows to chain several `ChangeNotifierProvider.value()` calls
/// into just one.
///
/// Instead of nesting calls for every model:
/// ```dart
/// return ChangeNotifierProvider.value(
///    value: myModel.metadata,
///    child: ChangeNotifierProvider.value(
///       value: myModel.processes,
///       child: ChangeNotifierProvider.value(
///          value: myModel.feed,
///          child: Container(...),
///       ),
///    ),
/// );
/// ```
///
/// Now you can simply invoke:
/// ```dart
/// return StateNotifierListener(
///    values: [myModel.metadata, myModel.processes, myModel.feed],
///    child: Container(...),
/// );
/// ```
///
class StateNotifierListener extends StatelessWidget {
  final List<StateNotifier> values;
  final Widget child;

  StateNotifierListener({@required this.values, @required this.child});

  @override
  Widget build(BuildContext context) {
    if (!(values is List) || values.length == 0)
      return child;
    else if (values.length == 1) {
      return ChangeNotifierProvider.value(
        value: values[0],
        child: child,
      );
    } else {
      return ChangeNotifierProvider.value(
        value: values[0],
        child: StateNotifierListener(
          values: values.sublist(1),
          child: child,
        ),
      );
    }
  }
}
