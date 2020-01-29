import 'package:flutter/material.dart';
import 'package:vocdoni/lib/state-notifier.dart';

// --------------------------------------------------------------------------
// NOTIFIER LISTENERS
// ---------------------------------------------------------------------------

/// StateNotifierListener allows to chain several `ChangeNotifierProvider.value()` calls
/// into just one.
///
/// Instead of nesting calls and builders for every model:
/// ```dart
/// return ChangeNotifierProvider.value(
///    value: myModel.metadata,
///    child: Builder(
///       builder: (context) => ChangeNotifierProvider.value(
///           // Rebuild when metadata changes
///           value: myModel.processes,
///           child: Builder(
///              builder: (context) => ChangeNotifierProvider.value(
///                 // Rebuild when processes changes
///                 value: myModel.feed,
///                 child: Builder(
///                     // Rebuild when feed changes
///                     builder: (context) => Container(...),
///                 )
///              ),
///           ),
///        ),
///     ),
/// );
/// ```
///
/// Now you can simply invoke:
/// ```dart
/// return StateNotifierListener(
///    values: [myModel.metadata, myModel.processes, myModel.feed],
///    builder: (context) => Container(...),
/// );
/// ```
///
class StateNotifierListener extends StatefulWidget {
  final List<StateNotifier> values;
  final Function(BuildContext) builder;

  StateNotifierListener({@required this.values, @required this.builder});

  @override
  _StateNotifierListenerState createState() => _StateNotifierListenerState();
}

class _StateNotifierListenerState extends State<StateNotifierListener> {
  int _buildCount = 0;
  void Function() _listener;

  @override
  void initState() {
    super.initState();

    _listener = () => setState(() => _buildCount++);
    assert(widget.values is List);

    for (final item in widget.values) {
      item.addListener(_listener);
    }
  }

  @override
  void dispose() {
    assert(widget.values is List);

    for (final item in widget.values) {
      item.removeListener(_listener);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
