import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:sky_player/sky_player.dart';

class SkyPlayerBasicOverlay extends StatefulWidget {
  final SkyPlayerState state;
  final SkyPlayerController controller;
  final SkyPlayerLocalization localization;

  const SkyPlayerBasicOverlay({
    super.key,
    required this.state,
    required this.controller,
    this.localization =
        const SkyPlayerLocalization(language: SkyPlayerLanguages.ru),
  });

  @override
  State<SkyPlayerBasicOverlay> createState() => _SkyPlayerBasicOverlayState();
}

class _SkyPlayerBasicOverlayState extends State<SkyPlayerBasicOverlay> {
  bool _showControls = true;
  Timer? _hideTimer;
  bool _showSettings = false;
  bool _showQualitySettings = false;
  bool _showAudioSettings = false;

  // NEW: subtitles settings flag
  bool _showSubtitleSettings = false;

  bool? _wasPlaying;

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    _restartHideTimer();
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (_showControls &&
        widget.state.isPlaying &&
        !_showSettings &&
        !_showSubtitleSettings) {
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted &&
            _showControls &&
            widget.state.isPlaying &&
            !_showSettings &&
            !_showSubtitleSettings) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _openSettings() {
    _hideTimer?.cancel();
    setState(() {
      _showSettings = true;
      _showSubtitleSettings = false;
    });
  }

  void _closeSettings() {
    setState(() {
      _showSettings = false;
      _showQualitySettings = false;
      _showSubtitleSettings = false;
    });
    if (widget.state.isPlaying && _showControls) {
      _restartHideTimer();
    }
  }

  void _openQualitySettings() {
    setState(() {
      _showQualitySettings = true;
      _showSubtitleSettings = false;
      _showAudioSettings = false;
    });
  }

  void _closeQualitySettings() {
    setState(() {
      _showQualitySettings = false;
    });
  }

  void _openAudioSettings() {
    setState(() {
      _showAudioSettings = true;
      _showSubtitleSettings = false;
      _showQualitySettings = false;
    });
  }

  void _closeAudioSettings() {
    setState(() {
      _showAudioSettings = false;
    });
  }

  // NEW: open/close subtitles settings
  void _openSubtitleSettings() {
    setState(() {
      _showSubtitleSettings = true;
      _showQualitySettings = false;
      _showAudioSettings = false;
    });
  }

