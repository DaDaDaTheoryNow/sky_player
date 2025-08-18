package com.dadadadev.sky_player.media

import androidx.media3.common.C
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import com.dadadadev.sky_player.models.AudioTrack
import com.dadadadev.sky_player.models.SubtitleTrack
import com.dadadadev.sky_player.models.VideoResolution
import timber.log.Timber

private const val TAG = "SkyPlayer: TrackManager"

/**
 * Encapsulates extraction and selection of video resolutions, audio and subtitle tracks.
 *
 * NOTE: callers must access the underlying ExoPlayer/trackSelector from the main thread.
 */
@UnstableApi
class TrackManager(private val trackSelector: DefaultTrackSelector) {

    data class SelectionResult(
        val applied: Boolean,
    )

    // -------------------------
    // Listing helpers
    // -------------------------
    fun listAvailableResolutions(): List<VideoResolution> {
        val mapped = trackSelector.currentMappedTrackInfo ?: return emptyList()
        val out = mutableListOf<VideoResolution>()

        for (ri in 0 until mapped.rendererCount) {
            if (mapped.getRendererType(ri) != C.TRACK_TYPE_VIDEO) continue
            val groups = mapped.getTrackGroups(ri)
            for (gi in 0 until groups.length) {
                val group = groups[gi]
                for (ti in 0 until group.length) {
                    if (mapped.getTrackSupport(ri, gi, ti) == C.FORMAT_HANDLED) {
                        val fmt = group.getFormat(ti)
                        val id = "${fmt.width}x${fmt.height}"
                        out.add(VideoResolution(id = id, width = fmt.width, height = fmt.height, bitrate = fmt.bitrate))
                    }
                }
            }
        }

        return out.distinctBy { it.id }
            .sortedWith(compareByDescending<VideoResolution> { it.width }.thenByDescending { it.height })
    }

