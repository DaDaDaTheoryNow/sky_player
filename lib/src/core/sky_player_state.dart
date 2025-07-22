import 'package:sky_player/src/models/video_resolution.dart';

class SkyPlayerState {
  final bool isPlaying;
  final int position;
  final int duration;
  final int buffering;
  final bool isLoading;
  final bool isNativeControlsEnabled;
  final bool isFullscreen;
  final String? selectedResolutionId;
  final List<VideoResolution> availableVideoResolutions;

  SkyPlayerState({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.buffering,
    required this.isLoading,
    required this.isNativeControlsEnabled,
    this.isFullscreen = false,
    this.selectedResolutionId,
    required this.availableVideoResolutions,
  });

  static SkyPlayerState initial() => SkyPlayerState(
        isPlaying: false,
        position: 0,
        duration: 0,
        buffering: 0,
        isLoading: true,
        isNativeControlsEnabled: false,
        isFullscreen: false,
        selectedResolutionId: null,
        availableVideoResolutions: [],
      );

  SkyPlayerState copyWith({
    bool? isPlaying,
    int? position,
    int? duration,
    int? buffering,
    bool? isLoading,
    bool? isNativeControlsEnabled,
    bool? isFullscreen,
    String? selectedResolutionId,
    List<VideoResolution>? availableVideoResolutions,
  }) {
    return SkyPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffering: buffering ?? this.buffering,
      isLoading: isLoading ?? this.isLoading,
      isNativeControlsEnabled:
          isNativeControlsEnabled ?? this.isNativeControlsEnabled,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      selectedResolutionId: selectedResolutionId ?? this.selectedResolutionId,
      availableVideoResolutions:
          availableVideoResolutions ?? this.availableVideoResolutions,
    );
  }
}
