import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sky_player/src/models/audio_track.dart';
import 'package:sky_player/src/models/cues.dart';
import 'package:sky_player/src/models/subtitle_track.dart';
import 'package:sky_player/src/models/video_resolution.dart';

import 'video_player_method_channel.dart';

/// Abstract platform interface for video player implementations.
/// This defines the contract that all platform-specific implementations must follow.
abstract class VideoPlayerPlatform extends PlatformInterface {
  VideoPlayerPlatform() : super(token: _token);

  // Token for verifying correct platform interface implementations
  static final Object _token = Object();

  // Default implementation uses method channel
  static VideoPlayerPlatform _instance = MethodChannelVideoPlayer();

  /// Current active platform implementation
  static VideoPlayerPlatform get instance => _instance;

  /// Override platform implementation (e.g., for tests or mocks)
  static set instance(VideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize logger for native player
  Future<void> initLogger(
      {required bool debug, bool fileLogging = false}) async {
    throw UnimplementedError('initLogger() has not been implemented.');
  }

  // -------------------------------
  // Core player operations
  // -------------------------------

  /// Creates a native texture for video rendering
  Future<int?> createTexture() async {
    throw UnimplementedError('createTexture() has not been implemented.');
  }

  /// Sets the size of the native video surface
  Future<void> setSurfaceSize(int width, int height) async {
    throw UnimplementedError('setSurfaceSize() has not been implemented.');
  }

  /// Initializes player with an HLS URL
  Future<void> initPlayerWithNetwork(String url) {
    throw UnimplementedError(
        'initPlayerWithNetwork() has not been implemented.');
  }

  /// Releases the player
  Future<void> releasePlayer() {
    throw UnimplementedError('releasePlayer() has not been implemented.');
  }

  /// Playback controls
  Future<void> play() =>
      throw UnimplementedError('play() has not been implemented.');
  Future<void> pause() =>
      throw UnimplementedError('pause() has not been implemented.');
  Future<void> seekTo(int position) =>
      throw UnimplementedError('seekTo() has not been implemented.');

  /// Track selection
  Future<void> setResolution(String? resolutionId) =>
      throw UnimplementedError('setResolution() has not been implemented.');
  Future<void> setAudioTrack(String? trackId) =>
      throw UnimplementedError('setAudioTrack() has not been implemented.');
  Future<void> setSubtitleTrack(String? trackId) =>
      throw UnimplementedError('setSubtitleTrack() has not been implemented.');

  // -------------------------------
  // State streams
  // -------------------------------

  /// Texture ID stream for Flutter rendering
  Stream<int?> get textureIdStream =>
      throw UnimplementedError('textureIdStream has not been implemented.');

  /// Video aspect ratio (width / height)
  Stream<double?> get videoAspectRatio =>
      throw UnimplementedError('videoAspectRatio has not been implemented.');

  /// True if video is currently playing
  Stream<bool> get isPlayingStream =>
      throw UnimplementedError('isPlayingStream has not been implemented.');

  /// Playback position in milliseconds
  Stream<int> get positionStream =>
      throw UnimplementedError('positionStream has not been implemented.');

  /// Total video duration in milliseconds
  Stream<int> get durationStream =>
      throw UnimplementedError('durationStream has not been implemented.');

  /// Current buffering state in milliseconds
  Stream<int> get bufferingStream =>
      throw UnimplementedError('bufferingStream has not been implemented.');

  /// Indicates if player is loading content
  Stream<bool> get isLoadingStream =>
      throw UnimplementedError('isLoadingStream has not been implemented.');

  /// Indicates if native player controls are enabled
  Stream<bool> get isNativeControlsEnabled => throw UnimplementedError(
      'isNativeControlsEnabled has not been implemented.');

  // -------------------------------
  // Track & subtitle info
  // -------------------------------

  Stream<String?> get selectedResolutionId => throw UnimplementedError(
      'selectedResolutionId has not been implemented.');
  Stream<List<VideoResolution>> get availableVideoResolutions =>
      throw UnimplementedError(
          'availableVideoResolutions has not been implemented.');

  Stream<String?> get selectedAudioTrackId => throw UnimplementedError(
      'selectedAudioTrackId has not been implemented.');
  Stream<List<AudioTrack>> get availableAudioTracks => throw UnimplementedError(
      'availableAudioTracks has not been implemented.');

  Stream<String?> get selectedSubtitleTrackId => throw UnimplementedError(
      'selectedSubtitleTrackId has not been implemented.');
  Stream<List<SubtitleTrack>> get availableSubtitleTracks =>
      throw UnimplementedError(
          'availableSubtitleTracks has not been implemented.');

  /// Provides active cues, useful for subtitles or timed metadata
  Stream<Cues> get currentCues =>
      throw UnimplementedError('currentCues has not been implemented.');
}
