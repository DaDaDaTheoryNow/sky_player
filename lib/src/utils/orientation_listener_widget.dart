import 'package:flutter/material.dart';

class OrientationListener extends StatefulWidget {
  final Widget child;
  final void Function(Orientation orientation) onOrientationChange;

  const OrientationListener({
    super.key,
    required this.child,
    required this.onOrientationChange,
  });

  @override
  State<OrientationListener> createState() => _OrientationListenerState();
}

class _OrientationListenerState extends State<OrientationListener> {
  Orientation? _lastOrientation;
  bool _isFirstBuild = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      if (!_isFirstBuild) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onOrientationChange(orientation);
        });
      }
      _lastOrientation = orientation;
      _isFirstBuild = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
