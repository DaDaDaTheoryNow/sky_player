import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import 'package:sky_player/sky_player.dart';
import 'package:sky_player/src/overlay/sky_player_basic_overlay.dart';
import 'package:sky_player/src/subtitles/subtitles_render_widget.dart';
import 'package:sky_player/src/utils/orientation_listener_widget.dart';

/// SkyPlayer — wrapper widget around the native player.
/// Supports fullscreen mode, automatic orientation transitions,
/// subtitle rendering and overlay delegation.

class SkyPlayer extends StatefulWidget {
  final String url;
  final SkyPlayerController? controller;
  final bool autoFullscreenOnRotate;
  final SkyPlayerAspectMode aspectMode;
  final SkyPlayerLanguages language;
  final bool forceDisposeController;

  /// Builder for the overlay (controls, buttons, etc.).
  final Widget Function(BuildContext, SkyPlayerState, SkyPlayerController)?
      overlayBuilder;

  /// Internal flag marking a fullscreen instance (created only when entering fullscreen).
  final bool _isFullScreenInstance;

  @internal
  const SkyPlayer({
    required this.url,
    this.controller,
    this.autoFullscreenOnRotate = false,
    this.aspectMode = SkyPlayerAspectMode.auto,
    this.overlayBuilder = defaultOverlayBuilder,
    this.language = SkyPlayerLanguages.en,
    this.forceDisposeController = false,
    super.key,
  }) : _isFullScreenInstance = false;

  /// Network constructor
  factory SkyPlayer.network(
    String url, {
    bool autoFullscreenOnRotate = false,
    SkyPlayerAspectMode aspectMode = SkyPlayerAspectMode.auto,
    SkyPlayerLanguages language = SkyPlayerLanguages.en,
    Widget Function(BuildContext, SkyPlayerState, SkyPlayerController)?
        overlayBuilder = defaultOverlayBuilder,
    Key? key,
  }) =>
      SkyPlayer(
        key: key,
        url: url,
        controller: null,
        autoFullscreenOnRotate: autoFullscreenOnRotate,
        aspectMode: aspectMode,
        overlayBuilder: overlayBuilder,
        language: language,
      );

  @internal
  const SkyPlayer.fullscreen({
    super.key,
    required this.url,
    required this.controller,
    required this.autoFullscreenOnRotate,
    required this.aspectMode,
    required this.language,
    this.overlayBuilder = defaultOverlayBuilder,
    this.forceDisposeController = false,
  }) : _isFullScreenInstance = true;

  static Widget defaultOverlayBuilder(
    BuildContext context,
    SkyPlayerState state,
    SkyPlayerController controller,
  ) {
    return SkyPlayerBasicOverlay(
      state: state,
      controller: controller,
      localization: SkyPlayerLocalization(language: state.language),
    );
  }

  @override
  State<SkyPlayer> createState() => _SkyPlayerState();
}

class _SkyPlayerState extends State<SkyPlayer> {
  late final SkyPlayerController _controller;
  late final bool _ownsController;

  @override
  void dispose() {
    // Dispose only controllers we created (avoid double-dispose).
    // If controller is not owned by this widget, it is expected to be disposed by the caller.
    if (_ownsController || widget.forceDisposeController) {
      debugPrint('SkyPlayer: Disposing controller');
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? SkyPlayerController();
    _ownsController = widget.controller == null;

    if (!_controller.isInitialized) {
      unawaited(_controller.initOrSwitchToUrl(widget.url));
    }

    _controller.setOverlayLanguage(widget.language);
  }

  @override
  void didUpdateWidget(covariant SkyPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the URL changed → reinitialize
    if (widget.url != oldWidget.url && !_controller.isDisposed) {
      unawaited(_controller.initOrSwitchToUrl(widget.url));
    }

    _controller.setOverlayLanguage(widget.language);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SkyPlayerState>(
      stream: _controller.stateStream,
      // Provide a safe initial state when the stream has not emitted yet.
      builder: (context, snapshot) {
        final state = snapshot.data ?? SkyPlayerState.initial();
        return _SkyPlayerWithControls(
          url: widget.url,
          state: state,
          controller: _controller,
          overlayBuilder: widget.overlayBuilder,
          isFullScreenInstance: widget._isFullScreenInstance,
          autoFullscreenOnRotate: widget.autoFullscreenOnRotate,
          aspectMode: widget.aspectMode,
          language: widget.language,
        );
      },
    );
  }
}

/// Widget that renders the player itself together with overlay/subtitles.
class _SkyPlayerWithControls extends StatefulWidget {
  final SkyPlayerController controller;
  final SkyPlayerState state;
  final String url;
  final bool isFullScreenInstance;
  final bool autoFullscreenOnRotate;
  final SkyPlayerAspectMode aspectMode;
  final SkyPlayerLanguages language;

