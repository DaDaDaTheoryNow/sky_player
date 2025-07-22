import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sky_player/src/models/video_resolution.dart';
import 'package:sky_player/src/video_player/video_player_platform_interface.dart';

import 'dart:async';

import 'sky_player_state.dart';

class SkyPlayerController {
  String? _url;
  String? get url => _url;

  final ValueNotifier<bool> isFullScreen = ValueNotifier(false);
  late final StreamController<bool> _isFullScreenController =
      StreamController<bool>.broadcast();

  SkyPlayerController() {
    isFullScreen.addListener(() {
      _isFullScreenController.add(isFullScreen.value);
    });
  }

  // TODO: check if hls, mp4...
  Future<void> initPlayer(String url) async {
    _url = url;
    await VideoPlayerPlatform.instance.initPlayerWithHls(url);
  }

  Future<void> play() => VideoPlayerPlatform.instance.play();
  Future<void> pause() => VideoPlayerPlatform.instance.pause();

  Future<void> showNativeControls() =>
      VideoPlayerPlatform.instance.setNativeControlsEnabled(true);
  Future<void> hideNativeControls() =>
      VideoPlayerPlatform.instance.setNativeControlsEnabled(false);

  Future<void> seekTo(int position) =>
      VideoPlayerPlatform.instance.seekTo(position);

  Future<void> setResolution(String? resolutionId) =>
      VideoPlayerPlatform.instance.setResolution(resolutionId);

  Stream<bool> get isPlayingStream =>
      VideoPlayerPlatform.instance.isPlayingStream;

  Stream<int> get positionStream => VideoPlayerPlatform.instance.positionStream;
  Stream<int> get durationStream => VideoPlayerPlatform.instance.durationStream;
  Stream<bool> get isLoadingStream =>
      VideoPlayerPlatform.instance.isLoadingStream;
  Stream<int> get bufferingStream =>
      VideoPlayerPlatform.instance.bufferingStream;

  Stream<bool> get isNativeControlsEnabled =>
      VideoPlayerPlatform.instance.isNativeControlsEnabled;

  Stream<String?> get selectedResolutionId =>
      VideoPlayerPlatform.instance.selectedResolutionId;

  Stream<List<VideoResolution>> get availableVideoResolutions =>
      VideoPlayerPlatform.instance.availableVideoResolutions;

  void openFullScreen() {
    isFullScreen.value = true;
  }

  void closeFullScreen() {
    isFullScreen.value = false;
  }

  Stream<bool> get isFullScreenStream =>
      _isFullScreenController.stream.startWith(isFullScreen.value);

  Stream<SkyPlayerState> get stateStream => Rx.combineLatest9<
          bool,
          int,
          int,
          int,
          bool,
          bool,
          bool,
          String?,
          List<VideoResolution>,
          SkyPlayerState>(
        isPlayingStream,
        positionStream,
        durationStream,
        bufferingStream,
        isLoadingStream,
        isNativeControlsEnabled,
        isFullScreenStream,
        selectedResolutionId,
        availableVideoResolutions,
        (isPlaying,
            position,
            duration,
            buffering,
            isLoading,
            isNativeControlsEnabled,
            isFullscreen,
            selectedResolutionId,
            availableVideoResolutions) {
          final newState = SkyPlayerState(
            isPlaying: isPlaying,
            position: position,
            duration: duration,
            buffering: buffering,
            isLoading: isLoading,
            isNativeControlsEnabled: isNativeControlsEnabled,
            isFullscreen: isFullscreen,
            selectedResolutionId: selectedResolutionId,
            availableVideoResolutions: availableVideoResolutions,
          );

          return newState;
        },
      );

  void dispose() {
    isFullScreen.dispose();
    _isFullScreenController.close();
  }
}
