import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sky_player/sky_player.dart';
import 'package:sky_player/src/video_player/video_player_platform_interface.dart';

/// Controller for SkyPlayer widget.
///
/// - Keeps a BehaviorSubject of the current UI state.
/// - Subscribes to native/platform streams and maps them to SkyPlayerState.
/// - Provides high-level control API (play/pause/seek/etc).
class SkyPlayerController {
  final VideoPlayerPlatform _platform;

  /// Last initialized URL (nullable).
  String? _url;
  String? get url => _url;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// BehaviorSubject holding the current state. Seeded with initial state.
  final BehaviorSubject<SkyPlayerState> _stateSubject =
      BehaviorSubject.seeded(SkyPlayerState.initial());

  /// Exposed read-only stream of state updates.
  Stream<SkyPlayerState> get stateStream => _stateSubject.stream;

  /// Synchronous access to current state snapshot.
  SkyPlayerState get currentState => _stateSubject.value;

  /// Internal list of platform subscriptions to cancel on dispose.
  final List<StreamSubscription> _platformSubs = [];

  /// Prevent double dispose.
  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// Prevent concurrent initPlayer calls.
  Future<void>? _initFuture;

  /// Constructor.
  ///
  /// - `platform` is injected to enable unit testing.
  SkyPlayerController({
    VideoPlayerPlatform? platform,
  }) : _platform = platform ?? VideoPlayerPlatform.instance {
    _subscribeToPlatformStreams();
  }

  /// Initialize the player logger.
  ///
  /// - If [isDebug] is `true`, logs will appear in Logcat / console for debugging.
  /// - If [isDebug] is `false` and [fileLogging] is `true`, logs will be written on Android
  ///   to a file at `/storage/emulated/0/Android/data/<package_name>/files/skyplayer.log` (rotates at 1MB).
  static void initLogger({
    bool isDebug = false,
    bool fileLogging = false,
  }) {
    VideoPlayerPlatform.instance
        .initLogger(debug: isDebug, fileLogging: fileLogging);
  }

  // ---------------------------
  // Initialization / lifecycle
  // ---------------------------

  Future<void> initOrSwitchToUrl(String url) async {
    if (!_initialized) {
      await _initPlayer(url, isWithCreateTexture: true);
      _initialized = true;
      _url = url;
      return;
    }

    if (_url != url) {
      await _initPlayer(url, isWithCreateTexture: false);
      _url = url;
    }
  }

  /// Initialize native player with provided URL.
  ///
  /// The method is idempotent: concurrent calls will return same future.
  Future<void> _initPlayer(String url, {bool isWithCreateTexture = true}) {
    if (_disposed) {
      return Future.error(StateError('Controller already disposed'));
    }

    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _initPlayerInternal(url);

    // When done, clear _initFuture so re-init is possible if desired.
    return _initFuture!.whenComplete(() {
      _initFuture = null;
    });
  }

  Future<void> _initPlayerInternal(String url,
      {bool isWithCreateTexture = true}) async {
    _url = url;
    try {
      // Initialize player (Network data source) on platform side.
      await _platform.initPlayerWithNetwork(url);

      if (isWithCreateTexture) {
        // Create native texture (platform may emit textureId via textureIdStream).
        await _createNativeTexture();
      }
    } catch (e, st) {
      debugPrint('SkyPlayerController: initPlayerWithNetwork failed: $e\n$st');
      rethrow;
    }
  }

