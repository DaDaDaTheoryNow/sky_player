package com.dadadadev.sky_player.media

import android.content.Context
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.exoplayer.upstream.LoadErrorHandlingPolicy
import com.dadadadev.sky_player.policies.InfiniteRetryPolicy
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.coroutines.CoroutineContext

private const val TAG = "SkyPlayer: PlayerController"

/**
 * Simplified controller responsible for player creation, attaching surface,
 * init/play/pause/seek. It emits events through a small event flow.
 *
 * Constructor takes dependencies so they can be replaced in tests.
 */
@UnstableApi
class PlayerController(
    private val context: Context,
    private val coroutineContext: CoroutineContext = Dispatchers.Main,
    dataSourceFactory: androidx.media3.datasource.DataSource.Factory? = null,
    trackSelector: DefaultTrackSelector = DefaultTrackSelector(context),
    retryPolicy: LoadErrorHandlingPolicy = InfiniteRetryPolicy()
) {
    private val _events = MutableSharedFlow<PlayerEvent>(replay = 1)
    val events = _events.asSharedFlow()

    private var _dataSourceFactory = dataSourceFactory ?: createDefaultDataSourceFactory()
    private var _trackSelector = trackSelector
    private var _retryPolicy = retryPolicy

    private var _player: ExoPlayer? = null
    val player: ExoPlayer
        get() = _player ?: createPlayer().also { _player = it }

    private val mediaSourceFactory: DefaultMediaSourceFactory by lazy {
        DefaultMediaSourceFactory(_dataSourceFactory)
            .setLoadErrorHandlingPolicy(_retryPolicy)
    }

    private fun createDefaultDataSourceFactory(): DefaultHttpDataSource.Factory {
        return DefaultHttpDataSource.Factory()
            .setUserAgent("PlayerApp")
            .setAllowCrossProtocolRedirects(true)
    }

    private fun createPlayer(): ExoPlayer {
        return ExoPlayer.Builder(context)
            .setMediaSourceFactory(mediaSourceFactory)
            .setTrackSelector(_trackSelector)
            .build()
            .also { configureListener(it) }
    }

    private val playerListenerObject = object : androidx.media3.common.Player.Listener {
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            emit(PlayerEvent.PlayingChanged(isPlaying))
        }
        override fun onPlaybackStateChanged(playbackState: Int) {
            emit(PlayerEvent.PlaybackStateChanged(playbackState))
        }
        override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
            emit(PlayerEvent.Error(error))
        }
        override fun onCues(cueGroup: androidx.media3.common.text.CueGroup) {
            val text = cueGroup.cues.joinToString("\n") { (it.text ?: "").toString().trim() }
            emit(PlayerEvent.Cues(text))
        }
        override fun onTracksChanged(tracks: androidx.media3.common.Tracks) {
            emit(PlayerEvent.TracksChanged)
        }
        override fun onVideoSizeChanged(videoSize: androidx.media3.common.VideoSize) {
            emit(PlayerEvent.VideoSizeChanged(videoSize))
        }
        override fun onRenderedFirstFrame() {
            emit(PlayerEvent.RenderedFirstFrame)
        }
    }

    private fun configureListener(p: ExoPlayer) {
        p.addListener(playerListenerObject)
    }

    private fun emit(ev: PlayerEvent) {
        CoroutineScope(coroutineContext).launch { _events.emit(ev) }
    }

    fun attachSurface(surface: Surface?) {
        player.setVideoSurface(surface)
    }

    fun initWithUrl(url: String) {
        try {
            player.stop()
            player.clearMediaItems()

            val mi = MediaItem.fromUri(url)
            player.setMediaItem(mi)
            player.prepare()
            player.playWhenReady = true
        } catch (e: Exception) {
            Timber.e(e, "Error initializing player with URL: $url")
            throw e
        }
    }

    fun play() = player.play()
    fun pause() = player.pause()

    @OptIn(ExperimentalCoroutinesApi::class)
    fun release() {
        try {
            _player?.let {
                it.removeListener(playerListenerObject)
                Timber.tag(TAG).d("release: player state listener released")

                it.release()
                Timber.tag(TAG).d("release: player released")
            }
        } finally {
            _player = null
            _events.resetReplayCache()
        }
    }

    fun seekTo(position: Long) = player.seekTo(position)
}

// Small sealed class for events — more typed and future-proof than raw callbacks.
sealed class PlayerEvent {
    data class PlayingChanged(val isPlaying: Boolean) : PlayerEvent()
    data class PlaybackStateChanged(val state: Int) : PlayerEvent()
    data class Error(val ex: androidx.media3.common.PlaybackException) : PlayerEvent()
    data class Cues(val text: String) : PlayerEvent()
    object TracksChanged : PlayerEvent()
    data class VideoSizeChanged(val videoSize: androidx.media3.common.VideoSize) : PlayerEvent()
    object RenderedFirstFrame : PlayerEvent()
}
