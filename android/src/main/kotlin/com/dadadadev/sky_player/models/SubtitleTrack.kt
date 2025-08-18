package com.dadadadev.sky_player.models

import kotlinx.serialization.Serializable

@Serializable
data class SubtitleTrack(
    val id: String,           // language code or custom id (e.g. "en", "ru", "sdh")
    val language: String?,    // ISO language or null
    val label: String         // human readable label
)