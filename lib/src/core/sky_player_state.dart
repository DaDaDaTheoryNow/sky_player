import 'package:sky_player/sky_player.dart';
import 'package:sky_player/src/localization/sky_player_languages.dart';

/// Represents the immutable state of a SkyPlayer instance.
/// Encapsulates all player-related properties including playback, tracks, cues, and UI flags.
class SkyPlayerState {
  // -------------------------------
  // Core player properties
  // -------------------------------
  final int? textureId; // Native texture ID for rendering the video
  final bool isPlaying; // Playback state
  final int position; // Current playback position in milliseconds
  final int duration; // Total duration in milliseconds
  final int buffering; // Buffering percentage
  final bool isLoading; // Indicates whether the player is initializing/loading
  final bool isFullscreen; // UI fullscreen flag

  final double? videoAspectRatio; // Optional aspect ratio of the video

  // -------------------------------
  // Video resolution properties
  // -------------------------------
  final String? selectedResolutionId;
  final List<VideoResolution> availableVideoResolutions;

  // -------------------------------
  // Audio track properties
  // -------------------------------
  final String? selectedAudioTrackId;
  final List<AudioTrack> availableAudioTracks;

  // -------------------------------
  // Subtitle properties
  // -------------------------------
  final String? selectedSubtitleTrackId;
  final List<SubtitleTrack> availableSubtitleTracks;

  // -------------------------------
  // Current cues (subtitles or captions)
  // -------------------------------
  final Cues currentCues;

  // -------------------------------
  // Overlay Language
  // -------------------------------
  final SkyPlayerLanguages language;

  SkyPlayerState({
    required this.textureId,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.buffering,
    required this.isLoading,
    this.isFullscreen = false,
    this.videoAspectRatio,
    this.selectedResolutionId,
    required this.availableVideoResolutions,
    this.selectedAudioTrackId,
    required this.availableAudioTracks,
    this.selectedSubtitleTrackId,
    required this.availableSubtitleTracks,
    required this.currentCues,
    this.language = SkyPlayerLanguages.en,
  });

  /// Returns a default, initial state of the player.
  /// Useful for initializing state in providers or state management solutions.
  static SkyPlayerState initial() => SkyPlayerState(
        textureId: null,
        isPlaying: false,
        position: 0,
        duration: 0,
        buffering: 0,
        isLoading: true,
        isFullscreen: false,
        selectedResolutionId: null,
        availableVideoResolutions: [],
        selectedAudioTrackId: null,
        availableAudioTracks: [],
        selectedSubtitleTrackId: null,
        availableSubtitleTracks: [],
        currentCues: Cues(text: ''),
        language: SkyPlayerLanguages.en,
      );

  // Internal sentinel for nullable fields that need explicit "unset" logic in copyWith
  static const _unset = Object();

  /// Returns a new [SkyPlayerState] with updated fields.
  /// Supports nullable updates and explicitly "unset" values for some fields.
  SkyPlayerState copyWith({
    int? textureId,
    bool? isPlaying,
    int? position,
    int? duration,
    int? buffering,
    bool? isLoading,
    bool? isFullscreen,
    double? videoAspectRatio,
    Object? selectedResolutionId = _unset,
    List<VideoResolution>? availableVideoResolutions,
    String? selectedAudioTrackId,
    List<AudioTrack>? availableAudioTracks,
    Object? selectedSubtitleTrackId = _unset,
    List<SubtitleTrack>? availableSubtitleTracks,
    Cues? currentCues,
    SkyPlayerLanguages? language,
  }) {
    return SkyPlayerState(
      textureId: textureId ?? this.textureId,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffering: buffering ?? this.buffering,
      isLoading: isLoading ?? this.isLoading,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      videoAspectRatio: videoAspectRatio ?? this.videoAspectRatio,
      selectedResolutionId: selectedResolutionId == _unset
          ? this.selectedResolutionId
          : selectedResolutionId as String?,
      availableVideoResolutions:
          availableVideoResolutions ?? this.availableVideoResolutions,
      selectedAudioTrackId: selectedAudioTrackId ?? this.selectedAudioTrackId,
      availableAudioTracks: availableAudioTracks ?? this.availableAudioTracks,
      selectedSubtitleTrackId: selectedSubtitleTrackId == _unset
          ? this.selectedSubtitleTrackId
          : selectedSubtitleTrackId as String?,
      availableSubtitleTracks:
          availableSubtitleTracks ?? this.availableSubtitleTracks,
      currentCues: currentCues ?? this.currentCues,
      language: language ?? this.language,
    );
  }
}
