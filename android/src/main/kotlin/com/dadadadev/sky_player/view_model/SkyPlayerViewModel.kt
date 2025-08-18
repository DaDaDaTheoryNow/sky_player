package com.dadadadev.sky_player.view_model

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.upstream.LoadErrorHandlingPolicy
import com.dadadadev.sky_player.media.PlayerController
import com.dadadadev.sky_player.media.PlayerEvent
import com.dadadadev.sky_player.media.TextureManager
import com.dadadadev.sky_player.media.TrackManager
import com.dadadadev.sky_player.models.Cues
import com.dadadadev.sky_player.policies.InfiniteRetryPolicy
import io.flutter.view.TextureRegistry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.shareIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber

private const val TAG = "SkyPlayer: SkyPlayerViewModel"

@UnstableApi
class SkyPlayerViewModel(
    context: Context,
    textureRegistry: TextureRegistry? = null,
    dataSourceFactory: DataSource.Factory? = null,
    retryPolicy: LoadErrorHandlingPolicy = InfiniteRetryPolicy(),
    trackSelectorOverride: DefaultTrackSelector? = null
) : ViewModel() {
    // Components (created with overrides or sensible defaults)
    private val trackSelector: DefaultTrackSelector = trackSelectorOverride ?: DefaultTrackSelector(context)
    private val textureManager = TextureManager(textureRegistry)
    private val playerController = PlayerController(
        context = context,
        dataSourceFactory = dataSourceFactory,
        trackSelector = trackSelector,
        retryPolicy = retryPolicy
    )
    private val trackManager = TrackManager(trackSelector)

    // Public state flow visible to observers
    private val _state = MutableStateFlow(SkyPlayerState())
    val state: StateFlow<SkyPlayerState> = _state.asStateFlow()

    // Shared ticker: cold flow shared as hot stream when observed
    private val positionTicker = flow {
        while (true) {
            emit(triplePosition())
            delay(500)
        }
    }.shareIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), replay = 1)

    init {
        observePlayerEvents()
        observePositionTicker()
    }

    // ---------------------------
    // Internal helpers
    // ---------------------------
    private fun triplePosition(): Triple<Long, Long, Long> {
        val pos = playerController.player.currentPosition.takeIf { it != C.TIME_UNSET } ?: 0L
        val dur = playerController.player.duration.takeIf { it != C.TIME_UNSET } ?: 0L
        val buffer = playerController.player.bufferedPosition.takeIf { it != C.TIME_UNSET } ?: 0L
        return Triple(pos, dur, buffer)
    }

    private fun observePlayerEvents() {
        viewModelScope.launch {
            playerController.events.collect { ev ->
                when (ev) {
                    is PlayerEvent.PlayingChanged -> {
                        _state.update { it.copy(isPlaying = ev.isPlaying) }
                        if (ev.isPlaying) startPollingPosition() else stopPollingPosition()
                    }
                    is PlayerEvent.PlaybackStateChanged -> handlePlaybackState(ev.state)
                    is PlayerEvent.Error -> handlePlaybackError(ev.ex)
                    is PlayerEvent.Cues -> _state.update { it.copy(currentCues = Cues(text = ev.text)) }
                    PlayerEvent.TracksChanged -> refreshTrackLists()
                    is PlayerEvent.VideoSizeChanged -> handleVideoSizeChanged(ev.videoSize)
                    PlayerEvent.RenderedFirstFrame -> _state.update { it.copy(isLoading = false) }
                }
            }
        }
    }

    private fun observePositionTicker() {
        viewModelScope.launch {
            positionTicker.collect { (pos, dur, buf) ->
                _state.update { it.copy(position = pos, duration = dur, buffering = buf) }
            }
        }
    }

    private fun handlePlaybackState(playbackState: Int) {
        when (playbackState) {
            Player.STATE_READY -> {
                _state.update { value ->
                    value.copy(
                        isPlaying = playerController.player.isPlaying,
                        position = playerController.player.currentPosition.takeIf { it != C.TIME_UNSET } ?: 0L,
                        duration = playerController.player.duration.takeIf { it != C.TIME_UNSET } ?: 0L,
                        isLoading = false
                    )
                }
                if (playerController.player.isPlaying) startPollingPosition()
            }
            Player.STATE_BUFFERING -> _state.update { it.copy(isPlaying = false, isLoading = true) }
            Player.STATE_ENDED, Player.STATE_IDLE -> stopPollingPosition()
            else -> {}
        }
    }

    private fun handlePlaybackError(ex: PlaybackException) {
        Timber.tag(TAG).e("playback error: ${ex.errorCode}: ${ex.message}")
        // Keep loading flag for network type IO errors
        if (ex.errorCode == PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED ||
            ex.errorCode == PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS) {
            _state.update { it.copy(isLoading = true) }
        }
    }

    private fun handleVideoSizeChanged(videoSize: VideoSize) {
        val vsw = videoSize.width
        val vsh = videoSize.height
        if (vsw > 0 && vsh > 0) {
            val aspectRatio = vsw.toDouble() / vsh.toDouble()
            _state.update { it.copy(videoAspectRatio = aspectRatio) }
            // adjust surface buffer if texture exists
            textureManager.currentTextureId()?.let {
                try {
                    textureManager.setDefaultBufferSize(vsw, vsh)
                } catch (t: Throwable) {
                    Timber.tag(TAG).w(t, "failed to set buffer size")
                }
            }
        }
    }

    private fun refreshTrackLists() {
        Timber.tag(TAG).i("refreshTrackLists")
        val resolutions = trackManager.listAvailableResolutions()
        val audio = trackManager.listAudioTracks(playerController.player) { id ->
            _state.update { it.copy(selectedAudioTrackId = id) }
        }
        val subtitles = trackManager.listSubtitleTracks(playerController.player)

        // keep selected ids if still present, else null
        _state.update {
            it.copy(
                availableVideoResolutions = resolutions,
                availableAudioTracks = audio,
                availableSubtitleTracks = subtitles,
                selectedResolutionId = if (resolutions.any { r -> r.id == it.selectedResolutionId }) it.selectedResolutionId else null,
                selectedSubtitleTrackId = if (subtitles.any { s -> s.id == it.selectedSubtitleTrackId }) it.selectedSubtitleTrackId else null,
                selectedAudioTrackId = if (audio.any { a -> a.id == it.selectedAudioTrackId }) it.selectedAudioTrackId else null,
//                isLoading = false
            )
        }
    }

    // ---------------------------
    // Texture API (public)
    // ---------------------------

    /**
     * Create SurfaceTexture entry, attach surface to player and return texture id (or null).
     * Safe to call multiple times; uses TextureManager for safe cleanup.
     */
    @Synchronized
    fun createTextureForPlayer(): Long? {
        val entryId = textureManager.createSurface() ?: return null
        val surface = textureManager.getSurface()
        playerController.attachSurface(surface)
        _state.update { it.copy(textureId = entryId) }
        Timber.tag(TAG).i("createTextureForPlayer id=$entryId")
        return entryId
    }

    @Synchronized
    fun setSurfaceSize(widthPx: Int, heightPx: Int) {
        textureManager.setDefaultBufferSize(widthPx, heightPx)
    }

    @Synchronized
    fun releaseTexture() {
        try {
            playerController.attachSurface(null)
        } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "releaseTexture: detach player surface failed")
        }

        textureManager.release()
        _state.update { it.copy(textureId = null) }
    }

    // ---------------------------
    // Track selection API
    // ---------------------------
    fun setResolution(resolutionId: String?) {
        val result = trackManager.selectResolution(resolutionId)
        if (result.applied) {
            _state.update { it.copy(selectedResolutionId = resolutionId) }
        } else {
            Timber.tag(TAG).w("setResolution: failed to apply $resolutionId")
        }
    }

    fun setAudioTrack(languageCode: String?) {
        val result = trackManager.selectAudioTrack(languageCode)
        if (result.applied) {
            _state.update { it.copy(selectedAudioTrackId = languageCode) }
        } else {
            Timber.tag(TAG).w("setAudioTrack: failed to apply $languageCode")
            return
        }
    }

    fun setSubtitleTrack(trackId: String?) {
        val result = trackManager.selectSubtitleTrack(trackId)
        if (result.applied) {
            _state.update { it.copy(selectedSubtitleTrackId = trackId) }
        } else {
            Timber.tag(TAG).w("setSubtitleTrack: failed to apply $trackId")
            return
        }
    }

    // ---------------------------
    // High-level player API
    // ---------------------------
    fun initPlayerWithNetwork(url: String) {
        playerController.initWithUrl(url)
    }

    fun play() = playerController.play()
    fun pause() = playerController.pause()

    fun seekTo(position: Long) {
        _state.update { it.copy(position = position, isLoading = true) }
        playerController.seekTo(position)
    }

    // ---------------------------
    // Polling helpers
    // ---------------------------
    private var isPolling = false
    private fun startPollingPosition() {
        if (isPolling) return
        isPolling = true
        viewModelScope.launch(Dispatchers.Main) {
            while (isPolling) {
                if (playerController.player.isPlaying) {
                    _state.update { value ->
                        value.copy(
                            position = playerController.player.currentPosition.takeIf { it != C.TIME_UNSET } ?: 0L,
                            duration = playerController.player.duration.takeIf { it != C.TIME_UNSET } ?: 0L,
                            buffering = playerController.player.bufferedPosition.takeIf { it != C.TIME_UNSET } ?: 0L
                        )
                    }
                }
                delay(500)
            }
        }
    }

    private fun stopPollingPosition() {
        isPolling = false
    }

    fun release() {
        try {
            stopPollingPosition()
        } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "release: stop failed")
        }

        try { releaseTexture() } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "release: releaseTexture failed")
        }

        try { playerController.release() } catch (t: Throwable) {
            Timber.tag(TAG).w(t, "release: playerController.release failed")
        }

        viewModelScope.coroutineContext.cancelChildren()
        Timber.tag(TAG).w("viewModel released")
    }

    override fun onCleared() {
        super.onCleared()
        release()
    }
}