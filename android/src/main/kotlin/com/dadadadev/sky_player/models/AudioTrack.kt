package com.dadadadev.sky_player.models

import kotlinx.serialization.Serializable

@Serializable
data class AudioTrack(
    val id: String,
    val language: String?,
    val label: String?,
)