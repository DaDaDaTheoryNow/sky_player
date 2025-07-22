import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sky_player/src/models/video_resolution.dart';
import 'package:sky_player/src/video_player/video_player_platform_interface.dart';

class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('sky_player_channel');

  @visibleForTesting
  final EventChannel eventChannel =
      const EventChannel('sky_player_channel/playerEvents');

  late final Stream<Map<String, dynamic>> _sharedStream;

  MethodChannelVideoPlayer() {
    _sharedStream = eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    }).asBroadcastStream();
  }

  @override
  Future<void> initPlayerWithHls(String url) {
    return methodChannel.invokeMethod('initPlayerWithHls', {
      'url': url,
    });
  }

  @override
  Future<void> play() {
    return methodChannel.invokeMethod<void>('play');
  }

  @override
  Future<void> pause() {
    return methodChannel.invokeMethod<void>('pause');
  }

  @override
  Future<void> seekTo(int position) {
    return methodChannel.invokeMethod<void>('seekTo', {
      'position': position,
    });
  }

  @override
  Future<void> setNativeControlsEnabled(bool isEnabled) {
    return methodChannel.invokeMethod<void>('setNativeControlsEnabled', {
      'isEnabled': isEnabled,
    });
  }

  @override
  Future<void> setResolution(String? resolutionId) {
    return methodChannel.invokeMethod<void>('setResolution', {
      'resolutionId': resolutionId,
    });
  }

  @override
  Stream<bool> get isPlayingStream =>
      _sharedStream.map((event) => event['isPlaying'] as bool);

  @override
  Stream<int> get positionStream =>
      _sharedStream.map((event) => event['position'] as int);

  @override
  Stream<int> get durationStream =>
      _sharedStream.map((event) => event['duration'] as int);

  @override
  Stream<int> get bufferingStream =>
      _sharedStream.map((event) => event['buffering'] as int);

  @override
  Stream<bool> get isLoadingStream =>
      _sharedStream.map((event) => event['isLoading'] as bool);

  @override
  Stream<bool> get isNativeControlsEnabled =>
      _sharedStream.map((event) => event['isNativeControlsEnabled'] as bool);

  @override
  Stream<String?> get selectedResolutionId =>
      _sharedStream.map((event) => event['selectedResolutionId'] as String?);

  @override
  Stream<List<VideoResolution>> get availableVideoResolutions {
    return _sharedStream.map((event) {
      try {
        final jsonString = event['availableResolutions'];
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          return decoded
              .map(
                  (e) => VideoResolution.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (e, stack) {
        debugPrint('Parsing error: $e\n$stack');
      }
      return <VideoResolution>[];
    });
  }
}
