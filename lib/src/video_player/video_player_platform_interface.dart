import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sky_player/src/models/video_resolution.dart';

import 'video_player_method_channel.dart';

abstract class VideoPlayerPlatform extends PlatformInterface {
  VideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPlatform _instance = MethodChannelVideoPlayer();

  static VideoPlayerPlatform get instance => _instance;

  static set instance(VideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initPlayerWithHls(String url) {
    throw UnimplementedError('initPlayerWithHls() has not been implemented.');
  }

  Future<void> play() {
    throw UnimplementedError('play() has not been implemented.');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() has not been implemented.');
  }

  Future<void> setNativeControlsEnabled(bool isEnabled) {
    throw UnimplementedError(
        'setNativeControlsEnabled() has not been implemented.');
  }

  Future<void> seekTo(int position) {
    throw UnimplementedError('seekTo() has not been implemented.');
  }

  Future<void> setResolution(String? resolutionId) {
    throw UnimplementedError('setResolution() has not been implemented.');
  }

  Stream<bool> get isPlayingStream {
    throw UnimplementedError('isPlayingStream has not been implemented.');
  }

  Stream<int> get positionStream {
    throw UnimplementedError('positionStream has not been implemented.');
  }

  Stream<int> get durationStream {
    throw UnimplementedError('durationStream has not been implemented.');
  }

  Stream<int> get bufferingStream {
    throw UnimplementedError('bufferingStream has not been implemented.');
  }

  Stream<bool> get isLoadingStream {
    throw UnimplementedError('isLoadingStream has not been implemented.');
  }

  Stream<bool> get isNativeControlsEnabled {
    throw UnimplementedError('durationStream has not been implemented.');
  }

  Stream<String?> get selectedResolutionId {
    throw UnimplementedError('selectedResolutionId has not been implemented.');
  }

  Stream<List<VideoResolution>> get availableVideoResolutions {
    throw UnimplementedError(
        'availableVideoResolutions has not been implemented.');
  }
}
