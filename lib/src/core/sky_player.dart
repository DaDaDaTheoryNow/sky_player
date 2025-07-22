// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:sky_player/src/core/sky_player_controller.dart';
import 'package:sky_player/src/core/sky_player_state.dart';
import 'package:sky_player/src/utils/orientation_listener_widget.dart';

class SkyPlayer extends StatefulWidget {
  final String url;
  final SkyPlayerController? controller;

  /// If true, the player will automatically enter fullscreen mode
  /// when the device is rotated to landscape, and automatically exit
  /// fullscreen mode when rotated back to portrait. This helps provide
  /// a native-like video experience, especially on mobile devices.
  ///
  /// Note: Only the main player (not fullscreen instance) will react to
  /// landscape and open fullscreen. Only the fullscreen instance will react
  /// to portrait and close itself.
  final bool autoEnterExitFullScreenMode;

  final Widget Function(BuildContext context, SkyPlayerState state,
      SkyPlayerController controller)? overlayBuilder;

  // Helps detect fullscreen mode
  // to prevent two platform views
  // this means that when you open full screen mode the previous one disappears
  final bool _isFullScreenInstance;

  const SkyPlayer({
    required this.url,
    this.controller,
    this.overlayBuilder,
    this.autoEnterExitFullScreenMode = false,
    super.key,
  }) : _isFullScreenInstance = false;

  const SkyPlayer._fullscreen({
    required this.url,
    required this.controller,
    this.overlayBuilder,
    required this.autoEnterExitFullScreenMode,
  }) : _isFullScreenInstance = true;

  factory SkyPlayer.network(
    String url, {
    SkyPlayerController? controller,
    Widget Function(BuildContext context, SkyPlayerState state,
            SkyPlayerController controller)?
        overlayBuilder,
    bool autoEnterExitFullScreenMode = false,
    Key? key,
  }) =>
      SkyPlayer(
        key: key,
        url: url,
        controller: controller,
        overlayBuilder: overlayBuilder,
        autoEnterExitFullScreenMode: autoEnterExitFullScreenMode,
      );

  @override
  State<SkyPlayer> createState() => _SkyPlayerState();
}

class _SkyPlayerState extends State<SkyPlayer> {
  late final SkyPlayerController _controller;
  late final bool _isLocalController;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isLocalController = false;
    } else {
      _controller = SkyPlayerController()..initPlayer(widget.url);
      _isLocalController = true;
    }
  }

  @override
  void dispose() {
    if (_isLocalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SkyPlayerState>(
      stream: _controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;

        return _SkyPlayerWithControls(
          url: widget.url,
          state: state ?? SkyPlayerState.initial(),
          controller: _controller,
          overlayBuilder: widget.overlayBuilder,
          isFullScreenInstance: widget._isFullScreenInstance,
          autoEnterExitFullScreenMode: widget.autoEnterExitFullScreenMode,
        );
      },
    );
  }
}

// Builds a player with a control overlay
class _SkyPlayerWithControls extends StatefulWidget {
  final SkyPlayerController controller;
  final SkyPlayerState state;
  final String url;
  final bool isFullScreenInstance;
  final bool autoEnterExitFullScreenMode;

  final Widget Function(BuildContext context, SkyPlayerState state,
      SkyPlayerController controller)? overlayBuilder;

  const _SkyPlayerWithControls({
    required this.url,
    required this.state,
    required this.controller,
    this.overlayBuilder,
    this.isFullScreenInstance = false,
    this.autoEnterExitFullScreenMode = false,
  });

  @override
  State<_SkyPlayerWithControls> createState() => _SkyPlayerWithControlsState();
}

class _SkyPlayerWithControlsState extends State<_SkyPlayerWithControls>
    with WidgetsBindingObserver {
  SkyPlayerController get _controller => widget.controller;

  // Fullscreen was opened by autorotate
  bool _autoFullScreenEntered = false;

  @override
  void initState() {
    super.initState();
    _controller.isFullScreen.addListener(_onFullScreenChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _controller.isFullScreen.removeListener(_onFullScreenChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onFullScreenChanged() {
    if (_controller.isFullScreen.value) {
      _openFullScreen();
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _openFullScreen() async {
    if (_controller.url != null) {
      // Set device orientation to landscape when entering fullscreen
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: SkyPlayer._fullscreen(
                url: _controller.url!,
                controller: _controller,
                overlayBuilder: widget.overlayBuilder,
                autoEnterExitFullScreenMode: widget.autoEnterExitFullScreenMode,
              ),
            ),
          ),
        ),
      );

      if (_autoFullScreenEntered) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        // Then we resolve all orientations through a small delay
        await Future.delayed(const Duration(milliseconds: 200));
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

        _autoFullScreenEntered = false;
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      _controller.closeFullScreen();
    }
  }

  void _closeFullscreenWithPop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationListener(
      onOrientationChange: (orientation) {
        // Entering fullscreen mode if we rotated the device to landscape mode
        if (!widget.isFullScreenInstance &&
            widget.autoEnterExitFullScreenMode &&
            orientation == Orientation.landscape &&
            !_controller.isFullScreen.value) {
          _autoFullScreenEntered = true;
          _controller.openFullScreen();
        }

        // Exit fullscreen mode when returning to portrait
        if (widget.isFullScreenInstance &&
            widget.autoEnterExitFullScreenMode &&
            orientation == Orientation.portrait) {
          _closeFullscreenWithPop();
        }
      },
      child: widget.isFullScreenInstance
          ? _buildPlayer()
          : ValueListenableBuilder<bool>(
              valueListenable: _controller.isFullScreen,
              builder: (context, isFullScreen, child) {
                if (isFullScreen) {
                  return const SizedBox.shrink();
                }
                return _buildPlayer();
              },
            ),
    );
  }

  Widget _buildPlayer() {
    Widget playerWidget;
    if (Platform.isAndroid) {
      playerWidget = PlatformViewLink(
        viewType: 'sky_player_view',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'sky_player_view',
            layoutDirection: TextDirection.ltr,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (Platform.isIOS) {
      playerWidget = UiKitView(
        viewType: 'sky_player_view',
        layoutDirection: TextDirection.ltr,
        creationParams: {
          'url':
              "https://playertest.longtailvideo.com/adaptive/elephants_dream_v4/index.m3u8"
        },
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      playerWidget = const Center(child: Text('Platform not available'));
    }

    return Stack(
      children: [
        playerWidget,
        // Overlay with player controls
        if (widget.overlayBuilder != null &&
            !widget.state.isNativeControlsEnabled)
          widget.overlayBuilder!(context, widget.state, _controller),
      ],
    );
  }
}
