import 'package:flutter/material.dart';

/// A widget that listens to orientation changes and notifies via a callback.
/// Useful for handling layout adjustments or player fullscreen changes when
/// device orientation changes.
class OrientationListener extends StatefulWidget {
  /// The child widget to display.
  final Widget child;

  /// Callback triggered whenever the device orientation changes.
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
  Orientation? _lastOrientation; // Stores the last known orientation
  bool _isFirstBuild = true; // Flag to skip callback on first build

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final orientation = MediaQuery.of(context).orientation;

    // Only trigger callback if orientation changed
    if (_lastOrientation != orientation) {
      if (!_isFirstBuild) {
        // Schedule the callback after the frame to avoid build conflicts
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
