package com.dadadadev.sky_player.view_model

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

@UnstableApi
class SkyPlayerViewModel(context: Context) : ViewModel() {
    private val trackSelector = DefaultTrackSelector(context)

    private val _player: ExoPlayer = ExoPlayer
        .Builder(context)
        .setTrackSelector(trackSelector)
        .build()
    val player: ExoPlayer get() = _player

    private val _state = MutableStateFlow(SkyPlayerState())
    val state = _state.asStateFlow()

    private var isPolling = false

    private val playerListener = object : Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _state.value = _state.value.copy(isPlaying = isPlaying)
            if (isPlaying) startPollingPosition() else stopPollingPosition()
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            when (playbackState) {
                Player.STATE_READY -> {
                    _state.value = _state.value.copy(
                        isPlaying = false,
                        position = _player.currentPosition,
                        duration = _player.duration.takeIf { it != C.TIME_UNSET } ?: 0L
                    )
                    if (_player.isPlaying) startPollingPosition()
                }
                Player.STATE_BUFFERING -> {
                    _state.value = _state.value.copy(
                        isPlaying = false,
                    )
                }
                Player.STATE_ENDED, Player.STATE_IDLE -> {
                    stopPollingPosition()
                }
                else -> {}
            }
        }

        override fun onTracksChanged(tracks: Tracks) {
            updateAvailableResolutions()
        }

        override fun onRenderedFirstFrame() {
            super.onRenderedFirstFrame()
            _state.update { it.copy(isLoading = false) }
        }
    }

    init {
        _player.addListener(playerListener)
    }

    private fun updateAvailableResolutions() {
        val resolutions = mutableListOf<VideoResolution>()
        val mapped = trackSelector.currentMappedTrackInfo ?: return

        for (ri in 0 until mapped.rendererCount) {
            if (mapped.getRendererType(ri) != C.TRACK_TYPE_VIDEO) continue

            val groups = mapped.getTrackGroups(ri)
            for (gi in 0 until groups.length) {
                val group = groups[gi]
                for (ti in 0 until group.length) {
                    if (mapped.getTrackSupport(ri, gi, ti) == C.FORMAT_HANDLED) {
                        val format = group.getFormat(ti)
                        val resolutionId = "${format.width}x${format.height}"

                        resolutions.add(
                            VideoResolution(
                                id = resolutionId,
                                width = format.width,
                                height = format.height,
                                bitrate = format.bitrate,
                            )
                        )
                    }
                }
            }
        }

        val uniqueResolutions = resolutions
            .distinctBy { it.id }
            .sortedWith(compareByDescending<VideoResolution> { it.width }.thenByDescending { it.height })

        _state.update {
            it.copy(
                availableVideoResolutions = uniqueResolutions,
                selectedResolutionId = if (uniqueResolutions.any { r -> r.id == it.selectedResolutionId }) {
                    it.selectedResolutionId
                } else {
                    uniqueResolutions.firstOrNull()?.id
                }
            )
        }
    }

    fun setResolution(resolutionId: String?) {
        val mapped = trackSelector.currentMappedTrackInfo ?: return
        val selectionOverride = resolutionId?.let { id ->
            for (ri in 0 until mapped.rendererCount) {
                if (mapped.getRendererType(ri) != C.TRACK_TYPE_VIDEO) continue

                val groups = mapped.getTrackGroups(ri)
                for (gi in 0 until groups.length) {
                    val group = groups[gi]
                    for (ti in 0 until group.length) {
                        if (mapped.getTrackSupport(ri, gi, ti) == C.FORMAT_HANDLED) {
                            val format = group.getFormat(ti)
                            if ("${format.width}x${format.height}" == id) {
                                return@let TrackSelectionOverride(group, ti)
                            }
                        }
                    }
                }
            }
            null
        } ?: return

        val parameters = trackSelector.buildUponParameters()
            .addOverride(
                selectionOverride
            )
            .build()

        trackSelector.setParameters(parameters)

        _state.update {
            it.copy(selectedResolutionId = resolutionId, isLoading = true)
        }
    }

    /**
     * Loads a new HLS stream from the provided URL.
     * Safe to call multiple times to switch videos on the fly.
     */
    fun initPlayerWithHls(url: String) {
        _player.stop()
        _player.clearMediaItems()

        val dataSourceFactory: DataSource.Factory = DefaultHttpDataSource.Factory()
            .setUserAgent("PlayerApp")
            .setAllowCrossProtocolRedirects(true)

        val mediaItem = MediaItem.fromUri(url)
        val hlsMediaSource = HlsMediaSource.Factory(dataSourceFactory)
            .createMediaSource(mediaItem)

        _player.setMediaSource(hlsMediaSource)
        _player.prepare()

        _player.playWhenReady = true
    }

    fun play() = _player.play()
    fun pause() = _player.pause()

    fun seekTo(position: Long) {
        _state.update { it.copy(position = position, isLoading = true) }
        _player.seekTo(position)
    }

    fun attachPlayerView(playerView: PlayerView) {
        _state.update { it.copy(playerView = playerView) }
    }

    fun detachPlayerView() {
        _state.update { it.copy(playerView = null) }
    }

    fun setNativeControlsEnabled(enabled: Boolean) {
        _state.update { it.copy(isNativeControlsEnabled = enabled) }
        _state.value.playerView?.let { it.useController = enabled }
    }

    private fun startPollingPosition() {
        if (isPolling) return
        isPolling = true
        viewModelScope.launch {
            while (isPolling) {
                if (_player.isPlaying) {
                    _state.value = _state.value.copy(
                        position = _player.currentPosition.takeIf { it != C.TIME_UNSET } ?: 0L,
                        duration = _player.duration.takeIf { it != C.TIME_UNSET } ?: 0L,
                        buffering = _player.bufferedPosition.takeIf { it != C.TIME_UNSET } ?: 0L,
                    )
                }
                delay(500)
            }
        }
    }

    private fun stopPollingPosition() {
        isPolling = false
    }

    override fun onCleared() {
        stopPollingPosition()
        _player.removeListener(playerListener)
        _player.release()
    }
}