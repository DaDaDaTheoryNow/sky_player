import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sky_player/src/models/audio_track.dart';
import 'package:sky_player/src/models/cues.dart';
import 'package:sky_player/src/models/subtitle_track.dart';
import 'package:sky_player/src/models/video_resolution.dart';
import 'package:sky_player/src/video_player/video_player_platform_interface.dart';

/// Platform implementation using MethodChannel for SkyPlayer.
/// Responsible for sending commands to native code and exposing state streams.
class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('sky_player_channel');

  @visibleForTesting
  final EventChannel eventChannel =
      const EventChannel('sky_player_channel/playerEvents');

  late final Stream<Map<String, dynamic>> _sharedStream;

  MethodChannelVideoPlayer() {
    // Convert the native event stream into a broadcast stream of maps
    _sharedStream = eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    }).asBroadcastStream();
  }

  @override
  Future<void> initLogger(
      {required bool debug, bool fileLogging = false}) async {
    await methodChannel.invokeMethod('initLogger', {
      'debug': debug,
      'fileLogging': fileLogging,
    });
  }
  // -------------------------------
  // Core player operations
  // -------------------------------

  @override
  Future<int?> createTexture() =>
      methodChannel.invokeMethod<int>('createTexture');

  @override
  Future<void> setSurfaceSize(int width, int height) =>
      methodChannel.invokeMethod<void>(
        'setSurfaceSize',
        {'width': width, 'height': height},
      );

  @override
  Future<void> initPlayerWithNetwork(String url) => methodChannel.invokeMethod(
        'initPlayerWithNetwork',
        {'url': url},
      );

  @override
  Future<void> releasePlayer() =>
      methodChannel.invokeMethod<void>('releasePlayer');

  @override
  Future<void> play() => methodChannel.invokeMethod<void>('play');

  @override
  Future<void> pause() => methodChannel.invokeMethod<void>('pause');

  @override
  Future<void> seekTo(int position) => methodChannel.invokeMethod<void>(
        'seekTo',
        {'position': position},
      );

  @override
  Future<void> setResolution(String? resolutionId) => methodChannel
      .invokeMethod<void>('setResolution', {'resolutionId': resolutionId});

  @override
  Future<void> setAudioTrack(String? trackId) =>
      methodChannel.invokeMethod<void>('setAudioTrack', {'trackId': trackId});

  @override
  Future<void> setSubtitleTrack(String? trackId) => methodChannel
      .invokeMethod<void>('setSubtitleTrack', {'trackId': trackId});

  // -------------------------------
  // Simple state streams
  // -------------------------------

  @override
  Stream<int?> get textureIdStream =>
      _sharedStream.map((e) => e['textureId'] as int?);

  @override
  Stream<double?> get videoAspectRatio =>
      _sharedStream.map((e) => e['videoAspectRatio'] as double?);

  @override
  Stream<bool> get isPlayingStream =>
      _sharedStream.map((e) => e['isPlaying'] as bool);

  @override
  Stream<int> get positionStream =>
      _sharedStream.map((e) => e['position'] as int);

  @override
  Stream<int> get durationStream =>
      _sharedStream.map((e) => e['duration'] as int);

  @override
  Stream<int> get bufferingStream =>
      _sharedStream.map((e) => e['buffering'] as int);

  @override
  Stream<bool> get isLoadingStream =>
      _sharedStream.map((e) => e['isLoading'] as bool);

  @override
  Stream<bool> get isNativeControlsEnabled =>
      _sharedStream.map((e) => e['isNativeControlsEnabled'] as bool);

  @override
  Stream<String?> get selectedResolutionId =>
      _sharedStream.map((e) => e['selectedResolutionId'] as String?);

  @override
  Stream<String?> get selectedAudioTrackId =>
      _sharedStream.map((e) => e['selectedAudioTrackId'] as String?);

  @override
  Stream<String?> get selectedSubtitleTrackId =>
      _sharedStream.map((e) => e['selectedSubtitleTrackId'] as String?);

  // -------------------------------
  // Complex streams with JSON decoding
  // -------------------------------

  Stream<List<T>> _decodeListStream<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return _sharedStream.map((event) {
      try {
        final jsonString = event[key];
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          return decoded
              .map((e) => fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (e, stack) {
        debugPrint('Parsing error ($key): $e\n$stack');
      }
      return <T>[];
    });
  }

  @override
  Stream<List<VideoResolution>> get availableVideoResolutions =>
      _decodeListStream(
          'availableResolutions', (e) => VideoResolution.fromJson(e));

  @override
  Stream<List<AudioTrack>> get availableAudioTracks =>
      _decodeListStream('availableAudioTracks', (e) => AudioTrack.fromJson(e));

  @override
  Stream<List<SubtitleTrack>> get availableSubtitleTracks => _decodeListStream(
      'availableSubtitleTracks', (e) => SubtitleTrack.fromJson(e));

  @override
  Stream<Cues> get currentCues => _sharedStream.map((e) =>
      Cues.fromJson(Map<String, dynamic>.from(jsonDecode(e['currentCues']))));
}