  final Widget Function(BuildContext, SkyPlayerState, SkyPlayerController)?
      overlayBuilder;

  const _SkyPlayerWithControls({
    required this.url,
    required this.state,
    required this.controller,
    this.isFullScreenInstance = false,
    this.autoFullscreenOnRotate = false,
    this.aspectMode = SkyPlayerAspectMode.auto,
    this.language = SkyPlayerLanguages.en,
    this.overlayBuilder,
  });

  @override
  State<_SkyPlayerWithControls> createState() => _SkyPlayerWithControlsState();
}

class _SkyPlayerWithControlsState extends State<_SkyPlayerWithControls> {
  SkyPlayerController get _controller => widget.controller;

  Timer? _surfaceSizeDebounceTimer;
  int? _lastWidthPx;
  int? _lastHeightPx;

  @override
  void dispose() {
    _surfaceSizeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Debounce sending the surface size to native code.
  void _maybeSendSurfaceSize(int widthPx, int heightPx) {
    if (_lastWidthPx == widthPx && _lastHeightPx == heightPx) return;

    _lastWidthPx = widthPx;
    _lastHeightPx = heightPx;

    _surfaceSizeDebounceTimer?.cancel();
    _surfaceSizeDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      try {
        widget.controller.setSurfaceSize(widthPx, heightPx);
      } catch (e, st) {
        debugPrint('SkyPlayer: setSurfaceSize failed: $e\n$st');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationListener(
      onOrientationChange: (orientation) {
        // When rotated to landscape, open fullscreen automatically if enabled.
        if (!widget.isFullScreenInstance &&
            widget.autoFullscreenOnRotate &&
            orientation == Orientation.landscape &&
            !widget.state.isFullscreen) {
          _controller.openFullScreenExternally(
            context,
            // Do not dispose controller after closing fullscreen.
            forceDisposeController: false,
          );
        }

        // When rotated back to portrait, close fullscreen if this is the fullscreen instance.
        if (widget.isFullScreenInstance &&
            widget.autoFullscreenOnRotate &&
            orientation == Orientation.portrait) {
          _controller.closeFullscreenPlayerWithPop(context);
        }
      },
      child: _buildPlayerStack(context),
    );
  }

  Widget _buildPlayerStack(BuildContext context) {
    final playerView = _buildPlatformPlayer(context);

    return Stack(
      children: <Widget>[
        playerView,
        if (widget.overlayBuilder != null)
          widget.overlayBuilder!(context, widget.state, _controller),
        if (widget.state.currentCues.text.isNotEmpty)
          SubtitlesRendererWidget(state: widget.state),
      ],
    );
  }

  Widget _buildPlatformPlayer(BuildContext context) {
    // Android: Texture, iOS: UiKitView, others: placeholder
    if (Platform.isAndroid) {
      return LayoutBuilder(builder: (context, constraints) {
        final textureId = widget.state.textureId;
        if (textureId == null) {
          return const ColoredBox(color: Colors.black);
        }

        final mq = MediaQuery.of(context);
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mq.size.width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mq.size.height;
        final dp = mq.devicePixelRatio;

        final (width, height) = _calculateDimensions(
          maxW: maxW,
          maxH: maxH,
          aspectRatio: widget.state.videoAspectRatio ?? (16.0 / 9.0),
        );

        // Debounce the native call for surface sizing.
        _maybeSendSurfaceSize((width * dp).round(), (height * dp).round());

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Texture(textureId: textureId),
          ),
        );
      });
    }

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'sky_player_view',
        layoutDirection: TextDirection.ltr,
        creationParams: {'url': widget.url},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    // Web / Desktop / Unsupported — show placeholder
    return const Center(child: Text('Platform not available'));
  }

  /// Calculate the display size for the player based on available space and aspect ratio.
  (double width, double height) _calculateDimensions({
    required double maxW,
    required double maxH,
    required double aspectRatio,
  }) {
    var width = maxW;
    var height = width / aspectRatio;

    if (height > maxH) {
      height = maxH;
      width = height * aspectRatio;
    }

    // Fallback if calculated dimensions are invalid.
    if (width <= 0 || height <= 0 || width.isNaN || height.isNaN) {
      width = maxW;
      height = maxW / aspectRatio;
    }

    return (width, height);
  }
}