  /// Opens a new fullscreen Route containing a SkyPlayer fullscreen instance
  /// that uses *this* controller (so playback continues in the same player).
  ///
  /// - [context] is required to push the route.
  /// - [url] is optional: if provided it will be initialized (or switched to).
  ///   If not provided, the controller must already have a valid url.
  /// - [aspectMode], [language], [overlayBuilder] forwarded to fullscreen widget.
  ///
  Future<void> openFullScreenExternally(
    BuildContext context, {
    String? url,
    SkyPlayerAspectMode aspectMode = SkyPlayerAspectMode.auto,
    SkyPlayerLanguages language = SkyPlayerLanguages.en,
    Widget Function(BuildContext, SkyPlayerState, SkyPlayerController)?
        overlayBuilder,
    @internal bool forceDisposeController = true,
  }) async {
    // Ensure controller has URL initialized or initialize it now.
    final targetUrl = url ?? _url;

    if (targetUrl == null || targetUrl.isEmpty) {
      throw ArgumentError.value(
          targetUrl, 'url', 'No URL provided and controller has no url.');
    }

    // Initialize if needed (creates texture etc).
    if (!_initialized || _url != targetUrl) {
      await initOrSwitchToUrl(targetUrl);
    }

    // Mark state as fullscreen so overlays that depend on it will update.
    if (!currentState.isFullscreen) {
      setFullScreen(true);
    }

    // Hide system chrome and lock to landscape for fullscreen experience.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Push fullscreen route. On pop we restore UI and orientation and clear state.
    // ignore: use_build_context_synchronously
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) return;