    fun listAudioTracks(
        player: androidx.media3.common.Player,
        onSelectedAudio: (String) -> Unit
    ): List<AudioTrack> {
        val out = mutableListOf<AudioTrack>()
        val tracks = player.currentTracks
        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_AUDIO) continue
            for (i in 0 until group.length) {
                val f = group.getTrackFormat(i)
                val id = f.language ?: "und"
                val label = f.label ?: f.language ?: "Unknown"

                val isSelected = group.isTrackSelected(i)

                if (isSelected) {
                    onSelectedAudio(id)
                }

                out.add(
                    AudioTrack(
                        id = id,
                        language = f.language,
                        label = label,
                    )
                )
            }
        }
        return out.distinctBy { it.id }
    }


    fun listSubtitleTracks(player: androidx.media3.common.Player): List<SubtitleTrack> {
        val out = mutableListOf<SubtitleTrack>()
        val tracks = player.currentTracks
        for (group in tracks.groups) {
            if (group.type != C.TRACK_TYPE_TEXT) continue
            for (i in 0 until group.length) {
                val f = group.getTrackFormat(i)
                val id = f.language ?: f.label ?: "und"
                val label = f.label ?: f.language ?: "Subtitles"
                out.add(SubtitleTrack(id = id, language = f.language, label = label))
            }
        }
        return out.distinctBy { it.id }
    }

    // -------------------------
    // Selection helpers
    // -------------------------

    /**
     * Apply resolution override by id (e.g. "1280x720").
     * - If resolutionId == null => clears video overrides.
     *
     * Must be called on the main thread.
     */
    fun selectResolution(resolutionId: String?): SelectionResult {
        val mapped = trackSelector.currentMappedTrackInfo ?: run {
            Timber.tag(TAG).w("selectResolution: no mapped track info")
            return SelectionResult(applied = false)
        }

        // Clear override
        if (resolutionId == null) {
            val params = trackSelector.buildUponParameters()
                .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                .build()
            trackSelector.setParameters(params)
            return SelectionResult(applied = true)
        }

        // Find and apply the override
        for (ri in 0 until mapped.rendererCount) {
            if (mapped.getRendererType(ri) != C.TRACK_TYPE_VIDEO) continue
            val groups = mapped.getTrackGroups(ri)
            for (gi in 0 until groups.length) {
                val group = groups[gi]
                for (ti in 0 until group.length) {
                    if (mapped.getTrackSupport(ri, gi, ti) != C.FORMAT_HANDLED) continue
                    val fmt = group.getFormat(ti)
                    if ("${fmt.width}x${fmt.height}" == resolutionId) {
                        val override = TrackSelectionOverride(group, ti)
                        val params = trackSelector.buildUponParameters()
                            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                            .addOverride(override)
                            .build()
                        trackSelector.setParameters(params)
                        return SelectionResult(applied = true)
                    }
                }
            }
        }

        Timber.tag(TAG).w("selectResolution: resolution not found: $resolutionId")
        return SelectionResult(applied = false)
    }

    /**
     * Select audio track by language code (e.g. "en") or clear when null.
     *
     * Must be called on the main thread.
     */
    fun selectAudioTrack(languageCode: String?): SelectionResult {
        val mapped = trackSelector.currentMappedTrackInfo ?: run {
            Timber.tag(TAG).w("selectAudioTrack: no mapped track info")
            return SelectionResult(applied = false)
        }

        if (languageCode == null) {
            val params = trackSelector.buildUponParameters()
                .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
                .setPreferredAudioLanguage(null)
                .build()
            trackSelector.setParameters(params)
            return SelectionResult(applied = true)
        }

        for (ri in 0 until mapped.rendererCount) {
            if (mapped.getRendererType(ri) != C.TRACK_TYPE_AUDIO) continue
            val groups = mapped.getTrackGroups(ri)
            for (gi in 0 until groups.length) {
                val group = groups[gi]
                for (ti in 0 until group.length) {
                    if (mapped.getTrackSupport(ri, gi, ti) != C.FORMAT_HANDLED) continue
                    val fmt = group.getFormat(ti)
                    if (fmt.language == languageCode) {
                        val override = TrackSelectionOverride(group, ti)
                        val params = trackSelector.buildUponParameters()
                            .clearOverridesOfType(C.TRACK_TYPE_AUDIO)
                            .addOverride(override)
                            .setPreferredAudioLanguage(languageCode)
                            .build()
                        trackSelector.setParameters(params)
                        return SelectionResult(applied = true)
                    }
                }
            }
        }

        Timber.tag(TAG).w("selectAudioTrack: language not found: $languageCode")
        return SelectionResult(applied = false)
    }

    /**
     * Select subtitle track by id (language or label based id), or clear when null.
     *
     * Must be called on the main thread.
     */
    fun selectSubtitleTrack(trackId: String?): SelectionResult {
        val mapped = trackSelector.currentMappedTrackInfo ?: run {
            Timber.tag(TAG).w("selectSubtitleTrack: no mapped track info")
            return SelectionResult(applied = false)
        }

        if (trackId == null) {
            val params = trackSelector.buildUponParameters()
                .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                .setPreferredTextLanguage(null)
                .build()
            trackSelector.setParameters(params)
            return SelectionResult(applied = true)
        }

        for (ri in 0 until mapped.rendererCount) {
            if (mapped.getRendererType(ri) != C.TRACK_TYPE_TEXT) continue
            val groups = mapped.getTrackGroups(ri)
            for (gi in 0 until groups.length) {
                val group = groups[gi]
                for (ti in 0 until group.length) {
                    if (mapped.getTrackSupport(ri, gi, ti) != C.FORMAT_HANDLED) continue
                    val fmt = group.getFormat(ti)
                    val id = fmt.language ?: fmt.label ?: "und"
                    if (id == trackId) {
                        val override = TrackSelectionOverride(group, ti)
                        val params = trackSelector.buildUponParameters()
                            .clearOverridesOfType(C.TRACK_TYPE_TEXT)
                            .addOverride(override)
                            .setPreferredTextLanguage(trackId)
                            .build()
                        trackSelector.setParameters(params)
                        return SelectionResult(applied = true)
                    }
                }
            }
        }

        Timber.tag(TAG).w("selectSubtitleTrack: id not found: $trackId")
        return SelectionResult(applied = false)
    }
}
