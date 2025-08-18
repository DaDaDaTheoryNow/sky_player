package com.dadadadev.sky_player.models

import kotlinx.serialization.Serializable

@Serializable
data class VideoResolution(
    val id: String,
    val width: Int,
    val height: Int,
    val bitrate: Int,
)