package com.dadadadev.sky_player.view_model

import com.dadadadev.sky_player.models.AudioTrack
import com.dadadadev.sky_player.models.Cues
import com.dadadadev.sky_player.models.SubtitleTrack
import com.dadadadev.sky_player.models.VideoResolution

data class SkyPlayerState(
    val textureId: Long? = null,

    val isPlaying: Boolean = false,
    val position: Long = 0L,
    val duration: Long = 0L,
    val buffering: Long = 0L,
    val isLoading: Boolean = true,
    val videoAspectRatio: Double? = null,

    // resolution section
    val availableVideoResolutions: List<VideoResolution> = emptyList(),
    val selectedResolutionId: String? = null,

    // audio track section
    val availableAudioTracks: List<AudioTrack> = emptyList(),
    val selectedAudioTrackId: String? = null,

    // subtitles section
    val availableSubtitleTracks: List<SubtitleTrack> = emptyList(),
    val selectedSubtitleTrackId: String? = null,
    val currentCues: Cues = Cues(),
)