  void _closeSubtitleSettings() {
    setState(() {
      _showSubtitleSettings = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _wasPlaying = widget.state.isPlaying;
    _restartHideTimer();
  }

  @override
  void didUpdateWidget(covariant SkyPlayerBasicOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_wasPlaying != widget.state.isPlaying) {
      _wasPlaying = widget.state.isPlaying;
      if (widget.state.isPlaying) {
        if (_showControls && !_showSettings && !_showSubtitleSettings) {
          _restartHideTimer();
        }
      } else {
        _hideTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final progress = Duration(milliseconds: state.position);
    final buffered = Duration(milliseconds: state.buffering);
    final total = Duration(milliseconds: state.duration);
    final settingsWidth = MediaQuery.of(context).size.width * 0.6;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Stack(
            children: [
              // Blur effect for the entire overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black.withAlpha(128),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _openSettings,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (state.isLoading) return;

                    if (state.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(128),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: state.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Icon(
                            state.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withAlpha(176),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProgressBar(
                        progress: progress,
                        buffered: buffered,
                        total: total,
                        onSeek: (duration) {
                          controller.seekTo(duration.inMilliseconds);
                        },
                        onDragUpdate: (details) {
                          controller.seekTo(details.timeStamp.inMilliseconds);
                        },
                        onDragStart: (details) {
                          _hideTimer?.cancel();
                        },
                        onDragEnd: () {
                          if (widget.state.isPlaying &&
                              _showControls &&
                              !_showSettings &&
                              !_showSubtitleSettings) {
                            _restartHideTimer();
                          }
                        },
                        barHeight: 4,
                        progressBarColor: Colors.white,
                        baseBarColor: Colors.white.withAlpha(128),
                        bufferedBarColor: Colors.white.withAlpha(102),
                        thumbColor: Colors.white,
                        thumbGlowColor: Colors.white.withAlpha(128),
                        thumbRadius: 8,
                        thumbGlowRadius: 16,
                        timeLabelLocation: TimeLabelLocation.below,
                        timeLabelTextStyle: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 0,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatDuration(progress)} / ${_formatDuration(total)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              state.isFullscreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              if (state.isFullscreen) {
                                controller
                                    .closeFullscreenPlayerWithPop(context);
                              } else {
                                controller.openFullScreenExternally(
                                  context,
                                  // Do not dispose controller after closing fullscreen.
                                  forceDisposeController: false,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_showSettings)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSettings,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                top: 0,
                bottom: 0,
                right: _showSettings ? 0 : -settingsWidth,
                width: settingsWidth,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withAlpha(176),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 32),
                        child: _showQualitySettings
                            ? _buildQualitySettings()
                            : _showAudioSettings
                                ? _buildAudioSettings()
                                : _showSubtitleSettings
                                    ? _buildSubtitleSettings()
                                    : _buildMainSettings(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainSettings() {
    final subtitleCurrentLabel = widget.state.selectedSubtitleTrackId == null
        ? widget.localization.off
        : widget.state.availableSubtitleTracks
            .firstWhere((t) => t.id == widget.state.selectedSubtitleTrackId,
                orElse: () => SubtitleTrack(
                    id: widget.state.selectedSubtitleTrackId ?? '',
                    language: null,
                    label: widget.state.selectedSubtitleTrackId ?? ''))
            .label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                widget.localization.settings,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _closeSettings,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildSettingsItem(
                icon: Icons.high_quality,
                title: widget.localization.quality,
                subtitle: widget.state.selectedResolutionId ??
                    widget.localization.auto,
                onTap: _openQualitySettings,
              ),
              _buildSettingsItem(
                icon: Icons.subtitles,
                title: widget.localization.subtitles,
                subtitle: subtitleCurrentLabel,
                onTap: _openSubtitleSettings,
              ),
              _buildSettingsItem(
                icon: Icons.volume_up,
                title: 'Аудиодорожка',
                subtitle: widget.state.availableAudioTracks
                        .cast<AudioTrack?>()
                        .firstWhere(
                          (track) =>
                              track?.id == widget.state.selectedAudioTrackId,
                          orElse: () => null,
                        )
                        ?.label ??
                    widget.localization.auto,
                onTap: _openAudioSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQualitySettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _closeQualitySettings,
            ),
            const SizedBox(width: 8),
            Text(
              widget.localization.videoQuality,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildOptionItem(
                title: widget.localization.auto,
                isSelected: widget.state.selectedResolutionId == null,
                onTap: () => widget.controller.setResolution(null),
              ),
              ...widget.state.availableVideoResolutions.map(
                (res) => _buildOptionItem(
                  title: res.id,
                  isSelected: res.id == widget.state.selectedResolutionId,
                  onTap: () => widget.controller.setResolution(res.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _closeAudioSettings,
            ),
            const SizedBox(width: 8),
            Text(
              widget.localization.audioTrack,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: widget.state.availableAudioTracks
                .map(
                  (track) => _buildOptionItem(
                    title: track.label ?? track.id,
                    isSelected: track.id == widget.state.selectedAudioTrackId,
                    onTap: () => widget.controller.setAudioTrack(track.id),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _closeSubtitleSettings,
            ),
            const SizedBox(width: 8),
            Text(
              widget.localization.subtitles,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildOptionItem(
                title: widget.localization.off,
                isSelected: widget.state.selectedSubtitleTrackId == null,
                onTap: () => widget.controller.setSubtitleTrack(null),
              ),
              ...widget.state.availableSubtitleTracks.map(
                (t) => _buildOptionItem(
                  title: t.label,
                  isSelected: t.id == widget.state.selectedSubtitleTrackId,
                  onTap: () => widget.controller.setSubtitleTrack(t.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      dense: true,
      minLeadingWidth: 24,
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withAlpha(176),
          fontSize: 13,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildOptionItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.amber, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
