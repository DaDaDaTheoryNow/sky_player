package com.dadadadev.sky_player.view_model

import androidx.media3.ui.PlayerView
import kotlinx.serialization.Serializable

data class SkyPlayerState(
    val isPlaying: Boolean = false,
    val position: Long = 0L,
    val duration: Long = 0L,
    val buffering: Long = 0L,
    val isLoading: Boolean = true,
    val isNativeControlsEnabled: Boolean = false,
    val playerView: PlayerView? = null,
    val availableVideoResolutions: List<VideoResolution> = emptyList(),
    val selectedResolutionId: String? = null
)

@Serializable
data class VideoResolution(
    val id: String,
    val width: Int,
    val height: Int,
    val bitrate: Int,
)