            closeFullscreenPlayerWithPop(ctx);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SkyPlayer.fullscreen(
              url: targetUrl,
              controller: this,
              aspectMode: aspectMode,
              overlayBuilder: overlayBuilder ?? SkyPlayer.defaultOverlayBuilder,
              autoFullscreenOnRotate: false,
              language: language,
              forceDisposeController: forceDisposeController,
            ),
          ),
        ),
      ),
    );

    setFullScreen(false);

    // After returning, restore system chrome and orientations and state.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // A short delay gives the platform time to apply the orientation.
    await Future.delayed(const Duration(milliseconds: 200));
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void closeFullscreenPlayerWithPop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Dispose controller, cancel subscriptions and close subject.
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _initialized = false;
    _url = null;

    // pause();
    _releasePlayer();

    for (final s in _platformSubs) {
      try {
        s.cancel();
      } catch (e, st) {
        debugPrint('SkyPlayerController: dispose failed: $e\n$st');
      }
    }
    _platformSubs.clear();

    try {
      _stateSubject.close();
    } catch (e, st) {
      debugPrint('SkyPlayerController: dispose failed: $e\n$st');
    }
  }

  // ---------------------------
  // Internal methods
  // ---------------------------
  Future<int?> _createNativeTexture() => _platform.createTexture();
  Future<void> _releasePlayer() => _platform.releasePlayer();

  // ---------------------------
  // Public API methods
  // ---------------------------

  Future<void> setSurfaceSize(int width, int height) =>
      _safePlatformCall(() => _platform.setSurfaceSize(width, height));

  Future<void> play() => _safePlatformCall(() => _platform.play());

  Future<void> pause() => _safePlatformCall(() => _platform.pause());

  Future<void> seekTo(int position) =>
      _safePlatformCall(() => _platform.seekTo(position));

  Future<void> setResolution(String? resolutionId) =>
      _safePlatformCall(() => _platform.setResolution(resolutionId));

  Future<void> setAudioTrack(String? trackId) =>
      _safePlatformCall(() => _platform.setAudioTrack(trackId));

  Future<void> setSubtitleTrack(String? trackId) =>
      _safePlatformCall(() => _platform.setSubtitleTrack(trackId));

  // ---------------------------
  // Fullscreen helpers (local state only)
  // ---------------------------

  void setFullScreen(bool isFullscreen) =>
      _updateState((s) => s.copyWith(isFullscreen: isFullscreen));

  // ---------------------------
  // Overlay Language
  // ---------------------------

  void setOverlayLanguage(SkyPlayerLanguages language) =>
      _updateState((s) => s.copyWith(language: language));

  // ---------------------------
  // Platform streams (exposed for tests / advanced usage)
  // ---------------------------

  Stream<int?> get textureIdStream => _platform.textureIdStream;
  Stream<double?> get videoAspectRatio => _platform.videoAspectRatio;
  Stream<bool> get isPlayingStream => _platform.isPlayingStream;
  Stream<int> get positionStream => _platform.positionStream;
  Stream<int> get durationStream => _platform.durationStream;
  Stream<bool> get isLoadingStream => _platform.isLoadingStream;
  Stream<int> get bufferingStream => _platform.bufferingStream;
  Stream<String?> get selectedResolutionId => _platform.selectedResolutionId;
  Stream<List<VideoResolution>> get availableVideoResolutions =>
      _platform.availableVideoResolutions;
  Stream<String?> get selectedAudioTrackId => _platform.selectedAudioTrackId;
  Stream<List<AudioTrack>> get availableAudioTracks =>
      _platform.availableAudioTracks;
  Stream<String?> get selectedSubtitleTrackId =>
      _platform.selectedSubtitleTrackId;
  Stream<List<SubtitleTrack>> get availableSubtitleTracks =>
      _platform.availableSubtitleTracks;
  Stream<Cues> get currentCues => _platform.currentCues;

  // ---------------------------
  // Internal helpers
  // ---------------------------

  /// Centralized subscription logic: map stream values to state changes using `updater`.
  void _bindStream<T>(
    Stream<T> stream,
    SkyPlayerState Function(SkyPlayerState base, T value) updater,
  ) {
    final sub = stream.listen((value) {
      try {
        _updateState((prev) => updater(prev, value));
      } catch (e, st) {
        debugPrint('SkyPlayerController: _bindStream failed: $e\n$st');
      }
    }, onError: (Object e, StackTrace st) {
      debugPrint('SkyPlayerController: _bindStream failed: $e\n$st');
    });
    _platformSubs.add(sub);
  }

  /// Subscribe to all relevant platform streams using a single helper.
  void _subscribeToPlatformStreams() {
    _bindStream<bool>(
        isPlayingStream, (prev, v) => prev.copyWith(isPlaying: v));
    _bindStream<int>(positionStream, (prev, v) => prev.copyWith(position: v));
    _bindStream<int>(durationStream, (prev, v) => prev.copyWith(duration: v));
    _bindStream<int>(bufferingStream, (prev, v) => prev.copyWith(buffering: v));
    _bindStream<bool>(
        isLoadingStream, (prev, v) => prev.copyWith(isLoading: v));
    _bindStream<double?>(
        videoAspectRatio, (prev, v) => prev.copyWith(videoAspectRatio: v));
    _bindStream<String?>(selectedResolutionId,
        (prev, v) => prev.copyWith(selectedResolutionId: v));
    _bindStream<List<VideoResolution>>(availableVideoResolutions,
        (prev, v) => prev.copyWith(availableVideoResolutions: v));
    _bindStream<String?>(selectedAudioTrackId,
        (prev, v) => prev.copyWith(selectedAudioTrackId: v));
    _bindStream<List<AudioTrack>>(availableAudioTracks,
        (prev, v) => prev.copyWith(availableAudioTracks: v));
    _bindStream<String?>(selectedSubtitleTrackId,
        (prev, v) => prev.copyWith(selectedSubtitleTrackId: v));
    _bindStream<List<SubtitleTrack>>(availableSubtitleTracks,
        (prev, v) => prev.copyWith(availableSubtitleTracks: v));
    _bindStream<int?>(
        textureIdStream, (prev, v) => prev.copyWith(textureId: v));
    _bindStream<Cues>(currentCues, (prev, v) => prev.copyWith(currentCues: v));
  }

  /// Thread-safe-ish update for BehaviorSubject state.
  ///
  /// Note: this is still only safe inside single isolate. If you expect
  /// concurrent mutations from multiple isolates, use another architecture.
  void _updateState(SkyPlayerState Function(SkyPlayerState) updater) {
    if (_disposed || _stateSubject.isClosed) return;

    try {
      final prev = _stateSubject.value;
      final next = updater(prev);
      // Optionally avoid pushing equal states if SkyPlayerState implements equality.
      _stateSubject.add(next);
    } catch (e, st) {
      debugPrint('SkyPlayerController: _updateState failed: $e\n$st');
    }
  }

  /// Wrapper to call platform APIs with centralized error logging.
  Future<T> _safePlatformCall<T>(Future<T> Function() call) async {
    if (_disposed) {
      return Future.error(StateError('Controller already disposed'));
    }
    try {
      return await call();
    } catch (e, st) {
      debugPrint('SkyPlayerController: _safePlatformCall failed: $e\n$st');
      rethrow;
    }
  }
}
